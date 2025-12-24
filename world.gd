extends Node2D
class_name InfiniteWorld

# Infinite, deterministic, noise-based world gen (FAST, non-bloated)
# - Water / sand / dirt / stone layers from a height field
# - Infinite chunk streaming
# - Forest + mountain emojis spawned from HEIGHT
# - Hover shows an info box
# - Click sends a signal

signal prop_clicked(prop_kind: String, world_pos: Vector2, chunk: Vector2i, local_px: Vector2i)
signal prop_right_clicked(prop : EmojiProp)

@export var seed: int = 12345
@export var chunk_size: int = 256
@export var view_radius_chunks: int = 4
@export var target_path: NodePath
@export var pixels_per_unit: float = 1.0

# How many chunks to generate per frame (keeps movement smooth)
@export var new_chunks_per_frame: int = 2

# --- Terrain noise ---
@export var continent_scale: float = 2200.0
@export var detail_scale: float = 280.0
@export var warp_scale: float = 600.0
@export var warp_strength: float = 220.0

# --- Terrain thresholds ---
@export var sea_level: float = 0.0
@export var coast_width: float = 0.06
@export var mountain_level: float = 0.55

# --- Ridge influence ---
@export var ridge_strength: float = 0.55

# --- Colors ---
@export var water_color: Color = Color(35/255.0, 120/255.0, 200/255.0, 1)
@export var sand_color: Color  = Color(214/255.0, 198/255.0, 136/255.0, 1)
@export var dirt_color: Color  = Color(55/255.0, 170/255.0, 80/255.0, 1)
@export var stone_color: Color = Color(120/255.0, 125/255.0, 130/255.0, 1)

# --- Emoji props ---
@export var spawn_emojis: bool = true
@export var emoji_step: int = 32
@export var max_emojis_per_chunk: int = 40
@export var emoji_scale: float = 0.9

# Forests
@export var forest_min_height: float = 0.10
@export var forest_max_height: float = 0.45
@export var forest_density: float = 0.10
@export var forest_emojis: Array[String] = ["🌲", "🌳", "🌴"]

# Mountains
@export var mountain_min_height: float = 0.65
@export var mountain_density: float = 0.08
@export var mountain_emojis: Array[String] = ["⛰️", "🏔️", "🗻"]

# Fish (water)
@export var fish_density: float = 0.05
@export var fish_emojis: Array[String] = ["🐟", "🐠", "🐡", "🦈", "🐙"]

# Sand (coast)
@export var sand_density: float = 0.06
@export var sand_emojis: Array[String] = ["🏜️", "🏖️"]

# Forage (plains)
@export var forage_min_height: float = 0.05
@export var forage_max_height: float = 0.40
@export var forage_density: float = 0.07
@export var forage_emojis: Array[String] = ["🌿", "🍄", "🌾", "🥕", "🥬"]

# --- Hover info box ---
@export var info_padding: Vector2 = Vector2(10, 8)
@export var info_offset: Vector2 = Vector2(18, 18) # offset from mouse
@export var info_font_size: int = 16

@onready var chunks_root: Node2D = $Chunks
var _target: Node2D

var _chunk_sprites: Dictionary = {} # Vector2i -> Sprite2D
var _chunk_decor: Dictionary = {}   # Vector2i -> Node2D
var _last_center: Vector2i = Vector2i(2147483647, 2147483647)
var _spawn_queue: Array = []        # Vector2i

# Godot noise (fast)
var _n_continent: FastNoiseLite
var _n_detail: FastNoiseLite
var _n_warp_x: FastNoiseLite
var _n_warp_y: FastNoiseLite
var _n_ridge: FastNoiseLite

# UI tooltip (CanvasLayer)
var _ui_layer: CanvasLayer
var _info_panel: PanelContainer
var _info_label: Label
var _act_panel: PanelContainer
var _act_box: VBoxContainer
var _hovering_prop: EmojiProp


# ----------------------------
# Emoji prop node (hover + click)
# ----------------------------
class EmojiProp:
	extends Label

	signal hovered(prop: EmojiProp)
	signal unhovered(prop: EmojiProp)
	signal clicked(prop: EmojiProp)
	signal right_clicked(prop: EmojiProp)

	var kind: String = ""
	var chunk: Vector2i = Vector2i.ZERO
	var local_px: Vector2i = Vector2i.ZERO
	var world_pos: Vector2 = Vector2.ZERO
	var height_value: float = 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		focus_mode = Control.FOCUS_NONE

		mouse_entered.connect(_on_enter)
		mouse_exited.connect(_on_exit)
		gui_input.connect(_on_gui_input)

	func _on_enter() -> void:
		emit_signal("hovered", self)

	func _on_exit() -> void:
		emit_signal("unhovered", self)

	func _on_gui_input(ev: InputEvent) -> void:
		if ev is InputEventMouseButton:
			var mb = ev as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
				emit_signal("clicked", self)
			elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
				print('r')
				emit_signal("right_clicked", self)


func _ready() -> void:
	if target_path != NodePath():
		_target = get_node_or_null(target_path) as Node2D

	_setup_noise()
	_setup_ui()
	_update_needed_chunks(true)


func _process(_dt: float) -> void:
	_update_needed_chunks(false)
	_spawn_some_from_queue()
	_update_info_panel_position()


func _setup_ui() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 100
	add_child(_ui_layer)

	_info_panel = PanelContainer.new()
	_info_panel.visible = false
	_ui_layer.add_child(_info_panel)

	_info_label = Label.new()
	_info_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_info_label.add_theme_font_size_override("font_size", info_font_size)
	_info_panel.add_child(_info_label)

	# Give it some padding via theme overrides (simple + works everywhere)
	_info_panel.add_theme_constant_override("padding_left", int(info_padding.x))
	_info_panel.add_theme_constant_override("padding_right", int(info_padding.x))
	_info_panel.add_theme_constant_override("padding_top", int(info_padding.y))
	_info_panel.add_theme_constant_override("padding_bottom", int(info_padding.y))
	
	_act_panel = PanelContainer.new()
	_act_panel.visible = false
	_ui_layer.add_child(_act_panel)

	_act_box = VBoxContainer.new()
	_act_panel.add_child(_act_box)

	# Give it some padding via theme overrides (simple + works everywhere)
	_act_panel.add_theme_constant_override("padding_left", int(info_padding.x))
	_act_panel.add_theme_constant_override("padding_right", int(info_padding.x))
	_act_panel.add_theme_constant_override("padding_top", int(info_padding.y))
	_act_panel.add_theme_constant_override("padding_bottom", int(info_padding.y))


func _update_info_panel_position() -> void:
	if _info_panel == null:
		return
	if not _info_panel.visible:
		return

	var mp = get_viewport().get_mouse_position()
	_info_panel.position = mp + info_offset


func _show_info_for_prop(p: EmojiProp) -> void:
	_hovering_prop = p
	_info_panel.visible = true

	var title = ""
	if p.kind == "forest":
		title = "Forest"
	elif p.kind == "mountain":
		title = "Mountain"
	else:
		title = p.kind

	_info_label.text = "%s\nChunk: (%d, %d)\nLocal: (%d, %d)\nHeight: %.3f" % [
		title, p.chunk.x, p.chunk.y, p.local_px.x, p.local_px.y, p.height_value
	]

func _show_action_menu(p: EmojiProp, a: Array, f : Callable) -> void:
	_hovering_prop = p
	var mp = get_viewport().get_mouse_position()
	_act_panel.position = mp + info_offset
	_act_panel.visible = true

	var title = "Actions"

	for child in _act_box.get_children():
		child.queue_free()

	for action_data in a:
		var x = Button.new()
		x.text = action_data.get("label", action_data.get("name", title))
		var disabled = action_data.get("disabled", false)
		x.disabled = disabled
		if not disabled:
			x.pressed.connect(func():
				_act_panel.visible = false
				f.call(action_data, p.kind)
			)
		_act_box.add_child(x)

func _hide_info_for_prop(p: EmojiProp) -> void:
	if _hovering_prop == p:
		_hovering_prop = null
		_info_panel.visible = false


func _setup_noise() -> void:
	_n_continent = FastNoiseLite.new()
	_n_continent.seed = seed
	_n_continent.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_n_continent.frequency = 1.0 / max(1.0, continent_scale)

	_n_detail = FastNoiseLite.new()
	_n_detail.seed = seed ^ 0xBEEF
	_n_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_n_detail.frequency = 1.0 / max(1.0, detail_scale)
	_n_detail.fractal_type = FastNoiseLite.FRACTAL_FBM
	_n_detail.fractal_octaves = 4
	_n_detail.fractal_gain = 0.5
	_n_detail.fractal_lacunarity = 2.0

	_n_warp_x = FastNoiseLite.new()
	_n_warp_x.seed = seed ^ 0x1234
	_n_warp_x.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_n_warp_x.frequency = 1.0 / max(1.0, warp_scale)

	_n_warp_y = FastNoiseLite.new()
	_n_warp_y.seed = seed ^ 0x5678
	_n_warp_y.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_n_warp_y.frequency = 1.0 / max(1.0, warp_scale)

	_n_ridge = FastNoiseLite.new()
	_n_ridge.seed = seed ^ 0xCAFE
	_n_ridge.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_n_ridge.frequency = 1.0 / max(1.0, detail_scale * 0.8)
	_n_ridge.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	_n_ridge.fractal_octaves = 3
	_n_ridge.fractal_gain = 0.6
	_n_ridge.fractal_lacunarity = 2.0


func _update_needed_chunks(force: bool) -> void:
	var pos: Vector2 = global_position
	if _target != null:
		pos = _target.global_position

	var wxi: int = int(round(pos.x * pixels_per_unit))
	var wyi: int = int(round(pos.y * pixels_per_unit))
	var ccx: int = _floor_div(wxi, chunk_size)
	var ccy: int = _floor_div(wyi, chunk_size)
	var center: Vector2i = Vector2i(ccx, ccy)

	if (not force) and center == _last_center:
		return
	_last_center = center

	var needed: Dictionary = {}
	var r: int = view_radius_chunks

	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var c = Vector2i(ccx + dx, ccy + dy)
			needed[c] = true
			if not _chunk_sprites.has(c) and not _spawn_queue.has(c):
				_spawn_queue.append(c)

	# unload far chunks
	for k in _chunk_sprites.keys():
		if not needed.has(k):
			if _chunk_decor.has(k):
				_chunk_decor[k].queue_free()
				_chunk_decor.erase(k)
			_chunk_sprites[k].queue_free()
			_chunk_sprites.erase(k)

			# If tooltip was showing something from this chunk, hide it
			if _hovering_prop != null and _hovering_prop.chunk == k:
				_hovering_prop = null
				_info_panel.visible = false


func _spawn_some_from_queue() -> void:
	var budget = max(1, new_chunks_per_frame)
	while budget > 0 and _spawn_queue.size() > 0:
		var c: Vector2i = _spawn_queue.pop_front()
		_make_chunk(c.x, c.y)
		budget -= 1


func _make_chunk(cx: int, cy: int) -> void:
	var result: Dictionary = _render_chunk(cx, cy)
	var img: Image = result["image"]
	var heights: PackedFloat32Array = result["heights"]

	var tex = ImageTexture.create_from_image(img)

	var sp = Sprite2D.new()
	sp.centered = false
	sp.texture = tex
	sp.position = Vector2(cx * chunk_size, cy * chunk_size) / pixels_per_unit
	chunks_root.add_child(sp)

	var key = Vector2i(cx, cy)
	_chunk_sprites[key] = sp

	if spawn_emojis:
		_spawn_props_for_chunk(key, heights, sp)


func _render_chunk(cx: int, cy: int) -> Dictionary:
	var S = chunk_size
	var img = Image.create(S, S, false, Image.FORMAT_RGBA8)

	var bytes = PackedByteArray()
	bytes.resize(S * S * 4)

	var heights = PackedFloat32Array()
	heights.resize(S * S)

	var wr = int(round(water_color.r * 255.0))
	var wg = int(round(water_color.g * 255.0))
	var wb = int(round(water_color.b * 255.0))
	var sr = int(round(sand_color.r * 255.0))
	var sg = int(round(sand_color.g * 255.0))
	var sb = int(round(sand_color.b * 255.0))
	var dr = int(round(dirt_color.r * 255.0))
	var dg = int(round(dirt_color.g * 255.0))
	var db = int(round(dirt_color.b * 255.0))
	var mr = int(round(stone_color.r * 255.0))
	var mg = int(round(stone_color.g * 255.0))
	var mb = int(round(stone_color.b * 255.0))

	var wx0 = cx * S
	var wy0 = cy * S
	var coast_den = max(0.0001, coast_width)

	for y in range(S):
		var wy = wy0 + y
		for x in range(S):
			var wx = wx0 + x

			# Domain warp
			var wxn = _n_warp_x.get_noise_2d(wx, wy) * warp_strength
			var wyn = _n_warp_y.get_noise_2d(wx + 1337, wy - 7331) * warp_strength
			var sx = float(wx) + wxn
			var sy = float(wy) + wyn

			# Base height
			var cont = _n_continent.get_noise_2d(sx, sy) * 0.85
			var det  = _n_detail.get_noise_2d(sx, sy) * 0.35
			var h = cont + det

			# Ridged boost (mountain flavor)
			var r = (_n_ridge.get_noise_2d(sx, sy) + 1.0) * 0.5
			h += (r - 0.5) * ridge_strength * 0.35

			heights[y * S + x] = h

			var o = (y * S + x) * 4

			if h < sea_level:
				bytes[o] = wr; bytes[o + 1] = wg; bytes[o + 2] = wb; bytes[o + 3] = 255
				continue

			var coast_t = (h - sea_level) / coast_den
			if coast_t < 1.0:
				bytes[o] = sr; bytes[o + 1] = sg; bytes[o + 2] = sb; bytes[o + 3] = 255
			else:
				if h > mountain_level:
					bytes[o] = mr; bytes[o + 1] = mg; bytes[o + 2] = mb; bytes[o + 3] = 255
				else:
					bytes[o] = dr; bytes[o + 1] = dg; bytes[o + 2] = db; bytes[o + 3] = 255

	img.set_data(S, S, false, Image.FORMAT_RGBA8, bytes)
	return {"image": img, "heights": heights}


# ----------------------------
# Forest + Mountain emoji props (hover tooltip + click signal)
# ----------------------------
func _spawn_props_for_chunk(c: Vector2i, heights: PackedFloat32Array, sp: Sprite2D) -> void:
	if _chunk_decor.has(c):
		_chunk_decor[c].queue_free()
		_chunk_decor.erase(c)

	var decor = Node2D.new()
	sp.add_child(decor)
	_chunk_decor[c] = decor

	var rng = RandomNumberGenerator.new()
	rng.seed = seed ^ (c.x * 928371 + c.y * 364583)

	var S = chunk_size
	var placed = 0
	var step = max(8, emoji_step)

	for y in range(0, S, step):
		for x in range(0, S, step):
			if placed >= max_emojis_per_chunk:
				return

			var h = float(heights[y * S + x])
			var roll = rng.randf()
			var coast_max = sea_level + coast_width

			if h < sea_level:
				if roll < fish_density:
					_add_prop(decor, "fish", _pick_emoji(rng, fish_emojis), c, Vector2i(x, y), h)
					placed += 1
			elif h < coast_max:
				if roll < sand_density:
					_add_prop(decor, "sand", _pick_emoji(rng, sand_emojis), c, Vector2i(x, y), h)
					placed += 1
			elif h > mountain_min_height:
				if roll < mountain_density:
					_add_prop(decor, "mountain", _pick_emoji(rng, mountain_emojis), c, Vector2i(x, y), h)
					placed += 1
			elif h > forest_min_height and h < forest_max_height:
				if roll < forest_density:
					_add_prop(decor, "forest", _pick_emoji(rng, forest_emojis), c, Vector2i(x, y), h)
					placed += 1
			elif h > forage_min_height and h < forage_max_height:
				if roll < forage_density:
					_add_prop(decor, "forage", _pick_emoji(rng, forage_emojis), c, Vector2i(x, y), h)
					placed += 1

func _pick_emoji(rng: RandomNumberGenerator, options: Array[String]) -> String:
	if options.is_empty():
		return ""
	return options[rng.randi_range(0, options.size() - 1)]


func _add_prop(parent: Node2D, kind: String, emoji: String, chunk: Vector2i, local_px: Vector2i, height_value: float) -> void:
	var p = EmojiProp.new()
	p.text = emoji
	p.scale = Vector2(emoji_scale, emoji_scale)
	p.position = Vector2(local_px.x, local_px.y) / pixels_per_unit
	p.kind = kind
	p.chunk = chunk
	p.local_px = local_px
	p.height_value = height_value

	# Compute world position (in Node2D space)
	var world_px = Vector2(
		float(chunk.x * chunk_size + local_px.x),
		float(chunk.y * chunk_size + local_px.y)
	)
	p.world_pos = world_px / pixels_per_unit

	# Hook hover/click
	p.hovered.connect(_on_prop_hovered)
	p.unhovered.connect(_on_prop_unhovered)
	p.clicked.connect(_on_prop_clicked)
	p.right_clicked.connect(_on_prop_right_clicked)

	parent.add_child(p)


func _on_prop_hovered(p: EmojiProp) -> void:
	_show_info_for_prop(p)


func _on_prop_unhovered(p: EmojiProp) -> void:
	_hide_info_for_prop(p)

func _on_prop_clicked(p: EmojiProp) -> void:
	emit_signal("prop_clicked", p.kind, p.world_pos, p.chunk, p.local_px)
	
func _on_prop_right_clicked(p: EmojiProp) -> void:
	emit_signal("prop_right_clicked", p)


# ----------------------------
# Integer floor division (handles negatives)
# ----------------------------
func _floor_div(a: int, b: int) -> int:
	var q: int = a / b
	var r: int = a % b
	if r != 0 and ((r > 0) != (b > 0)):
		q -= 1
	return q

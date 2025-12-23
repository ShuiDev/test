extends TileMap

var tile_source_id: int = 2

@export var forest_tile_pools: Dictionary = {
	"default": [Vector2i(3, 34)]
}

@export var min_square_size: int = 6
@export var max_square_size: int = 16
@export var min_square_size_recursive: int = 4
@export var max_depth: int = 3
@export var circles_per_square_corner: int = 1

@export var debug_draw_circles: bool = true  # set false if you only want squares

var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	
	# If you want to be sure it's on-screen, you can use the camera tile:
	# var cam := get_viewport().get_camera_2d()
	# var center_cell := Vector2i(0, 0)
	# if cam:
	#     center_cell = local_to_map(to_local(cam.global_position))
	# else:
	#     center_cell = Vector2i(0, 0)
	# generate_forest(center_cell, "default")
	
	generate_forest(Vector2i(0, 0), "default")


func generate_forest(center_cell: Vector2i, forest_type: String = "default") -> void:
	var size := rng.randi_range(min_square_size, max_square_size)
	_grow_square_recursive(center_cell, size, forest_type, 0)


func _grow_square_recursive(
	center_cell: Vector2i,
	size: int,
	forest_type: String,
	depth: int
) -> void:
	if depth > max_depth:
		return
	if size < min_square_size_recursive:
		return

	# 1. Paint this square
	_paint_square(center_cell, size, forest_type)

	# 2. Compute corners in tile coords (exact square corners)
	var half := size / 2
	var start_x := center_cell.x - half
	var start_y := center_cell.y - half

	var top_left: Vector2i     = Vector2i(start_x,             start_y)
	var top_right: Vector2i    = Vector2i(start_x + size - 1,  start_y)
	var bottom_left: Vector2i  = Vector2i(start_x,             start_y + size - 1)
	var bottom_right: Vector2i = Vector2i(start_x + size - 1,  start_y + size - 1)

	var corners: Array[Vector2i] = [top_left, top_right, bottom_left, bottom_right]

	# 3. For each corner: spawn circles, then squares on those circles
	for corner in corners:
		var radius_min := int(round(float(size) * 0.5))
		var radius_max := size
		if radius_min < 1:
			radius_min = 1
		if radius_max < radius_min:
			radius_max = radius_min

		var radius := rng.randi_range(radius_min, radius_max)

		# OPTIONAL: actually *draw* the circle so you see it
		if debug_draw_circles:
			_paint_circle(corner, radius, forest_type)

		# Pick square centers on this circle
		for i in range(circles_per_square_corner):
			var angle := rng.randf_range(0.0, TAU)
			var offset := Vector2(
				cos(angle) * float(radius),
				sin(angle) * float(radius)
			)
			var new_center := corner + Vector2i(
				round(offset.x),
				round(offset.y)
			)

			var child_size := rng.randi_range(
				max(min_square_size_recursive, int(size * 0.5)),
				size
			)

			_grow_square_recursive(new_center, child_size, forest_type, depth + 1)


func _paint_square(center_cell: Vector2i, size: int, forest_type: String) -> void:
	# Make a clean size x size square
	var half := size / 2
	var start_x := center_cell.x - half
	var start_y := center_cell.y - half

	for x in range(start_x, start_x + size):
		for y in range(start_y, start_y + size):
			var cell := Vector2i(x, y)
			_place_forest_tile(cell, forest_type)


func _paint_circle(center_cell: Vector2i, radius: int, forest_type: String) -> void:
	# Filled disc of tiles
	var r2 := radius * radius
	for x in range(center_cell.x - radius, center_cell.x + radius + 1):
		for y in range(center_cell.y - radius, center_cell.y + radius + 1):
			var dx := x - center_cell.x
			var dy := y - center_cell.y
			if dx * dx + dy * dy <= r2:
				_place_forest_tile(Vector2i(x, y), forest_type)


func _get_random_tile_from_pool(forest_type: String):
	var pool = forest_tile_pools.get(forest_type, null)
	if pool == null:
		pool = forest_tile_pools.get("default", [])
	if pool.size() == 0:
		return null
	var index = rng.randi_range(0, pool.size() - 1)
	return pool[index]


func _place_forest_tile(cell: Vector2i, forest_type: String) -> void:
	var tile = _get_random_tile_from_pool(forest_type)
	if tile == null:
		return

	# Godot 4 TileMap.set_cell:
	# set_cell(layer, coords, source_id, atlas_coords, alternative_tile)
	set_cell(0, cell, tile_source_id, tile, 0)

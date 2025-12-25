extends Node2D

@onready var action = $ActionComponent
@onready var world = $World/world
@onready var activity = $ActivityComponent
@onready var skills = {
	"Dexterity": $Control/Dexterity,
	"Woodcutting": $Control/Woodcutting,
	"Firemaking": $Control/Firemaking,
	"Mining": $Control/Mining,
	"Fishing": $Control/Fishing,
	"Foraging": $Control/Foraging,
	"Digging": $Control/Digging,
}
var _current_skill_name: String = ""

func _ready() -> void:
	$Fight/fight.player_sc = $StatsComponent
	$World/world.prop_right_clicked.connect(show_actions)


func show_actions(p):
	var actions = _decorate_actions(action.get_actions(p.kind), p.tier_level)
	if actions.is_empty():
		return
	world._show_action_menu(p, actions, _on_action_selected)

func _on_action_selected(action_data: Dictionary, target_kind: String) -> void:
	var skill_name = action_data.get("skill", "")
	if not skills.has(skill_name):
		return
	if action_data.get("disabled", false):
		return
	_stop_all_skills()
	_current_skill_name = skill_name
	var scaled_xp = _scale_xp(action_data.get("xp", 0.0))
	activity.setActivity(
		action_data.get("name", ""),
		target_kind,
		scaled_xp,
		action_data.get("speed", 1.0)
	)
	skills[skill_name]._set_activity(
		action_data.get("name", ""),
		target_kind,
		scaled_xp,
		action_data.get("speed", 1.0)
	)
	skills["Dexterity"]._set_activity(
		"Training",
		skill_name,
		action_data.get("xp", 0.0),
		action_data.get("speed", 1.0)
	)

func _decorate_actions(actions: Array, tier_level: int) -> Array:
	var decorated: Array = []
	for action_data in actions:
		var data = action_data.duplicate()
		var skill_name = data.get("skill", "")
		var required_level = int(data.get("min_level", 1))
		var skill_level = _get_skill_level(skill_name)
		if tier_level > 0 and required_level != tier_level:
			continue
		if required_level > 1:
			data["label"] = "%s (Lvl %s)" % [data.get("name", ""), required_level]
		if skill_level > 0 and skill_level < required_level:
			data["disabled"] = true
		decorated.append(data)
	return decorated

func _get_skill_level(skill_name: String) -> int:
	if skills.has(skill_name):
		return skills[skill_name].get_level()
	return 0

func _scale_xp(base_xp: float) -> float:
	var dex_level = _get_skill_level("Dexterity")
	if dex_level <= 1:
		return base_xp
	return base_xp * (1.0 + (dex_level - 1) * 0.05)

func _stop_all_skills() -> void:
	for skill in skills.values():
		skill._set_active(false)
			action_data.get("name", ""),
			target_kind,
			action_data.get("xp", 0.0),
			action_data.get("speed", 1.0)
		)

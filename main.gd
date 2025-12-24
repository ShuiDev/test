extends Node2D

@onready var action = $ActionComponent
@onready var world = $World/world
@onready var activity = $ActivityComponent
@onready var skills = {
	"Woodcutting": $Control/Woodcutting,
	"Firemaking": $Control/Firemaking,
	"Mining": $Control/Mining,
	"Fishing": $Control/Fishing,
	"Foraging": $Control/Foraging,
	"Digging": $Control/Digging,
}

func _ready() -> void:
	$Fight/fight.player_sc = $StatsComponent
	$World/world.prop_right_clicked.connect(show_actions)


func show_actions(p):
	var actions = action.get_actions(p.kind)
	if actions.is_empty():
		return
	world._show_action_menu(p, actions, _on_action_selected)

func _on_action_selected(action_data: Dictionary, target_kind: String) -> void:
	activity.setActivity(
		action_data.get("name", ""),
		target_kind,
		action_data.get("xp", 0.0),
		action_data.get("speed", 1.0)
	)
	var skill_name = action_data.get("skill", "")
	if skills.has(skill_name):
		skills[skill_name]._set_activity(
			action_data.get("name", ""),
			target_kind,
			action_data.get("xp", 0.0),
			action_data.get("speed", 1.0)
		)

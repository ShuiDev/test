extends Node2D

@onready var action = $ActionComponent
@onready var world = $World/world
@onready var activity = $ActivityComponent

func _ready() -> void:
	$Fight/fight.player_sc = $StatsComponent
	$World/world.prop_right_clicked.connect(show_actions)


func show_actions(p):
	world._show_action_menu(p,action.get_actions(p.kind),activity.setActivity)

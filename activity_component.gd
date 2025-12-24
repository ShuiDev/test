extends Node

signal activity_changed(action: String, target: String, xp_tick: float, tick_speed: float)

@export var currentAction : String
@export var currentActionTarget: String
@export var currentXPTick: float = 0.0
@export var currentTickSpeed: float = 1.0

@onready var currentActivity = {"action":currentAction,"target":currentActionTarget}

func setActivity(a : String, t : String, x: float = 0.0, s: float = 1.0):
	currentAction = a
	currentActionTarget = t
	currentXPTick = x
	currentTickSpeed = s
	currentActivity = {"action": currentAction, "target": currentActionTarget, "xp_tick": currentXPTick, "tick_speed": currentTickSpeed}
	emit_signal("activity_changed", currentAction, currentActionTarget, currentXPTick, currentTickSpeed)

extends Node

@export var currentAction : String
@export var currentActionTarget: String

@onready var currentActivity = {"action":currentAction,"target":currentActionTarget}

func setActivity(a : String, t : String):
	currentAction = a
	currentActionTarget = t

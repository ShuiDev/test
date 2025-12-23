extends Node


@export var MAX_HP : int
var HP : int

func _ready() -> void:
	HP = MAX_HP
	
func take_damage(atk : Attack):
	HP -= atk.get_damage()

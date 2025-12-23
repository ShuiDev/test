extends Node


@export var action : String
var action_dict : Dictionary = {'forest' : ['Chop', 'Burn']}


func get_actions(p):
	return action_dict[p]

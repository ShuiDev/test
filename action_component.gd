extends Node


@export var action : String
var action_dict : Dictionary = {
	"forest": [
		{"name": "Chop", "xp": 1.0, "speed": 0.4, "skill": "Woodcutting"},
		{"name": "Burn", "xp": 0.6, "speed": 0.7, "skill": "Firemaking"},
	],
	"mountain": [
		{"name": "Mine", "xp": 1.5, "speed": 0.8, "skill": "Mining"},
	],
	"fish": [
		{"name": "Fish", "xp": 1.2, "speed": 0.6, "skill": "Fishing"},
	],
	"sand": [
		{"name": "Dig", "xp": 0.8, "speed": 0.5, "skill": "Digging"},
	],
	"forage": [
		{"name": "Forage", "xp": 0.9, "speed": 0.4, "skill": "Foraging"},
	],
}


func get_actions(p):
	return action_dict.get(p, [])

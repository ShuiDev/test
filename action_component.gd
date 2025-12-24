extends Node


@export var action : String
var action_dict : Dictionary = {
	"forest": [
		{"name": "Chop Pine", "xp": 1.0, "speed": 0.4, "skill": "Woodcutting", "min_level": 1},
		{"name": "Chop Oak", "xp": 2.2, "speed": 0.5, "skill": "Woodcutting", "min_level": 10},
		{"name": "Chop Elder", "xp": 4.5, "speed": 0.7, "skill": "Woodcutting", "min_level": 25},
		{"name": "Burn Logs", "xp": 0.6, "speed": 0.7, "skill": "Firemaking", "min_level": 1},
		{"name": "Burn Charcoal", "xp": 1.4, "speed": 0.8, "skill": "Firemaking", "min_level": 8},
		{"name": "Burn Resin", "xp": 3.0, "speed": 1.0, "skill": "Firemaking", "min_level": 20},
	],
	"mountain": [
		{"name": "Mine Copper", "xp": 1.5, "speed": 0.8, "skill": "Mining", "min_level": 1},
		{"name": "Mine Iron", "xp": 3.0, "speed": 0.9, "skill": "Mining", "min_level": 15},
		{"name": "Mine Mithril", "xp": 5.0, "speed": 1.1, "skill": "Mining", "min_level": 30},
	],
	"fish": [
		{"name": "Net Fish", "xp": 1.2, "speed": 0.6, "skill": "Fishing", "min_level": 1},
		{"name": "Catch Salmon", "xp": 2.6, "speed": 0.7, "skill": "Fishing", "min_level": 12},
		{"name": "Harpoon Tuna", "xp": 4.2, "speed": 0.9, "skill": "Fishing", "min_level": 25},
	],
	"sand": [
		{"name": "Dig Sand", "xp": 0.8, "speed": 0.5, "skill": "Digging", "min_level": 1},
		{"name": "Dig Clay", "xp": 1.8, "speed": 0.6, "skill": "Digging", "min_level": 10},
		{"name": "Dig Glass", "xp": 3.0, "speed": 0.7, "skill": "Digging", "min_level": 20},
	],
	"forage": [
		{"name": "Forage Herbs", "xp": 0.9, "speed": 0.4, "skill": "Foraging", "min_level": 1},
		{"name": "Forage Berries", "xp": 1.7, "speed": 0.5, "skill": "Foraging", "min_level": 8},
		{"name": "Forage Rare Mushrooms", "xp": 3.4, "speed": 0.7, "skill": "Foraging", "min_level": 20},
	],
}


func get_actions(p):
	return action_dict.get(p, [])

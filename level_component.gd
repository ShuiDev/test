extends Node


var MAX_LVL = 200
@export var CURVE : Curve
var level : int = 1

func gainLevel():
	level += 1
	%ProgressBar.max_value = CURVE.sample(level)

func getLevel():
	return level

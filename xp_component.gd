extends Node


@export var MAX_XP = 10**12
var xp : float

func gainXP(x: float):
	xp += x
	if xp > MAX_XP:
		xp = MAX_XP
	%ProgressBar.set_value_no_signal(xp)

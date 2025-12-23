extends Timer

@export var activityXPTick : float
@export var activityTickSpeed : float

func _process(delta: float) -> void:
	wait_time = activityTickSpeed
	
func setXP(x):
	activityXPTick = x
	
func setSpeed(s):
	activityTickSpeed = s
	
func getXP():
	return activityXPTick

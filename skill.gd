extends VBoxContainer

@onready var tc = $TickComponent
@onready var xc = $XPComponent
@onready var lc = $LevelComponent
@onready var ac = $ActivityComponent

func _on_tick() -> void:
	xc.gainXP(tc.getXP())
	if %ProgressBar.value == %ProgressBar.max_value:
		lc.gainLevel()
	_update_label()
		
		
func _set_activity(a,t,x,s) -> void:
	ac.setActivity(a,t)
	tc.setXP(x)
	tc.setSpeed(s)
	_update_label()

func _update_label() -> void:
	$Label.text = "Activity: %s %s\nLevel: %s\nCurrent XP: %s\nNeeded XP: %s" % [
		ac.currentAction,
		ac.currentActionTarget,
		lc.getLevel(),
		%ProgressBar.value,
		%ProgressBar.max_value
	]

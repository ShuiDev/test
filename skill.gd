extends VBoxContainer

@onready var tc = $TickComponent
@onready var xc = $XPComponent
@onready var lc = $LevelComponent
@onready var ac = $ActivityComponent

func _on_tick() -> void:
	xc.gainXP(tc.getXP())
	if %ProgressBar.value == %ProgressBar.max_value:
		lc.gainLevel()
		$Label.text = "Level: %s
		Current XP: %s
		Neded XP: %s" % [lc.getLevel(), %ProgressBar.value, %ProgressBar.max_value]
	
	
func _set_activity(a,t,x,s) -> void:
	ac.setActivity(a,t)
	tc.setXP(x)
	tc.setSpeed(s)

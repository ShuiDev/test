extends VBoxContainer

@onready var tc = $TickComponent
@onready var xc = $XPComponent
@onready var lc = $LevelComponent
@onready var ac = $ActivityComponent

func _ready() -> void:
	_set_active(false)
	_update_label()

func _on_tick() -> void:
	xc.gainXP(tc.getXP())
	if %ProgressBar.value == %ProgressBar.max_value:
		lc.gainLevel()
	_update_label()
		
		
func _set_activity(a,t,x,s) -> void:
	ac.setActivity(a,t)
	tc.setXP(x)
	tc.setSpeed(s)
	_set_active(true)
	_update_label()

func _set_active(active: bool) -> void:
	if active:
		tc.paused = false
		if tc.is_stopped():
			tc.start()
	else:
		tc.stop()
		tc.paused = true
		ac.setActivity("", "", 0.0, tc.wait_time)
		_update_label()

func get_level() -> int:
	return lc.getLevel()

func _update_label() -> void:
	var activity = "Idle"
	if ac.currentAction.strip_edges() != "":
		activity = "%s %s" % [ac.currentAction, ac.currentActionTarget]
	$Label.text = "%s\nActivity: %s\nLevel: %s\nXP: %s / %s" % [
		name,
		activity,
		lc.getLevel(),
		%ProgressBar.value,
		%ProgressBar.max_value
	]

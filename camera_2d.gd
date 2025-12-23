extends Camera2D

@export var drag_speed: float = 1.0
var _dragging := false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		_dragging = event.pressed
	if event is InputEventMouseMotion and _dragging:
		global_position -= event.relative * drag_speed

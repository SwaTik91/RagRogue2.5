extends Button
## Debug toggle: player cannot die while god mode is on.

const DIRECTOR_PATH := NodePath("../../../CombatDirector")


func _ready() -> void:
	toggle_mode = true
	text = "GOD"
	focus_mode = Control.FOCUS_NONE
	pressed.connect(_on_pressed)
	_refresh()


func _on_pressed() -> void:
	var director := get_node_or_null(DIRECTOR_PATH)
	if director == null or not director.has_method("set_god_mode"):
		return
	director.set_god_mode(button_pressed)
	_refresh()


func _refresh() -> void:
	if button_pressed:
		text = "GOD ON"
		modulate = Color(0.55, 1.0, 0.65, 1.0)
	else:
		text = "GOD"
		modulate = Color(1.0, 1.0, 1.0, 0.92)

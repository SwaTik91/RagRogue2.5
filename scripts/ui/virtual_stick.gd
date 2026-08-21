extends Control

signal vector_changed(vector: Vector2)

@export var max_radius: float = 72.0
@export var deadzone: float = 0.12

var vector: Vector2 = Vector2.ZERO
var _pointer_id: int = -1


func _ready() -> void:
	add_to_group("virtual_stick")
	mouse_filter = Control.MOUSE_FILTER_STOP
	_update_knob()


func get_vector() -> Vector2:
	return vector


func set_pointer(local_pos: Vector2) -> void:
	var center := size * 0.5
	var offset := local_pos - center
	if offset.length() <= deadzone * max_radius:
		vector = Vector2.ZERO
	else:
		vector = (offset / max_radius).limit_length(1.0)
	_update_knob()
	vector_changed.emit(vector)


func release() -> void:
	vector = Vector2.ZERO
	_pointer_id = -1
	_update_knob()
	vector_changed.emit(vector)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_pointer_id = event.index
			set_pointer(event.position)
			accept_event()
		elif event.index == _pointer_id:
			release()
			accept_event()
	elif event is InputEventScreenDrag and event.index == _pointer_id:
		set_pointer(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pointer_id = 0
			set_pointer(event.position)
			accept_event()
		else:
			release()
			accept_event()
	elif event is InputEventMouseMotion and _pointer_id != -1:
		set_pointer(event.position)
		accept_event()


func _input(event: InputEvent) -> void:
	if _pointer_id < 0:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		release()
	elif event is InputEventMouseMotion:
		set_pointer(get_local_mouse_position())
	elif event is InputEventScreenTouch and not event.pressed and event.index == _pointer_id:
		release()
	elif event is InputEventScreenDrag and event.index == _pointer_id:
		set_pointer(get_local_mouse_position())


func _update_knob() -> void:
	if not is_inside_tree():
		return
	var knob := get_node_or_null("Knob") as Control
	if knob == null:
		return
	var center := size * 0.5
	knob.position = center + vector * max_radius - knob.size * 0.5

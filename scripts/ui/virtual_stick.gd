extends Control

signal vector_changed(vector: Vector2)

@export var max_radius: float = 80.0
@export var deadzone: float = 0.1
@export var knob_radius: float = 34.0

var vector: Vector2 = Vector2.ZERO
var _pointer_id: int = -1
var _pressed := false


func _ready() -> void:
	add_to_group("virtual_stick")
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(max_radius * 2 + knob_radius, max_radius * 2 + knob_radius)


func _draw() -> void:
	var center := size * 0.5
	# Outer glow
	draw_circle(center, max_radius + 14, Color(0.05, 0.08, 0.12, 0.28))
	# Base ring
	draw_circle(center, max_radius + 6, Color(0.12, 0.16, 0.22, 0.55))
	draw_circle(center, max_radius, Color(0.18, 0.22, 0.3, 0.42))
	draw_arc(center, max_radius, 0, TAU, 72, Color(0.72, 0.78, 0.9, 0.35), 2.5, true)
	draw_arc(center, max_radius - 6, 0, TAU, 72, Color(0.08, 0.1, 0.14, 0.5), 1.5, true)
	# Cross hint
	draw_line(center + Vector2(-max_radius * 0.35, 0), center + Vector2(max_radius * 0.35, 0), Color(1, 1, 1, 0.06), 2)
	draw_line(center + Vector2(0, -max_radius * 0.35), center + Vector2(0, max_radius * 0.35), Color(1, 1, 1, 0.06), 2)
	var knob_center := center + vector * max_radius
	# Knob shadow
	draw_circle(knob_center + Vector2(2, 4), knob_radius + 2, Color(0, 0, 0, 0.25))
	# Knob body
	draw_circle(knob_center, knob_radius, Color(0.94, 0.96, 1, 0.92))
	draw_circle(knob_center, knob_radius - 4, Color(0.78, 0.84, 0.96, 0.35))
	draw_arc(knob_center, knob_radius - 2, 0, TAU, 48, Color(1, 1, 1, 0.55), 2.0, true)


func get_vector() -> Vector2:
	return vector


func set_pointer(local_pos: Vector2) -> void:
	var center := size * 0.5
	var offset := local_pos - center
	if offset.length() <= deadzone * max_radius:
		vector = Vector2.ZERO
	else:
		vector = (offset / max_radius).limit_length(1.0)
	_pressed = vector != Vector2.ZERO
	queue_redraw()
	vector_changed.emit(vector)


func release() -> void:
	vector = Vector2.ZERO
	_pointer_id = -1
	_pressed = false
	queue_redraw()
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

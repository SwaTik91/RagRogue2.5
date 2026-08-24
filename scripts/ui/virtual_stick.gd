extends Control

## Dynamic virtual joystick — appears where the user touches the left half of the screen.
## Keeps get_vector / set_pointer / release API for player controller and headless tests.

signal vector_changed(vector: Vector2)

const MIN_TOUCH_DP := 48.0

@export var max_radius: float = 80.0
@export var deadzone: float = 0.1
@export var knob_radius: float = 34.0
@export var palm_border_px: float = 50.0
@export var finger_visual_offset: Vector2 = Vector2(0.0, -56.0)
@export var hud_exclusion: Rect2 = Rect2(0.0, 0.0, 320.0, 88.0)

var vector: Vector2 = Vector2.ZERO

var _pointer_id: int = -1
var _joystick_center: Vector2 = Vector2.ZERO
var _stick_visible := false


func _ready() -> void:
	add_to_group("virtual_stick")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_right = 0.0
	offset_bottom = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	max_radius = maxf(max_radius, MIN_TOUCH_DP)
	knob_radius = maxf(knob_radius, MIN_TOUCH_DP * 0.45)
	custom_minimum_size = Vector2.ZERO


func get_vector() -> Vector2:
	return vector


func set_pointer(local_pos: Vector2) -> void:
	if not _stick_visible:
		_pointer_id = 0
		_activate_at(get_global_rect().get_center())
	_update_from_local(local_pos)


func release() -> void:
	_deactivate()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event.position, event.index)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _pointer_id == -1 and _is_valid_spawn(event.position):
				_pointer_id = 0
				_activate_at(event.position)
				_update_from_global(event.position)
		elif _pointer_id == 0:
			_deactivate()
	elif event is InputEventMouseMotion and _pointer_id == 0:
		_update_from_global(event.position)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _pointer_id == -1 and _is_valid_spawn(event.position):
			_pointer_id = event.index
			_activate_at(event.position)
			_update_from_global(event.position)
	elif event.index == _pointer_id:
		_deactivate()


func _handle_drag(global_pos: Vector2, index: int) -> void:
	if index == _pointer_id:
		_update_from_global(global_pos)


func _is_valid_spawn(pos: Vector2) -> bool:
	var vp := get_viewport_rect()
	if pos.x >= vp.size.x * 0.5:
		return false
	var margin := palm_border_px
	if pos.x < margin or pos.y < margin:
		return false
	if pos.x > vp.size.x - margin or pos.y > vp.size.y - margin:
		return false
	if hud_exclusion.has_point(pos):
		return false
	return true


func _activate_at(global_pos: Vector2) -> void:
	_joystick_center = global_pos + finger_visual_offset
	_stick_visible = true
	queue_redraw()


func _deactivate() -> void:
	_pointer_id = -1
	_stick_visible = false
	vector = Vector2.ZERO
	queue_redraw()
	vector_changed.emit(vector)


func _update_from_global(global_pos: Vector2) -> void:
	_update_from_local(_event_to_local(global_pos))


func _event_to_local(event_pos: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * event_pos


func _update_from_local(local_pos: Vector2) -> void:
	if not _stick_visible:
		return
	var center_local := _event_to_local(_joystick_center)
	var offset: Vector2 = local_pos - center_local
	if offset.length() <= deadzone * max_radius:
		vector = Vector2.ZERO
	else:
		vector = (offset / max_radius).limit_length(1.0)
	queue_redraw()
	vector_changed.emit(vector)


func _draw() -> void:
	if not _stick_visible:
		return
	var center: Vector2 = _event_to_local(_joystick_center)
	var knob_center: Vector2 = center + vector * max_radius
	# Outer glow
	draw_circle(center, max_radius + 14.0, Color(0.05, 0.08, 0.12, 0.28))
	# Base ring
	draw_circle(center, max_radius + 6.0, Color(0.12, 0.16, 0.22, 0.55))
	draw_circle(center, max_radius, Color(0.18, 0.22, 0.3, 0.42))
	draw_arc(center, max_radius, 0.0, TAU, 72, Color(0.72, 0.78, 0.9, 0.35), 2.5, true)
	draw_arc(center, max_radius - 6.0, 0.0, TAU, 72, Color(0.08, 0.1, 0.14, 0.5), 1.5, true)
	# Cross hint
	draw_line(center + Vector2(-max_radius * 0.35, 0.0), center + Vector2(max_radius * 0.35, 0.0), Color(1, 1, 1, 0.06), 2.0)
	draw_line(center + Vector2(0.0, -max_radius * 0.35), center + Vector2(0.0, max_radius * 0.35), Color(1, 1, 1, 0.06), 2.0)
	# Knob shadow
	draw_circle(knob_center + Vector2(2.0, 4.0), knob_radius + 2.0, Color(0.0, 0.0, 0.0, 0.25))
	# Knob body
	draw_circle(knob_center, knob_radius, Color(0.94, 0.96, 1.0, 0.92))
	draw_circle(knob_center, knob_radius - 4.0, Color(0.78, 0.84, 0.96, 0.35))
	draw_arc(knob_center, knob_radius - 2.0, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.55), 2.0, true)

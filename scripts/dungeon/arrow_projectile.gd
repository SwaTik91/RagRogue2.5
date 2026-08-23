class_name ArrowProjectile
extends Node2D
## Top-down arrow bolt; flies to target and invokes callback on arrival.

const SPEED := 920.0
const HIT_DIST := 14.0

var _target: Vector2 = Vector2.ZERO
var _on_arrive: Callable
var _active := false
var _fire := false

@onready var _shaft: Polygon2D = $Shaft
@onready var _head: Polygon2D = $Head
@onready var _glow: Polygon2D = $Glow


func launch(from: Vector2, to: Vector2, fire: bool, on_arrive: Callable) -> void:
	global_position = from
	_target = to
	_on_arrive = on_arrive
	_fire = fire
	_active = true
	_apply_style()
	var dir := to - from
	if dir.length_squared() > 0.01:
		rotation = dir.angle()
	z_index = 12


func _apply_style() -> void:
	if _fire:
		if _shaft != null:
			_shaft.color = Color(1.0, 0.45, 0.12, 1.0)
		if _head != null:
			_head.color = Color(1.0, 0.75, 0.2, 1.0)
		if _glow != null:
			_glow.visible = true
			_glow.color = Color(1.0, 0.35, 0.05, 0.35)
	else:
		if _shaft != null:
			_shaft.color = Color(0.85, 0.78, 0.55, 1.0)
		if _head != null:
			_head.color = Color(0.55, 0.42, 0.28, 1.0)
		if _glow != null:
			_glow.visible = false


func _physics_process(delta: float) -> void:
	if not _active:
		return
	var to_target := _target - global_position
	var dist := to_target.length()
	if dist <= HIT_DIST:
		_finish()
		return
	var step := SPEED * delta
	if step >= dist:
		global_position = _target
		_finish()
		return
	global_position += to_target / dist * step
	rotation = to_target.angle()


func _finish() -> void:
	_active = false
	if _on_arrive.is_valid():
		_on_arrive.call()
	queue_free()

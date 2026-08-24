class_name MobProjectile
extends Node2D
## Slow top-down mob projectile (carrot, apple, holy bolt) — no homing.

const HIT_DIST := 16.0

var _target: Vector2 = Vector2.ZERO
var _on_arrive: Callable
var _active := false
var _speed := 300.0

@onready var _sprite: Sprite2D = $Sprite
@onready var _fallback: Polygon2D = $Fallback


func launch(from: Vector2, to: Vector2, projectile_kind: String, speed: float, on_arrive: Callable) -> void:
	global_position = from
	_target = to
	_on_arrive = on_arrive
	_speed = maxf(120.0, speed)
	_active = true
	_apply_style(projectile_kind)
	var dir := to - from
	if dir.length_squared() > 0.01:
		rotation = dir.angle()
	z_index = 11


func _apply_style(kind: String) -> void:
	var tex: Texture2D = null
	match kind:
		"carrot":
			tex = _load_tex("res://assets/art/pixellab/mobs/carrot_proj.png")
			if _fallback != null:
				_fallback.color = Color(1.0, 0.55, 0.15, 1.0)
				_fallback.polygon = PackedVector2Array([
					Vector2(-10, -3), Vector2(12, -3), Vector2(14, 0), Vector2(12, 3), Vector2(-10, 3),
				])
		"apple":
			tex = _load_tex("res://assets/art/pixellab/mobs/apple_proj.png")
			if _fallback != null:
				_fallback.color = Color(0.85, 0.2, 0.18, 1.0)
				_fallback.polygon = PackedVector2Array([
					Vector2(0, -8), Vector2(7, -2), Vector2(6, 7), Vector2(-6, 7), Vector2(-7, -2),
				])
		"holy", "holy_burst":
			tex = _load_tex("res://assets/art/pixellab/mobs/holy_proj.png")
			if _fallback != null:
				_fallback.color = Color(1.0, 0.95, 0.55, 1.0)
				_fallback.polygon = PackedVector2Array([
					Vector2(0, -9), Vector2(8, 0), Vector2(0, 9), Vector2(-8, 0),
				])
		"flame":
			tex = _load_tex("res://assets/art/pixellab/mobs/flame_proj.png")
			if _fallback != null:
				_fallback.color = Color(1.0, 0.45, 0.08, 1.0)
				_fallback.polygon = PackedVector2Array([
					Vector2(0, -10), Vector2(6, -2), Vector2(4, 8), Vector2(-4, 8), Vector2(-6, -2),
				])
		_:
			if _fallback != null:
				_fallback.color = Color(0.7, 0.7, 0.75, 1.0)
	if _sprite != null:
		_sprite.texture = tex
		_sprite.visible = tex != null
	if _fallback != null:
		_fallback.visible = tex == null


func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _physics_process(delta: float) -> void:
	if not _active:
		return
	var to_target := _target - global_position
	var dist := to_target.length()
	if dist <= HIT_DIST:
		_finish()
		return
	var step := _speed * delta
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

class_name ActorVisual
extends RefCounted
## Procedural motion / combat feedback on a Sprite2D (no sprite-sheet frames yet).

const BOB_SPEED := 9.0
const BOB_AMOUNT := 5.0
const LEAN_AMOUNT := 0.07

var sprite: Sprite2D = null
var body: Node2D = null
var _base_scale := Vector2.ONE
var _base_y := 0.0
var _bob_phase := 0.0
var _facing := 1.0
var _attack_tween: Tween = null
var _is_attacking := false


func setup(sprite_node: Sprite2D, body_node: Node2D = null) -> void:
	sprite = sprite_node
	body = body_node
	if sprite != null:
		_base_scale = sprite.scale
		_base_y = sprite.position.y


func capture_base_scale() -> void:
	if sprite != null:
		_base_scale = sprite.scale
		_base_y = sprite.position.y


func update_motion(velocity: Vector2, delta: float) -> void:
	if sprite == null or _is_attacking:
		return
	var moving := velocity.length_squared() > 4.0
	if absf(velocity.x) > 2.0:
		_facing = 1.0 if velocity.x >= 0.0 else -1.0
	sprite.flip_h = _facing < 0.0
	if moving:
		_bob_phase += delta * BOB_SPEED
		var bob := sin(_bob_phase) * BOB_AMOUNT
		var lean := velocity.normalized().x * LEAN_AMOUNT
		sprite.position.y = _base_y + bob
		sprite.rotation = lean
		var squash := 1.0 + absf(sin(_bob_phase)) * 0.04
		sprite.scale = Vector2(_base_scale.x * squash, _base_scale.y * (1.0 - squash * 0.02 + 0.02))
	else:
		_bob_phase = 0.0
		sprite.position.y = lerpf(sprite.position.y, _base_y, 0.2)
		sprite.rotation = lerpf(sprite.rotation, 0.0, 0.2)
		sprite.scale = _base_scale


func play_attack(is_skill: bool = false) -> void:
	if sprite == null:
		return
	_play_attack_on_sprite(is_skill)


func play_hit() -> void:
	if sprite == null:
		return
	var host := _tween_host()
	if host == null:
		return
	var tween := host.create_tween()
	tween.tween_property(sprite, "modulate", Color(1.4, 0.55, 0.55, 1), 0.05)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)


func _play_attack_on_sprite(is_skill: bool) -> void:
	var host := _tween_host()
	if host == null:
		return
	if _attack_tween != null and _attack_tween.is_valid():
		_attack_tween.kill()
	_is_attacking = true
	var lunge := 22.0 if not is_skill else 34.0
	var squash := 1.14 if not is_skill else 1.22
	var flash := Color(1.25, 1.15, 0.85, 1) if is_skill else Color(1.15, 1.1, 1.0, 1)
	var dir := _facing
	var start_pos := Vector2(sprite.position.x, _base_y)
	var lunge_pos := start_pos + Vector2(dir * lunge, -6.0 if is_skill else -3.0)
	_attack_tween = host.create_tween()
	_attack_tween.set_parallel(true)
	_attack_tween.tween_property(sprite, "position", lunge_pos, 0.07).set_ease(Tween.EASE_OUT)
	_attack_tween.tween_property(sprite, "scale", _base_scale * squash, 0.07)
	_attack_tween.tween_property(sprite, "modulate", flash, 0.05)
	_attack_tween.set_parallel(false)
	_attack_tween.tween_property(sprite, "position", start_pos, 0.11).set_ease(Tween.EASE_IN)
	_attack_tween.parallel().tween_property(sprite, "scale", _base_scale, 0.11)
	_attack_tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.11)
	_attack_tween.tween_callback(func() -> void:
		_is_attacking = false
		sprite.position = Vector2(sprite.position.x, _base_y)
	)


func _tween_host() -> Node:
	if body != null:
		return body
	if sprite != null:
		return sprite.get_parent()
	return null

class_name ActorAnimator
extends RefCounted
## Drives AnimatedSprite2D state machine: idle / walk / attack / skill / hit.

var anim: AnimatedSprite2D = null
var body: Node2D = null
var _base_scale := Vector2.ONE
var _facing := 1.0
var _busy := false
var _pending_motion := Vector2.ZERO
var _pending_frames: SpriteFrames = null
var _pending_height := 0.0


func setup(animated_sprite: AnimatedSprite2D, body_node: Node2D = null) -> void:
	anim = animated_sprite
	body = body_node
	if anim != null:
		_base_scale = anim.scale
		if not anim.animation_finished.is_connected(_on_animation_finished):
			anim.animation_finished.connect(_on_animation_finished)
	if _pending_frames != null:
		apply_sprite_frames(_pending_frames, _pending_height)
		_pending_frames = null


func apply_sprite_frames(frames: SpriteFrames, target_height: float) -> void:
	if frames == null:
		return
	if anim == null:
		_pending_frames = frames
		_pending_height = target_height
		return
	anim.sprite_frames = frames
	anim.centered = true
	var tex := frames.get_frame_texture("idle", 0)
	if tex != null:
		var h := float(tex.get_height())
		if h > 0.0:
			var s := target_height / h
			_base_scale = Vector2(s, s)
			anim.scale = _base_scale
	anim.play("idle")


func capture_base_scale() -> void:
	if anim != null:
		_base_scale = anim.scale


func update_motion(velocity: Vector2, _delta: float) -> void:
	if anim == null or anim.sprite_frames == null:
		return
	_pending_motion = velocity
	if _busy:
		_apply_facing(velocity)
		return
	var moving := velocity.length_squared() > 16.0
	_apply_facing(velocity)
	if moving:
		if anim.animation != "walk":
			anim.play("walk")
	else:
		if anim.animation != "idle":
			anim.play("idle")


func play_attack(is_skill: bool = false) -> void:
	if anim == null or anim.sprite_frames == null:
		return
	var name := "skill" if is_skill else "attack"
	if not anim.sprite_frames.has_animation(name):
		name = "attack"
	_busy = true
	_apply_facing(_pending_motion if _pending_motion.length_squared() > 1.0 else Vector2(_facing, 0))
	if is_skill:
		anim.modulate = Color(1.2, 1.15, 1.05, 1)
	anim.play(name)


func play_hit() -> void:
	if anim == null or anim.sprite_frames == null:
		return
	if anim.sprite_frames.has_animation("hit"):
		_busy = true
		anim.play("hit")
	else:
		_flash_hit()


func _on_animation_finished() -> void:
	if anim == null:
		return
	var finished := anim.animation
	if finished in ["attack", "skill", "hit"]:
		_busy = false
		anim.modulate = Color.WHITE
		var moving := _pending_motion.length_squared() > 16.0
		anim.play("walk" if moving else "idle")


func _apply_facing(velocity: Vector2) -> void:
	if anim == null:
		return
	if absf(velocity.x) > 2.0:
		_facing = 1.0 if velocity.x >= 0.0 else -1.0
	anim.flip_h = _facing < 0.0


func _flash_hit() -> void:
	var host := _tween_host()
	if host == null or anim == null:
		return
	var tween := host.create_tween()
	tween.tween_property(anim, "modulate", Color(1.45, 0.5, 0.5, 1), 0.05)
	tween.tween_property(anim, "modulate", Color.WHITE, 0.12)


func _tween_host() -> Node:
	if body != null:
		return body
	if anim != null:
		return anim.get_parent()
	return null

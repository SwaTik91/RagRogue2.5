class_name ActorAnimator
extends RefCounted
## Drives AnimatedSprite2D state machine: idle / walk / attack / skill / hit.

const ANIM_IDLE := &"idle"
const ANIM_WALK := &"walk"
const ANIM_ATTACK := &"attack"
const ANIM_SKILL := &"skill"
const ANIM_HIT := &"hit"

const ONE_SHOT_ANIMS: Array[StringName] = [ANIM_ATTACK, ANIM_SKILL, ANIM_HIT]

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
	anim.speed_scale = 1.0
	var tex := frames.get_frame_texture(ANIM_IDLE, 0)
	if tex != null:
		var h := float(tex.get_height())
		if h > 0.0:
			var s := target_height / h
			_base_scale = Vector2(s, s)
			anim.scale = _base_scale
	_play_sync(ANIM_IDLE)


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
	if moving and anim.sprite_frames.has_animation(ANIM_WALK):
		_play_loop(ANIM_WALK)
	else:
		_play_loop(ANIM_IDLE)


func play_attack(is_skill: bool = false) -> void:
	if anim == null or anim.sprite_frames == null:
		return
	var name: StringName = ANIM_SKILL if is_skill else ANIM_ATTACK
	if not anim.sprite_frames.has_animation(name):
		name = ANIM_ATTACK
	if not anim.sprite_frames.has_animation(name):
		return
	_busy = true
	_apply_facing(_pending_motion if _pending_motion.length_squared() > 1.0 else Vector2(_facing, 0))
	if is_skill:
		anim.modulate = Color(1.2, 1.15, 1.05, 1)
	_play_sync(name)


func play_hit() -> void:
	if anim == null or anim.sprite_frames == null:
		return
	if anim.sprite_frames.has_animation(ANIM_HIT):
		_busy = true
		_play_sync(ANIM_HIT)
	else:
		_flash_hit()


func _on_animation_finished() -> void:
	if anim == null:
		return
	var finished: StringName = anim.animation
	if finished in ONE_SHOT_ANIMS:
		_busy = false
		anim.modulate = Color.WHITE
		var moving := _pending_motion.length_squared() > 16.0
		if moving and anim.sprite_frames.has_animation(ANIM_WALK):
			_play_loop(ANIM_WALK)
		else:
			_play_loop(ANIM_IDLE)


func _play_loop(name: StringName) -> void:
	if anim == null or anim.sprite_frames == null:
		return
	if not anim.sprite_frames.has_animation(name):
		name = ANIM_IDLE
	if not anim.sprite_frames.has_animation(name):
		return
	if anim.animation != name:
		_play_sync(name)


func _play_sync(name: StringName) -> void:
	if anim == null:
		return
	anim.play(name)
	# AnimatedSprite2D has no advance(); flush pose on the same frame (skill golden path).
	anim.set_frame_and_progress(0, 0.0)


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

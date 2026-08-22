class_name ActorAnimator
extends RefCounted
## Directional AnimatedSprite2D: idle/walk/attack/skill per facing (down/up/left/right).

const ANIM_IDLE := &"idle"
const ANIM_WALK := &"walk"
const ANIM_ATTACK := &"attack"
const ANIM_SKILL := &"skill"
const ANIM_HIT := &"hit"

var anim: AnimatedSprite2D = null
var body: Node2D = null
var _base_scale := Vector2.ONE
var _facing_dir := DirectionIds.DOWN
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
	anim.flip_h = false
	var tex := _first_frame_texture(frames)
	if tex != null:
		var h := float(tex.get_height())
		if h > 0.0:
			var s := target_height / h
			_base_scale = Vector2(s, s)
			anim.scale = _base_scale
	_play_dir_sync(ANIM_IDLE, _facing_dir)


func capture_base_scale() -> void:
	if anim != null:
		_base_scale = anim.scale


func update_motion(velocity: Vector2, _delta: float) -> void:
	if anim == null or anim.sprite_frames == null:
		return
	_pending_motion = velocity
	_facing_dir = DirectionIds.from_velocity(velocity, _facing_dir)
	if _busy:
		return
	var moving := velocity.length_squared() > 16.0
	if moving:
		_play_dir_loop(ANIM_WALK, _facing_dir)
	else:
		_play_dir_loop(ANIM_IDLE, _facing_dir)


func play_attack(is_skill: bool = false) -> void:
	if anim == null or anim.sprite_frames == null:
		return
	var base: StringName = ANIM_SKILL if is_skill else ANIM_ATTACK
	if not _has_any_dir(base):
		base = ANIM_ATTACK
	if not _has_any_dir(base):
		return
	_busy = true
	var motion := _pending_motion
	if motion.length_squared() < 1.0:
		motion = _dir_to_vector(_facing_dir)
	_facing_dir = DirectionIds.from_velocity(motion, _facing_dir)
	if is_skill:
		anim.modulate = Color(1.2, 1.15, 1.05, 1)
	_play_dir_sync(base, _facing_dir)


func play_hit() -> void:
	if anim == null or anim.sprite_frames == null:
		return
	if anim.sprite_frames.has_animation(ANIM_HIT):
		_busy = true
		anim.flip_h = false
		_play_sync(ANIM_HIT)
	else:
		_flash_hit()


func _on_animation_finished() -> void:
	if anim == null:
		return
	if not _is_one_shot(anim.animation):
		return
	_busy = false
	anim.modulate = Color.WHITE
	var moving := _pending_motion.length_squared() > 16.0
	if moving:
		_play_dir_loop(ANIM_WALK, _facing_dir)
	else:
		_play_dir_loop(ANIM_IDLE, _facing_dir)


func _play_dir_loop(base: StringName, dir: String) -> void:
	var name := _resolve_dir_anim(base, dir)
	if not anim.sprite_frames.has_animation(name):
		return
	if anim.animation != name:
		_play_sync(name)


func _play_dir_sync(base: StringName, dir: String) -> void:
	var name := _resolve_dir_anim(base, dir)
	if anim == null or anim.sprite_frames == null:
		return
	if not anim.sprite_frames.has_animation(name):
		return
	_play_sync(name)


func _play_sync(name: StringName) -> void:
	if anim == null:
		return
	if anim.animation == name and anim.is_playing():
		return
	anim.play(name)
	anim.set_frame_and_progress(0, 0.0)


func _resolve_dir_anim(base: StringName, dir: String) -> StringName:
	var keyed := StringName(DirectionIds.anim_key(String(base), dir))
	if anim.sprite_frames.has_animation(keyed):
		anim.flip_h = false
		return keyed
	if dir == DirectionIds.LEFT:
		var mirror := StringName(DirectionIds.anim_key(String(base), DirectionIds.RIGHT))
		if anim.sprite_frames.has_animation(mirror):
			anim.flip_h = true
			return mirror
	var down := StringName(DirectionIds.anim_key(String(base), DirectionIds.DOWN))
	if anim.sprite_frames.has_animation(down):
		anim.flip_h = false
		return down
	if anim.sprite_frames.has_animation(base):
		anim.flip_h = dir == DirectionIds.LEFT
		return base
	return base


func _has_any_dir(base: StringName) -> bool:
	if anim == null or anim.sprite_frames == null:
		return false
	for d in DirectionIds.ALL:
		if anim.sprite_frames.has_animation(StringName(DirectionIds.anim_key(String(base), d))):
			return true
	return anim.sprite_frames.has_animation(base)


func _is_one_shot(name: StringName) -> bool:
	var s := String(name)
	return s.begins_with("attack") or s.begins_with("skill") or s == "hit"


func _first_frame_texture(frames: SpriteFrames) -> Texture2D:
	for d in DirectionIds.ALL:
		var key := StringName(DirectionIds.anim_key("idle", d))
		if frames.has_animation(key):
			return frames.get_frame_texture(key, 0)
	if frames.has_animation(ANIM_IDLE):
		return frames.get_frame_texture(ANIM_IDLE, 0)
	return null


func _dir_to_vector(dir: String) -> Vector2:
	match dir:
		DirectionIds.RIGHT:
			return Vector2(1, 0)
		DirectionIds.LEFT:
			return Vector2(-1, 0)
		DirectionIds.UP:
			return Vector2(0, -1)
		_:
			return Vector2(0, 1)


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

class_name SpriteFramesFactory
extends RefCounted
## Build SpriteFrames from idle cutouts — each frame is a baked texture offset.

const WALK_OFFSETS := [
	Vector2(0, 0),
	Vector2(0, -6),
	Vector2(0, -2),
	Vector2(0, -7),
]
const ATTACK_OFFSETS := [
	Vector2(0, 0),
	Vector2(10, -2),
	Vector2(18, -4),
	Vector2(8, -1),
]
const SKILL_OFFSETS := [
	Vector2(0, -2),
	Vector2(6, -6),
	Vector2(14, -10),
	Vector2(20, -8),
	Vector2(10, -4),
]
const HIT_OFFSETS := [Vector2(-4, 0), Vector2(4, 0), Vector2(0, 0)]
const SLIME_ATTACK_OFFSETS := [
	Vector2(0, 0), Vector2(6, -1), Vector2(12, -2), Vector2(4, 0),
]

static var _cache: Dictionary = {}


static func player_frames(class_id: int) -> SpriteFrames:
	var key := "player_%d" % class_id
	if _cache.has(key):
		return _cache[key] as SpriteFrames
	var path := SpriteCatalog.player_idle_path(class_id)
	var tex := SpriteCatalog._load_texture(path)
	if tex == null:
		return null
	var frames := _build_actor_frames(tex, 0.11, 0.07, true)
	_cache[key] = frames
	return frames


static func monster_frames(monster_id: String) -> SpriteFrames:
	var key := "monster_%s" % monster_id
	if _cache.has(key):
		return _cache[key] as SpriteFrames
	var tex := SpriteCatalog.monster_texture(monster_id)
	if tex == null:
		return null
	var walk_step := 0.13
	var attack_step := 0.08
	if monster_id == "act_boss":
		walk_step = 0.16
		attack_step = 0.1
	var frames := _build_actor_frames(tex, walk_step, attack_step, monster_id != "cave_slime")
	_cache[key] = frames
	return frames


static func _build_actor_frames(
	tex: Texture2D,
	walk_step: float,
	attack_step: float,
	is_humanoid: bool
) -> SpriteFrames:
	var frames := SpriteFrames.new()

	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.set_animation_speed("idle", 3.0)
	_add_offset_frames(frames, "idle", tex, 0.35, [Vector2(0, 0), Vector2(0, -2)])

	frames.add_animation("walk")
	frames.set_animation_loop("walk", true)
	frames.set_animation_speed("walk", 1.0)
	_add_offset_frames(frames, "walk", tex, walk_step, WALK_OFFSETS)

	frames.add_animation("attack")
	frames.set_animation_loop("attack", false)
	frames.set_animation_speed("attack", 1.0)
	var atk := ATTACK_OFFSETS if is_humanoid else SLIME_ATTACK_OFFSETS
	_add_offset_frames(frames, "attack", tex, attack_step, atk)

	frames.add_animation("skill")
	frames.set_animation_loop("skill", false)
	frames.set_animation_speed("skill", 1.0)
	_add_offset_frames(frames, "skill", tex, attack_step * 0.85, SKILL_OFFSETS)

	frames.add_animation("hit")
	frames.set_animation_loop("hit", false)
	frames.set_animation_speed("hit", 1.0)
	_add_offset_frames(frames, "hit", tex, 0.06, HIT_OFFSETS)

	return frames


static func _add_offset_frames(
	frames: SpriteFrames,
	anim_name: String,
	source: Texture2D,
	duration: float,
	offsets: Array
) -> void:
	for off in offsets:
		var baked := _offset_texture(source, off as Vector2)
		frames.add_frame(anim_name, baked, duration)


static func _offset_texture(tex: Texture2D, offset: Vector2) -> Texture2D:
	var src := tex.get_image()
	if src == null:
		return tex
	var w := src.get_width()
	var h := src.get_height()
	var dst := Image.create(w, h, false, Image.FORMAT_RGBA8)
	dst.fill(Color(0, 0, 0, 0))
	var blit_pos := Vector2i(int(offset.x), int(offset.y))
	dst.blit_rect(src, Rect2i(0, 0, w, h), blit_pos)
	return ImageTexture.create_from_image(dst)

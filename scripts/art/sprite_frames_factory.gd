class_name SpriteFramesFactory
extends RefCounted
## Load directional Ludo frames: assets/art/anim/{actor}/{facing}/{anim}/frame_*.webp
## Animation names: idle_down, walk_up, attack_right, ...

static var _cache: Dictionary = {}

const ACTOR_FOR_CLASS := {
	ClassId.Value.SWORDMAN: "swordman",
	ClassId.Value.MAGE: "mage",
	ClassId.Value.ARCHER: "archer",
}

const MONSTER_ACTOR := {
	"cave_slime": "cave_slime",
	"stone_beetle": "stone_beetle",
	"act_boss": "vault_warden",
	"lunatic": "lunatic",
	"drops": "drops",
	"angel_mvp": "angel_mvp",
}

const MOBS_WITH_SKILL := [
	"lunatic",
	"drops",
	"angel_mvp",
]

const ANIM_SPEEDS := {
	"idle": 6.0,
	"walk": 10.0,
	"attack": 14.0,
	"skill": 14.0,
	"hit": 16.0,
}


static func player_frames(class_id: int) -> SpriteFrames:
	var actor := str(ACTOR_FOR_CLASS.get(class_id, "mage"))
	return _actor_frames(actor, true)


static func monster_frames(monster_id: String) -> SpriteFrames:
	var actor := str(MONSTER_ACTOR.get(monster_id, "cave_slime"))
	return _actor_frames(actor, false)


static func _actor_frames(actor: String, is_hero: bool) -> SpriteFrames:
	var key := "%s_%s" % [actor, "hero" if is_hero else "mob"]
	if _cache.has(key):
		return _cache[key] as SpriteFrames
	var anims := ["idle", "walk", "attack"]
	if is_hero or actor in MOBS_WITH_SKILL:
		anims.append("skill")
	var frames := SpriteFrames.new()
	var any := false
	for anim_name in anims:
		var added_dir := _add_directional_anims(frames, anim_name, actor)
		if added_dir:
			any = true
		elif _add_anim_from_folder(
			frames,
			DirectionIds.anim_key(anim_name, DirectionIds.DOWN),
			actor,
			anim_name
		):
			any = true
	if not any:
		return _fallback_frames(actor, is_hero)
	_cache[key] = frames
	return frames


static func _add_directional_anims(frames: SpriteFrames, anim_name: String, actor: String) -> bool:
	var any := false
	for facing in DirectionIds.ALL:
		var anim_key := DirectionIds.anim_key(anim_name, facing)
		var folder := "%s/%s" % [facing, anim_name]
		if _add_anim_from_folder(frames, anim_key, actor, folder):
			any = true
	return any


static func _add_anim_from_folder(
	frames: SpriteFrames,
	anim_name: String,
	actor: String,
	folder_anim: String
) -> bool:
	var dir := "res://assets/art/anim/%s/%s" % [actor, folder_anim]
	var textures := _load_frame_textures(dir)
	if textures.is_empty():
		return false
	var base_anim := anim_name.split("_")[0]
	var loop := base_anim in ["idle", "walk"]
	frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, loop)
	var speed := float(ANIM_SPEEDS.get(base_anim, 8.0))
	frames.set_animation_speed(anim_name, speed)
	for tex in textures:
		frames.add_frame(anim_name, tex)
	return true


static func _load_frame_textures(dir: String) -> Array:
	var out: Array = _load_individual_frames(dir)
	if not out.is_empty():
		return out
	return _load_sheet_frames(dir)


static func _load_individual_frames(dir: String) -> Array:
	var out: Array = []
	for i in 16:
		var path := "%s/frame_%02d.webp" % [dir, i]
		if not ResourceLoader.exists(path):
			path = "%s/frame_%02d.png" % [dir, i]
			if not ResourceLoader.exists(path):
				break
		var tex := load(path) as Texture2D
		if tex == null:
			break
		out.append(tex)
	if not out.is_empty():
		return out
	var names: Array = _list_frame_files(dir)
	for fname in names:
		if not fname.begins_with("frame_"):
			continue
		if not (fname.ends_with(".png") or fname.ends_with(".webp")):
			continue
		var path := "%s/%s" % [dir, fname]
		var tex := load(path) as Texture2D
		if tex != null:
			out.append(tex)
	return out


static func _load_sheet_frames(dir: String) -> Array:
	var sheet_path := "%s/sheet.webp" % dir
	if not ResourceLoader.exists(sheet_path):
		sheet_path = "%s/sheet.png" % dir
		if not ResourceLoader.exists(sheet_path):
			return []
	var sheet := load(sheet_path) as Texture2D
	if sheet == null:
		return []
	var cols := 1
	var rows := 1
	var frame_count := 0
	var meta_path := "%s/ludo_meta.json" % dir
	if ResourceLoader.exists(meta_path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
		if parsed is Dictionary:
			var meta: Dictionary = parsed
			cols = maxi(int(meta.get("num_cols", 1)), 1)
			rows = maxi(int(meta.get("num_rows", 1)), 1)
			frame_count = int(meta.get("num_frames", cols * rows))
	if frame_count <= 0:
		frame_count = cols * rows
	var sheet_size := sheet.get_size()
	var cell_w := sheet_size.x / float(cols)
	var cell_h := sheet_size.y / float(rows)
	var out: Array = []
	for i in frame_count:
		var col := i % cols
		var row := i / cols
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(col * cell_w, row * cell_h, cell_w, cell_h)
		out.append(atlas)
	return out


static func _list_frame_files(dir: String) -> Array:
	var names: Array = []
	if DirAccess.dir_exists_absolute(dir):
		names = Array(DirAccess.get_files_at(dir))
	elif ResourceLoader.exists(dir):
		names = Array(DirAccess.get_files_at(dir))
	else:
		var abs := ProjectSettings.globalize_path(dir)
		if abs != "" and DirAccess.dir_exists_absolute(abs):
			names = Array(DirAccess.get_files_at(abs))
	names.sort()
	return names


static func _fallback_frames(actor: String, is_hero: bool) -> SpriteFrames:
	var tex: Texture2D = null
	if is_hero:
		for cid in ACTOR_FOR_CLASS.keys():
			if ACTOR_FOR_CLASS[cid] == actor:
				tex = SpriteCatalog.player_texture(cid)
				break
	else:
		for mid in MONSTER_ACTOR.keys():
			if MONSTER_ACTOR[mid] == actor:
				tex = SpriteCatalog.monster_texture(mid)
				break
	if tex == null:
		return null
	var frames := SpriteFrames.new()
	var down_idle := DirectionIds.anim_key("idle", DirectionIds.DOWN)
	frames.add_animation(down_idle)
	frames.set_animation_loop(down_idle, true)
	frames.add_frame(down_idle, tex)
	var down_walk := DirectionIds.anim_key("walk", DirectionIds.DOWN)
	frames.add_animation(down_walk)
	frames.set_animation_loop(down_walk, true)
	frames.add_frame(down_walk, tex)
	var down_attack := DirectionIds.anim_key("attack", DirectionIds.DOWN)
	frames.add_animation(down_attack)
	frames.set_animation_loop(down_attack, false)
	frames.add_frame(down_attack, tex)
	if is_hero:
		var down_skill := DirectionIds.anim_key("skill", DirectionIds.DOWN)
		frames.add_animation(down_skill)
		frames.set_animation_loop(down_skill, false)
		frames.add_frame(down_skill, tex)
	return frames

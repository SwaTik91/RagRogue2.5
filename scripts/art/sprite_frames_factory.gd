class_name SpriteFramesFactory
extends RefCounted
## Load Ludo-generated frame sequences from assets/art/anim/{actor}/{anim}/

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
}

## Baseline fps tuned for 9-frame Ludo cycles; scaled by frame count at load time.
const ANIM_SPEEDS := {
	"idle": 8.0,
	"walk": 14.0,
	"attack": 16.0,
	"skill": 16.0,
	"hit": 18.0,
}

const BASELINE_FRAME_COUNT := 9.0


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
	if is_hero:
		anims.append("skill")
	var frames := SpriteFrames.new()
	var any := false
	for anim_name in anims:
		var added := _add_anim_from_folder(frames, anim_name, actor, anim_name)
		if added:
			any = true
	if not any:
		return _fallback_frames(actor, is_hero)
	_cache[key] = frames
	return frames


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
	textures = _normalize_textures(textures)
	frames.add_animation(anim_name)
	var loop := anim_name in ["idle", "walk"]
	frames.set_animation_loop(anim_name, loop)
	var frame_count := textures.size()
	var speed := _speed_for_frame_count(anim_name, frame_count)
	frames.set_animation_speed(anim_name, speed)
	var step := 0.09 if anim_name == "walk" else 0.08
	for tex in textures:
		frames.add_frame(anim_name, tex, step)
	return true


static func _speed_for_frame_count(anim_name: String, frame_count: int) -> float:
	var base := float(ANIM_SPEEDS.get(anim_name, 8.0))
	if frame_count <= 0:
		return base
	return base * (float(frame_count) / BASELINE_FRAME_COUNT)


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


static func _normalize_textures(textures: Array) -> Array:
	if textures.is_empty():
		return textures
	var max_w := 0
	var max_h := 0
	for tex in textures:
		if not (tex is Texture2D):
			continue
		var size: Vector2 = (tex as Texture2D).get_size()
		max_w = maxi(max_w, int(size.x))
		max_h = maxi(max_h, int(size.y))
	if max_w <= 0 or max_h <= 0:
		return textures
	var needs_norm := false
	for tex in textures:
		if not (tex is Texture2D):
			continue
		var size: Vector2 = (tex as Texture2D).get_size()
		if int(size.x) != max_w or int(size.y) != max_h:
			needs_norm = true
			break
	if not needs_norm:
		return textures
	var out: Array = []
	for tex in textures:
		if tex is Texture2D:
			out.append(_center_texture(tex as Texture2D, max_w, max_h))
	return out


static func _center_texture(tex: Texture2D, canvas_w: int, canvas_h: int) -> Texture2D:
	var img := tex.get_image()
	if img == null or img.is_empty():
		return tex
	var canvas := Image.create(canvas_w, canvas_h, false, img.get_format())
	canvas.fill(Color(0, 0, 0, 0))
	var offset := Vector2i(
		(canvas_w - img.get_width()) / 2,
		(canvas_h - img.get_height()) / 2
	)
	canvas.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), offset)
	return ImageTexture.create_from_image(canvas)


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
	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.add_frame("idle", tex, 0.5)
	frames.add_animation("walk")
	frames.set_animation_loop("walk", true)
	frames.add_frame("walk", tex, 0.12)
	frames.add_animation("attack")
	frames.set_animation_loop("attack", false)
	frames.add_frame("attack", tex, 0.1)
	if is_hero:
		frames.add_animation("skill")
		frames.set_animation_loop("skill", false)
		frames.add_frame("skill", tex, 0.08)
	return frames

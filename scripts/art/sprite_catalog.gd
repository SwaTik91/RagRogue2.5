class_name SpriteCatalog
extends RefCounted

const SCALE_BOOST := 1.7
const HERO_EXTRA_SCALE := 1.5

const PLAYER_TARGET_HEIGHT := 64.0 * SCALE_BOOST * HERO_EXTRA_SCALE
const ENEMY_TARGET_HEIGHT := 56.0 * SCALE_BOOST
const BOSS_TARGET_HEIGHT := 96.0 * SCALE_BOOST
const SLIME_TARGET_HEIGHT := 48.0 * SCALE_BOOST

const PLAYER_IDLE_PATHS := {
	ClassId.Value.SWORDMAN: "res://assets/art/characters/swordman/idle.png",
	ClassId.Value.MAGE: "res://assets/art/characters/mage/idle.png",
	ClassId.Value.ARCHER: "res://assets/art/characters/archer/idle.png",
}

const PLAYER_GAME_IDLE_PATHS := {
	ClassId.Value.SWORDMAN: "res://assets/art/game/swordman-idle.png",
	ClassId.Value.MAGE: "res://assets/art/game/mage-idle.png",
	ClassId.Value.ARCHER: "res://assets/art/game/archer-idle.png",
}

const MONSTER_PATHS := {
	"cave_slime": "res://assets/art/game/cave-slime.png",
	"stone_beetle": "res://assets/art/game/stone-beetle.png",
	"act_boss": "res://assets/art/game/vault-warden.png",
	"lunatic": "res://assets/art/game/lunatic.png",
	"drops": "res://assets/art/game/drops.png",
	"angel_mvp": "res://assets/art/game/angel-mvp.png",
}


static func player_idle_path(class_id: int) -> String:
	var path := str(PLAYER_GAME_IDLE_PATHS.get(class_id, PLAYER_GAME_IDLE_PATHS[ClassId.Value.SWORDMAN]))
	if ResourceLoader.exists(path):
		return path
	return str(PLAYER_IDLE_PATHS.get(class_id, PLAYER_IDLE_PATHS[ClassId.Value.SWORDMAN]))


static func player_texture(class_id: int) -> Texture2D:
	return _load_texture(player_idle_path(class_id))


static func monster_texture(monster_id: String) -> Texture2D:
	var path := str(MONSTER_PATHS.get(monster_id, MONSTER_PATHS["cave_slime"]))
	if not ResourceLoader.exists(path):
		path = "res://assets/art/game/%s.png" % monster_id.replace("_", "-")
		if monster_id == "cave_slime":
			path = "res://assets/art/game/cave-slime.png"
		elif monster_id == "stone_beetle":
			path = "res://assets/art/game/stone-beetle.png"
		elif monster_id == "act_boss":
			path = "res://assets/art/game/vault-warden.png"
	return _load_texture(path)


static func fit_animated_sprite(sprite: AnimatedSprite2D, target_height: float) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	var tex := sprite.sprite_frames.get_frame_texture("idle", 0)
	if tex == null:
		return
	var h := float(tex.get_height())
	if h <= 0.0:
		return
	var s := target_height / h
	sprite.scale = Vector2(s, s)


static func fit_sprite(sprite: Sprite2D, texture: Texture2D, target_height: float) -> void:
	if sprite == null or texture == null:
		return
	sprite.texture = texture
	sprite.centered = true
	var h := float(texture.get_height())
	if h <= 0.0:
		return
	var s := target_height / h
	sprite.scale = Vector2(s, s)


static func target_height_for_monster(monster_id: String) -> float:
	if monster_id == "angel_mvp":
		return BOSS_TARGET_HEIGHT * 1.35
	if monster_id == "act_boss":
		return BOSS_TARGET_HEIGHT
	if monster_id == "cave_slime":
		return SLIME_TARGET_HEIGHT
	if monster_id == "drops":
		return ENEMY_TARGET_HEIGHT * 0.92
	return ENEMY_TARGET_HEIGHT


static func _load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

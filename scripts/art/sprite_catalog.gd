class_name SpriteCatalog
extends RefCounted

const PLAYER_TARGET_HEIGHT := 64.0
const ENEMY_TARGET_HEIGHT := 56.0
const BOSS_TARGET_HEIGHT := 96.0

const PLAYER_PATHS := {
	ClassId.Value.SWORDMAN: "res://assets/art/game/swordman-idle.png",
	ClassId.Value.MAGE: "res://assets/art/game/mage-idle.png",
	ClassId.Value.ARCHER: "res://assets/art/game/archer-idle.png",
}

const MONSTER_PATHS := {
	"cave_slime": "res://assets/art/game/cave-slime.png",
	"stone_beetle": "res://assets/art/game/stone-beetle.png",
	"act_boss": "res://assets/art/game/vault-warden.png",
}


static func player_texture(class_id: int) -> Texture2D:
	var path := str(PLAYER_PATHS.get(class_id, PLAYER_PATHS[ClassId.Value.SWORDMAN]))
	return _load_texture(path)


static func monster_texture(monster_id: String) -> Texture2D:
	var path := str(MONSTER_PATHS.get(monster_id, MONSTER_PATHS["cave_slime"]))
	return _load_texture(path)


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


static func _load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

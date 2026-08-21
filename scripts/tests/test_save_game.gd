extends RefCounted

const SAVE_PATH := "user://test_save.json"
const SESSION_PATH := "user://test_session_save.json"


func run() -> Array:
	var errors: Array = []
	_wipe_user("test_save.json")
	_wipe_user("test_session_save.json")
	_test_round_trip_save(errors)
	_test_game_session_persist(errors)
	_test_active_class_round_trip(errors)
	_test_malformed_heroes_recovers(errors)
	_test_active_hero_clamps(errors)
	_wipe_user("test_save.json")
	_wipe_user("test_session_save.json")
	return errors


func _wipe_user(filename: String) -> void:
	var dir := DirAccess.open("user://")
	if dir != null and dir.file_exists(filename):
		dir.remove(filename)


func _staff() -> GearItem:
	return GearItem.from_dict({
		"id": "staff_n",
		"name": "Apprentice Staff",
		"slot": "weapon",
		"rarity": Rarity.Value.N,
		"atk_bonus": 3,
		"def_bonus": 0,
		"hp_bonus": 0
	})


func _test_round_trip_save(errors: Array) -> void:
	var created: Dictionary = SaveGame.load_or_create(SAVE_PATH)
	if int(created.get("version", 0)) != 1:
		errors.append("new save version should be 1")
	var heroes = created.get("heroes", [])
	if heroes.size() != 3:
		errors.append("new save should have 3 heroes (one per ClassId)")
		return
	var mage := Hero.from_dict(heroes[ClassId.Value.MAGE])
	if mage.class_id != ClassId.Value.MAGE:
		errors.append("heroes[MAGE] should be Mage")
	mage.add_xp(100)
	mage.equip(_staff())
	created["heroes"][ClassId.Value.MAGE] = mage.to_dict()
	SaveGame.write(SAVE_PATH, created)

	var loaded: Dictionary = SaveGame.load_or_create(SAVE_PATH)
	var mage2 := Hero.from_dict(loaded["heroes"][ClassId.Value.MAGE])
	if mage2.level != 2:
		errors.append("round-trip should keep mage level 2, got %s" % mage2.level)
	if not mage2.equipped.has("weapon"):
		errors.append("round-trip should keep equipped weapon")
	elif mage2.equipped["weapon"].id != "staff_n":
		errors.append("round-trip weapon id should be staff_n")


func _test_game_session_persist(errors: Array) -> void:
	var script: GDScript = load("res://scripts/app/game_session.gd")
	var session = script.new()
	session.save_path = SESSION_PATH
	session.reload()
	session.active_class = ClassId.Value.MAGE
	var hero: Hero = session.active_hero()
	if hero.class_id != ClassId.Value.MAGE:
		errors.append("active_hero should match active_class Mage")
	hero.add_xp(100)
	hero.equip(_staff())
	session.persist()
	session.free()

	var session2 = script.new()
	session2.save_path = SESSION_PATH
	session2.reload()
	session2.active_class = ClassId.Value.MAGE
	var hero2: Hero = session2.active_hero()
	if hero2.level != 2:
		errors.append("GameSession.persist should keep mage level 2, got %s" % hero2.level)
	if not hero2.equipped.has("weapon"):
		errors.append("GameSession.persist should keep equipped gear")
	session2.free()


func _test_active_class_round_trip(errors: Array) -> void:
	var script: GDScript = load("res://scripts/app/game_session.gd")
	var session = script.new()
	session.save_path = SESSION_PATH
	session.reload()
	session.active_class = ClassId.Value.ARCHER
	session.persist()
	session.free()

	var session2 = script.new()
	session2.save_path = SESSION_PATH
	session2.reload()
	if int(session2.active_class) != ClassId.Value.ARCHER:
		errors.append("reload should restore active_class Archer, got %s" % session2.active_class)
	var hero: Hero = session2.active_hero()
	if hero.class_id != ClassId.Value.ARCHER:
		errors.append("restored active_hero should be Archer")
	session2.free()


func _test_malformed_heroes_recovers(errors: Array) -> void:
	var bad := {
		"version": 1,
		"heroes": [
			{"class_id": 0, "level": 1, "xp": 0, "hp_max": 55, "skill_ids": [], "equipped": {}},
			"not-a-hero",
			42
		]
	}
	SaveGame.write(SAVE_PATH, bad)
	var loaded: Dictionary = SaveGame.load_or_create(SAVE_PATH)
	var heroes = loaded.get("heroes", [])
	if not (heroes is Array) or heroes.size() != 3:
		errors.append("malformed heroes should be replaced with 3 default heroes")
		return
	for i in heroes.size():
		if not (heroes[i] is Dictionary):
			errors.append("recovered heroes[%s] should be a Dictionary" % i)


func _test_active_hero_clamps(errors: Array) -> void:
	var script: GDScript = load("res://scripts/app/game_session.gd")
	var session = script.new()
	session.save_path = SESSION_PATH
	session.reload()
	session.active_class = 99
	var hero: Hero = session.active_hero()
	if hero == null:
		errors.append("active_hero should clamp instead of OOB")
	elif hero.class_id < ClassId.Value.SWORDMAN or hero.class_id > ClassId.Value.ARCHER:
		errors.append("clamped active_hero should be a valid class, got %s" % hero.class_id)
	session.free()

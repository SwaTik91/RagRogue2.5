extends RefCounted


func run() -> Array:
	var errors: Array = []
	_test_mage_unlocks_by_level(errors)
	_test_all_classes_have_starter_and_unlocks(errors)
	_test_player_loads_unlocked_skills(errors)
	return errors


func _test_mage_unlocks_by_level(errors: Array) -> void:
	var mage := Hero.new(ClassId.Value.MAGE)
	if not mage.has_method("unlocked_skill_ids"):
		errors.append("Hero.unlocked_skill_ids should exist")
		return
	if mage.level != 1:
		errors.append("new Mage should start at level 1")
	var level_one: Array = mage.unlocked_skill_ids()
	if level_one.size() != 3:
		errors.append("Mage level 1 should have 3 skills, got %d" % level_one.size())
	mage.level = 5
	var level_five: Array = mage.unlocked_skill_ids()
	if level_five.size() != 5:
		errors.append("Mage level 5 should have 5 skills, got %d" % level_five.size())
	for sid in level_one:
		if not level_five.has(sid):
			errors.append("level 5 should keep starter skill %s" % sid)
	mage.level = 3
	if mage.unlocked_skill_ids().size() != 4:
		errors.append("Mage level 3 should have 4 skills")


func _test_all_classes_have_starter_and_unlocks(errors: Array) -> void:
	for class_id in [ClassId.Value.SWORDMAN, ClassId.Value.MAGE, ClassId.Value.ARCHER]:
		var hero := Hero.new(class_id)
		var starters: Array = hero.unlocked_skill_ids()
		if starters.size() != 3:
			errors.append("class %d level 1 should have 3 skills, got %d" % [class_id, starters.size()])
		hero.level = 5
		var unlocked: Array = hero.unlocked_skill_ids()
		if unlocked.size() != 5:
			errors.append("class %d level 5 should have 5 skills, got %d" % [class_id, unlocked.size()])


func _test_player_loads_unlocked_skills(errors: Array) -> void:
	var script: GDScript = load("res://scripts/dungeon/player_controller.gd")
	if script == null or not script.can_instantiate():
		errors.append("PlayerController script missing")
		return
	var player = script.new()
	var mage := Hero.new(ClassId.Value.MAGE)
	player.bind_hero(mage)
	if player.skills.size() != 3:
		errors.append("level 1 Mage bind should load 3 skills, got %d" % player.skills.size())
	mage.level = 5
	player.bind_hero(mage)
	if player.skills.size() != 5:
		errors.append("level 5 Mage bind should load 5 skills, got %d" % player.skills.size())
	player.free()

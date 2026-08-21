extends RefCounted


func run() -> Array:
	var errors: Array = []
	_test_mage_unlocks_by_level(errors)
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

extends RefCounted

func run() -> Array:
	var errors: Array = []
	_test_nearest_alive_target(errors)
	_test_heal_when_low(errors)
	_test_aoe_when_crowded(errors)
	_test_basic_damage_floor(errors)
	return errors


func _test_nearest_alive_target(errors: Array) -> void:
	var enemies: Array = [
		{"pos": Vector2(10, 0), "hp": 10},
		{"pos": Vector2(3, 0), "hp": 8},
		{"pos": Vector2(1, 0), "hp": 0}
	]
	var idx: int = AutoCombat.pick_target(Vector2.ZERO, enemies)
	if idx != 1:
		errors.append("nearest alive enemy should be index 1, got %s" % idx)
	if AutoCombat.pick_target(Vector2.ZERO, []) != -1:
		errors.append("empty enemies should return -1")
	var all_dead: Array = [{"pos": Vector2(1, 0), "hp": 0}]
	if AutoCombat.pick_target(Vector2.ZERO, all_dead) != -1:
		errors.append("no alive enemy should return -1")


func _test_heal_when_low(errors: Array) -> void:
	var heal := SkillDef.from_dict({
		"id": "heal",
		"name": "Heal",
		"kind": "heal",
		"power": 5,
		"cooldown": 8.0
	})
	var bolt := SkillDef.from_dict({
		"id": "bolt",
		"name": "Bolt",
		"kind": "single",
		"power": 12,
		"cooldown": 2.0
	})
	var skills: Array = [heal, bolt]
	var cds := {"heal": 0.0, "bolt": 0.0}
	var picked := AutoCombat.pick_skill(skills, cds, 30.0, 100.0, 0)
	if picked != "heal":
		errors.append("hp ratio < 0.35 should prefer heal off CD, got %s" % picked)


func _test_aoe_when_crowded(errors: Array) -> void:
	var nova := SkillDef.from_dict({
		"id": "nova",
		"name": "Nova",
		"kind": "aoe",
		"power": 8,
		"cooldown": 5.0
	})
	var bolt := SkillDef.from_dict({
		"id": "bolt",
		"name": "Bolt",
		"kind": "single",
		"power": 12,
		"cooldown": 2.0
	})
	var skills: Array = [nova, bolt]
	var cds := {"nova": 0.0, "bolt": 0.0}
	var picked := AutoCombat.pick_skill(skills, cds, 80.0, 100.0, 3)
	if picked != "nova":
		errors.append("enemy_count_in_aoe >= 3 should prefer aoe, got %s" % picked)


func _test_basic_damage_floor(errors: Array) -> void:
	if AutoCombat.basic_damage(1, 100) != 1:
		errors.append("basic_damage should floor at 1")
	if AutoCombat.basic_damage(5, 2) != 4:
		errors.append("basic_damage 5 vs def 2 should be 4")

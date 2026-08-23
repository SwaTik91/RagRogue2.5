extends RefCounted


func run() -> Array:
	var errors: Array = []
	var script: GDScript = load("res://scripts/dungeon/combat_director.gd")
	if script == null:
		errors.append("CombatDirector script missing")
		return errors
	if not script.can_instantiate():
		errors.append("CombatDirector script cannot instantiate")
		return errors
	var director = script.new()
	_test_ranges_and_aggro(director, errors)
	_test_combatant_dict_shape(director, errors)
	_test_player_strikes_in_range(director, errors)
	_test_no_strike_outside_range(director, errors)
	_test_cds_tick_and_skill_without_input(director, errors)
	_test_mage_dies_standing_in_pack(director, errors)
	director.free()
	return errors


func _test_ranges_and_aggro(director, errors: Array) -> void:
	if not director.has_method("attack_range_for_class"):
		errors.append("CombatDirector.attack_range_for_class should exist")
		return
	if not is_equal_approx(float(director.attack_range_for_class(ClassId.Value.SWORDMAN)), 90.0):
		errors.append("Swordman attack range should be 90")
	if not is_equal_approx(float(director.attack_range_for_class(ClassId.Value.MAGE)), 160.0):
		errors.append("Mage attack range should be 160")
	if not is_equal_approx(float(director.attack_range_for_class(ClassId.Value.ARCHER)), 320.0):
		errors.append("Archer attack range should be 320")
	if not is_equal_approx(float(director.AGGRO_RADIUS), 360.0):
		errors.append("AGGRO_RADIUS should be 360")


func _test_combatant_dict_shape(director, errors: Array) -> void:
	if not director.has_method("to_combatant"):
		errors.append("CombatDirector.to_combatant should exist")
		return
	var c: Dictionary = director.to_combatant(Vector2(4, 5), 12.0)
	if not c.has("pos") or not c.has("hp"):
		errors.append("combatant dict must include {pos, hp}")
		return
	if not (c.pos is Vector2):
		errors.append("combatant pos must be Vector2")
	if AutoCombat.pick_target(Vector2.ZERO, [c]) != 0:
		errors.append("to_combatant dict must work with AutoCombat.pick_target")


func _test_player_strikes_in_range(director, errors: Array) -> void:
	if not director.has_method("player_act"):
		errors.append("CombatDirector.player_act should exist")
		return
	var player := {
		"pos": Vector2.ZERO,
		"hp": 40.0,
		"hp_max": 40.0,
		"atk": 5,
		"def": 2,
		"class_id": ClassId.Value.SWORDMAN
	}
	var enemies: Array = [
		{"pos": Vector2(50, 0), "hp": 20.0, "def": 0}
	]
	var result: Dictionary = director.player_act(player, enemies, [], {})
	if not result.get("applied", false):
		errors.append("player should auto-attack nearest enemy in melee range")
	if float(enemies[0].hp) >= 20.0:
		errors.append("in-range basic attack should reduce enemy hp")


func _test_no_strike_outside_range(director, errors: Array) -> void:
	var player := {
		"pos": Vector2.ZERO,
		"hp": 40.0,
		"hp_max": 40.0,
		"atk": 5,
		"def": 2,
		"class_id": ClassId.Value.SWORDMAN
	}
	var enemies: Array = [
		{"pos": Vector2(400, 0), "hp": 20.0, "def": 0}
	]
	var result: Dictionary = director.player_act(player, enemies, [], {})
	if result.get("applied", false):
		errors.append("player must not attack beyond range/aggro")
	if not is_equal_approx(float(enemies[0].hp), 20.0):
		errors.append("out-of-range enemy hp should stay 20")


func _test_cds_tick_and_skill_without_input(director, errors: Array) -> void:
	if not director.has_method("tick_cds"):
		errors.append("CombatDirector.tick_cds should exist")
		return
	var cds := {"flame_spark": 1.5}
	director.tick_cds(cds, 0.5)
	if not is_equal_approx(float(cds["flame_spark"]), 1.0):
		errors.append("tick_cds should subtract delta, got %s" % cds["flame_spark"])
	var spark := SkillDef.from_dict({
		"id": "flame_spark",
		"name": "Flame Spark",
		"kind": "single",
		"power": 8,
		"cooldown": 3.0
	})
	var player := {
		"pos": Vector2.ZERO,
		"hp": 40.0,
		"hp_max": 40.0,
		"atk": 4,
		"def": 2,
		"class_id": ClassId.Value.MAGE
	}
	var enemies: Array = [
		{"pos": Vector2(80, 0), "hp": 35.0, "def": 0}
	]
	var skill_cds := {"flame_spark": 0.0}
	var result: Dictionary = director.player_act(player, enemies, [spark], skill_cds)
	if result.get("skill_id", "") != "flame_spark":
		errors.append("skills should fire automatically via AutoCombat, got skill_id=%s" % result.get("skill_id", ""))
	if float(enemies[0].hp) >= 35.0:
		errors.append("auto skill should deal damage")
	for method_name in ["attack", "cast_skill", "fire_skill", "use_skill"]:
		if director.has_method(method_name):
			errors.append("CombatDirector must not expose input attack method " + method_name)


func _test_mage_dies_standing_in_pack(director, errors: Array) -> void:
	if not director.has_method("simulate_tick"):
		errors.append("CombatDirector.simulate_tick should exist")
		return
	var player := {
		"pos": Vector2.ZERO,
		"hp": 40.0,
		"hp_max": 40.0,
		"atk": 4,
		"def": 2,
		"class_id": ClassId.Value.MAGE
	}
	var enemies: Array = [
		{"pos": Vector2(40, 0), "hp": 20.0, "atk": 3, "def": 0},
		{"pos": Vector2(50, 10), "hp": 20.0, "atk": 3, "def": 0},
		{"pos": Vector2(30, -10), "hp": 35.0, "atk": 5, "def": 2}
	]
	var player_cds := {}
	var enemy_cds: Array = [{}, {}, {}]
	var defeated := false
	for _i in 40:
		var tick: Dictionary = director.simulate_tick(player, enemies, [], player_cds, enemy_cds, 1.0)
		if tick.get("defeated", false) or float(player.hp) <= 0.0:
			defeated = true
			break
	if not defeated:
		errors.append("Mage standing in a pack should reach hp <= 0")

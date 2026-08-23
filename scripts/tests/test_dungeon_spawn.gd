extends RefCounted


func run() -> Array:
	var errors: Array = []
	_test_monsters_json(errors)
	_test_spawn_plan_from_ids(errors)
	_test_enemy_actor_combatant(errors)
	return errors


func _test_monsters_json(errors: Array) -> void:
	if not FileAccess.file_exists("res://data/monsters.json"):
		errors.append("data/monsters.json missing")
		return
	var file := FileAccess.open("res://data/monsters.json", FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Array) or parsed.is_empty():
		errors.append("monsters.json should be a non-empty array")
		return
	var by_id := {}
	for item in parsed:
		by_id[str(item.get("id", ""))] = item
	if not by_id.has("drops") or int(by_id["drops"].get("hp", 0)) != 32:
		errors.append("drops should have hp 32")


func _test_spawn_plan_from_ids(errors: Array) -> void:
	var script: GDScript = load("res://scripts/dungeon/dungeon_controller.gd")
	if script == null:
		errors.append("DungeonController script missing")
		return
	if not script.can_instantiate():
		errors.append("DungeonController script cannot instantiate")
		return
	var controller = script.new()
	if not controller.has_method("spawn_plan"):
		errors.append("DungeonController.spawn_plan should exist")
		controller.free()
		return
	if not controller.has_method("current_room_monster_ids"):
		errors.append("DungeonController.current_room_monster_ids should exist")
		controller.free()
		return
	var plan: Array = controller.spawn_plan(["drops", "drops", "drops"])
	if plan.size() != 3:
		errors.append("spawn_plan should resolve 3 drops, got %s" % plan.size())
	elif str(plan[0].get("id", "")) != "drops" or int(plan[0].get("hp", 0)) != 32:
		errors.append("first spawn should be drops hp 32")
	var run := RunState.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	run.start_act(rng)
	var room_ids: Array = controller.current_room_monster_ids(run)
	for mid in room_ids:
		if str(mid) in ["mob_a", "boss_act1"]:
			errors.append("current room should not use placeholder id %s" % mid)
	var unknown: Array = controller.spawn_plan(["no_such_mob", "drops"])
	if unknown.size() != 1 or str(unknown[0].get("id", "")) != "drops":
		errors.append("spawn_plan should skip unknown ids")
	controller.free()


func _test_enemy_actor_combatant(errors: Array) -> void:
	var script: GDScript = load("res://scripts/dungeon/enemy_actor.gd")
	if script == null:
		errors.append("EnemyActor script missing")
		return
	if not script.can_instantiate():
		errors.append("EnemyActor script cannot instantiate")
		return
	var enemy = script.new()
	if not enemy.has_method("bind_monster"):
		errors.append("EnemyActor.bind_monster should exist")
		enemy.free()
		return
	if not enemy.has_method("to_combatant"):
		errors.append("EnemyActor.to_combatant should exist")
		enemy.free()
		return
	enemy.bind_monster({
		"id": "cave_slime",
		"name": "Cave Slime",
		"tier": 1,
		"hp": 20,
		"atk": 3,
		"def": 0
	})
	if str(enemy.monster_id) != "cave_slime":
		errors.append("bind_monster should set monster_id")
	if not is_equal_approx(float(enemy.hp), 20.0):
		errors.append("bind_monster should set hp from def")
	var c: Dictionary = enemy.to_combatant()
	if not c.has("pos") or not c.has("hp"):
		errors.append("enemy combatant must include {pos, hp}")
	elif not (c.pos is Vector2):
		errors.append("enemy combatant pos must be Vector2")
	enemy.free()

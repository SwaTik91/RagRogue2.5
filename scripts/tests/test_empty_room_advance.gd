extends RefCounted


func run() -> Array:
	var errors: Array = []
	_test_start_run_loot_advances_to_pack_or_act_end(errors)
	_test_skips_consecutive_empty_loot_and_event(errors)
	return errors


func _test_start_run_loot_advances_to_pack_or_act_end(errors: Array) -> void:
	var script: GDScript = load("res://scripts/dungeon/dungeon_controller.gd")
	if script == null:
		errors.append("DungeonController script missing")
		return
	var controller = script.new()
	if not controller.has_method("advance_past_empty_rooms"):
		errors.append("DungeonController.advance_past_empty_rooms should exist")
		controller.free()
		return
	var session_script: GDScript = load("res://scripts/app/game_session.gd")
	if session_script == null:
		errors.append("GameSession script missing")
		controller.free()
		return
	var session = session_script.new()
	session.save_path = "user://test_empty_room_advance.json"
	session.reload()
	session.start_run()
	session.run.rooms[session.run.room_index] = {
		"type": RoomType.Value.LOOT,
		"monster_ids": [],
		"cleared": false
	}
	controller.advance_past_empty_rooms(session.run)
	var finished: bool = int(session.run.floor_index) >= FloorGen.ACT_FLOOR_COUNT
	var ids: Array = controller.current_room_monster_ids(session.run)
	if not finished and ids.is_empty():
		errors.append("after skip, current room should have combat/boss ids or act should be finished")
	if not finished and not ids.is_empty():
		var room: Dictionary = session.run.rooms[session.run.room_index]
		var rtype := int(room.get("type", -1))
		if rtype != RoomType.Value.COMBAT and rtype != RoomType.Value.BOSS:
			errors.append("landed pack room should be COMBAT or BOSS, got type %s" % rtype)
	controller.free()
	session.free()


func _test_skips_consecutive_empty_loot_and_event(errors: Array) -> void:
	var script: GDScript = load("res://scripts/dungeon/dungeon_controller.gd")
	if script == null:
		errors.append("DungeonController script missing")
		return
	var controller = script.new()
	if not controller.has_method("advance_past_empty_rooms"):
		errors.append("DungeonController.advance_past_empty_rooms should exist")
		controller.free()
		return
	var run := RunState.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	run.start_act(rng)
	run.rooms = [
		{"type": RoomType.Value.LOOT, "monster_ids": [], "cleared": false},
		{"type": RoomType.Value.EVENT, "monster_ids": [], "cleared": false},
		{"type": RoomType.Value.COMBAT, "monster_ids": ["drops", "drops", "drops"], "cleared": false}
	]
	run.room_index = 0
	run.floor_index = 0
	controller.advance_past_empty_rooms(run)
	var ids: Array = controller.current_room_monster_ids(run)
	if run.room_index != 2:
		errors.append("should skip empty LOOT+EVENT to the combat pack, room_index=%s" % run.room_index)
	if ids != ["drops", "drops", "drops"]:
		errors.append("current room should be the drops pack, got %s" % str(ids))
	controller.free()

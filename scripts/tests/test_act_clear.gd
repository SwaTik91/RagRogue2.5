extends RefCounted

const SESSION_PATH := "user://test_act_clear_save.json"


func run() -> Array:
	var errors: Array = []
	_wipe_user("test_act_clear_save.json")
	_test_debug_short_act_default_false(errors)
	_test_debug_short_act_builds_one_combat_and_boss(errors)
	_test_combat_clear_waits_for_upgrade_then_advances(errors)
	_test_combat_clear_awards_xp(errors)
	_test_boss_clear_grants_loot_and_victory_toast(errors)
	_test_victory_ends_run(errors)
	_test_hub_shows_victory_toast(errors)
	_test_hub_shows_equip_and_skills(errors)
	_wipe_user("test_act_clear_save.json")
	return errors


func _wipe_user(filename: String) -> void:
	var dir := DirAccess.open("user://")
	if dir != null and dir.file_exists(filename):
		dir.remove(filename)


func _make_session():
	var script: GDScript = load("res://scripts/app/game_session.gd")
	var session = script.new()
	session.save_path = SESSION_PATH
	session.reload()
	return session


func _make_controller():
	var script: GDScript = load("res://scripts/dungeon/dungeon_controller.gd")
	if script == null:
		return null
	return script.new()


func _test_debug_short_act_default_false(errors: Array) -> void:
	var session = _make_session()
	if not ("debug_short_act" in session):
		errors.append("GameSession.debug_short_act should exist")
		session.free()
		return
	if session.debug_short_act:
		errors.append("GameSession.debug_short_act should default false")
	session.free()


func _test_debug_short_act_builds_one_combat_and_boss(errors: Array) -> void:
	var session = _make_session()
	if not ("debug_short_act" in session):
		errors.append("GameSession.debug_short_act should exist")
		session.free()
		return
	session.debug_short_act = true
	session.start_run()
	var rooms: Array = session.run.rooms
	if rooms.size() != 2:
		errors.append("debug_short_act should build 1 combat + boss, got %s rooms" % rooms.size())
		session.free()
		return
	if int(rooms[0].get("type", -1)) != RoomType.Value.COMBAT:
		errors.append("short act first room should be COMBAT")
	if int(rooms[1].get("type", -1)) != RoomType.Value.BOSS:
		errors.append("short act second room should be BOSS")
	var boss_ids: Array = rooms[1].get("monster_ids", [])
	if boss_ids != ["angel_mvp"]:
		errors.append("short act boss should be angel_mvp, got %s" % str(boss_ids))
	session.run.on_room_cleared()
	session.run.on_room_cleared()
	if int(session.run.floor_index) < 1:
		errors.append("short act should finish after one floor, floor_index=%s" % session.run.floor_index)
	session.free()


func _test_combat_clear_waits_for_upgrade_then_advances(errors: Array) -> void:
	var controller = _make_controller()
	if controller == null:
		errors.append("DungeonController script missing")
		return
	if not controller.has_method("handle_combat_clear"):
		errors.append("DungeonController.handle_combat_clear should exist")
		controller.free()
		return
	if not controller.has_method("apply_upgrade_and_advance"):
		errors.append("DungeonController.apply_upgrade_and_advance should exist")
		controller.free()
		return
	var session = _make_session()
	session.start_run()
	session.run.rooms = [
		{"type": RoomType.Value.COMBAT, "monster_ids": ["drops", "drops", "drops"], "cleared": false},
		{"type": RoomType.Value.LOOT, "monster_ids": [], "cleared": false},
		{"type": RoomType.Value.EVENT, "monster_ids": [], "cleared": false},
		{"type": RoomType.Value.COMBAT, "monster_ids": ["drops", "drops", "drops"], "cleared": false}
	]
	session.run.room_index = 0
	session.run.floor_index = 0
	var outcome := str(controller.handle_combat_clear(session))
	if outcome != "upgrade":
		errors.append("COMBAT clear should offer upgrades, got %s" % outcome)
	if session.run.room_index != 0:
		errors.append("COMBAT clear must not advance before an upgrade is picked, room_index=%s" % session.run.room_index)
	if session.run.modifiers.size() != 0:
		errors.append("COMBAT clear must not apply an upgrade before pick")
	controller.apply_upgrade_and_advance(session, "atk_up")
	if session.run.modifiers.size() != 1 or session.run.modifiers[0] != "atk_up":
		errors.append("picked upgrade should call run.apply_upgrade, got %s" % str(session.run.modifiers))
	if session.run.room_index != 3:
		errors.append("after pick, should skip empty LOOT+EVENT to next combat, room_index=%s" % session.run.room_index)
	var ids: Array = controller.current_room_monster_ids(session.run)
	if ids != ["drops", "drops", "drops"]:
		errors.append("after pick+skip, current room should be drops pack, got %s" % str(ids))
	controller.free()
	session.free()


func _test_combat_clear_awards_xp(errors: Array) -> void:
	var controller = _make_controller()
	if controller == null:
		errors.append("DungeonController script missing")
		return
	var session = _make_session()
	session.active_class = ClassId.Value.MAGE
	var hero: Hero = session.active_hero()
	var xp_before := hero.xp
	var level_before := hero.level
	session.start_run()
	session.run.rooms = [
		{"type": RoomType.Value.COMBAT, "monster_ids": ["drops", "drops"], "cleared": false}
	]
	session.run.room_index = 0
	session.run.floor_index = 0
	if not controller.has_method("handle_combat_clear"):
		errors.append("DungeonController.handle_combat_clear should exist")
		controller.free()
		session.free()
		return
	controller.handle_combat_clear(session)
	# drops tier 2 x2 => 40 XP
	if hero.xp != xp_before + 40 and not (hero.level > level_before):
		errors.append("combat clear should award XP for spawned tiers, xp=%s level=%s" % [hero.xp, hero.level])
	controller.free()
	session.free()

	var session2 = _make_session()
	session2.active_class = ClassId.Value.MAGE
	var hero2: Hero = session2.active_hero()
	if hero2.xp < 40 and hero2.level <= 1:
		errors.append("persist after combat clear should keep awarded XP, xp=%s level=%s" % [hero2.xp, hero2.level])
	session2.free()


func _test_boss_clear_grants_loot_and_victory_toast(errors: Array) -> void:
	var controller = _make_controller()
	if controller == null:
		errors.append("DungeonController script missing")
		return
	if not controller.has_method("handle_combat_clear"):
		errors.append("DungeonController.handle_combat_clear should exist")
		controller.free()
		return
	var session = _make_session()
	if not session.has_method("apply_victory"):
		errors.append("GameSession.apply_victory should exist")
		controller.free()
		session.free()
		return
	session.active_class = ClassId.Value.MAGE
	var hero: Hero = session.active_hero()
	var before_level := hero.level
	hero.equip(GearItem.from_dict({
		"id": "staff_n",
		"name": "Apprentice Staff",
		"slot": "weapon",
		"rarity": Rarity.Value.N,
		"atk_bonus": 3,
		"def_bonus": 0,
		"hp_bonus": 0
	}))
	session.start_run()
	session.run.rooms = [
		{"type": RoomType.Value.BOSS, "monster_ids": ["angel_mvp"], "cleared": false}
	]
	session.run.room_index = 0
	session.run.floor_index = FloorGen.ACT_FLOOR_COUNT - 1
	var outcome := str(controller.handle_combat_clear(session))
	if outcome != "victory":
		errors.append("BOSS clear should resolve as victory, got %s" % outcome)
	if str(session.pending_toast) == "Поражение":
		errors.append("boss clear must not use Поражение toast")
	if str(session.pending_toast) != "Победа":
		errors.append("pending_toast should be Победа, got %s" % session.pending_toast)
	if hero.level != before_level:
		errors.append("boss clear must not wipe hero level, got %s" % hero.level)
	if hero.equipped.is_empty():
		errors.append("boss clear should keep/grant gear, equipped empty")
	for slot in hero.equipped:
		var item: GearItem = hero.equipped[slot]
		if item.rarity != Rarity.Value.N and item.rarity != Rarity.Value.R:
			errors.append("boss loot rarity should be N or R, got %s" % item.rarity)
	controller.free()
	session.free()

	var session2 = _make_session()
	session2.active_class = ClassId.Value.MAGE
	var hero2: Hero = session2.active_hero()
	if hero2.equipped.is_empty():
		errors.append("persist after victory should keep granted gear")
	if hero2.level != before_level:
		errors.append("persist after victory should keep hero level")
	session2.free()


func _test_victory_ends_run(errors: Array) -> void:
	var session = _make_session()
	if not session.has_method("apply_victory"):
		errors.append("GameSession.apply_victory should exist")
		session.free()
		return
	session.start_run()
	session.run.apply_upgrade("atk_up")
	if session.run.modifiers.is_empty():
		errors.append("precondition: atk_up should be on the run")
		session.free()
		return
	session.apply_victory()
	if session.run.alive:
		errors.append("apply_victory should set run.alive = false")
	if session.run.modifiers.size() != 0:
		errors.append("apply_victory should clear run modifiers, got %s" % str(session.run.modifiers))
	session.free()


func _test_hub_shows_victory_toast(errors: Array) -> void:
	var script: GDScript = load("res://scripts/ui/hub_controller.gd")
	if script == null:
		errors.append("HubController script missing")
		return
	var hub = script.new()
	if not hub.has_method("consume_pending_toast"):
		errors.append("HubController.consume_pending_toast should exist")
		hub.free()
		return
	var text: String = hub.consume_pending_toast("Победа")
	if text != "Победа":
		errors.append("hub toast text should accept Победа, got %s" % text)
	if text == "Поражение":
		errors.append("victory toast must not be Поражение")
	hub.free()


func _test_hub_shows_equip_and_skills(errors: Array) -> void:
	var script: GDScript = load("res://scripts/ui/hub_controller.gd")
	if script == null:
		errors.append("HubController script missing")
		return
	var hub = script.new()
	if not hub.has_method("equipped_summary") or not hub.has_method("skills_summary"):
		errors.append("HubController should expose equipped_summary and skills_summary")
		hub.free()
		return
	var mage := Hero.new(ClassId.Value.MAGE)
	mage.equip(GearItem.from_dict({
		"id": "staff_n",
		"name": "Apprentice Staff",
		"slot": "weapon",
		"rarity": Rarity.Value.N,
		"atk_bonus": 3,
		"def_bonus": 0,
		"hp_bonus": 0
	}))
	var gear_line := str(hub.equipped_summary(mage))
	if gear_line.find("staff_n") < 0 and gear_line.find("Apprentice Staff") < 0:
		errors.append("equipped_summary should show weapon id or name, got %s" % gear_line)
	if gear_line.find("armor") < 0 and gear_line.find("Броня") < 0:
		errors.append("equipped_summary should mention armor slot, got %s" % gear_line)
	var skill_line := str(hub.skills_summary(mage))
	if skill_line.find("flame_spark") < 0 and skill_line.find("Flame Spark") < 0:
		errors.append("skills_summary should list unlocked skill id or name, got %s" % skill_line)
	hub.free()

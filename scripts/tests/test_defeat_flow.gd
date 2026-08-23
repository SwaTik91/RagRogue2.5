extends RefCounted

const SESSION_PATH := "user://test_defeat_flow_save.json"


func run() -> Array:
	var errors: Array = []
	_wipe_user("test_defeat_flow_save.json")
	_test_apply_defeat_keeps_progress(errors)
	_test_hub_shows_defeat_toast(errors)
	_wipe_user("test_defeat_flow_save.json")
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


func _test_apply_defeat_keeps_progress(errors: Array) -> void:
	var script: GDScript = load("res://scripts/app/game_session.gd")
	var session = script.new()
	session.save_path = SESSION_PATH
	session.reload()
	session.active_class = ClassId.Value.MAGE
	var hero: Hero = session.active_hero()
	hero.add_xp(100)
	hero.equip(_staff())
	session.start_run()
	session.run.apply_upgrade("atk_up")
	if not session.has_method("apply_defeat"):
		errors.append("GameSession.apply_defeat should exist")
		session.free()
		return
	session.apply_defeat()
	if session.run.alive:
		errors.append("apply_defeat should set run.alive = false")
	if hero.level != 2:
		errors.append("defeat must not wipe hero level, got %s" % hero.level)
	if not hero.equipped.has("weapon"):
		errors.append("defeat must not wipe permanent gear")
	if session.run.modifiers.size() != 0:
		errors.append("defeat should clear run modifiers")
	if str(session.pending_toast) != "Поражение":
		errors.append("pending_toast should be Поражение, got %s" % session.pending_toast)
	session.free()

	var session2 = script.new()
	session2.save_path = SESSION_PATH
	session2.reload()
	session2.active_class = ClassId.Value.MAGE
	var hero2: Hero = session2.active_hero()
	if hero2.level != 2:
		errors.append("persist after defeat should keep mage level 2, got %s" % hero2.level)
	if not hero2.equipped.has("weapon"):
		errors.append("persist after defeat should keep equipped gear")
	session2.free()


func _test_hub_shows_defeat_toast(errors: Array) -> void:
	var script: GDScript = load("res://scripts/ui/hub_controller.gd")
	if script == null:
		errors.append("HubController script missing")
		return
	var hub = script.new()
	if not hub.has_method("consume_pending_toast"):
		errors.append("HubController.consume_pending_toast should exist")
		hub.free()
		return
	var text: String = hub.consume_pending_toast("Поражение")
	if text != "Поражение":
		errors.append("hub toast text should be Поражение")
	hub.free()

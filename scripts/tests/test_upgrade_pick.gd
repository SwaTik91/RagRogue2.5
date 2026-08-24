extends RefCounted


func run() -> Array:
	var errors: Array = []
	_test_script_and_pick_three(errors)
	_test_choose_emits_id(errors)
	_test_scene_has_three_buttons(errors)
	return errors


func _test_script_and_pick_three(errors: Array) -> void:
	var script: GDScript = load("res://scripts/ui/upgrade_pick.gd")
	if script == null:
		errors.append("UpgradePick script missing")
		return
	if not script.can_instantiate():
		errors.append("UpgradePick script cannot instantiate")
		return
	var pick = script.new()
	if not pick.has_method("pick_three"):
		errors.append("UpgradePick.pick_three should exist")
		pick.free()
		return
	if not pick.has_method("present"):
		errors.append("UpgradePick.present should exist")
		pick.free()
		return
	if not pick.has_method("choose"):
		errors.append("UpgradePick.choose should exist")
		pick.free()
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var offered: Array = pick.pick_three(rng)
	if offered.size() != 3:
		errors.append("pick_three should return 3 upgrades, got %s" % offered.size())
		pick.free()
		return
	var ids := {}
	for item in offered:
		if not (item is Dictionary) or not item.has("id"):
			errors.append("each offered upgrade should be a dict with id")
			pick.free()
			return
		ids[str(item["id"])] = true
	if ids.size() != 3:
		errors.append("pick_three should return 3 unique ids, got %s" % str(ids.keys()))
	for expected in ["atk_up", "hp_up", "cdr"]:
		if not ids.has(expected):
			errors.append("catalog pick should include %s when only 3 upgrades exist" % expected)
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 99
	var again: Array = pick.pick_three(rng2)
	if again.size() == 3 and offered.size() == 3:
		if str(again[0].get("id", "")) != str(offered[0].get("id", "")):
			errors.append("pick_three should be deterministic for a seeded rng")
	pick.free()


func _test_choose_emits_id(errors: Array) -> void:
	var script: GDScript = load("res://scripts/ui/upgrade_pick.gd")
	if script == null:
		return
	var pick = script.new()
	if not pick.has_method("choose") or not pick.has_signal("upgrade_chosen"):
		errors.append("UpgradePick.choose should emit upgrade_chosen")
		pick.free()
		return
	var got := [""]
	pick.upgrade_chosen.connect(func(upgrade_id: String) -> void: got[0] = upgrade_id)
	if pick.has_method("present"):
		pick.present([
			{"id": "atk_up", "name": "Sharpened Focus"},
			{"id": "hp_up", "name": "Vital Charm"},
			{"id": "cdr", "name": "Quick Chant"}
		])
	else:
		pick.free()
		return
	pick.choose(1)
	if got[0] != "hp_up":
		errors.append("choose(1) should emit hp_up, got %s" % got[0])
	pick.free()


func _test_scene_has_three_buttons(errors: Array) -> void:
	if not FileAccess.file_exists("res://scenes/ui/upgrade_pick.tscn"):
		errors.append("scenes/ui/upgrade_pick.tscn missing")
		return
	var packed: PackedScene = load("res://scenes/ui/upgrade_pick.tscn")
	if packed == null:
		errors.append("upgrade_pick.tscn failed to load")
		return
	var ui = packed.instantiate()
	var found := 0
	for i in 3:
		var node = ui.get_node_or_null("Panel/Choices/Choice%d" % i)
		if node is Button:
			found += 1
	if found != 3:
		errors.append("upgrade pick scene should have three Choice buttons, found %s" % found)
	ui.free()

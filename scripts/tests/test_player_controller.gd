extends RefCounted


func run() -> Array:
	var errors: Array = []
	_test_player_move_api(errors)
	_test_virtual_stick(errors)
	return errors


func _test_player_move_api(errors: Array) -> void:
	var script: GDScript = load("res://scripts/dungeon/player_controller.gd")
	if script == null:
		errors.append("PlayerController script missing")
		return
	if not script.can_instantiate():
		errors.append("PlayerController script cannot instantiate")
		return
	var player = script.new()
	if not player.has_method("bind_hero"):
		errors.append("PlayerController.bind_hero should exist")
		player.free()
		return
	if not player.has_method("set_move_vector"):
		errors.append("PlayerController.set_move_vector should exist")
		player.free()
		return
	if not player.has_method("compute_velocity"):
		errors.append("PlayerController.compute_velocity should exist")
		player.free()
		return
	if not player.has_method("combine_move_vector"):
		errors.append("PlayerController.combine_move_vector should exist")
		player.free()
		return
	var hero := Hero.new(ClassId.Value.MAGE)
	player.bind_hero(hero)
	var expected_speed := float(CombatStats.from_hero(hero).move_speed)
	if not is_equal_approx(float(player.move_speed), expected_speed):
		errors.append("move_speed should come from CombatStats.from_hero")
	player.set_move_vector(Vector2(2, 0))
	var vel: Vector2 = player.compute_velocity()
	if not vel.is_equal_approx(Vector2.RIGHT * expected_speed):
		errors.append("compute_velocity should be clamped move_vector * move_speed")
	var no_editor: Vector2 = player.combine_move_vector(Vector2.ZERO, Vector2.UP, false)
	if not no_editor.is_equal_approx(Vector2.ZERO):
		errors.append("keyboard must not contribute when editor_debug is false")
	var editor_key: Vector2 = player.combine_move_vector(Vector2.ZERO, Vector2.UP, true)
	if not editor_key.is_equal_approx(Vector2.UP):
		errors.append("keyboard should contribute when editor_debug is true")
	var editor_override: Vector2 = player.combine_move_vector(Vector2.RIGHT, Vector2.UP, true)
	if not editor_override.is_equal_approx(Vector2.UP):
		errors.append("editor keyboard should override stick when pressed")
	for method_name in ["attack", "cast_skill", "fire_skill", "use_skill"]:
		if player.has_method(method_name):
			errors.append("PlayerController must not expose attack/skill method " + method_name)
	if not player.has_method("to_combatant"):
		errors.append("PlayerController.to_combatant should exist")
	else:
		player.hp = 33.0
		var c: Dictionary = player.to_combatant()
		if not c.has("pos") or not c.has("hp"):
			errors.append("player combatant must include {pos, hp}")
		elif not (c.pos is Vector2):
			errors.append("player combatant pos must be Vector2")
		elif not is_equal_approx(float(c.hp), 33.0):
			errors.append("player combatant hp should match actor hp")
	player.free()


func _test_virtual_stick(errors: Array) -> void:
	var script: GDScript = load("res://scripts/ui/virtual_stick.gd")
	if script == null:
		errors.append("VirtualStick script missing")
		return
	if not script.can_instantiate():
		errors.append("VirtualStick script cannot instantiate")
		return
	var stick = script.new()
	if not stick.has_method("set_pointer"):
		errors.append("VirtualStick.set_pointer should exist")
		stick.free()
		return
	if not stick.has_method("get_vector"):
		errors.append("VirtualStick.get_vector should exist")
		stick.free()
		return
	if not stick.has_method("release"):
		errors.append("VirtualStick.release should exist")
		stick.free()
		return
	stick.size = Vector2(160, 160)
	stick.max_radius = 80.0
	stick.set_pointer(Vector2(160, 80))
	var v: Vector2 = stick.get_vector()
	if v.x <= 0.0:
		errors.append("stick pointer right of center should yield +x")
	if v.length() > 1.0 + 0.001:
		errors.append("stick vector length must be <= 1")
	stick.release()
	if not stick.get_vector().is_equal_approx(Vector2.ZERO):
		errors.append("stick release should zero the vector")
	stick.free()

extends RefCounted

func run() -> Array:
	var errors: Array = []
	_test_upgrade_adds_modifier(errors)
	_test_clearing_last_room_increments_floor(errors)
	return errors


func _seeded_rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	return rng


func _test_upgrade_adds_modifier(errors: Array) -> void:
	var run := RunState.new()
	run.start_act(_seeded_rng())
	run.apply_upgrade("atk_up")
	if run.modifiers.size() != 1 or run.modifiers[0] != "atk_up":
		errors.append("atk_up should append modifier, got %s" % str(run.modifiers))
	run.apply_upgrade("not_an_upgrade")
	if run.modifiers.size() != 1:
		errors.append("unknown upgrade id should be ignored")


func _test_clearing_last_room_increments_floor(errors: Array) -> void:
	var run := RunState.new()
	run.start_act(_seeded_rng())
	if run.floor_index != 0:
		errors.append("start_act should set floor_index to 0")
	if run.rooms.size() < 3:
		errors.append("start_act should generate a floor with rooms")
	var room_count: int = run.rooms.size()
	for _i in room_count - 1:
		run.on_room_cleared()
	if run.floor_index != 0:
		errors.append("clearing non-last rooms should stay on floor 0")
	if run.room_index != room_count - 1:
		errors.append("should be on last room before final clear, room_index=%s" % run.room_index)
	run.on_room_cleared()
	if run.floor_index != 1:
		errors.append("clearing last room should increment floor, got %s" % run.floor_index)
	if run.room_index != 0:
		errors.append("new floor should reset room_index to 0")

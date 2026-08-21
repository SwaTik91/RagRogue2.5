extends SceneTree

func _init() -> void:
	var failed := 0
	failed += _run("res://scripts/tests/test_smoke.gd")
	failed += _run("res://scripts/tests/test_hero.gd")
	failed += _run("res://scripts/tests/test_auto_combat.gd")
	failed += _run("res://scripts/tests/test_floor_gen.gd")
	failed += _run("res://scripts/tests/test_run_state.gd")
	quit(1 if failed > 0 else 0)

func _run(path: String) -> int:
	var script: GDScript = load(path)
	if script == null:
		push_error("Missing test: " + path)
		return 1
	if not script.can_instantiate():
		push_error("Unusable test script: " + path)
		return 1
	var inst = script.new()
	if inst.has_method("run"):
		var errs: Array = inst.run()
		for e in errs:
			push_error(str(e))
		return errs.size()
	push_error("No run() in " + path)
	return 1

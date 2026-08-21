extends RefCounted

const SESSION_PATH := "user://test_start_run_save.json"


func run() -> Array:
	var errors: Array = []
	_wipe_user("test_start_run_save.json")
	_test_start_run_sets_alive(errors)
	_wipe_user("test_start_run_save.json")
	return errors


func _wipe_user(filename: String) -> void:
	var dir := DirAccess.open("user://")
	if dir != null and dir.file_exists(filename):
		dir.remove(filename)


func _test_start_run_sets_alive(errors: Array) -> void:
	var script: GDScript = load("res://scripts/app/game_session.gd")
	var session = script.new()
	session.save_path = SESSION_PATH
	session.reload()
	session.run.alive = false
	if not session.has_method("start_run"):
		errors.append("GameSession.start_run should exist")
		session.free()
		return
	session.start_run()
	if session.run == null or not session.run.alive:
		errors.append("GameSession.start_run() should set run.alive == true")
	session.free()

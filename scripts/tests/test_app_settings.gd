extends RefCounted

const SETTINGS_FILE := "ragrogue_settings_test.cfg"


func run() -> Array:
	var errors: Array = []
	_wipe()
	_test_defaults_and_persist(errors)
	_wipe()
	_test_language_guard(errors)
	_wipe()
	return errors


func _wipe() -> void:
	var dir := DirAccess.open("user://")
	if dir != null and dir.file_exists(SETTINGS_FILE):
		dir.remove(SETTINGS_FILE)


func _test_defaults_and_persist(errors: Array) -> void:
	var script: GDScript = load("res://scripts/app/app_settings.gd")
	var s = script.new()
	s.path = "user://%s" % SETTINGS_FILE
	s.load_from_disk()
	if s.language != "ru":
		errors.append("default language should be ru")
	s.set_master_volume(0.5)
	s.set_music_volume(0.25)
	s.set_sfx_volume(0.75)
	s.set_language("en")
	s.free()
	var s2 = script.new()
	s2.path = "user://%s" % SETTINGS_FILE
	s2.load_from_disk()
	if absf(s2.master_volume - 0.5) > 0.001:
		errors.append("master_volume should persist")
	if absf(s2.music_volume - 0.25) > 0.001:
		errors.append("music_volume should persist")
	if absf(s2.sfx_volume - 0.75) > 0.001:
		errors.append("sfx_volume should persist")
	if s2.language != "en":
		errors.append("language should persist as en")
	s2.free()


func _test_language_guard(errors: Array) -> void:
	var script: GDScript = load("res://scripts/app/app_settings.gd")
	var s = script.new()
	s.path = "user://%s" % SETTINGS_FILE
	s.set_language("de")
	if s.language != "ru":
		errors.append("invalid language should be ignored (stay ru)")
	# Loc table
	if Loc.t("play", "en") != "Play":
		errors.append("Loc.t play/en should be Play")
	if Loc.t("play", "ru") != "Играть":
		errors.append("Loc.t play/ru should be Играть")
	s.free()

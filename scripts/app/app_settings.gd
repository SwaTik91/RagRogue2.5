extends Node
## Persistent player preferences (volume + language). Autoload: AppSettings.

const DEFAULT_PATH := "user://ragrogue_settings.cfg"
const SECTION := "audio"
const SECTION_UI := "ui"

var path: String = DEFAULT_PATH
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
## "ru" | "en"
var language: String = "ru"

signal settings_changed


func _ready() -> void:
	load_from_disk()
	apply_audio()


func load_from_disk() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	master_volume = clampf(float(cfg.get_value(SECTION, "master", master_volume)), 0.0, 1.0)
	music_volume = clampf(float(cfg.get_value(SECTION, "music", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(cfg.get_value(SECTION, "sfx", sfx_volume)), 0.0, 1.0)
	var lang := str(cfg.get_value(SECTION_UI, "language", language))
	if lang in ["ru", "en"]:
		language = lang


func save_to_disk() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "master", master_volume)
	cfg.set_value(SECTION, "music", music_volume)
	cfg.set_value(SECTION, "sfx", sfx_volume)
	cfg.set_value(SECTION_UI, "language", language)
	cfg.save(path)


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	apply_audio()
	save_to_disk()
	settings_changed.emit()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	apply_audio()
	save_to_disk()
	settings_changed.emit()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	apply_audio()
	save_to_disk()
	settings_changed.emit()


func set_language(code: String) -> void:
	if code not in ["ru", "en"]:
		return
	language = code
	save_to_disk()
	settings_changed.emit()


func apply_audio() -> void:
	_set_bus_linear("Master", master_volume)
	_set_bus_linear("Music", music_volume * master_volume)
	_set_bus_linear("SFX", sfx_volume * master_volume)


func _set_bus_linear(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	var v := clampf(linear, 0.0, 1.0)
	if v <= 0.0001:
		AudioServer.set_bus_mute(idx, true)
		AudioServer.set_bus_volume_db(idx, -80.0)
	else:
		AudioServer.set_bus_mute(idx, false)
		AudioServer.set_bus_volume_db(idx, linear_to_db(v))

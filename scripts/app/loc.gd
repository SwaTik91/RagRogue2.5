class_name Loc
extends RefCounted
## Tiny RU/EN string table for menu / hub / settings.

const STRINGS := {
	"play": {"ru": "Играть", "en": "Play"},
	"heroes": {"ru": "Герои", "en": "Heroes"},
	"settings": {"ru": "Настройки", "en": "Settings"},
	"tagline": {"ru": "Roguelike · автобой · ручной ход", "en": "Roguelike · auto combat · manual move"},
	"back": {"ru": "Назад", "en": "Back"},
	"back_menu": {"ru": "Назад в меню", "en": "Back to menu"},
	"settings_title": {"ru": "Настройки", "en": "Settings"},
	"master_vol": {"ru": "Общая громкость", "en": "Master volume"},
	"music_vol": {"ru": "Музыка", "en": "Music"},
	"sfx_vol": {"ru": "Эффекты", "en": "SFX"},
	"language": {"ru": "Язык", "en": "Language"},
	"pick_hero": {"ru": "Выбери героя", "en": "Choose a hero"},
	"enter_dungeon": {"ru": "В подземелье", "en": "Enter dungeon"},
	"level": {"ru": "Уровень %d", "en": "Level %d"},
	"settings_saved": {"ru": "Сохранено", "en": "Saved"},
}


static func t(key: String, language: String = "") -> String:
	var lang := language
	if lang == "":
		var settings = _settings()
		if settings != null:
			lang = str(settings.language)
		else:
			lang = "ru"
	var entry = STRINGS.get(key, null)
	if entry == null:
		return key
	if entry is Dictionary:
		return str(entry.get(lang, entry.get("ru", key)))
	return str(entry)


static func _settings() -> Node:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		return (loop as SceneTree).root.get_node_or_null("AppSettings")
	return null

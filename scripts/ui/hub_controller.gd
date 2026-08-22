extends Control

@onready var level_label: Label = get_node_or_null("%LevelLabel") as Label
@onready var swordman_button: Button = get_node_or_null("%SwordmanButton") as Button
@onready var mage_button: Button = get_node_or_null("%MageButton") as Button
@onready var archer_button: Button = get_node_or_null("%ArcherButton") as Button
@onready var enter_button: Button = get_node_or_null("%EnterButton") as Button
@onready var toast_label: Label = get_node_or_null("%ToastLabel") as Label
@onready var gear_label: Label = get_node_or_null("%GearLabel") as Label
@onready var skills_label: Label = get_node_or_null("%SkillsLabel") as Label
@onready var swordman_portrait: TextureRect = get_node_or_null("%SwordmanPortrait") as TextureRect
@onready var mage_portrait: TextureRect = get_node_or_null("%MagePortrait") as TextureRect
@onready var archer_portrait: TextureRect = get_node_or_null("%ArcherPortrait") as TextureRect
@onready var back_button: Button = get_node_or_null("%BackButton") as Button

const SELECTED_MODULATE := Color(1, 1, 1, 1)
const IDLE_MODULATE := Color(0.55, 0.58, 0.62, 1)


func _ready() -> void:
	if swordman_button != null:
		swordman_button.pressed.connect(func() -> void: select_class(ClassId.Value.SWORDMAN))
	if mage_button != null:
		mage_button.pressed.connect(func() -> void: select_class(ClassId.Value.MAGE))
	if archer_button != null:
		archer_button.pressed.connect(func() -> void: select_class(ClassId.Value.ARCHER))
	if enter_button != null:
		enter_button.pressed.connect(enter_dungeon)
	if back_button != null:
		back_button.pressed.connect(_on_back)
	_apply_locale()
	_refresh_hero_panel()
	_show_toast(consume_pending_toast())


func _apply_locale() -> void:
	var subtitle := get_node_or_null("VBox/SubtitleLabel") as Label
	if subtitle != null:
		subtitle.text = Loc.t("pick_hero")
	if enter_button != null:
		enter_button.text = Loc.t("enter_dungeon")
	if back_button != null:
		back_button.text = Loc.t("back_menu")


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

func select_class(class_id: int) -> void:
	var session := _game_session()
	if session == null:
		return
	session.active_class = class_id
	session.persist()
	_refresh_hero_panel()


func enter_dungeon() -> void:
	var session := _game_session()
	if session != null:
		session.start_run()
	var tree := get_tree()
	if tree != null:
		tree.change_scene_to_file("res://scenes/dungeon/dungeon.tscn")


func consume_pending_toast(message: String = "") -> String:
	if message != "":
		return message
	var session := _game_session()
	if session == null:
		return ""
	var text := str(session.pending_toast)
	session.pending_toast = ""
	return text


func _show_toast(text: String) -> void:
	if toast_label == null:
		toast_label = get_node_or_null("%ToastLabel") as Label
	if toast_label == null:
		return
	toast_label.text = text
	toast_label.visible = text != ""
	if text == "Победа":
		toast_label.add_theme_color_override("font_color", Color(0.42, 0.86, 0.48, 1))
	elif text == "Поражение":
		toast_label.add_theme_color_override("font_color", Color(0.92, 0.32, 0.32, 1))


func equipped_summary(hero: Hero) -> String:
	return "Оружие: %s  Броня: %s  Аксессуар: %s" % [
		_slot_text(hero, "weapon"),
		_slot_text(hero, "armor"),
		_slot_text(hero, "accessory")
	]


func skills_summary(hero: Hero) -> String:
	if hero == null or not hero.has_method("unlocked_skill_ids"):
		return "Навыки: —"
	var ids: Array = hero.unlocked_skill_ids()
	if ids.is_empty():
		return "Навыки: —"
	var parts: PackedStringArray = PackedStringArray()
	for sid in ids:
		parts.append(str(sid))
	return "Навыки: " + ", ".join(parts)


func _slot_text(hero: Hero, slot: String) -> String:
	if hero == null or not hero.equipped.has(slot):
		return "—"
	var item = hero.equipped[slot]
	if item is GearItem:
		if str(item.name) != "":
			return str(item.name)
		return str(item.id)
	if item is Dictionary:
		var item_name := str(item.get("name", ""))
		if item_name != "":
			return item_name
		return str(item.get("id", "—"))
	return "—"


func _refresh_hero_panel() -> void:
	var session := _game_session()
	if session == null or not session.has_method("active_hero"):
		return
	var hero: Hero = session.active_hero()
	if level_label != null:
		level_label.text = Loc.t("level") % hero.level
	if gear_label != null:
		gear_label.text = equipped_summary(hero)
	if skills_label != null:
		skills_label.text = skills_summary(hero)
	_refresh_class_selection(int(session.active_class))


func _refresh_class_selection(active_class: int) -> void:
	_set_portrait_state(swordman_portrait, swordman_button, active_class == ClassId.Value.SWORDMAN)
	_set_portrait_state(mage_portrait, mage_button, active_class == ClassId.Value.MAGE)
	_set_portrait_state(archer_portrait, archer_button, active_class == ClassId.Value.ARCHER)


func _set_portrait_state(portrait: TextureRect, button: Button, selected: bool) -> void:
	if portrait != null:
		portrait.modulate = SELECTED_MODULATE if selected else IDLE_MODULATE
	if button != null:
		button.disabled = false
		if selected:
			button.add_theme_color_override("font_color", Color(0.95, 0.92, 0.55, 1))
		else:
			button.remove_theme_color_override("font_color")


func _game_session() -> Node:
	var tree := get_tree()
	if tree != null:
		return tree.root.get_node_or_null("GameSession")
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		return (loop as SceneTree).root.get_node_or_null("GameSession")
	return null

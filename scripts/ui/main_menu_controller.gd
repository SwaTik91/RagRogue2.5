extends Control

@onready var play_button: Button = get_node_or_null("%PlayButton") as Button
@onready var heroes_button: Button = get_node_or_null("%HeroesButton") as Button
@onready var settings_button: Button = get_node_or_null("%SettingsButton") as Button
@onready var title_label: Label = get_node_or_null("%TitleLabel") as Label
@onready var tagline: Label = get_node_or_null("%Tagline") as Label
@onready var toast_label: Label = get_node_or_null("%ToastLabel") as Label


func _ready() -> void:
	_style_menu_buttons()
	_apply_locale()
	if play_button != null:
		play_button.pressed.connect(_on_play)
	if heroes_button != null:
		heroes_button.pressed.connect(_on_heroes)
	if settings_button != null:
		settings_button.pressed.connect(_on_settings)
	_show_toast("")
	var settings := _app_settings()
	if settings != null and settings.has_signal("settings_changed"):
		if not settings.settings_changed.is_connected(_apply_locale):
			settings.settings_changed.connect(_apply_locale)


func _apply_locale() -> void:
	if play_button != null:
		play_button.text = Loc.t("play")
	if heroes_button != null:
		heroes_button.text = Loc.t("heroes")
	if settings_button != null:
		settings_button.text = Loc.t("settings")
	if tagline != null:
		tagline.text = Loc.t("tagline")


func _style_menu_buttons() -> void:
	_apply_button_style(play_button, true)
	_apply_button_style(heroes_button, false)
	_apply_button_style(settings_button, false)
	if title_label != null:
		title_label.add_theme_color_override("font_color", Color(0.92, 0.9, 0.84, 1))
		title_label.add_theme_color_override("font_outline_color", Color(0.12, 0.1, 0.08, 1))
		title_label.add_theme_constant_override("outline_size", 8)


func _apply_button_style(button: Button, primary: bool) -> void:
	if button == null:
		return
	var normal := StyleBoxFlat.new()
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 18
	normal.corner_radius_bottom_right = 4
	normal.corner_radius_bottom_left = 18
	normal.content_margin_left = 22
	normal.content_margin_right = 22
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	if primary:
		normal.bg_color = Color(0.78, 0.62, 0.34, 0.92)
		normal.border_color = Color(0.95, 0.82, 0.48, 1)
		button.add_theme_color_override("font_color", Color(0.12, 0.1, 0.08, 1))
		button.add_theme_color_override("font_hover_color", Color(0.08, 0.07, 0.05, 1))
		button.add_theme_color_override("font_pressed_color", Color(0.05, 0.04, 0.03, 1))
	else:
		normal.bg_color = Color(0.14, 0.12, 0.1, 0.78)
		normal.border_color = Color(0.42, 0.34, 0.24, 0.9)
		button.add_theme_color_override("font_color", Color(0.9, 0.86, 0.78, 1))
		button.add_theme_color_override("font_hover_color", Color(0.98, 0.94, 0.86, 1))
		button.add_theme_color_override("font_pressed_color", Color(0.75, 0.7, 0.6, 1))
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = normal.bg_color.lightened(0.08)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = normal.bg_color.darkened(0.1)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)


func _on_play() -> void:
	var session := _game_session()
	if session != null:
		session.start_run()
	get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")


func _on_heroes() -> void:
	get_tree().change_scene_to_file("res://scenes/hub/hub.tscn")


func _on_settings() -> void:
	get_tree().change_scene_to_file("res://scenes/settings/settings.tscn")


func _show_toast(text: String) -> void:
	if toast_label == null:
		return
	toast_label.text = text
	toast_label.visible = text != ""


func _game_session() -> Node:
	var tree := get_tree()
	if tree != null:
		return tree.root.get_node_or_null("GameSession")
	return null


func _app_settings() -> Node:
	var tree := get_tree()
	if tree != null:
		return tree.root.get_node_or_null("AppSettings")
	return null

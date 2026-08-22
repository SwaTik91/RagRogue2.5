extends Control

@onready var play_button: Button = get_node_or_null("%PlayButton") as Button
@onready var heroes_button: Button = get_node_or_null("%HeroesButton") as Button
@onready var settings_button: Button = get_node_or_null("%SettingsButton") as Button
@onready var toast_label: Label = get_node_or_null("%ToastLabel") as Label


func _ready() -> void:
	if play_button != null:
		play_button.pressed.connect(_on_play)
	if heroes_button != null:
		heroes_button.pressed.connect(_on_heroes)
	if settings_button != null:
		settings_button.pressed.connect(_on_settings)
	_show_toast("")


func _on_play() -> void:
	var session := _game_session()
	if session != null:
		session.start_run()
	get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")


func _on_heroes() -> void:
	get_tree().change_scene_to_file("res://scenes/hub/hub.tscn")


func _on_settings() -> void:
	_show_toast("Настройки — скоро")


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

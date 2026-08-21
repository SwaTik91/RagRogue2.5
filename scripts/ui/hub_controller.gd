extends Control

@onready var level_label: Label = %LevelLabel
@onready var swordman_button: Button = %SwordmanButton
@onready var mage_button: Button = %MageButton
@onready var archer_button: Button = %ArcherButton
@onready var enter_button: Button = %EnterButton
@onready var toast_label: Label = get_node_or_null("%ToastLabel") as Label


func _ready() -> void:
	swordman_button.pressed.connect(func() -> void: select_class(ClassId.Value.SWORDMAN))
	mage_button.pressed.connect(func() -> void: select_class(ClassId.Value.MAGE))
	archer_button.pressed.connect(func() -> void: select_class(ClassId.Value.ARCHER))
	enter_button.pressed.connect(enter_dungeon)
	_refresh_level()
	_show_toast(consume_pending_toast())


func select_class(class_id: int) -> void:
	var session := _game_session()
	if session == null:
		return
	session.active_class = class_id
	session.persist()
	_refresh_level()


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


func _refresh_level() -> void:
	if level_label == null:
		return
	var session := _game_session()
	if session == null or not session.has_method("active_hero"):
		return
	var hero: Hero = session.active_hero()
	level_label.text = "Уровень %d" % hero.level


func _game_session() -> Node:
	var tree := get_tree()
	if tree != null:
		return tree.root.get_node_or_null("GameSession")
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		return (loop as SceneTree).root.get_node_or_null("GameSession")
	return null

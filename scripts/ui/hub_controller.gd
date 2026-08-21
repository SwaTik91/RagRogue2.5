extends Control

@onready var level_label: Label = %LevelLabel
@onready var swordman_button: Button = %SwordmanButton
@onready var mage_button: Button = %MageButton
@onready var archer_button: Button = %ArcherButton
@onready var enter_button: Button = %EnterButton


func _ready() -> void:
	swordman_button.pressed.connect(func() -> void: select_class(ClassId.Value.SWORDMAN))
	mage_button.pressed.connect(func() -> void: select_class(ClassId.Value.MAGE))
	archer_button.pressed.connect(func() -> void: select_class(ClassId.Value.ARCHER))
	enter_button.pressed.connect(enter_dungeon)
	_refresh_level()


func select_class(class_id: int) -> void:
	GameSession.active_class = class_id
	GameSession.persist()
	_refresh_level()


func enter_dungeon() -> void:
	GameSession.start_run()
	var tree := get_tree()
	if tree != null:
		tree.change_scene_to_file("res://scenes/dungeon/dungeon.tscn")


func _refresh_level() -> void:
	if level_label == null:
		return
	var hero: Hero = GameSession.active_hero()
	level_label.text = "Уровень %d" % hero.level

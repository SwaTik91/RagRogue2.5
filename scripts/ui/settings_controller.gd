extends Control

@onready var title_label: Label = get_node_or_null("%TitleLabel") as Label
@onready var master_slider: HSlider = get_node_or_null("%MasterSlider") as HSlider
@onready var music_slider: HSlider = get_node_or_null("%MusicSlider") as HSlider
@onready var sfx_slider: HSlider = get_node_or_null("%SfxSlider") as HSlider
@onready var language_option: OptionButton = get_node_or_null("%LanguageOption") as OptionButton
@onready var master_label: Label = get_node_or_null("%MasterLabel") as Label
@onready var music_label: Label = get_node_or_null("%MusicLabel") as Label
@onready var sfx_label: Label = get_node_or_null("%SfxLabel") as Label
@onready var language_label: Label = get_node_or_null("%LanguageLabel") as Label
@onready var back_button: Button = get_node_or_null("%BackButton") as Button
@onready var toast_label: Label = get_node_or_null("%ToastLabel") as Label

var _updating_ui: bool = false


func _ready() -> void:
	if master_slider != null:
		master_slider.value_changed.connect(_on_master)
	if music_slider != null:
		music_slider.value_changed.connect(_on_music)
	if sfx_slider != null:
		sfx_slider.value_changed.connect(_on_sfx)
	if language_option != null:
		language_option.item_selected.connect(_on_language)
	if back_button != null:
		back_button.pressed.connect(_on_back)
	_sync_from_settings()
	_apply_labels()


func _sync_from_settings() -> void:
	var s := _settings()
	if s == null:
		return
	_updating_ui = true
	if master_slider != null:
		master_slider.value = s.master_volume * 100.0
	if music_slider != null:
		music_slider.value = s.music_volume * 100.0
	if sfx_slider != null:
		sfx_slider.value = s.sfx_volume * 100.0
	if language_option != null:
		language_option.clear()
		language_option.add_item("Русский", 0)
		language_option.add_item("English", 1)
		language_option.select(0 if s.language == "ru" else 1)
	_updating_ui = false


func _apply_labels() -> void:
	if title_label != null:
		title_label.text = Loc.t("settings_title")
	if master_label != null:
		master_label.text = Loc.t("master_vol")
	if music_label != null:
		music_label.text = Loc.t("music_vol")
	if sfx_label != null:
		sfx_label.text = Loc.t("sfx_vol")
	if language_label != null:
		language_label.text = Loc.t("language")
	if back_button != null:
		back_button.text = Loc.t("back")


func _on_master(value: float) -> void:
	if _updating_ui:
		return
	var s := _settings()
	if s != null:
		s.set_master_volume(value / 100.0)
	_flash_saved()


func _on_music(value: float) -> void:
	if _updating_ui:
		return
	var s := _settings()
	if s != null:
		s.set_music_volume(value / 100.0)
	_flash_saved()


func _on_sfx(value: float) -> void:
	if _updating_ui:
		return
	var s := _settings()
	if s != null:
		s.set_sfx_volume(value / 100.0)
	_flash_saved()


func _on_language(index: int) -> void:
	if _updating_ui:
		return
	var s := _settings()
	if s != null:
		s.set_language("ru" if index == 0 else "en")
	_apply_labels()
	_flash_saved()


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")


func _flash_saved() -> void:
	if toast_label == null:
		return
	toast_label.text = Loc.t("settings_saved")
	toast_label.visible = true


func _settings() -> Node:
	return get_tree().root.get_node_or_null("AppSettings")

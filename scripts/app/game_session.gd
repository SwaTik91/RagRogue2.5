extends Node

const DEFAULT_SAVE_PATH := "user://ragrogue_save.json"

var ready_for_play: bool = false
var account: Dictionary = {}
var active_class: int = ClassId.Value.SWORDMAN
var run: RunState = RunState.new()
var save_path: String = DEFAULT_SAVE_PATH
var pending_toast: String = ""
var debug_short_act: bool = false

var _heroes: Array = []


func _ready() -> void:
	reload()


func reload() -> void:
	account = SaveGame.load_or_create(save_path)
	_heroes.clear()
	for d in account.get("heroes", []):
		if d is Dictionary:
			_heroes.append(Hero.from_dict(d))
	ready_for_play = _heroes.size() == 3


func active_hero() -> Hero:
	if _heroes.is_empty():
		reload()
	return _heroes[active_class]


func persist() -> void:
	var packed: Array = []
	for hero in _heroes:
		packed.append(hero.to_dict())
	account["version"] = 1
	account["heroes"] = packed
	SaveGame.write(save_path, account)


func start_run() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	run.start_act(rng, debug_short_act)


func apply_defeat() -> void:
	RewardResolver.apply_death(active_hero(), run)
	pending_toast = "Поражение"
	persist()


func apply_victory(rng: RandomNumberGenerator = null) -> void:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	RewardResolver.grant_boss_loot(active_hero(), _load_gear_pool(), rng)
	pending_toast = "Победа"
	persist()


func _load_gear_pool() -> Array:
	var pool: Array = []
	var file := FileAccess.open("res://data/gear.json", FileAccess.READ)
	if file == null:
		return pool
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Array):
		return pool
	for item in parsed:
		if item is Dictionary:
			pool.append(GearItem.from_dict(item))
	return pool

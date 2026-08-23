class_name RunState
extends RefCounted

var floor_index: int = 0
var rooms: Array = []
var room_index: int = 0
var modifiers: Array[String] = []
var alive: bool = true
var short_act: bool = false

var _rng: RandomNumberGenerator
var _known_upgrades: Dictionary = {}


func _init() -> void:
	_known_upgrades = _load_upgrade_ids()


func start_act(rng: RandomNumberGenerator, p_short_act: bool = false) -> void:
	_rng = rng
	short_act = p_short_act
	floor_index = 0
	room_index = 0
	modifiers.clear()
	alive = true
	rooms = FloorGen.make_floor(floor_index, _rng, short_act)


func apply_upgrade(upgrade_id: String) -> void:
	if not _known_upgrades.has(upgrade_id):
		return
	modifiers.append(upgrade_id)


func on_death() -> void:
	alive = false
	modifiers.clear()


func on_room_cleared() -> void:
	if room_index >= 0 and room_index < rooms.size():
		var room: Dictionary = rooms[room_index]
		room["cleared"] = true
		rooms[room_index] = room
	if room_index < rooms.size() - 1:
		room_index += 1
		return
	floor_index += 1
	room_index = 0
	var rng := _rng if _rng != null else RandomNumberGenerator.new()
	rooms = FloorGen.make_floor(floor_index, rng, short_act)


func _load_upgrade_ids() -> Dictionary:
	var ids := {}
	var file := FileAccess.open("res://data/run_upgrades.json", FileAccess.READ)
	if file == null:
		return ids
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Array):
		return ids
	for item in parsed:
		if item is Dictionary and item.has("id"):
			ids[str(item["id"])] = true
	return ids

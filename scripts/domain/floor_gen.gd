class_name FloorGen
extends RefCounted

const ACT_FLOOR_COUNT := 4


static func make_floor(floor_index: int, rng: RandomNumberGenerator) -> Array:
	var rooms: Array = []
	var combat_count := 2 + rng.randi_range(1, 2)
	for _i in combat_count:
		rooms.append(_room(RoomType.Value.COMBAT, _combat_ids(floor_index, rng)))
	if rng.randf() < 0.5:
		rooms.append(_room(RoomType.Value.EVENT, []))
	rooms.append(_room(RoomType.Value.LOOT, []))
	_shuffle(rooms, rng)
	if floor_index == ACT_FLOOR_COUNT - 1:
		rooms.append(_room(RoomType.Value.BOSS, ["act_boss"]))
	return rooms


static func _combat_ids(floor_index: int, rng: RandomNumberGenerator) -> Array:
	var pack: Array = ["cave_slime"]
	if floor_index >= 1 or rng.randf() < 0.5:
		pack.append("stone_beetle")
	if floor_index >= 2 or rng.randf() < 0.4:
		pack.append("cave_slime")
	return pack


static func _room(type: int, monster_ids: Array) -> Dictionary:
	return {
		"type": type,
		"monster_ids": monster_ids,
		"cleared": false
	}


static func _shuffle(rooms: Array, rng: RandomNumberGenerator) -> void:
	for i in range(rooms.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = rooms[i]
		rooms[i] = rooms[j]
		rooms[j] = tmp

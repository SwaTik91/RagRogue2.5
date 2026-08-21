class_name FloorGen
extends RefCounted

const ACT_FLOOR_COUNT := 4


static func make_floor(floor_index: int, rng: RandomNumberGenerator) -> Array:
	var rooms: Array = []
	var combat_count := 2 + rng.randi_range(1, 2)
	for _i in combat_count:
		rooms.append(_room(RoomType.Value.COMBAT, ["mob_a"]))
	if rng.randf() < 0.5:
		rooms.append(_room(RoomType.Value.EVENT, []))
	rooms.append(_room(RoomType.Value.LOOT, []))
	_shuffle(rooms, rng)
	if floor_index == ACT_FLOOR_COUNT - 1:
		rooms.append(_room(RoomType.Value.BOSS, ["boss_act1"]))
	return rooms


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

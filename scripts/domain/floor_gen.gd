class_name FloorGen
extends RefCounted

const ACT_FLOOR_COUNT := 4
const DROPS_PACK: Array = ["drops", "drops", "drops"]


static func act_floor_count(short_act: bool = false) -> int:
	return 1 if short_act else ACT_FLOOR_COUNT


static func make_floor(floor_index: int, rng: RandomNumberGenerator, short_act: bool = false) -> Array:
	if short_act:
		return [
			_room(RoomType.Value.COMBAT, DROPS_PACK.duplicate()),
			_room(RoomType.Value.BOSS, DROPS_PACK.duplicate()),
		]
	var rooms: Array = []
	var combat_count := 2 + rng.randi_range(1, 2)
	for _i in combat_count:
		rooms.append(_room(RoomType.Value.COMBAT, DROPS_PACK.duplicate()))
	if rng.randf() < 0.5:
		rooms.append(_room(RoomType.Value.EVENT, []))
	rooms.append(_room(RoomType.Value.LOOT, []))
	_shuffle(rooms, rng)
	if floor_index == act_floor_count(short_act) - 1:
		rooms.append(_room(RoomType.Value.BOSS, DROPS_PACK.duplicate()))
	return rooms


static func _combat_ids(_floor_index: int, _rng: RandomNumberGenerator) -> Array:
	return DROPS_PACK.duplicate()


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

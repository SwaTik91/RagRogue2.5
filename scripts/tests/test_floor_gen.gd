extends RefCounted

const CATALOG_IDS := [
	"cave_slime",
	"stone_beetle",
	"lunatic",
	"drops",
	"angel_mvp",
	"act_boss",
]
const DROPS_PACK := ["drops", "drops", "drops"]
const PLACEHOLDERS := ["mob_a", "boss_act1"]


func run() -> Array:
	var errors: Array = []
	_test_floor_has_at_least_three_rooms(errors)
	_test_final_floor_has_boss(errors)
	_test_monster_ids_match_catalog(errors)
	return errors


func _seeded_rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _test_floor_has_at_least_three_rooms(errors: Array) -> void:
	var rooms: Array = FloorGen.make_floor(0, _seeded_rng(1))
	if rooms.size() < 3:
		errors.append("floor should have >= 3 rooms, got %s" % rooms.size())
	for room in rooms:
		if not (room is Dictionary):
			errors.append("room should be a dict")
			continue
		if not room.has("type") or not room.has("monster_ids") or not room.has("cleared"):
			errors.append("room dict should have type, monster_ids, cleared")
			break


func _test_final_floor_has_boss(errors: Array) -> void:
	var rooms: Array = FloorGen.make_floor(3, _seeded_rng(7))
	var boss_count := 0
	for room in rooms:
		if room.get("type") == RoomType.Value.BOSS:
			boss_count += 1
	if boss_count != 1:
		errors.append("final floor should have exactly one BOSS, got %s" % boss_count)
	if rooms.is_empty() or rooms[rooms.size() - 1].get("type") != RoomType.Value.BOSS:
		errors.append("final floor should end with a BOSS room")
	for floor_index in 3:
		var early: Array = FloorGen.make_floor(floor_index, _seeded_rng(11 + floor_index))
		for room in early:
			if room.get("type") == RoomType.Value.BOSS:
				errors.append("non-final floor %s should not have BOSS" % floor_index)
				break


func _test_monster_ids_match_catalog(errors: Array) -> void:
	var seen := {}
	for seed_value in range(1, 16):
		for floor_index in FloorGen.ACT_FLOOR_COUNT:
			var rooms: Array = FloorGen.make_floor(floor_index, _seeded_rng(seed_value * 17 + floor_index))
			for room in rooms:
				var ids: Array = room.get("monster_ids", [])
				for mid in ids:
					var id_str := str(mid)
					seen[id_str] = true
					if id_str in PLACEHOLDERS:
						errors.append("FloorGen should not emit placeholder id %s" % id_str)
						return
					if id_str not in CATALOG_IDS:
						errors.append("FloorGen id %s is not in monsters.json catalog" % id_str)
						return
				if room.get("type") == RoomType.Value.COMBAT:
					if ids != DROPS_PACK:
						errors.append("COMBAT room should spawn 3 drops, got %s" % str(ids))
						return
				if room.get("type") == RoomType.Value.BOSS:
					if ids != DROPS_PACK:
						errors.append("BOSS room should spawn 3 drops, got %s" % str(ids))
						return
	if not seen.has("drops"):
		errors.append("FloorGen should emit drops")

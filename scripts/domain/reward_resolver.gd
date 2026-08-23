class_name RewardResolver
extends RefCounted


static func xp_for_monster(monster_tier: int) -> int:
	return 10 * monster_tier


static func apply_room_clear(hero: Hero, monster_tier: int) -> void:
	hero.add_xp(xp_for_monster(monster_tier))


static func apply_death(hero: Hero, run: RunState) -> void:
	run.on_death()
	# Permanent level/gear stay on the hero object.


static func grant_boss_loot(hero: Hero, gear_pool: Array, rng: RandomNumberGenerator) -> void:
	var candidates: Array = []
	for item in gear_pool:
		var rarity := _item_rarity(item)
		if rarity == Rarity.Value.N or rarity == Rarity.Value.R:
			candidates.append(item)
	if candidates.is_empty():
		return
	var pick = candidates[rng.randi_range(0, candidates.size() - 1)]
	var gear: GearItem = pick if pick is GearItem else GearItem.from_dict(pick)
	hero.equip(gear)


static func _item_rarity(item) -> int:
	if item is GearItem:
		return item.rarity
	if item is Dictionary:
		return int(item.get("rarity", Rarity.Value.N))
	return -1

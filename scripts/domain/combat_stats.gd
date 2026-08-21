class_name CombatStats
extends RefCounted

const MOVE_SPEED := 120.0


static func base_stats(class_id: int) -> Dictionary:
	match class_id:
		ClassId.Value.SWORDMAN:
			return {"atk": 5, "def": 4, "hp_max": 55}
		ClassId.Value.MAGE:
			return {"atk": 4, "def": 2, "hp_max": 40}
		ClassId.Value.ARCHER:
			return {"atk": 5, "def": 2, "hp_max": 45}
		_:
			return {"atk": 1, "def": 1, "hp_max": 1}


static func from_hero(hero: Hero) -> Dictionary:
	var base := base_stats(hero.class_id)
	var atk: int = int(base.atk)
	var def: int = int(base.def)
	var hp: int = int(base.hp_max)
	for slot in hero.equipped:
		var item: GearItem = hero.equipped[slot]
		if item == null:
			continue
		atk += item.atk_bonus
		def += item.def_bonus
		hp += item.hp_bonus
	return {
		"atk": atk,
		"def": def,
		"hp_max": hp,
		"move_speed": MOVE_SPEED
	}

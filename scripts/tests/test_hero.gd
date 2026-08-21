extends RefCounted

func run() -> Array:
	var errors: Array = []
	var h := Hero.new(ClassId.Value.MAGE)
	if h.level != 1:
		errors.append("new hero level should be 1")
	h.add_xp(100)
	if h.level != 2:
		errors.append("100 xp should level 1->2")
	var stats := CombatStats.from_hero(h)
	if int(stats.atk) < 1:
		errors.append("atk should be positive")
	var gear := GearItem.from_dict({
		"id": "staff_n",
		"name": "Apprentice Staff",
		"slot": "weapon",
		"rarity": Rarity.Value.N,
		"atk_bonus": 3,
		"def_bonus": 0,
		"hp_bonus": 0
	})
	h.equip(gear)
	var stats2 := CombatStats.from_hero(h)
	if int(stats2.atk) <= int(stats.atk):
		errors.append("weapon should increase atk")
	return errors

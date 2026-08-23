extends RefCounted

func run() -> Array:
	var errors: Array = []
	_test_xp_for_monster(errors)
	_test_xp_grant_levels_hero(errors)
	_test_death_does_not_reset_level(errors)
	_test_boss_loot_from_n_r_pool(errors)
	return errors


func _staff() -> GearItem:
	return GearItem.from_dict({
		"id": "staff_n",
		"name": "Apprentice Staff",
		"slot": "weapon",
		"rarity": Rarity.Value.N,
		"atk_bonus": 3,
		"def_bonus": 0,
		"hp_bonus": 0
	})


func _test_xp_for_monster(errors: Array) -> void:
	if RewardResolver.xp_for_monster(1) != 10:
		errors.append("xp_for_monster(1) should be 10")
	if RewardResolver.xp_for_monster(3) != 30:
		errors.append("xp_for_monster(3) should be 30")


func _test_xp_grant_levels_hero(errors: Array) -> void:
	var hero := Hero.new(ClassId.Value.MAGE)
	# Level 1 needs 100 XP; tier 10 => 100 XP.
	RewardResolver.apply_room_clear(hero, 10)
	if hero.level != 2:
		errors.append("apply_room_clear tier 10 should level 1->2, got %s" % hero.level)
	if hero.xp != 0:
		errors.append("level-up should consume 100 XP, leftover xp=%s" % hero.xp)


func _test_death_does_not_reset_level(errors: Array) -> void:
	var hero := Hero.new(ClassId.Value.MAGE)
	hero.add_xp(100)
	hero.equip(_staff())
	var run := RunState.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	run.start_act(rng)
	run.apply_upgrade("atk_up")
	if run.modifiers.size() != 1:
		errors.append("precondition: atk_up should be on the run")
	RewardResolver.apply_death(hero, run)
	if hero.level != 2:
		errors.append("death should not reset hero level, got %s" % hero.level)
	if not hero.equipped.has("weapon"):
		errors.append("death should not reset hero gear")
	if run.modifiers.size() != 0:
		errors.append("death should clear run modifiers, got %s" % str(run.modifiers))
	if run.alive:
		errors.append("death should set run.alive false")


func _test_boss_loot_from_n_r_pool(errors: Array) -> void:
	var hero := Hero.new(ClassId.Value.MAGE)
	var pool: Array = [
		GearItem.from_dict({
			"id": "staff_n",
			"name": "Apprentice Staff",
			"slot": "weapon",
			"rarity": Rarity.Value.N,
			"atk_bonus": 3,
			"def_bonus": 0,
			"hp_bonus": 0
		}),
		GearItem.from_dict({
			"id": "robe_r",
			"name": "Warded Robe",
			"slot": "armor",
			"rarity": Rarity.Value.R,
			"atk_bonus": 0,
			"def_bonus": 2,
			"hp_bonus": 5
		}),
		GearItem.from_dict({
			"id": "crown_sr",
			"name": "Crown",
			"slot": "accessory",
			"rarity": Rarity.Value.SR,
			"atk_bonus": 5,
			"def_bonus": 5,
			"hp_bonus": 10
		})
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	RewardResolver.grant_boss_loot(hero, pool, rng)
	if hero.equipped.is_empty():
		errors.append("boss clear should grant one gear item")
		return
	for slot in hero.equipped:
		var item: GearItem = hero.equipped[slot]
		if item.id == "crown_sr":
			errors.append("boss loot should not roll SR yet")
		if item.rarity != Rarity.Value.N and item.rarity != Rarity.Value.R:
			errors.append("boss loot rarity should be N or R, got %s" % item.rarity)

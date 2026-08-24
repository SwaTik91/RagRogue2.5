extends RefCounted


func run() -> Array:
	var errors: Array = []
	var hero := Hero.new(ClassId.Value.MAGE)
	var base: Dictionary = CombatStats.from_hero(hero)
	var boosted: Dictionary = CombatStats.from_hero(hero, ["atk_up"])
	if int(boosted.atk) <= int(base.atk):
		errors.append("atk_up should increase atk, base=%s boosted=%s" % [base.atk, boosted.atk])
	var hp_boosted: Dictionary = CombatStats.from_hero(hero, ["hp_up"])
	if int(hp_boosted.hp_max) <= int(base.hp_max):
		errors.append("hp_up should increase hp_max")
	var cdr_boosted: Dictionary = CombatStats.from_hero(hero, ["cdr"])
	if float(cdr_boosted.get("cdr_bonus", 0.0)) <= 0.0:
		errors.append("cdr should add cdr_bonus")
	var script: GDScript = load("res://scripts/dungeon/player_controller.gd")
	if script != null and script.can_instantiate():
		var player = script.new()
		player.bind_hero(hero)
		var bound_base := int(player.atk)
		player.bind_hero(hero, ["atk_up"])
		if int(player.atk) <= bound_base:
			errors.append("PlayerController.bind_hero should apply atk_up")
		player.free()
	return errors

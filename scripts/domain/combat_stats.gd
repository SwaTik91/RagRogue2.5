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


static func from_hero(hero: Hero, modifiers: Array = []) -> Dictionary:
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
	var stats := {
		"atk": atk,
		"def": def,
		"hp_max": hp,
		"move_speed": MOVE_SPEED,
		"cdr_bonus": 0.0
	}
	return apply_modifiers(stats, modifiers)


static func apply_modifiers(stats: Dictionary, modifiers: Array) -> Dictionary:
	var out := stats.duplicate()
	if not out.has("cdr_bonus"):
		out["cdr_bonus"] = 0.0
	var catalog := _load_upgrade_catalog()
	for raw in modifiers:
		var row = catalog.get(str(raw), {})
		if not (row is Dictionary) or row.is_empty():
			continue
		out.atk = int(out.atk) + int(row.get("atk_bonus", 0))
		out.def = int(out.get("def", 0)) + int(row.get("def_bonus", 0))
		out.hp_max = int(out.hp_max) + int(row.get("hp_bonus", 0))
		out.cdr_bonus = float(out.get("cdr_bonus", 0.0)) + float(row.get("cdr_bonus", 0.0))
	return out


static func _load_upgrade_catalog() -> Dictionary:
	var catalog := {}
	var file := FileAccess.open("res://data/run_upgrades.json", FileAccess.READ)
	if file == null:
		return catalog
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Array):
		return catalog
	for item in parsed:
		if item is Dictionary and item.has("id"):
			catalog[str(item["id"])] = item
	return catalog

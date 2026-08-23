class_name Hero
extends RefCounted

var class_id: int = ClassId.Value.SWORDMAN
var level: int = 1
var xp: int = 0
var hp_max: int = 0
var skill_ids: Array[String] = []
## slot name (`weapon` / `armor` / `accessory`) -> GearItem
var equipped: Dictionary = {}


func _init(p_class_id: int = ClassId.Value.SWORDMAN) -> void:
	class_id = p_class_id
	hp_max = int(_base_stats().hp_max)


func add_xp(amount: int) -> void:
	xp += amount
	while xp >= 100 * level:
		xp -= 100 * level
		level += 1


func unlocked_skill_ids() -> Array[String]:
	var ids: Array[String] = []
	var file := FileAccess.open("res://data/skills.json", FileAccess.READ)
	if file == null:
		return ids
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Array):
		return ids
	for item in parsed:
		if not (item is Dictionary):
			continue
		if int(item.get("class_id", -1)) != class_id:
			continue
		if int(item.get("unlock_level", 1)) > level:
			continue
		var sid := str(item.get("id", ""))
		if sid == "":
			continue
		ids.append(sid)
	return ids


func equip(item: GearItem) -> void:
	equipped[item.slot] = item
	hp_max = int(CombatStats.from_hero(self).hp_max)


func to_dict() -> Dictionary:
	var eq := {}
	for slot in equipped:
		var item = equipped[slot]
		if item is GearItem:
			eq[slot] = item.to_dict()
		elif item is Dictionary:
			eq[slot] = item
	return {
		"class_id": class_id,
		"level": level,
		"xp": xp,
		"hp_max": hp_max,
		"skill_ids": skill_ids.duplicate(),
		"equipped": eq
	}


static func from_dict(d: Dictionary) -> Hero:
	var hero := Hero.new(int(d.get("class_id", ClassId.Value.SWORDMAN)))
	hero.level = int(d.get("level", 1))
	hero.xp = int(d.get("xp", 0))
	hero.skill_ids.clear()
	for sid in d.get("skill_ids", []):
		hero.skill_ids.append(str(sid))
	hero.equipped.clear()
	var eq = d.get("equipped", {})
	if eq is Dictionary:
		for slot in eq:
			var item_data = eq[slot]
			if item_data is Dictionary:
				hero.equip(GearItem.from_dict(item_data))
	if hero.equipped.is_empty():
		hero.hp_max = int(d.get("hp_max", hero.hp_max))
	return hero


func _base_stats() -> Dictionary:
	return CombatStats.base_stats(class_id)

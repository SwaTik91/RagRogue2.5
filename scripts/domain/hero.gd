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


func equip(item: GearItem) -> void:
	equipped[item.slot] = item
	hp_max = int(CombatStats.from_hero(self).hp_max)


func _base_stats() -> Dictionary:
	return CombatStats.base_stats(class_id)

class_name GearItem
extends RefCounted

var id: String = ""
var name: String = ""
var slot: String = ""
var rarity: int = Rarity.Value.N
var atk_bonus: int = 0
var def_bonus: int = 0
var hp_bonus: int = 0


static func from_dict(d: Dictionary) -> GearItem:
	var item := GearItem.new()
	item.id = str(d.get("id", ""))
	item.name = str(d.get("name", ""))
	item.slot = str(d.get("slot", ""))
	item.rarity = int(d.get("rarity", Rarity.Value.N))
	item.atk_bonus = int(d.get("atk_bonus", 0))
	item.def_bonus = int(d.get("def_bonus", 0))
	item.hp_bonus = int(d.get("hp_bonus", 0))
	return item


func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"slot": slot,
		"rarity": rarity,
		"atk_bonus": atk_bonus,
		"def_bonus": def_bonus,
		"hp_bonus": hp_bonus
	}

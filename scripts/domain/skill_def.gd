class_name SkillDef
extends RefCounted

var id: String = ""
var name: String = ""
var class_id: int = 0
var cooldown: float = 0.0
var power: int = 0
var kind: String = "single"
var unlock_level: int = 1


static func from_dict(d: Dictionary) -> SkillDef:
	var skill := SkillDef.new()
	skill.id = str(d.get("id", ""))
	skill.name = str(d.get("name", ""))
	skill.class_id = int(d.get("class_id", 0))
	skill.cooldown = float(d.get("cooldown", 0.0))
	skill.power = int(d.get("power", 0))
	skill.kind = str(d.get("kind", "single"))
	skill.unlock_level = int(d.get("unlock_level", 1))
	return skill


func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"class_id": class_id,
		"cooldown": cooldown,
		"power": power,
		"kind": kind,
		"unlock_level": unlock_level
	}

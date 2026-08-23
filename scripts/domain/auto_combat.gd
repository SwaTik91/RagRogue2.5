class_name AutoCombat
extends RefCounted


static func pick_target(self_pos: Vector2, enemies: Array) -> int:
	var best_idx := -1
	var best_dist := INF
	for i in enemies.size():
		var enemy: Dictionary = enemies[i]
		if float(enemy.get("hp", 0)) <= 0.0:
			continue
		var pos: Vector2 = enemy.get("pos", Vector2.ZERO)
		var dist := self_pos.distance_to(pos)
		if dist < best_dist:
			best_dist = dist
			best_idx = i
	return best_idx


static func pick_skill(skills: Array, cds: Dictionary, self_hp: float, self_hp_max: float, enemy_count_in_aoe: int) -> String:
	if self_hp_max > 0.0 and self_hp / self_hp_max < 0.35:
		var heal_id := _first_kind_off_cd(skills, cds, "heal")
		if heal_id != "":
			return heal_id
	if enemy_count_in_aoe >= 3:
		var aoe_id := _first_kind_off_cd(skills, cds, "aoe")
		if aoe_id != "":
			return aoe_id
	return _highest_power_kind_off_cd(skills, cds, "single")


static func basic_damage(atk: int, target_def: int) -> int:
	return maxi(1, atk - int(target_def / 2))


static func skill_damage(power: int, atk: int, target_def: int) -> int:
	return maxi(1, power + atk - int(target_def / 2))


static func _is_off_cd(skill_id: String, cds: Dictionary) -> bool:
	return float(cds.get(skill_id, 0.0)) <= 0.0


static func _first_kind_off_cd(skills: Array, cds: Dictionary, kind: String) -> String:
	for item in skills:
		var skill: SkillDef = item
		if skill.kind == "passive":
			continue
		if skill.kind != kind:
			continue
		if _is_off_cd(skill.id, cds):
			return skill.id
	return ""


static func _highest_power_kind_off_cd(skills: Array, cds: Dictionary, kind: String) -> String:
	var best_id := ""
	var best_power := -1
	for item in skills:
		var skill: SkillDef = item
		if skill.kind == "passive":
			continue
		if skill.kind != kind:
			continue
		if not _is_off_cd(skill.id, cds):
			continue
		if skill.power > best_power:
			best_power = skill.power
			best_id = skill.id
	return best_id

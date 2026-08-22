extends Node

const AGGRO_RADIUS := 180.0
const MELEE_RANGE := 90.0
const RANGED_RANGE := 160.0
const AOE_RADIUS := 160.0
const BASIC_CD_KEY := "_basic"
const BASIC_CD := 1.0
const ENEMY_ATTACK_RANGE := 90.0
const ENEMY_BASIC_CD := 1.0

var player: Node = null
var enemies: Array = []
var combat_paused: bool = false
var defeated: bool = false
var room_cleared: bool = false


func attack_range_for_class(class_id: int) -> float:
	if class_id == ClassId.Value.SWORDMAN:
		return MELEE_RANGE
	return RANGED_RANGE


func to_combatant(pos: Vector2, hp: float) -> Dictionary:
	return {"pos": pos, "hp": hp}


func tick_cds(cds: Dictionary, delta: float) -> void:
	for key in cds.keys():
		cds[key] = maxf(0.0, float(cds[key]) - delta)


func player_act(player_state: Dictionary, foes: Array, skills: Array, cds: Dictionary) -> Dictionary:
	var empty := {"applied": false, "skill_id": "", "target_index": -1, "damage": 0}
	var idx: int = AutoCombat.pick_target(player_state.pos, foes)
	if idx < 0:
		return empty
	var target: Dictionary = foes[idx]
	var dist: float = player_state.pos.distance_to(target.pos)
	if dist > AGGRO_RADIUS:
		return empty
	var in_aoe := _count_in_range(player_state.pos, foes, AOE_RADIUS)
	var skill_id := AutoCombat.pick_skill(
		skills,
		cds,
		float(player_state.hp),
		float(player_state.hp_max),
		in_aoe
	)
	var skill := _find_skill(skills, skill_id)
	if skill != null and skill.kind == "heal":
		var heal := maxi(1, skill.power)
		player_state.hp = minf(float(player_state.hp_max), float(player_state.hp) + float(heal))
		cds[skill.id] = _skill_cooldown(skill, player_state)
		return {"applied": true, "skill_id": skill.id, "target_index": -1, "damage": -heal}
	var reach := attack_range_for_class(int(player_state.get("class_id", 0)))
	if dist > reach:
		return empty
	if skill != null and skill.kind == "aoe":
		var dealt := 0
		for foe in foes:
			if float(foe.get("hp", 0)) <= 0.0:
				continue
			if player_state.pos.distance_to(foe.pos) > AOE_RADIUS:
				continue
			var aoe_dmg := AutoCombat.skill_damage(skill.power, int(player_state.atk), int(foe.get("def", 0)))
			foe.hp = maxf(0.0, float(foe.hp) - float(aoe_dmg))
			dealt = aoe_dmg
		cds[skill.id] = _skill_cooldown(skill, player_state)
		return {"applied": true, "skill_id": skill.id, "target_index": idx, "damage": dealt}
	if skill != null:
		var skill_dmg := AutoCombat.skill_damage(skill.power, int(player_state.atk), int(target.get("def", 0)))
		target.hp = maxf(0.0, float(target.hp) - float(skill_dmg))
		cds[skill.id] = _skill_cooldown(skill, player_state)
		return {"applied": true, "skill_id": skill.id, "target_index": idx, "damage": skill_dmg}
	if float(cds.get(BASIC_CD_KEY, 0.0)) > 0.0:
		return empty
	var basic_dmg := AutoCombat.basic_damage(int(player_state.atk), int(target.get("def", 0)))
	target.hp = maxf(0.0, float(target.hp) - float(basic_dmg))
	cds[BASIC_CD_KEY] = BASIC_CD
	return {"applied": true, "skill_id": "", "target_index": idx, "damage": basic_dmg}


func enemy_act(enemy: Dictionary, player_state: Dictionary, cds: Dictionary) -> Dictionary:
	var empty := {"applied": false, "damage": 0}
	if float(enemy.get("hp", 0.0)) <= 0.0:
		return empty
	var dist: float = enemy.pos.distance_to(player_state.pos)
	if dist > AGGRO_RADIUS or dist > ENEMY_ATTACK_RANGE:
		return empty
	if float(cds.get(BASIC_CD_KEY, 0.0)) > 0.0:
		return empty
	var dmg := AutoCombat.basic_damage(int(enemy.get("atk", 1)), int(player_state.get("def", 0)))
	player_state.hp = maxf(0.0, float(player_state.hp) - float(dmg))
	cds[BASIC_CD_KEY] = ENEMY_BASIC_CD
	return {"applied": true, "damage": dmg}


func simulate_tick(
	player_state: Dictionary,
	foes: Array,
	skills: Array,
	player_cds: Dictionary,
	enemy_cds: Array,
	delta: float
) -> Dictionary:
	var events: Array = []
	tick_cds(player_cds, delta)
	for i in enemy_cds.size():
		tick_cds(enemy_cds[i], delta)
	var player_attack := player_act(player_state, foes, skills, player_cds)
	if player_attack.applied and int(player_attack.get("damage", 0)) > 0:
		events.append({
			"type": "player_attack",
			"skill_id": str(player_attack.get("skill_id", "")),
			"target_index": int(player_attack.get("target_index", -1)),
			"damage": int(player_attack.get("damage", 0)),
		})
	for i in foes.size():
		var ecds: Dictionary = enemy_cds[i] if i < enemy_cds.size() else {}
		var enemy_attack := enemy_act(foes[i], player_state, ecds)
		if enemy_attack.applied:
			events.append({
				"type": "enemy_attack",
				"enemy_index": i,
				"damage": int(enemy_attack.get("damage", 0)),
			})
	var any_alive := false
	for foe in foes:
		if float(foe.get("hp", 0.0)) > 0.0:
			any_alive = true
			break
	var is_defeated := float(player_state.get("hp", 0.0)) <= 0.0
	return {
		"player_hp": player_state.hp,
		"defeated": is_defeated,
		"room_cleared": (not any_alive) and foes.size() > 0 and not is_defeated,
		"events": events,
	}


func _physics_process(delta: float) -> void:
	if combat_paused or defeated:
		return
	if player == null or not is_instance_valid(player):
		return
	var player_state := _read_player()
	var foes := _read_enemies()
	var enemy_cds := _read_enemy_cds()
	var skills: Array = player.skills if "skills" in player else []
	var player_cds: Dictionary = player.cds if "cds" in player else {}
	var result := simulate_tick(player_state, foes, skills, player_cds, enemy_cds, delta)
	_write_player(player_state)
	_write_enemies(foes)
	_play_combat_events(result.get("events", []))
	if "cds" in player:
		player.cds = player_cds
	_write_enemy_cds(enemy_cds)
	_chase_aggro_enemies()
	if result.defeated:
		defeated = true
		_handle_defeat()
	elif result.room_cleared:
		combat_paused = true
		room_cleared = true
		_handle_room_clear()


func _read_player() -> Dictionary:
	var pos: Vector2 = player.global_position if player.is_inside_tree() else player.position
	var state := {
		"pos": pos,
		"hp": float(player.hp),
		"hp_max": float(player.hp_max),
		"atk": int(player.atk),
		"def": int(player.defense),
		"class_id": int(player.class_id),
		"cdr_bonus": float(player.cdr_bonus) if "cdr_bonus" in player else 0.0
	}
	var session := get_node_or_null("/root/GameSession")
	if session != null and session.has_method("active_hero") and "run" in session:
		var hero = session.active_hero()
		if hero is Hero:
			var stats := CombatStats.from_hero(hero, session.run.modifiers)
			state.atk = int(stats.atk)
			state.def = int(stats.def)
			state.hp_max = float(stats.hp_max)
			state.cdr_bonus = float(stats.get("cdr_bonus", 0.0))
	return state


func _skill_cooldown(skill: SkillDef, player_state: Dictionary) -> float:
	var cdr := clampf(float(player_state.get("cdr_bonus", 0.0)), 0.0, 0.9)
	return maxf(0.05, skill.cooldown * (1.0 - cdr))


func _read_enemies() -> Array:
	var out: Array = []
	for node in enemies:
		if node == null or not is_instance_valid(node):
			continue
		var pos: Vector2 = node.global_position if node.is_inside_tree() else node.position
		out.append({
			"pos": pos,
			"hp": float(node.hp),
			"atk": int(node.atk),
			"def": int(node.defense),
			"node": node
		})
	return out


func _read_enemy_cds() -> Array:
	var out: Array = []
	for node in enemies:
		if node == null or not is_instance_valid(node):
			out.append({})
			continue
		out.append(node.cds if "cds" in node else {})
	return out


func _write_player(player_state: Dictionary) -> void:
	var before := float(player.hp)
	player.hp = float(player_state.hp)
	if player.hp < before:
		_spawn_float(player.position, "-%d" % int(before - player.hp), Color(1, 0.45, 0.4))
		if player.has_method("play_hit_anim"):
			player.play_hit_anim()


func _write_enemies(foes: Array) -> void:
	for foe in foes:
		var node = foe.get("node")
		if node == null or not is_instance_valid(node):
			continue
		var before := float(node.hp)
		node.hp = float(foe.hp)
		if node.hp < before:
			_spawn_float(node.position, "-%d" % int(before - node.hp), Color(1, 0.86, 0.35))
			if node.has_method("play_hit_anim"):
				node.play_hit_anim()
		if node.has_method("refresh_alive"):
			node.refresh_alive()


func _play_combat_events(events: Array) -> void:
	for ev in events:
		if not (ev is Dictionary):
			continue
		var kind := str(ev.get("type", ""))
		if kind == "player_attack":
			if player != null and player.has_method("play_combat_anim"):
				var skill_id := str(ev.get("skill_id", ""))
				player.play_combat_anim(skill_id != "")
		elif kind == "enemy_attack":
			var idx := int(ev.get("enemy_index", -1))
			if idx >= 0 and idx < enemies.size():
				var node = enemies[idx]
				if node != null and node.has_method("play_combat_anim"):
					node.play_combat_anim(false)


func _write_enemy_cds(enemy_cds: Array) -> void:
	for i in enemies.size():
		var node = enemies[i]
		if node == null or not is_instance_valid(node) or i >= enemy_cds.size():
			continue
		node.cds = enemy_cds[i]


func _chase_aggro_enemies() -> void:
	if player == null or not is_instance_valid(player):
		return
	var player_pos: Vector2 = player.global_position if player.is_inside_tree() else player.position
	for node in enemies:
		if node == null or not is_instance_valid(node):
			continue
		if float(node.hp) <= 0.0:
			if node is CharacterBody2D:
				node.velocity = Vector2.ZERO
			continue
		var pos: Vector2 = node.global_position if node.is_inside_tree() else node.position
		var dist := pos.distance_to(player_pos)
		if node is CharacterBody2D and dist <= AGGRO_RADIUS and dist > ENEMY_ATTACK_RANGE:
			var dir := (player_pos - pos).normalized()
			node.velocity = dir * float(node.move_speed)
			node.move_and_slide()
		elif node is CharacterBody2D:
			node.velocity = Vector2.ZERO


func _spawn_float(world_pos: Vector2, text: String, color: Color) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var label := Label.new()
	label.text = text
	label.modulate = color
	label.position = world_pos + Vector2(-12, -28)
	parent.add_child(label)
	var tween := parent.create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -36), 0.55)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.55)
	tween.tween_callback(label.queue_free)


func _handle_defeat() -> void:
	var session := get_node_or_null("/root/GameSession")
	if session != null and session.has_method("apply_defeat"):
		session.apply_defeat()
	call_deferred("_change_to_hub")


func _change_to_hub() -> void:
	var tree := get_tree()
	if tree != null:
		tree.change_scene_to_file("res://scenes/hub/hub.tscn")


func _handle_room_clear() -> void:
	var parent := get_parent()
	if parent != null and parent.has_method("on_combat_room_cleared"):
		parent.on_combat_room_cleared()


func _count_in_range(origin: Vector2, foes: Array, radius: float) -> int:
	var count := 0
	for foe in foes:
		if float(foe.get("hp", 0.0)) <= 0.0:
			continue
		if origin.distance_to(foe.pos) <= radius:
			count += 1
	return count


func _find_skill(skills: Array, skill_id: String) -> SkillDef:
	if skill_id == "":
		return null
	for item in skills:
		if item is SkillDef and item.id == skill_id:
			return item
	return null

extends Node

const AGGRO_RADIUS := 360.0
const MELEE_RANGE := 90.0
const RANGED_RANGE := 160.0
const ARCHER_RANGE := 320.0
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
var _archer_impact_queue: Array = []
var _mob_player_impact_queue: Array = []


func _ready() -> void:
	add_to_group(&"combat_director")


func attack_range_for_class(class_id: int) -> float:
	if class_id == ClassId.Value.SWORDMAN:
		return MELEE_RANGE
	if class_id == ClassId.Value.ARCHER:
		return ARCHER_RANGE
	return RANGED_RANGE


func engagement_radius_for_class(class_id: int) -> float:
	return maxf(AGGRO_RADIUS, attack_range_for_class(class_id))


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
	var class_id := int(player_state.get("class_id", 0))
	var dist: float = player_state.pos.distance_to(target.pos)
	if dist > engagement_radius_for_class(class_id):
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
	var reach := attack_range_for_class(class_id)
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
	var reach := float(enemy.get("attack_range", ENEMY_ATTACK_RANGE))
	if dist > AGGRO_RADIUS:
		return empty
	if dist > reach:
		return empty
	var skills: Array = enemy.get("skills", [])
	if not skills.is_empty():
		var skill: Dictionary = _pick_enemy_skill(skills, cds)
		if not skill.is_empty():
			var sid := str(skill.get("id", ""))
			cds[sid] = float(skill.get("cooldown", 2.0))
			if str(skill.get("kind", "")) == "heal_self":
				var heal_amt := int(skill.get("heal", 10))
				var hp_max := float(enemy.get("hp_max", enemy.get("hp", 1.0)))
				enemy.hp = minf(hp_max, float(enemy.get("hp", 0.0)) + float(heal_amt))
				return {
					"applied": true,
					"skill_id": sid,
					"heal": heal_amt,
					"kind": "heal_self",
				}
			if str(skill.get("kind", "")) == "ground_burn":
				var burn_mult := float(skill.get("damage_mult", 0.4))
				var tick_dmg := AutoCombat.basic_damage(
					int(round(float(enemy.get("atk", 1)) * burn_mult)),
					int(player_state.get("def", 0))
				)
				return {
					"applied": true,
					"skill_id": sid,
					"kind": "ground_burn",
					"deferred": true,
					"radius": float(skill.get("radius", 300.0)),
					"patch_count": int(skill.get("patch_count", 10)),
					"patch_radius": float(skill.get("patch_radius", 44.0)),
					"duration": float(skill.get("duration", 5.0)),
					"tick_interval": float(skill.get("tick_interval", 0.45)),
					"tick_damage": tick_dmg,
				}
			if str(skill.get("kind", "")) == "aoe_player":
				var aoe_r := float(skill.get("radius", 120.0))
				var aoe_mult := float(skill.get("damage_mult", 1.3))
				var aoe_dmg := AutoCombat.basic_damage(
					int(round(float(enemy.get("atk", 1)) * aoe_mult)),
					int(player_state.get("def", 0))
				)
				player_state.hp = maxf(0.0, float(player_state.hp) - float(aoe_dmg))
				return {
					"applied": true,
					"skill_id": sid,
					"kind": "aoe_player",
					"damage": aoe_dmg,
					"radius": aoe_r,
				}
			var mult := float(skill.get("damage_mult", 1.0))
			var raw_atk := int(round(float(enemy.get("atk", 1)) * mult))
			var dmg := AutoCombat.basic_damage(raw_atk, int(player_state.get("def", 0)))
			if skill.has("projectile"):
				return {
					"applied": true,
					"skill_id": sid,
					"damage": dmg,
					"projectile": str(skill.get("projectile", "")),
					"speed": float(skill.get("speed", 280.0)),
					"kind": "projectile",
					"deferred": true,
				}
			player_state.hp = maxf(0.0, float(player_state.hp) - float(dmg))
			return {"applied": true, "skill_id": sid, "damage": dmg}
	if dist > ENEMY_ATTACK_RANGE:
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
	if player_attack.applied:
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
				"skill_id": str(enemy_attack.get("skill_id", "")),
				"kind": str(enemy_attack.get("kind", "melee")),
				"heal": int(enemy_attack.get("heal", 0)),
				"projectile": str(enemy_attack.get("projectile", "")),
				"speed": float(enemy_attack.get("speed", 280.0)),
				"deferred": bool(enemy_attack.get("deferred", false)),
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
	var pos := PlaneCoords.from_node(player)
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
		var pos := PlaneCoords.from_node(node)
		out.append({
			"pos": pos,
			"hp": float(node.hp),
			"hp_max": float(node.hp_max),
			"atk": int(node.atk),
			"def": int(node.defense),
			"attack_range": float(node.attack_range) if "attack_range" in node else ENEMY_ATTACK_RANGE,
			"skills": node.skills if "skills" in node else [],
			"monster_id": str(node.monster_id) if "monster_id" in node else "",
			"node": node,
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
		_spawn_float(PlaneCoords.from_node(player), "-%d" % int(before - player.hp), Color(1, 0.45, 0.4))
		if player.has_method("play_hit_anim"):
			player.play_hit_anim()


func _write_enemies(foes: Array) -> void:
	var defer_archer_hit := _is_archer_player()
	for foe in foes:
		var node = foe.get("node")
		if node == null or not is_instance_valid(node):
			continue
		var before := float(node.hp)
		node.hp = float(foe.hp)
		if node.has_method("set_hp_value"):
			node.set_hp_value(float(foe.hp))
		if node.hp < before:
			var dmg := int(before - node.hp)
			if defer_archer_hit:
				_archer_impact_queue.append({
					"node": node,
					"damage": dmg,
					"pos": PlaneCoords.from_node(node),
				})
			else:
				_spawn_float(PlaneCoords.from_node(node), "-%d" % dmg, Color(1, 0.86, 0.35))
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
			var skill_id := str(ev.get("skill_id", ""))
			if player != null and player.has_method("play_combat_anim"):
				player.play_combat_anim(skill_id)
			if _is_archer_player():
				_play_archer_attack_vfx(skill_id, int(ev.get("target_index", -1)))
		elif kind == "enemy_attack":
			var idx := int(ev.get("enemy_index", -1))
			if idx >= 0 and idx < enemies.size():
				var node = enemies[idx]
				if node != null and node.has_method("play_combat_anim"):
					var sid := str(ev.get("skill_id", ""))
					node.play_combat_anim(sid)
				if str(ev.get("kind", "")) == "heal_self":
					var heal_amt := int(ev.get("heal", 0))
					if heal_amt > 0 and node != null and is_instance_valid(node):
						_spawn_float(PlaneCoords.from_node(node), "+%d" % heal_amt, Color(0.45, 1.0, 0.55))
						if node.has_method("get_mob_vfx"):
							var vfx: MobVfx = node.get_mob_vfx()
							if vfx != null:
								vfx.play_heal_flash(PlaneCoords.from_node(node))
				elif str(ev.get("kind", "")) == "ground_burn" and ev.get("deferred", false):
					_queue_ground_burn(ev, idx)
				elif str(ev.get("kind", "")) == "aoe_player":
					var aoe_r := float(ev.get("radius", 120.0))
					if player != null and is_instance_valid(player):
						if node != null and node.has_method("get_mob_vfx"):
							var vfx_a: MobVfx = node.get_mob_vfx()
							if vfx_a != null:
								vfx_a.play_aoe_flash(PlaneCoords.from_node(player), aoe_r)
				elif str(ev.get("kind", "")) == "projectile" and ev.get("deferred", false):
					_queue_mob_projectile(ev, idx)


func _write_enemy_cds(enemy_cds: Array) -> void:
	for i in enemies.size():
		var node = enemies[i]
		if node == null or not is_instance_valid(node) or i >= enemy_cds.size():
			continue
		node.cds = enemy_cds[i]


func _chase_aggro_enemies() -> void:
	if player == null or not is_instance_valid(player):
		return
	var player_pos := PlaneCoords.from_node(player)
	for node in enemies:
		if node == null or not is_instance_valid(node):
			continue
		if float(node.hp) <= 0.0:
			PlaneCoords.set_body_velocity(node, Vector2.ZERO)
			continue
		var pos := PlaneCoords.from_node(node)
		var dist := pos.distance_to(player_pos)
		if dist <= AGGRO_RADIUS and dist > _enemy_hold_distance(node):
			var dir := (player_pos - pos).normalized()
			PlaneCoords.set_body_velocity(node, dir * float(node.move_speed))
			if node is CharacterBody3D:
				(node as CharacterBody3D).move_and_slide()
			elif node is CharacterBody2D:
				(node as CharacterBody2D).move_and_slide()
			if node.has_method("refresh_motion_anim"):
				node.refresh_motion_anim()
		else:
			PlaneCoords.set_body_velocity(node, Vector2.ZERO)


func _spawn_float(plane_pos: Vector2, text: String, color: Color) -> void:
	var hud := get_parent().get_node_or_null("HUD") if get_parent() != null else null
	if hud == null:
		return
	var label := Label.new()
	label.text = text
	label.modulate = color
	label.position = _plane_to_screen(plane_pos) + Vector2(-12, -28)
	hud.add_child(label)
	var tween := hud.create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -36), 0.55)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.55)
	tween.tween_callback(label.queue_free)


func _plane_to_screen(plane: Vector2) -> Vector2:
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		return cam.get_screen_center() + (plane - cam.global_position)
	var cam3d := get_viewport().get_camera_3d()
	if cam3d != null:
		var world := PlaneCoords.to_vector3(plane, 48.0)
		if cam3d.is_position_in_frustum(world):
			return cam3d.unproject_position(world)
	return plane


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


func _is_archer_player() -> bool:
	return player != null and "class_id" in player and int(player.class_id) == ClassId.Value.ARCHER


func _play_archer_attack_vfx(skill_id: String, target_index: int) -> void:
	if player == null or not player.has_method("get_archer_vfx"):
		return
	var vfx: ArcherVfx = player.get_archer_vfx()
	if vfx == null:
		_flush_archer_impacts()
		return
	var impacts: Array = _archer_impact_queue.duplicate()
	_archer_impact_queue.clear()
	if impacts.is_empty():
		return
	var from := PlaneCoords.from_node(player) + Vector2(0, -6)
	if skill_id == ArcherVfx.SKILL_DOUBLE_STRIFE and impacts.size() == 1:
		var impact: Dictionary = impacts[0]
		var node = impact.get("node")
		if node != null and is_instance_valid(node):
			vfx.play_attack(
				skill_id,
				from,
				node,
				func(): _apply_archer_impact(impact),
			)
			return
	for impact in impacts:
		if not impact is Dictionary:
			continue
		var node = impact.get("node")
		if node == null or not is_instance_valid(node):
			_apply_archer_impact(impact)
			continue
		var captured: Dictionary = impact
		vfx.play_attack("", from, node, func(): _apply_archer_impact(captured))


func _apply_archer_impact(impact: Dictionary) -> void:
	if impact.is_empty():
		return
	var node = impact.get("node")
	var dmg := int(impact.get("damage", 0))
	var pos: Vector2 = impact.get("pos", Vector2.ZERO)
	if node != null and is_instance_valid(node):
		pos = PlaneCoords.from_node(node)
	var fire := false
	if player != null and player.has_method("get_archer_vfx"):
		var vfx: ArcherVfx = player.get_archer_vfx()
		if vfx != null:
			fire = vfx.uses_fire_arrows()
	var parent := get_parent()
	if parent != null:
		HitSpark.spawn(parent, pos, fire)
	if dmg > 0:
		_spawn_float(pos, "-%d" % dmg, Color(1, 0.86, 0.35))
	if node != null and is_instance_valid(node) and node.has_method("play_hit_anim"):
		node.play_hit_anim()


func _flush_archer_impacts() -> void:
	while not _archer_impact_queue.is_empty():
		var impact: Dictionary = _archer_impact_queue.pop_front()
		_apply_archer_impact(impact)


func _enemy_hold_distance(node: Node) -> float:
	var reach := ENEMY_ATTACK_RANGE
	if node != null and node.has_method("get_attack_range"):
		reach = float(node.get_attack_range())
	var effective := minf(reach, AGGRO_RADIUS)
	return maxf(MELEE_RANGE * 0.55, effective * 0.62)


func _pick_enemy_skill(skills: Array, cds: Dictionary) -> Dictionary:
	var ready: Array = []
	for skill in skills:
		if not skill is Dictionary:
			continue
		var sid := str(skill.get("id", ""))
		if sid == "":
			continue
		if float(cds.get(sid, 0.0)) > 0.0:
			continue
		ready.append(skill)
	if ready.is_empty():
		return {}
	return ready[randi() % ready.size()]


func _queue_mob_projectile(ev: Dictionary, enemy_index: int) -> void:
	if player == null or not is_instance_valid(player):
		return
	if enemy_index < 0 or enemy_index >= enemies.size():
		return
	var node = enemies[enemy_index]
	if node == null or not is_instance_valid(node):
		return
	if not node.has_method("get_mob_vfx"):
		_apply_mob_player_impact(ev)
		return
	var vfx: MobVfx = node.get_mob_vfx()
	if vfx == null:
		_apply_mob_player_impact(ev)
		return
	var skills: Array = node.skills if "skills" in node else []
	var skill: Dictionary = {}
	var sid := str(ev.get("skill_id", ""))
	for item in skills:
		if item is Dictionary and str(item.get("id", "")) == sid:
			skill = item
			break
	if skill.is_empty():
		skill = {
			"projectile": str(ev.get("projectile", "carrot")),
			"speed": float(ev.get("speed", 280.0)),
		}
	var from := PlaneCoords.from_node(node) + Vector2(0, -10)
	var captured: Dictionary = ev.duplicate()
	vfx.play_skill(sid, skill, from, player as Node2D, func(): _apply_mob_player_impact(captured))


func apply_player_dot(damage: int) -> void:
	if player == null or not is_instance_valid(player) or damage <= 0:
		return
	player.hp = maxf(0.0, float(player.hp) - float(damage))
	_spawn_float(PlaneCoords.from_node(player), "-%d" % damage, Color(1.0, 0.55, 0.25))
	if player.has_method("play_hit_anim"):
		player.play_hit_anim()


func _queue_ground_burn(ev: Dictionary, enemy_index: int) -> void:
	if player == null or not is_instance_valid(player):
		return
	if enemy_index < 0 or enemy_index >= enemies.size():
		return
	var node = enemies[enemy_index]
	if node == null or not is_instance_valid(node) or not node.has_method("get_mob_vfx"):
		return
	var vfx: MobVfx = node.get_mob_vfx()
	if vfx == null:
		return
	var skills: Array = node.skills if "skills" in node else []
	var skill: Dictionary = {}
	var sid := str(ev.get("skill_id", ""))
	for item in skills:
		if item is Dictionary and str(item.get("id", "")) == sid:
			skill = item.duplicate()
			break
	if skill.is_empty():
		skill = ev.duplicate()
	skill["tick_damage"] = int(ev.get("tick_damage", 4))
	vfx.play_ground_burn(sid, skill, player as Node2D)


func _apply_mob_player_impact(ev: Dictionary) -> void:
	if ev.is_empty() or player == null:
		return
	var dmg := int(ev.get("damage", 0))
	if dmg > 0:
		player.hp = maxf(0.0, float(player.hp) - float(dmg))
		_spawn_float(PlaneCoords.from_node(player), "-%d" % dmg, Color(1, 0.45, 0.4))
		if player.has_method("play_hit_anim"):
			player.play_hit_anim()
	var parent := get_parent()
	if parent != null and dmg > 0:
		HitSpark.spawn(parent, PlaneCoords.from_node(player), false)

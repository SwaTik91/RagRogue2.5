extends CharacterBody3D

const EDITOR_FEATURE := "editor"

var move_speed: float = CombatStats.MOVE_SPEED
var hp: float = 1.0
var hp_max: float = 1.0
var atk: int = 1
var defense: int = 1
var cdr_bonus: float = 0.0
var class_id: int = ClassId.Value.SWORDMAN
var skills: Array = []
var cds: Dictionary = {}
var _move_vector: Vector2 = Vector2.ZERO
var _stick: Node = null
var demo_move_override: Vector2 = Vector2.ZERO
var demo_move_active: bool = false

@onready var _visual: Node3D = $HeroVisual3D


func _ready() -> void:
	_bind_active_hero()
	call_deferred("_resolve_stick")


func play_combat_anim(is_skill: bool = false) -> void:
	if _visual != null and _visual.has_method("play_attack_pulse"):
		_visual.play_attack_pulse()


func play_hit_anim() -> void:
	if _visual != null and _visual.has_method("play_hit_flash"):
		_visual.play_hit_flash()


func set_demo_move(v: Vector2) -> void:
	demo_move_active = true
	demo_move_override = v.limit_length(1.0)


func clear_demo_move() -> void:
	demo_move_active = false
	demo_move_override = Vector2.ZERO


func bind_hero(hero: Hero, modifiers: Array = []) -> void:
	if hero == null:
		return
	_apply_combat_stats(CombatStats.from_hero(hero, modifiers))
	hp = hp_max
	class_id = hero.class_id
	skills = _load_class_skills(hero)
	cds.clear()
	_apply_look()


func apply_run_stats(hero: Hero, modifiers: Array = []) -> void:
	if hero == null:
		return
	var prev_max := hp_max
	_apply_combat_stats(CombatStats.from_hero(hero, modifiers))
	var gained := hp_max - prev_max
	if gained > 0.0:
		hp += gained
	hp = minf(hp, hp_max)


func _apply_combat_stats(stats: Dictionary) -> void:
	move_speed = float(stats.move_speed)
	atk = int(stats.atk)
	defense = int(stats.def)
	hp_max = float(stats.hp_max)
	cdr_bonus = float(stats.get("cdr_bonus", 0.0))


func to_combatant() -> Dictionary:
	return {"pos": PlaneCoords.from_node(self), "hp": hp}


func set_move_vector(v: Vector2) -> void:
	_move_vector = v.limit_length(1.0)


func get_move_vector() -> Vector2:
	return _move_vector


func compute_velocity() -> Vector2:
	return _move_vector * move_speed


func combine_move_vector(stick: Vector2, keyboard: Vector2, editor_debug: bool) -> Vector2:
	var v := stick
	if editor_debug and keyboard.length_squared() > 0.0:
		v = keyboard
	return v.limit_length(1.0)


func editor_keyboard_vector() -> Vector2:
	if not OS.has_feature(EDITOR_FEATURE):
		return Vector2.ZERO
	return _wasd_vector()


func _physics_process(_delta: float) -> void:
	if demo_move_active:
		set_move_vector(demo_move_override)
	else:
		var stick_v := _stick_vector()
		var key_v := editor_keyboard_vector()
		set_move_vector(combine_move_vector(stick_v, key_v, OS.has_feature(EDITOR_FEATURE)))
	var plane_v := compute_velocity()
	velocity = Vector3(plane_v.x, 0.0, plane_v.y)
	move_and_slide()
	if _visual != null and _visual.has_method("face_plane_direction"):
		_visual.face_plane_direction(plane_v)


func _stick_vector() -> Vector2:
	if _stick == null:
		_resolve_stick()
	if _stick != null and _stick.has_method("get_vector"):
		return _stick.get_vector()
	return Vector2.ZERO


func _wasd_vector() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		v.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		v.y += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		v.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		v.x += 1.0
	return v.limit_length(1.0)


func _resolve_stick() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var nodes := tree.get_nodes_in_group("virtual_stick")
	if not nodes.is_empty():
		_stick = nodes[0]


func _bind_active_hero() -> void:
	var session := get_node_or_null("/root/GameSession")
	if session == null or not session.has_method("active_hero"):
		return
	var hero = session.active_hero()
	if hero is Hero:
		var modifiers: Array = []
		if "run" in session and session.run != null:
			modifiers = session.run.modifiers
		bind_hero(hero, modifiers)


func capped_skill_ids(unlocked: Array) -> Array:
	var out: Array = []
	var limit := mini(4, unlocked.size())
	for i in limit:
		out.append(unlocked[i])
	return out


func _load_class_skills(hero: Hero) -> Array:
	var loaded: Array = []
	var file := FileAccess.open("res://data/skills.json", FileAccess.READ)
	if file == null:
		return loaded
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Array):
		return loaded
	var allowed: Dictionary = {}
	var unlocked: Array = hero.unlocked_skill_ids() if hero.has_method("unlocked_skill_ids") else hero.skill_ids
	unlocked = capped_skill_ids(unlocked)
	for sid in unlocked:
		allowed[str(sid)] = true
	for item in parsed:
		if not (item is Dictionary):
			continue
		if int(item.get("class_id", -1)) != hero.class_id:
			continue
		var sid := str(item.get("id", ""))
		if not allowed.is_empty() and not allowed.has(sid):
			continue
		loaded.append(SkillDef.from_dict(item))
	return loaded


func _apply_look() -> void:
	if _visual != null and _visual.has_method("apply_class"):
		_visual.apply_class(class_id)

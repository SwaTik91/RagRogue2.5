extends CharacterBody2D

const EDITOR_FEATURE := "editor"

var move_speed: float = CombatStats.MOVE_SPEED
var hp: float = 1.0
var hp_max: float = 1.0
var atk: int = 1
var defense: int = 1
var class_id: int = ClassId.Value.SWORDMAN
var skills: Array = []
var cds: Dictionary = {}
var _move_vector: Vector2 = Vector2.ZERO
var _stick: Node = null


func _ready() -> void:
	_bind_active_hero()
	_make_camera_current()
	call_deferred("_resolve_stick")


func bind_hero(hero: Hero) -> void:
	if hero == null:
		return
	var stats := CombatStats.from_hero(hero)
	move_speed = float(stats.move_speed)
	atk = int(stats.atk)
	defense = int(stats.def)
	hp_max = float(stats.hp_max)
	hp = hp_max
	class_id = hero.class_id
	skills = _load_class_skills(hero)
	cds.clear()


func to_combatant() -> Dictionary:
	var pos := global_position if is_inside_tree() else position
	return {"pos": pos, "hp": hp}


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
	var stick_v := _stick_vector()
	var key_v := editor_keyboard_vector()
	set_move_vector(combine_move_vector(stick_v, key_v, OS.has_feature(EDITOR_FEATURE)))
	velocity = compute_velocity()
	move_and_slide()


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
		bind_hero(hero)


func _load_class_skills(hero: Hero) -> Array:
	var loaded: Array = []
	var file := FileAccess.open("res://data/skills.json", FileAccess.READ)
	if file == null:
		return loaded
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Array):
		return loaded
	var allowed: Dictionary = {}
	for sid in hero.skill_ids:
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


func _make_camera_current() -> void:
	var cam := get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return
	cam.enabled = true
	cam.position_smoothing_enabled = true
	cam.make_current()

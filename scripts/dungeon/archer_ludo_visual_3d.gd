extends Node3D
## Ludo rigged GLB archer with preset animations (idle/walk/attack/skill/hit).

const MODEL_PATH := "res://assets/art/3d/archer/archer_rigged.glb"

const ANIM_PATHS: Dictionary = {
	"idle": "res://assets/art/3d/archer/anims/idle.glb",
	"walk": "res://assets/art/3d/archer/anims/walk.glb",
	"attack": "res://assets/art/3d/archer/anims/attack.glb",
	"skill": "res://assets/art/3d/archer/anims/skill.glb",
	"hit": "res://assets/art/3d/archer/anims/hit.glb",
}

const LOOP_ANIMS: Array[StringName] = [&"idle", &"walk"]

var _model_root: Node3D = null
var _anim: AnimationPlayer = null
var _busy := false
var _pending_motion := Vector2.ZERO


func _ready() -> void:
	_spawn_model()
	_import_animations()
	if _anim != null and not _anim.animation_finished.is_connected(_on_animation_finished):
		_anim.animation_finished.connect(_on_animation_finished)
	_play_loop(&"idle")


func apply_class(_class_id: int) -> void:
	pass


func face_plane_direction(dir: Vector2) -> void:
	if dir.length_squared() < 0.01:
		return
	rotation.y = atan2(dir.x, dir.y)


func update_motion(plane_velocity: Vector2) -> void:
	_pending_motion = plane_velocity
	if _busy or _anim == null:
		return
	var moving := plane_velocity.length_squared() > 16.0
	var target: StringName = &"walk" if moving else &"idle"
	_play_loop(target)


func play_hit_flash() -> void:
	_play_once(&"hit")


func play_attack_pulse() -> void:
	_play_once(&"attack")


func play_skill() -> void:
	_play_once(&"skill")


func _spawn_model() -> void:
	var packed := load(MODEL_PATH) as PackedScene
	if packed == null:
		push_warning("ArcherLudoVisual3D: missing model " + MODEL_PATH)
		return
	_model_root = packed.instantiate() as Node3D
	if _model_root == null:
		return
	add_child(_model_root)
	_fit_model_scale()
	_anim = _find_animation_player(_model_root)
	if _anim == null:
		push_warning("ArcherLudoVisual3D: no AnimationPlayer in rigged model")


func _import_animations() -> void:
	if _anim == null:
		return
	for anim_key in ANIM_PATHS.keys():
		_steal_animation(str(anim_key), str(ANIM_PATHS[anim_key]))


func _steal_animation(target_name: String, glb_path: String) -> void:
	var packed := load(glb_path) as PackedScene
	if packed == null:
		push_warning("ArcherLudoVisual3D: missing anim " + glb_path)
		return
	var temp := packed.instantiate()
	var src := _find_animation_player(temp)
	if src == null:
		temp.free()
		return
	for anim_name in src.get_animation_list():
		var anim := src.get_animation(anim_name)
		if anim == null:
			continue
		var key := StringName(target_name)
		if _anim.has_animation(key):
			_anim.remove_animation(key)
		_anim.add_animation(key, anim.duplicate())
		if key in LOOP_ANIMS:
			_anim.get_animation(key).loop_mode = Animation.LOOP_LINEAR
		else:
			_anim.get_animation(key).loop_mode = Animation.LOOP_NONE
	temp.free()


func _play_loop(name: StringName) -> void:
	if _anim == null or not _anim.has_animation(name):
		return
	if _anim.current_animation == name and _anim.is_playing():
		return
	_anim.play(name)


func _play_once(name: StringName) -> void:
	if _anim == null or not _anim.has_animation(name):
		return
	_busy = true
	_anim.play(name)


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name in LOOP_ANIMS:
		return
	_busy = false
	update_motion(_pending_motion)


func _fit_model_scale() -> void:
	if _model_root == null:
		return
	var aabb := _visual_aabb(_model_root)
	if aabb.size.y < 0.01:
		_model_root.scale = Vector3(42, 42, 42)
		return
	var target_h := 76.0
	var s := target_h / aabb.size.y
	_model_root.scale = Vector3(s, s, s)
	_model_root.position.y = -aabb.position.y * s


func _visual_aabb(node: Node3D) -> AABB:
	var combined := AABB()
	var first := true
	for mesh in _find_mesh_instances(node):
		var mi := mesh as MeshInstance3D
		if mi == null:
			continue
		var local: AABB = mi.transform * mi.get_aabb()
		if first:
			combined = local
			first = false
		else:
			combined = combined.merge(local)
	return combined


func _find_mesh_instances(node: Node) -> Array:
	var out: Array = []
	if node is MeshInstance3D:
		out.append(node)
	for child in node.get_children():
		out.append_array(_find_mesh_instances(child))
	return out


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

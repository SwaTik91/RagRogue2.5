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
const LIB_NAME := &""

var _model_root: Node3D = null
var _skeleton: Skeleton3D = null
var _anim: AnimationPlayer = null
var _busy := false
var _pending_motion := Vector2.ZERO


func _ready() -> void:
	_spawn_model()
	_setup_animation_player()
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
	var moving := plane_velocity.length_squared() > 4.0
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
	_skeleton = _find_skeleton(_model_root)
	_fit_model_scale()


func _setup_animation_player() -> void:
	if _model_root == null:
		return
	_anim = AnimationPlayer.new()
	_anim.name = "AnimationPlayer"
	_model_root.add_child(_anim)
	var lib := AnimationLibrary.new()
	_anim.add_animation_library(LIB_NAME, lib)


func _import_animations() -> void:
	if _anim == null or _skeleton == null:
		return
	var lib := _anim.get_animation_library(LIB_NAME)
	if lib == null:
		return
	for anim_key in ANIM_PATHS.keys():
		var remapped := _load_remapped_animation(str(anim_key), str(ANIM_PATHS[anim_key]))
		if remapped == null:
			continue
		var key := StringName(anim_key)
		if lib.has_animation(String(key)):
			lib.remove_animation(String(key))
		lib.add_animation(String(key), remapped)
		if key in LOOP_ANIMS:
			remapped.loop_mode = Animation.LOOP_LINEAR
		else:
			remapped.loop_mode = Animation.LOOP_NONE


func _load_remapped_animation(target_name: String, glb_path: String) -> Animation:
	var packed := load(glb_path) as PackedScene
	if packed == null:
		push_warning("ArcherLudoVisual3D: missing anim " + glb_path)
		return null
	var temp := packed.instantiate()
	var src_ap := _find_animation_player(temp)
	if src_ap == null:
		temp.free()
		push_warning("ArcherLudoVisual3D: no AnimationPlayer in " + glb_path)
		return null
	var src_anim: Animation = null
	for anim_name in src_ap.get_animation_list():
		src_anim = src_ap.get_animation(anim_name)
		if src_anim != null:
			break
	temp.free()
	if src_anim == null:
		return null
	return _remap_to_skeleton(src_anim.duplicate(), _skeleton)


func _remap_to_skeleton(src: Animation, skel: Skeleton3D) -> Animation:
	var out := Animation.new()
	out.length = src.length
	var skel_path := skel.name
	for t in src.get_track_count():
		var path_str := String(src.track_get_path(t))
		var bone_name := path_str.get_file()
		if skel.find_bone(bone_name) < 0:
			continue
		var track_type := src.track_get_type(t)
		if track_type not in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D]:
			continue
		var new_path := NodePath(skel_path + ":" + bone_name)
		var nt := out.add_track(track_type)
		out.track_set_path(nt, new_path)
		out.track_set_interpolation_type(nt, src.track_get_interpolation_type(t))
		for k in src.track_get_key_count(t):
			var key_time: float = src.track_get_key_time(t, k)
			var key_val: Variant = src.track_get_key_value(t, k)
			if track_type == Animation.TYPE_ROTATION_3D:
				out.rotation_track_insert_key(nt, key_time, key_val as Quaternion)
			elif track_type == Animation.TYPE_POSITION_3D:
				out.position_track_insert_key(nt, key_time, key_val as Vector3)
			else:
				out.scale_track_insert_key(nt, key_time, key_val as Vector3)
	return out


func _play_loop(name: StringName) -> void:
	if _anim == null or not _has_animation(name):
		return
	var anim_name := String(name)
	if _anim.current_animation == anim_name and _anim.is_playing():
		return
	_anim.play(anim_name)


func _play_once(name: StringName) -> void:
	if _anim == null or not _has_animation(name):
		return
	_busy = true
	_anim.play(String(name))


func _has_animation(name: StringName) -> bool:
	var lib := _anim.get_animation_library(LIB_NAME)
	return lib != null and lib.has_animation(String(name))


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


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

extends Node3D
## Orthographic 2.5D follow camera (RO-style diagonal view).
## `tilt_degrees` = elevation of camera above the ground plane.

@export var target_path: NodePath
@export var orbit_distance := 360.0
@export var tilt_degrees := 58.0
@export var ortho_size := 260.0
@export var look_at_height := 40.0
@export var smoothing := 16.0
@export var reference_viewport_height := 720.0

var _target: Node3D = null
var _camera: Camera3D = null


func _ready() -> void:
	_camera = get_node_or_null("Camera3D") as Camera3D
	if _camera != null:
		_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		_camera.rotation = Vector3.ZERO
		_camera.make_current()
	if target_path != NodePath():
		_target = get_node_or_null(target_path) as Node3D
	call_deferred("_bootstrap_camera")


func set_target(node: Node3D) -> void:
	_target = node
	_apply_camera(1.0)


func _bootstrap_camera() -> void:
	if _camera != null:
		_camera.make_current()
	_apply_camera(1.0)


func _physics_process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var weight := 1.0
	if smoothing > 0.0 and delta > 0.0:
		weight = clampf(delta * smoothing, 0.0, 1.0)
	_apply_camera(weight)


func _apply_camera(weight: float) -> void:
	if _target == null or not is_instance_valid(_target) or _camera == null:
		return
	var focus := _target.global_position + Vector3(0.0, look_at_height, 0.0)
	var elev := deg_to_rad(clampf(tilt_degrees, 25.0, 85.0))
	var offset := Vector3(0.0, orbit_distance * sin(elev), orbit_distance * cos(elev))
	var desired_pos := focus + offset
	var cam_pos := desired_pos
	if weight < 1.0:
		cam_pos = _camera.global_position.lerp(desired_pos, weight)
	_camera.global_position = cam_pos
	_face_camera_at(focus, cam_pos)
	_camera.size = _effective_ortho_size()


func _face_camera_at(target: Vector3, from: Vector3) -> void:
	var forward := (target - from).normalized()
	if forward.length_squared() < 0.0001:
		return
	var up := Vector3.UP
	if absf(forward.dot(up)) > 0.95:
		up = Vector3.BACK
	_camera.global_transform = Transform3D(Basis.looking_at(forward, up), from)


func _effective_ortho_size() -> float:
	var vp := get_viewport()
	if vp == null:
		return ortho_size
	var h := maxf(vp.get_visible_rect().size.y, 1.0)
	return ortho_size * (h / maxf(reference_viewport_height, 1.0))

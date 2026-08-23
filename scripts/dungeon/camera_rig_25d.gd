extends Node3D
## Follow camera: orthographic 2.5D (tilted top-down, RO-style field).
## `tilt_degrees` = elevation above the ground plane (higher = more top-down).

@export var target_path: NodePath
@export var orbit_distance := 380.0
@export var tilt_degrees := 58.0
@export var ortho_size := 300.0
@export var look_at_height := 42.0
@export var smoothing := 8.0

var _target: Node3D = null
var _camera: Camera3D = null


func _ready() -> void:
	_camera = get_node_or_null("Camera3D") as Camera3D
	if _camera != null:
		_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		_camera.size = ortho_size
		_camera.make_current()
	if target_path != NodePath():
		_target = get_node_or_null(target_path) as Node3D


func set_target(node: Node3D) -> void:
	_target = node


func _physics_process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var focus := _target.global_position + Vector3(0.0, look_at_height, 0.0)
	var elev := deg_to_rad(clampf(tilt_degrees, 18.0, 72.0))
	var back := orbit_distance * cos(elev)
	var up := orbit_distance * sin(elev)
	var desired := focus + Vector3(0.0, up, back)
	if smoothing > 0.0 and delta > 0.0:
		global_position = global_position.lerp(desired, clampf(delta * smoothing, 0.0, 1.0))
	else:
		global_position = desired
	if _camera != null:
		_camera.look_at(focus, Vector3.UP)

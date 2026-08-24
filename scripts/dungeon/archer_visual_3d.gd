extends Node3D
## Stylized low-poly archer with bow + quiver (3D placeholder).

@onready var _body_mesh: MeshInstance3D = $Body
@onready var _head_mesh: MeshInstance3D = $Head
@onready var _hood_mesh: MeshInstance3D = $Hood
@onready var _bow_mesh: MeshInstance3D = $Bow
@onready var _bow_string: MeshInstance3D = $BowString
@onready var _quiver_mesh: MeshInstance3D = $Quiver

const BODY_COLOR := Color(0.42, 0.52, 0.38)
const LEATHER_COLOR := Color(0.48, 0.34, 0.22)
const HOOD_COLOR := Color(0.28, 0.42, 0.3)
const BOW_COLOR := Color(0.55, 0.42, 0.28)

var _flash_tween: Tween = null


func face_plane_direction(dir: Vector2) -> void:
	if dir.length_squared() < 0.01:
		return
	rotation.y = atan2(dir.x, dir.y)


func play_hit_flash() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = create_tween()
	_paint(_body_mesh, Color(1.2, 0.45, 0.45))
	_flash_tween.tween_callback(func(): _paint(_body_mesh, BODY_COLOR)).set_delay(0.14)


func play_attack_pulse() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	var t := create_tween()
	t.tween_property(_bow_mesh, "rotation_degrees", Vector3(0, 0, -18), 0.07)
	t.parallel().tween_property(_bow_string, "position", Vector3(8, 72, 22), 0.07)
	t.tween_property(_bow_mesh, "rotation_degrees", Vector3(0, 0, 0), 0.1)
	t.parallel().tween_property(_bow_string, "position", Vector3(14, 72, 22), 0.1)


func _ready() -> void:
	_paint(_body_mesh, BODY_COLOR)
	_paint(_head_mesh, Color(0.9, 0.76, 0.62))
	_paint(_hood_mesh, HOOD_COLOR)
	_paint(_bow_mesh, BOW_COLOR)
	_paint(_bow_string, Color(0.92, 0.9, 0.82))
	_paint(_quiver_mesh, LEATHER_COLOR)


func _paint(mesh: MeshInstance3D, color: Color) -> void:
	if mesh == null:
		return
	var mat := mesh.get_surface_override_material(0) as StandardMaterial3D
	if mat == null:
		mat = StandardMaterial3D.new()
		mesh.set_surface_override_material(0, mat)
	mat.albedo_color = color

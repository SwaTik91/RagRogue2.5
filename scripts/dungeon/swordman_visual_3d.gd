extends Node3D
## Stylized low-poly swordman (placeholder until GLB import).

@onready var _body_mesh: MeshInstance3D = $Body
@onready var _head_mesh: MeshInstance3D = $Head
@onready var _sword_mesh: MeshInstance3D = $Sword
@onready var _cape_mesh: MeshInstance3D = $Cape

var _base_body: Color = Color(0.72, 0.78, 0.92)
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
	_flash_tween.tween_callback(func(): _paint(_body_mesh, _base_body)).set_delay(0.14)


func play_attack_pulse() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	var t := create_tween()
	t.tween_property(_sword_mesh, "position", Vector3(42, 95, 12), 0.08)
	t.tween_property(_sword_mesh, "position", Vector3(28, 88, 18), 0.12)


func _paint(mesh: MeshInstance3D, color: Color) -> void:
	if mesh == null:
		return
	var mat := mesh.get_surface_override_material(0) as StandardMaterial3D
	if mat == null:
		mat = StandardMaterial3D.new()
		mesh.set_surface_override_material(0, mat)
	mat.albedo_color = color

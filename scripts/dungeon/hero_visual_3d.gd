extends Node3D
## Stylized low-poly hero mesh (placeholder until GLB/Ludo 3D import).

const CLASS_COLORS: Dictionary = {
	ClassId.Value.SWORDMAN: Color(0.72, 0.78, 0.92),
	ClassId.Value.MAGE: Color(0.55, 0.62, 0.95),
	ClassId.Value.ARCHER: Color(0.62, 0.88, 0.55),
}

@onready var _body_mesh: MeshInstance3D = $Body
@onready var _head_mesh: MeshInstance3D = $Head
@onready var _sword_mesh: MeshInstance3D = $Sword
@onready var _cape_mesh: MeshInstance3D = $Cape

var _base_body: Color = Color.WHITE
var _flash_tween: Tween = null


func _ready() -> void:
	apply_class(ClassId.Value.SWORDMAN)


func apply_class(class_id: int) -> void:
	_base_body = CLASS_COLORS.get(class_id, Color(0.7, 0.75, 0.9))
	_paint(_body_mesh, _base_body)
	_paint(_head_mesh, Color(0.92, 0.78, 0.65))
	_paint(_cape_mesh, _base_body.lightened(0.12))
	_paint(_sword_mesh, Color(0.85, 0.88, 0.95))


func face_plane_direction(dir: Vector2) -> void:
	if dir.length_squared() < 0.01:
		return
	var angle := atan2(dir.x, dir.y)
	rotation.y = angle


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
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		mesh.set_surface_override_material(0, mat)
	mat.albedo_color = color

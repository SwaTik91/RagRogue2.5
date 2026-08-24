extends Node3D
## Low-poly mob mesh keyed by monster_id.

@onready var _core: MeshInstance3D = $Core
@onready var _accent: MeshInstance3D = $Accent

var _base: Color = Color.WHITE
var _flash_tween: Tween = null


func apply_monster(monster_id: String) -> void:
	var palette := _palette_for(monster_id)
	_base = palette.body
	_paint(_core, palette.body)
	_paint(_accent, palette.accent)
	scale = Vector3.ONE * palette.scale


func face_plane_direction(dir: Vector2) -> void:
	if dir.length_squared() < 0.01:
		return
	rotation.y = atan2(dir.x, dir.y)


func play_hit_flash() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = create_tween()
	_paint(_core, Color(1.25, 0.5, 0.45))
	_flash_tween.tween_callback(func(): _paint(_core, _base)).set_delay(0.14)


func _palette_for(monster_id: String) -> Dictionary:
	match monster_id:
		"stone_beetle":
			return {"body": Color(0.55, 0.38, 0.22), "accent": Color(0.35, 0.25, 0.15), "scale": 1.1}
		"vault_warden":
			return {"body": Color(0.45, 0.5, 0.58), "accent": Color(0.72, 0.75, 0.82), "scale": 1.35}
		"act_boss":
			return {"body": Color(0.55, 0.22, 0.62), "accent": Color(0.85, 0.35, 0.75), "scale": 1.75}
		_:
			return {"body": Color(0.38, 0.72, 0.42), "accent": Color(0.55, 0.9, 0.55), "scale": 1.0}


func _paint(mesh: MeshInstance3D, color: Color) -> void:
	if mesh == null:
		return
	var mat := mesh.get_surface_override_material(0) as StandardMaterial3D
	if mat == null:
		mat = StandardMaterial3D.new()
		mesh.set_surface_override_material(0, mat)
	mat.albedo_color = color

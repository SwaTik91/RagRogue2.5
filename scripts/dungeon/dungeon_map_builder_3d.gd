class_name DungeonMapBuilder3D
extends RefCounted
## 2.5D dungeon floor + border walls (3D meshes, same field size as 2D map).

const FIELD_W := 3920.0
const FIELD_H := 2480.0


static func build(parent: Node3D) -> void:
	if parent == null:
		return
	var root := Node3D.new()
	root.name = "RoMap3D"
	parent.add_child(root)
	parent.move_child(root, 0)
	_add_lighting(root)
	_add_floor(root)
	_add_path_cross(root)
	_add_border_walls(parent)
	_add_atmosphere(parent)


static func _add_lighting(root: Node3D) -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-58, 35, 0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	root.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.name = "Fill"
	fill.rotation_degrees = Vector3(-20, -120, 0)
	fill.light_energy = 0.35
	fill.shadow_enabled = false
	root.add_child(fill)


static func _add_floor(root: Node3D) -> void:
	var floor := MeshInstance3D.new()
	floor.name = "Floor"
	var plane := PlaneMesh.new()
	plane.size = Vector2(FIELD_W, FIELD_H)
	floor.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.34, 0.58, 0.32)
	mat.albedo_texture = _grass_texture()
	mat.uv1_scale = Vector3(FIELD_W / 512.0, FIELD_H / 512.0, 1.0)
	floor.set_surface_override_material(0, mat)
	floor.position = Vector3(0, 0, 0)
	root.add_child(floor)


static func _add_path_cross(root: Node3D) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.58, 0.54, 0.48)
	mat.albedo_texture = _stone_texture()
	var horiz := MeshInstance3D.new()
	horiz.name = "PathH"
	var h_plane := PlaneMesh.new()
	h_plane.size = Vector2(FIELD_W, FIELD_H * 0.22)
	horiz.mesh = h_plane
	horiz.set_surface_override_material(0, mat)
	horiz.position = Vector3(0, 0.04, 0)
	root.add_child(horiz)
	var vert := MeshInstance3D.new()
	vert.name = "PathV"
	var v_plane := PlaneMesh.new()
	v_plane.size = Vector2(FIELD_W * 0.18, FIELD_H)
	vert.mesh = v_plane
	vert.set_surface_override_material(0, mat)
	vert.position = Vector3(0, 0.04, 0)
	root.add_child(vert)


static func _add_border_walls(parent: Node3D) -> void:
	var walls := StaticBody3D.new()
	walls.name = "Walls"
	parent.add_child(walls)
	_add_wall_box(walls, Vector3(0, 40, -1280), Vector3(4080, 80, 80))
	_add_wall_box(walls, Vector3(0, 40, 1280), Vector3(4080, 80, 80))
	_add_wall_box(walls, Vector3(-2000, 40, 0), Vector3(80, 80, 2640))
	_add_wall_box(walls, Vector3(2000, 40, 0), Vector3(80, 80, 2640))


static func _add_wall_box(parent: StaticBody3D, center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = center
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_inst.mesh = box_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.38, 0.32)
	mesh_inst.set_surface_override_material(0, mat)
	body.add_child(mesh_inst)
	parent.add_child(body)


static func _grass_texture() -> Texture2D:
	var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	var c1 := Color(0.34, 0.58, 0.32, 1)
	var c2 := Color(0.28, 0.5, 0.26, 1)
	for y in 256:
		for x in 256:
			var t := (float(x) + float(y)) / 512.0
			img.set_pixel(x, y, c1.lerp(c2, t))
	return ImageTexture.create_from_image(img)


static func _stone_texture() -> Texture2D:
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var base := Color(0.58, 0.54, 0.48, 1)
	for y in 128:
		for x in 128:
			var n := sin(x * 0.35) * cos(y * 0.28) * 0.04
			img.set_pixel(x, y, base.lightened(n))
	return ImageTexture.create_from_image(img)


static func _add_atmosphere(parent: Node3D) -> void:
	var atmo: Node = load("res://scripts/dungeon/dungeon_atmosphere.gd").new()
	atmo.name = "Atmosphere"
	parent.add_child(atmo)

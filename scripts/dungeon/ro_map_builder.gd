class_name RoMapBuilder
extends RefCounted
## Procedural Ragnarok-style outdoor field: grass tiles, stone paths, trees and rocks.

const FIELD_W := 3920.0
const FIELD_H := 2480.0
const TILE := 64


static func build(parent: Node2D) -> void:
	if parent == null:
		return
	var root := Node2D.new()
	root.name = "RoMap"
	parent.add_child(root)
	parent.move_child(root, 0)
	_add_floor(root)
	_add_paths(root)
	_add_props(root)
	_add_wall_trim(parent)


static func _add_floor(root: Node2D) -> void:
	var tex := _grass_texture(512)
	var floor := Sprite2D.new()
	floor.texture = tex
	floor.centered = true
	floor.position = Vector2.ZERO
	floor.scale = Vector2(FIELD_W / 512.0, FIELD_H / 512.0)
	floor.z_index = -20
	root.add_child(floor)
	# Soft grass variation patches
	for i in 4:
		var patch := Sprite2D.new()
		patch.texture = tex
		patch.centered = true
		patch.position = Vector2(-900 + i * 520, -400 + (i % 2) * 500)
		patch.scale = Vector2(1.6, 1.2)
		patch.modulate = Color(0.9, 1.0, 0.9, 0.35)
		patch.z_index = -19
		root.add_child(patch)


static func _add_paths(root: Node2D) -> void:
	var path_tex := _stone_texture(256)
	var horiz := Sprite2D.new()
	horiz.texture = path_tex
	horiz.centered = true
	horiz.position = Vector2(0, 0)
	horiz.scale = Vector2(FIELD_W / 256.0, 0.22)
	horiz.z_index = -15
	horiz.modulate = Color(0.9, 0.88, 0.84, 1)
	root.add_child(horiz)
	var vert := Sprite2D.new()
	vert.texture = path_tex
	vert.centered = true
	vert.position = Vector2(0, 0)
	vert.scale = Vector2(0.18, FIELD_H / 256.0)
	vert.z_index = -15
	vert.modulate = Color(0.88, 0.86, 0.82, 1)
	root.add_child(vert)


static func _add_props(root: Node2D) -> void:
	var spots: Array = [
		Vector2(-780, -520), Vector2(620, -380), Vector2(-420, 280), Vector2(840, 460),
		Vector2(-1100, 120), Vector2(300, -620), Vector2(-200, 620), Vector2(1100, -200),
		Vector2(-900, 700), Vector2(950, 80), Vector2(-550, -80), Vector2(450, 320),
	]
	for i in spots.size():
		var pos: Vector2 = spots[i]
		if i % 3 == 0:
			_add_tree(root, pos)
		elif i % 3 == 1:
			_add_rock(root, pos)
		else:
			_add_barrel(root, pos)


static func _add_tree(root: Node2D, pos: Vector2) -> void:
	var trunk := Polygon2D.new()
	trunk.color = Color(0.35, 0.22, 0.14, 1)
	trunk.polygon = [Vector2(-10, 8), Vector2(10, 8), Vector2(8, 28), Vector2(-8, 28)]
	trunk.position = pos
	trunk.z_index = -8
	root.add_child(trunk)
	var foliage := Polygon2D.new()
	foliage.color = Color(0.22, 0.52, 0.28, 1)
	foliage.polygon = [Vector2(0, -34), Vector2(26, -6), Vector2(16, 18), Vector2(-16, 18), Vector2(-26, -6)]
	foliage.position = pos + Vector2(0, -8)
	foliage.z_index = -7
	root.add_child(foliage)
	var highlight := Polygon2D.new()
	highlight.color = Color(0.38, 0.68, 0.38, 0.55)
	highlight.polygon = [Vector2(-8, -20), Vector2(6, -10), Vector2(0, 4), Vector2(-14, 0)]
	highlight.position = pos + Vector2(-6, -14)
	highlight.z_index = -6
	root.add_child(highlight)


static func _add_rock(root: Node2D, pos: Vector2) -> void:
	var rock := Polygon2D.new()
	rock.color = Color(0.48, 0.46, 0.42, 1)
	rock.polygon = [Vector2(-22, 6), Vector2(-8, -16), Vector2(18, -10), Vector2(24, 8), Vector2(6, 16), Vector2(-16, 14)]
	rock.position = pos
	rock.z_index = -8
	root.add_child(rock)


static func _add_barrel(root: Node2D, pos: Vector2) -> void:
	var body := Polygon2D.new()
	body.color = Color(0.52, 0.34, 0.2, 1)
	body.polygon = [Vector2(-14, -12), Vector2(14, -12), Vector2(16, 14), Vector2(-16, 14)]
	body.position = pos
	body.z_index = -8
	root.add_child(body)
	var band := Polygon2D.new()
	band.color = Color(0.28, 0.2, 0.12, 1)
	band.polygon = [Vector2(-16, -2), Vector2(16, -2), Vector2(16, 4), Vector2(-16, 4)]
	band.position = pos
	band.z_index = -7
	root.add_child(band)


static func _add_wall_trim(parent: Node2D) -> void:
	var border := Color(0.42, 0.38, 0.32, 1)
	_add_rect(parent, Vector2(0, -1210), Vector2(4000, 60), border, -5)
	_add_rect(parent, Vector2(0, 1210), Vector2(4000, 60), border, -5)
	_add_rect(parent, Vector2(-1970, 0), Vector2(60, 2520), border, -5)
	_add_rect(parent, Vector2(1970, 0), Vector2(60, 2520), border, -5)


static func _add_rect(parent: Node2D, center: Vector2, size: Vector2, color: Color, z: int) -> void:
	var half := size * 0.5
	var poly := Polygon2D.new()
	poly.color = color
	poly.z_index = z
	poly.polygon = [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)]
	poly.position = center
	parent.add_child(poly)


static func _grass_texture(size: int = TILE) -> Texture2D:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c1 := Color(0.34, 0.58, 0.32, 1)
	var c2 := Color(0.28, 0.5, 0.26, 1)
	for y in size:
		for x in size:
			var t := (float(x) + float(y)) / (size * 2.0)
			var c := c1.lerp(c2, t)
			if (x / 8 + y / 8) % 2 == 0:
				c = c.lightened(0.06)
			img.set_pixel(x, y, c)
	for i in 4:
		var fx := 8 + i * 14
		var fy := 10 + (i * 11) % (size - 12)
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if fx + dx < size and fy + dy < size:
					img.set_pixel(fx + dx, fy + dy, Color(0.75, 0.82, 0.45, 0.8))
	var tex := ImageTexture.create_from_image(img)
	return tex


static func _stone_texture(size: int = TILE) -> Texture2D:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var base := Color(0.58, 0.54, 0.48, 1)
	for y in size:
		for x in size:
			var n := sin(x * 0.35) * cos(y * 0.28) * 0.04
			img.set_pixel(x, y, base.lightened(n))
	for i in 6:
		var px := (i * 17 + 5) % size
		var py := (i * 23 + 9) % size
		img.set_pixel(px, py, base.darkened(0.12))
	var tex := ImageTexture.create_from_image(img)
	return tex

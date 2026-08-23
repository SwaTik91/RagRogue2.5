class_name BossCastVfx
extends Node2D
## Short-lived boss cast flashes (heal / flame / ground).


static func heal_burst(parent: Node, world_pos: Vector2) -> void:
	var node := Node2D.new()
	node.global_position = world_pos + Vector2(0, -8)
	node.z_index = 12
	parent.add_child(node)
	var ring := Polygon2D.new()
	ring.color = Color(0.45, 1.0, 0.65, 0.55)
	ring.polygon = _ring_poly(28.0, 18.0, 16)
	node.add_child(ring)
	var tween := node.create_tween()
	tween.tween_property(ring, "scale", Vector2(1.8, 1.8), 0.35)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.35)
	tween.tween_callback(node.queue_free)


static func flame_burst(parent: Node, world_pos: Vector2) -> void:
	var node := Node2D.new()
	node.global_position = world_pos
	node.z_index = 12
	parent.add_child(node)
	var core := Polygon2D.new()
	core.color = Color(1.0, 0.55, 0.1, 0.75)
	core.polygon = _ring_poly(14.0, 22.0, 12)
	node.add_child(core)
	var tween := node.create_tween()
	tween.tween_property(node, "scale", Vector2(2.2, 2.2), 0.28)
	tween.parallel().tween_property(core, "modulate:a", 0.0, 0.28)
	tween.tween_callback(node.queue_free)


static func ground_cast(parent: Node, world_pos: Vector2, radius: float) -> void:
	var node := Node2D.new()
	node.global_position = world_pos
	node.z_index = 11
	parent.add_child(node)
	var wave := Polygon2D.new()
	wave.color = Color(0.9, 0.35, 0.08, 0.35)
	wave.polygon = _ring_poly(radius * 0.25, radius, 24)
	node.add_child(wave)
	var tween := node.create_tween()
	tween.tween_property(wave, "scale", Vector2(1.6, 1.6), 0.45)
	tween.parallel().tween_property(wave, "modulate:a", 0.0, 0.45)
	tween.tween_callback(node.queue_free)


static func crystal_burst(parent: Node, world_pos: Vector2, radius: float) -> void:
	var node := Node2D.new()
	node.global_position = world_pos
	node.z_index = 12
	parent.add_child(node)
	for i in 6:
		var shard := Polygon2D.new()
		shard.color = Color(0.55, 0.75, 1.0, 0.85)
		var ang := TAU * float(i) / 6.0
		shard.polygon = PackedVector2Array([
			Vector2.ZERO,
			Vector2(cos(ang) * radius * 0.35, sin(ang) * radius * 0.2),
			Vector2(cos(ang + 0.2) * radius * 0.2, sin(ang + 0.2) * radius * 0.12),
		])
		node.add_child(shard)
	var tween := node.create_tween()
	tween.tween_property(node, "scale", Vector2(1.3, 1.3), 0.22)
	tween.parallel().tween_property(node, "modulate:a", 0.0, 0.32)
	tween.tween_callback(node.queue_free)


static func _ring_poly(inner: float, outer: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a0 := TAU * float(i) / float(segments)
		var a1 := TAU * float(i + 1) / float(segments)
		pts.append(Vector2(cos(a0) * inner, sin(a0) * inner * 0.6))
		pts.append(Vector2(cos(a1) * outer, sin(a1) * outer * 0.6))
	return pts

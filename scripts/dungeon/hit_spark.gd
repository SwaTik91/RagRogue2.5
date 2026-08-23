class_name HitSpark
extends Node2D
## Brief impact flash at arrow hit.


static func spawn(parent: Node, world_pos: Vector2, fire: bool = false) -> void:
	if parent == null:
		return
	var spark := HitSpark.new()
	parent.add_child(spark)
	spark.global_position = world_pos
	spark._play(fire)


func _play(fire: bool) -> void:
	z_index = 14
	var ring := Polygon2D.new()
	ring.polygon = _circle_poly(10.0, 10)
	ring.color = Color(1.0, 0.9, 0.45, 0.85) if not fire else Color(1.0, 0.55, 0.15, 0.9)
	add_child(ring)
	scale = Vector2(0.35, 0.35)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.35, 1.35), 0.12)
	tween.tween_property(ring, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(queue_free)


static func _circle_poly(radius: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	return pts

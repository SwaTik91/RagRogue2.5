class_name PlaneCoords
extends RefCounted
## Bridge 2D combat/map coords (x, y) ↔ 3D world (x, z) with Y-up.


static func from_node(node: Node) -> Vector2:
	if node is Node3D:
		var p := (node as Node3D).global_position
		return Vector2(p.x, p.z)
	if node is Node2D:
		return (node as Node2D).global_position
	return Vector2.ZERO


static func from_vector3(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


static func to_vector3(plane: Vector2, y: float = 0.0) -> Vector3:
	return Vector3(plane.x, y, plane.y)


static func set_node_plane(node: Node3D, plane: Vector2, y: float = 0.0) -> void:
	node.global_position = to_vector3(plane, y)


static func is_body3d(node: Node) -> bool:
	return node is CharacterBody3D


static func set_body_velocity(body: Node, plane_velocity: Vector2) -> void:
	if body is CharacterBody3D:
		(body as CharacterBody3D).velocity = Vector3(plane_velocity.x, 0.0, plane_velocity.y)
	elif body is CharacterBody2D:
		(body as CharacterBody2D).velocity = plane_velocity

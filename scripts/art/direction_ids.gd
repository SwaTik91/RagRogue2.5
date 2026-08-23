class_name DirectionIds
extends RefCounted
## Four-way facing for top-down RPG sprites (Godot Y+ = down on screen).

const DOWN := "down"
const UP := "up"
const RIGHT := "right"
const LEFT := "left"

const ALL: Array[String] = [DOWN, UP, RIGHT, LEFT]


static func from_velocity(velocity: Vector2, last_dir: String = DOWN) -> String:
	if velocity.length_squared() < 4.0:
		return last_dir if last_dir in ALL else DOWN
	if absf(velocity.x) > absf(velocity.y):
		return RIGHT if velocity.x > 0.0 else LEFT
	return DOWN if velocity.y > 0.0 else UP


static func anim_key(base: String, dir: String) -> String:
	return "%s_%s" % [base, dir]

extends Node3D
## Swaps 3D class visuals (swordman / archer / mage fallback).

const VISUAL_SCENES: Dictionary = {
	ClassId.Value.SWORDMAN: preload("res://scenes/dungeon/swordman_visual_3d.tscn"),
	ClassId.Value.ARCHER: preload("res://scenes/dungeon/archer_ludo_visual_3d.tscn"),
	ClassId.Value.MAGE: preload("res://scenes/dungeon/swordman_visual_3d.tscn"),
}

var _active: Node3D = null
var _class_id: int = -1


func apply_class(class_id: int) -> void:
	if _class_id == class_id and _active != null:
		return
	_class_id = class_id
	if _active != null:
		_active.queue_free()
		_active = null
	var scene: PackedScene = VISUAL_SCENES.get(class_id, VISUAL_SCENES[ClassId.Value.SWORDMAN])
	if scene == null:
		return
	_active = scene.instantiate() as Node3D
	add_child(_active)


func face_plane_direction(dir: Vector2) -> void:
	if _active != null and _active.has_method("face_plane_direction"):
		_active.face_plane_direction(dir)


func update_motion(plane_velocity: Vector2) -> void:
	if _active != null and _active.has_method("update_motion"):
		_active.update_motion(plane_velocity)


func play_hit_flash() -> void:
	if _active != null and _active.has_method("play_hit_flash"):
		_active.play_hit_flash()


func play_attack_pulse() -> void:
	if _active != null and _active.has_method("play_attack_pulse"):
		_active.play_attack_pulse()


func play_skill() -> void:
	if _active != null and _active.has_method("play_skill"):
		_active.play_skill()

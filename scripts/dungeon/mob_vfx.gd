class_name MobVfx
extends Node2D
## Boss / mob skill visuals: projectiles, scorched ground, cast flashes.

const PROJECTILE_SCENE := preload("res://scenes/dungeon/mob_projectile.tscn")


func play_skill(
	skill_id: String,
	skill: Dictionary,
	from: Vector2,
	target_node: Node2D,
	on_impact: Callable,
) -> void:
	var kind := str(skill.get("kind", ""))
	if kind == "ground_burn":
		play_ground_burn(skill_id, skill, target_node)
		return
	if target_node == null or not is_instance_valid(target_node):
		if on_impact.is_valid():
			on_impact.call()
		return
	var projectile := str(skill.get("projectile", "carrot"))
	var speed := float(skill.get("speed", 280.0))
	var to := PlaneCoords.from_node(target_node) + Vector2(0, -8)
	if skill_id == "flame_earth" or projectile == "flame":
		BossCastVfx.flame_burst(_vfx_root(), from)
	var bolt := PROJECTILE_SCENE.instantiate() as MobProjectile
	var root := _vfx_root()
	if root == null:
		if on_impact.is_valid():
			on_impact.call()
		return
	root.add_child(bolt)
	bolt.launch(from, to, projectile, speed, on_impact)


func play_ground_burn(skill_id: String, skill: Dictionary, target_node: Node2D) -> void:
	if target_node == null or not is_instance_valid(target_node):
		return
	var anchor := PlaneCoords.from_node(target_node)
	var radius := float(skill.get("radius", 300.0))
	var patch_count := int(skill.get("patch_count", 10))
	var patch_radius := float(skill.get("patch_radius", 44.0))
	var duration := float(skill.get("duration", 5.0))
	var tick_interval := float(skill.get("tick_interval", 0.45))
	var tick_damage := int(skill.get("tick_damage", 4))
	BossCastVfx.ground_cast(_vfx_root(), anchor, radius)
	var root := _vfx_root()
	if root == null:
		return
	for _i in patch_count:
		var ang := randf() * TAU
		var dist := randf() * radius
		var pos := anchor + Vector2(cos(ang), sin(ang)) * dist
		var patch := GroundFirePatch.new()
		patch.setup(pos, patch_radius, duration, tick_interval, tick_damage)
		root.add_child(patch)


func play_heal_flash(world_pos: Vector2) -> void:
	BossCastVfx.heal_burst(_vfx_root(), world_pos)


func play_aoe_flash(world_pos: Vector2, radius: float) -> void:
	BossCastVfx.crystal_burst(_vfx_root(), world_pos, radius)


func _vfx_root() -> Node:
	var root := get_tree().current_scene
	if root == null:
		root = get_parent()
	return root

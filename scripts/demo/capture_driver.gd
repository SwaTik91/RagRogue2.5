extends Node

const RUN_SECONDS := 12.0

var _player: CharacterBody2D = null
var _elapsed := 0.0


func _ready() -> void:
	process_physics_priority = -100
	call_deferred("_bind_player")


func _bind_player() -> void:
	var dungeon := get_parent().get_node_or_null("Dungeon")
	if dungeon == null:
		return
	_player = dungeon.get_node_or_null("Player") as CharacterBody2D


func _physics_process(delta: float) -> void:
	_elapsed += delta
	_auto_pick_upgrade()
	if _player == null:
		_bind_player()
		return
	if not _player.has_method("set_demo_move"):
		return
	var target := _nearest_enemy()
	if target == Vector2.ZERO:
		var t := _elapsed
		_player.set_demo_move(Vector2(sin(t * 0.7), cos(t * 0.55)).normalized())
	else:
		var dir := (target - _player.global_position)
		if dir.length_squared() > 4.0:
			_player.set_demo_move(dir.normalized())
		else:
			_player.set_demo_move(Vector2.ZERO)
	if _elapsed >= RUN_SECONDS:
		get_tree().quit()


func _nearest_enemy() -> Vector2:
	var dungeon := get_parent().get_node_or_null("Dungeon")
	if dungeon == null:
		return Vector2.ZERO
	var root := dungeon.get_node_or_null("Enemies") as Node2D
	if root == null:
		return Vector2.ZERO
	var best := Vector2.ZERO
	var best_d := INF
	for child in root.get_children():
		if not (child is Node2D):
			continue
		if "hp" in child and float(child.hp) <= 0.0:
			continue
		if not child.visible:
			continue
		var p: Vector2 = child.global_position
		var d := _player.global_position.distance_squared_to(p)
		if d < best_d:
			best_d = d
			best = p
	return best


func _auto_pick_upgrade() -> void:
	var dungeon := get_parent().get_node_or_null("Dungeon")
	if dungeon == null:
		return
	var hud := dungeon.get_node_or_null("HUD")
	if hud == null:
		return
	for c in hud.get_children():
		if c.has_method("choose") and c.visible:
			c.choose(0)
			return

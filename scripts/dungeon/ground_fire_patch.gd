class_name GroundFirePatch
extends Node2D
## Scorched ground + flame tick hazard (Angeling boss).

const DIRECTOR_GROUP := &"combat_director"

var _radius := 44.0
var _duration := 5.0
var _tick_interval := 0.45
var _tick_damage := 4
var _life := 0.0
var _tick_timer := 0.0
var _scorch: Polygon2D
var _flame: Polygon2D


func setup(
	world_pos: Vector2,
	patch_radius: float,
	duration: float,
	tick_interval: float,
	tick_damage: int,
) -> void:
	global_position = world_pos
	_radius = maxf(16.0, patch_radius)
	_duration = maxf(1.0, duration)
	_tick_interval = maxf(0.2, tick_interval)
	_tick_damage = maxi(1, tick_damage)
	z_index = 0
	_build_visual()


func _build_visual() -> void:
	_scorch = Polygon2D.new()
	_scorch.color = Color(0.18, 0.1, 0.08, 0.72)
	_scorch.polygon = _circle_poly(_radius * 1.15, 14)
	add_child(_scorch)
	_flame = Polygon2D.new()
	_flame.color = Color(1.0, 0.45, 0.12, 0.55)
	_flame.polygon = _circle_poly(_radius * 0.62, 10)
	add_child(_flame)


func _circle_poly(r: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a) * r, sin(a) * r * 0.55))
	return pts


func _process(delta: float) -> void:
	_life += delta
	if _life >= _duration:
		queue_free()
		return
	var pulse := 0.85 + sin(_life * 9.0) * 0.15
	if _flame != null:
		_flame.modulate = Color(1.0, 0.5 + pulse * 0.2, 0.1, 0.35 + pulse * 0.25)
	_tick_timer += delta
	if _tick_timer >= _tick_interval:
		_tick_timer = 0.0
		_try_damage_player()


func _try_damage_player() -> void:
	var director := get_tree().get_first_node_in_group(DIRECTOR_GROUP)
	if director == null or not director.has_method("apply_player_dot"):
		return
	var player: Node2D = null
	if "player" in director:
		player = director.player as Node2D
	if player == null or not is_instance_valid(player):
		return
	var ppos := PlaneCoords.from_node(player)
	if ppos.distance_to(global_position) <= _radius:
		director.apply_player_dot(_tick_damage)

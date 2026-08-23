class_name ArcherVfx
extends Node2D
## Archer combat visuals: flying arrows, orbit ring, fire style.

const SKILL_DOUBLE_STRIFE := "double_strife"
const SKILL_ARROW_RING := "arrow_ring"
const SKILL_SUPER_BOW := "super_bow"

const RING_BASE_COUNT := 2
const RING_BASE_RADIUS := 52.0
const RING_COUNT_PER_LEVEL := 1
const RING_RADIUS_PER_LEVEL := 8.0
const RING_MAX_COUNT := 6
const RING_MAX_RADIUS := 110.0

var _ring_enabled := false
var _super_bow := false
var _hero_level := 1
var _ring_arrows: Array[Node2D] = []
var _ring_angle := 0.0
var _vfx_root: Node = null


func configure(skills: Array, hero_level: int, vfx_root: Node) -> void:
	_vfx_root = vfx_root
	_hero_level = maxi(1, hero_level)
	_ring_enabled = false
	_super_bow = false
	for item in skills:
		if not (item is SkillDef):
			continue
		if item.id == SKILL_ARROW_RING:
			_ring_enabled = true
		if item.id == SKILL_SUPER_BOW:
			_super_bow = true
	_rebuild_ring()


func uses_fire_arrows() -> bool:
	return _super_bow


func play_attack(
	skill_id: String,
	from: Vector2,
	target_node: Node,
	on_impact: Callable,
) -> void:
	if target_node == null or not is_instance_valid(target_node):
		return
	var to := PlaneCoords.from_node(target_node) + Vector2(0, -8)
	var fire := uses_fire_arrows()
	if skill_id == SKILL_DOUBLE_STRIFE:
		_launch_arrow(from, to + Vector2(-6, 4), fire, on_impact, 0.0)
		_launch_arrow(from, to + Vector2(6, -4), fire, Callable(), 0.07)
	else:
		_launch_arrow(from, to, fire, on_impact, 0.0)


func _launch_arrow(
	from: Vector2,
	to: Vector2,
	fire: bool,
	on_impact: Callable,
	delay: float,
) -> void:
	var parent := _projectile_parent()
	if parent == null:
		if on_impact.is_valid():
			on_impact.call()
		return
	if delay <= 0.0:
		_spawn_arrow(parent, from, to, fire, on_impact)
	else:
		var timer := get_tree().create_timer(delay)
		timer.timeout.connect(func():
			if is_instance_valid(parent):
				_spawn_arrow(parent, from, to, fire, on_impact)
		)


func _spawn_arrow(
	parent: Node,
	from: Vector2,
	to: Vector2,
	fire: bool,
	on_impact: Callable,
) -> void:
	var scene := load("res://scenes/dungeon/arrow_projectile.tscn") as PackedScene
	if scene == null:
		if on_impact.is_valid():
			on_impact.call()
		return
	var arrow := scene.instantiate() as ArrowProjectile
	parent.add_child(arrow)
	arrow.launch(from, to, fire, on_impact)


func _projectile_parent() -> Node:
	if _vfx_root != null and is_instance_valid(_vfx_root):
		return _vfx_root
	return get_parent()


func _process(delta: float) -> void:
	if not _ring_enabled:
		return
	_ring_angle += delta * 1.65
	var params := _ring_params()
	var count: int = params.count
	var radius: float = params.radius
	for i in count:
		if i >= _ring_arrows.size():
			continue
		var arrow := _ring_arrows[i]
		if arrow == null:
			continue
		var a := _ring_angle + TAU * float(i) / float(count)
		arrow.position = Vector2(cos(a), sin(a)) * radius
		arrow.rotation = a + PI * 0.5


func _ring_params() -> Dictionary:
	var lvl_bonus := maxi(0, _hero_level - 1)
	var count := mini(
		RING_MAX_COUNT,
		RING_BASE_COUNT + int(lvl_bonus / 2) * RING_COUNT_PER_LEVEL
	)
	var radius := mini(
		RING_MAX_RADIUS,
		RING_BASE_RADIUS + float(lvl_bonus) * RING_RADIUS_PER_LEVEL
	)
	return {"count": count, "radius": radius}


func _rebuild_ring() -> void:
	for node in _ring_arrows:
		if node != null:
			node.queue_free()
	_ring_arrows.clear()
	if not _ring_enabled:
		return
	var count: int = _ring_params().count
	for i in count:
		var orb := _make_ring_arrow()
		add_child(orb)
		_ring_arrows.append(orb)


func _make_ring_arrow() -> Node2D:
	var root := Node2D.new()
	var shaft := Polygon2D.new()
	shaft.polygon = PackedVector2Array([
		Vector2(-10, -1.5), Vector2(8, -1.5), Vector2(8, 1.5), Vector2(-10, 1.5),
	])
	shaft.color = Color(0.82, 0.74, 0.5, 1.0)
	var head := Polygon2D.new()
	head.polygon = PackedVector2Array([
		Vector2(8, -3), Vector2(16, 0), Vector2(8, 3),
	])
	if _super_bow:
		shaft.color = Color(1.0, 0.5, 0.15, 1.0)
		head.color = Color(1.0, 0.75, 0.2, 1.0)
	else:
		head.color = Color(0.5, 0.38, 0.24, 1.0)
	root.add_child(shaft)
	root.add_child(head)
	root.scale = Vector2(0.85, 0.85)
	return root

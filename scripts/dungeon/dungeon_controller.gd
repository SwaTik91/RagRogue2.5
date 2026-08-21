extends Node2D

var _director: Node = null
var _player: Node = null
var _enemies_root: Node2D = null
var _monster_table: Dictionary = {}
var _hp_label: Label = null
var _banner: Label = null


func _ready() -> void:
	_monster_table = _load_monster_table()
	_player = get_node_or_null("Player")
	_director = get_node_or_null("CombatDirector")
	_enemies_root = get_node_or_null("Enemies") as Node2D
	if _enemies_root == null:
		_enemies_root = Node2D.new()
		_enemies_root.name = "Enemies"
		add_child(_enemies_root)
	_hp_label = get_node_or_null("HUD/HpLabel") as Label
	_banner = get_node_or_null("HUD/BannerLabel") as Label
	spawn_current_room()


func _process(_delta: float) -> void:
	_refresh_hp_label()


func spawn_plan(monster_ids: Array) -> Array:
	if _monster_table.is_empty():
		_monster_table = _load_monster_table()
	var plan: Array = []
	for raw_id in monster_ids:
		var mid := str(raw_id)
		if _monster_table.has(mid):
			plan.append(_monster_table[mid].duplicate(true))
	return plan


func current_room_monster_ids(run: RunState) -> Array:
	if run == null or run.room_index < 0 or run.room_index >= run.rooms.size():
		return []
	var room = run.rooms[run.room_index]
	if room is Dictionary:
		return room.get("monster_ids", [])
	return []


func spawn_current_room() -> void:
	var session := get_node_or_null("/root/GameSession")
	if session == null or not ("run" in session):
		return
	_clear_enemies()
	var plan := spawn_plan(current_room_monster_ids(session.run))
	for i in plan.size():
		var enemy := _make_enemy(plan[i], i, plan.size())
		_enemies_root.add_child(enemy)
	_bind_director()
	if _banner != null and not plan.is_empty():
		_banner.text = ""


func on_combat_room_cleared() -> void:
	if _banner != null:
		_banner.text = "Комната зачищена"
	var session := get_node_or_null("/root/GameSession")
	if session == null or not ("run" in session):
		return
	# Task 9 will insert the upgrade pick before advancing.
	session.run.on_room_cleared()
	if session.run.floor_index >= FloorGen.ACT_FLOOR_COUNT:
		return
	var timer := get_tree().create_timer(0.9)
	timer.timeout.connect(spawn_current_room, CONNECT_ONE_SHOT)


func spawn_plan_positions(count: int) -> Array:
	var out: Array = []
	for i in count:
		out.append(_pack_position(i, count))
	return out


func _make_enemy(def: Dictionary, index: int, count: int) -> Node:
	var packed: PackedScene = load("res://scenes/dungeon/enemy.tscn")
	var enemy: Node
	if packed != null:
		enemy = packed.instantiate()
	else:
		enemy = load("res://scripts/dungeon/enemy_actor.gd").new()
	if enemy.has_method("bind_monster"):
		enemy.bind_monster(def)
	enemy.position = _pack_position(index, count)
	return enemy


func _pack_position(index: int, count: int) -> Vector2:
	var col := index % 3
	var row := int(index / 3)
	var centered := float(col) - minf(1.0, float(count - 1) * 0.5)
	return Vector2(230.0 + float(col) * 36.0, centered * 42.0 + float(row) * 46.0)


func _bind_director() -> void:
	if _director == null:
		return
	_director.player = _player
	_director.enemies = _enemies_root.get_children()
	_director.combat_paused = false
	_director.defeated = false
	_director.room_cleared = false


func _clear_enemies() -> void:
	if _enemies_root == null:
		return
	for child in _enemies_root.get_children():
		_enemies_root.remove_child(child)
		child.free()


func _refresh_hp_label() -> void:
	if _hp_label == null or _player == null or not is_instance_valid(_player):
		return
	_hp_label.text = "HP %d/%d" % [maxi(0, int(_player.hp)), int(_player.hp_max)]


func _load_monster_table() -> Dictionary:
	var table := {}
	var file := FileAccess.open("res://data/monsters.json", FileAccess.READ)
	if file == null:
		return table
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Array):
		return table
	for item in parsed:
		if item is Dictionary and item.has("id"):
			table[str(item["id"])] = item
	return table

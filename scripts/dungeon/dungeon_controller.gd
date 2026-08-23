extends Node2D

var _director: Node = null
var _player: Node = null
var _enemies_root: Node2D = null
var _monster_table: Dictionary = {}
var _hp_label: Label = null
var _banner: Label = null
var _upgrade_modal: Node = null


func _ready() -> void:
	RoMapBuilder.build(self)
	_monster_table = _load_monster_table()
	_player = get_node_or_null("Player")
	_director = get_node_or_null("CombatDirector")
	_enemies_root = get_node_or_null("Enemies") as Node2D
	if _enemies_root == null:
		_enemies_root = Node2D.new()
		_enemies_root.name = "Enemies"
		add_child(_enemies_root)
	_hp_label = get_node_or_null("HUD/SafeArea/HpLabel") as Label
	if _hp_label == null:
		_hp_label = get_node_or_null("HUD/HpLabel") as Label
	_banner = get_node_or_null("HUD/SafeArea/BannerLabel") as Label
	if _banner == null:
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


func is_act_finished(run: RunState) -> bool:
	if run == null:
		return true
	var short := false
	if "short_act" in run:
		short = bool(run.short_act)
	return run.floor_index >= FloorGen.act_floor_count(short)


func current_room_type(run: RunState) -> int:
	if run == null or run.room_index < 0 or run.room_index >= run.rooms.size():
		return -1
	var room = run.rooms[run.room_index]
	if room is Dictionary:
		return int(room.get("type", -1))
	return -1


func advance_past_empty_rooms(run: RunState) -> void:
	if run == null:
		return
	var guard := 0
	while not is_act_finished(run) and spawn_plan(current_room_monster_ids(run)).is_empty():
		run.on_room_cleared()
		guard += 1
		if guard > 64:
			break


func spawn_current_room() -> void:
	var session := get_node_or_null("/root/GameSession")
	if session == null or not ("run" in session):
		return
	advance_past_empty_rooms(session.run)
	if is_act_finished(session.run):
		return
	_clear_enemies()
	var plan := spawn_plan(current_room_monster_ids(session.run))
	for i in plan.size():
		var enemy := _make_enemy(plan[i], i, plan.size())
		_enemies_root.add_child(enemy)
	_bind_director()
	if _banner != null and not plan.is_empty():
		_banner.text = ""


func handle_combat_clear(session) -> String:
	if session == null or not ("run" in session):
		return "none"
	award_combat_clear_xp(session)
	if _banner != null:
		_banner.text = "Комната зачищена"
	if current_room_type(session.run) == RoomType.Value.BOSS:
		if session.has_method("apply_victory"):
			session.apply_victory()
		return "victory"
	return "upgrade"


func room_clear_monster_tier(run: RunState) -> int:
	var total := 0
	for def in spawn_plan(current_room_monster_ids(run)):
		if def is Dictionary:
			total += int(def.get("tier", 0))
	return total


func award_combat_clear_xp(session) -> void:
	if session == null or not ("run" in session):
		return
	if not session.has_method("active_hero"):
		return
	var hero = session.active_hero()
	if not (hero is Hero):
		return
	var tier := room_clear_monster_tier(session.run)
	if tier <= 0:
		return
	RewardResolver.apply_room_clear(hero, tier)
	if session.has_method("persist"):
		session.persist()


func apply_upgrade_and_advance(session, upgrade_id: String) -> void:
	if session == null or not ("run" in session):
		return
	session.run.apply_upgrade(str(upgrade_id))
	_refresh_player_run_stats(session)
	session.run.on_room_cleared()
	advance_past_empty_rooms(session.run)
	if is_act_finished(session.run):
		if is_inside_tree():
			call_deferred("_change_to_hub")
		return
	if is_inside_tree():
		spawn_current_room()


func _refresh_player_run_stats(session) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if session == null or not session.has_method("active_hero"):
		return
	var hero = session.active_hero()
	if not (hero is Hero):
		return
	var modifiers: Array = session.run.modifiers if "run" in session else []
	if _player.has_method("apply_run_stats"):
		_player.apply_run_stats(hero, modifiers)
	elif _player.has_method("bind_hero"):
		_player.bind_hero(hero, modifiers)


func on_combat_room_cleared() -> void:
	var session := get_node_or_null("/root/GameSession")
	var outcome := handle_combat_clear(session)
	if outcome == "victory":
		call_deferred("_change_to_hub")
		return
	if outcome == "upgrade":
		_show_upgrade_pick()


func _show_upgrade_pick() -> void:
	if _upgrade_modal != null and is_instance_valid(_upgrade_modal):
		_upgrade_modal.queue_free()
		_upgrade_modal = null
	var packed: PackedScene = load("res://scenes/ui/upgrade_pick.tscn")
	if packed == null:
		var session := get_node_or_null("/root/GameSession")
		apply_upgrade_and_advance(session, "")
		return
	_upgrade_modal = packed.instantiate()
	var hud := get_node_or_null("HUD")
	if hud != null:
		hud.add_child(_upgrade_modal)
	else:
		add_child(_upgrade_modal)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var offered: Array = []
	if _upgrade_modal.has_method("pick_three"):
		offered = _upgrade_modal.pick_three(rng)
	if _upgrade_modal.has_method("present"):
		_upgrade_modal.present(offered)
	if _upgrade_modal.has_signal("upgrade_chosen"):
		_upgrade_modal.upgrade_chosen.connect(_on_upgrade_chosen, CONNECT_ONE_SHOT)


func _on_upgrade_chosen(upgrade_id: String) -> void:
	if _upgrade_modal != null and is_instance_valid(_upgrade_modal):
		_upgrade_modal.queue_free()
	_upgrade_modal = null
	var session := get_node_or_null("/root/GameSession")
	apply_upgrade_and_advance(session, upgrade_id)


func _change_to_hub() -> void:
	var tree := get_tree()
	if tree != null:
		tree.change_scene_to_file("res://scenes/hub/hub.tscn")


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
	if enemy is Node2D:
		(enemy as Node2D).position = _pack_position(index, count)
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
	_hp_label.text = "HP %d/%d  v0.1.28" % [maxi(0, int(_player.hp)), int(_player.hp_max)]


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

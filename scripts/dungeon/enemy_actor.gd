extends CharacterBody2D

var monster_id: String = ""
var display_name: String = ""
var hp: float = 1.0
var hp_max: float = 1.0
var atk: int = 1
var defense: int = 0
var tier: int = 1
var move_speed: float = 80.0
var cds: Dictionary = {}
var _visual := ActorVisual.new()


func bind_monster(def: Dictionary) -> void:
	monster_id = str(def.get("id", ""))
	display_name = str(def.get("name", monster_id))
	hp_max = float(def.get("hp", 1))
	hp = hp_max
	atk = int(def.get("atk", 1))
	defense = int(def.get("def", 0))
	tier = int(def.get("tier", 1))
	cds.clear()
	_apply_look()
	refresh_alive()


func play_combat_anim(is_skill: bool = false) -> void:
	_visual.play_attack(is_skill)


func play_hit_anim() -> void:
	_visual.play_hit()


func _ready() -> void:
	var sprite := get_node_or_null("Sprite") as Sprite2D
	if sprite != null:
		_visual.setup(sprite, self)


func _physics_process(delta: float) -> void:
	_visual.update_motion(velocity, delta)


func to_combatant() -> Dictionary:
	var pos := global_position if is_inside_tree() else position
	return {"pos": pos, "hp": hp}


func refresh_alive() -> void:
	var alive := hp > 0.0
	visible = alive
	var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		shape.disabled = not alive


func _apply_look() -> void:
	var sprite := get_node_or_null("Sprite") as Sprite2D
	var tex := SpriteCatalog.monster_texture(monster_id)
	if sprite != null and tex != null:
		var target := SpriteCatalog.target_height_for_monster(monster_id)
		SpriteCatalog.fit_sprite(sprite, tex, target)
		_visual.capture_base_scale()
		var poly := get_node_or_null("Body") as Polygon2D
		if poly != null:
			poly.visible = false
		scale = Vector2.ONE
		return
	var body := get_node_or_null("Body") as Polygon2D
	if body == null:
		return
	body.visible = true
	match monster_id:
		"stone_beetle":
			body.color = Color(0.55, 0.38, 0.22, 1)
			scale = Vector2(1.05, 1.05)
		"act_boss":
			body.color = Color(0.55, 0.22, 0.62, 1)
			scale = Vector2(1.7, 1.7)
		_:
			body.color = Color(0.38, 0.72, 0.42, 1)
			scale = Vector2.ONE

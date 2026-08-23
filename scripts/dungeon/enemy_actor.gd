extends CharacterBody2D

const HP_BAR_HALF_W := 24.0
const HP_BAR_H := 6.0

var monster_id: String = ""
var display_name: String = ""
var hp: float = 1.0
var hp_max: float = 1.0
var atk: int = 1
var defense: int = 0
var tier: int = 1
var move_speed: float = 80.0
var attack_range: float = 90.0
var is_boss: bool = false
var skills: Array = []
var cds: Dictionary = {}
var _animator := ActorAnimator.new()
var _mob_vfx: MobVfx = null

@onready var _anim_sprite: AnimatedSprite2D = $Sprite
@onready var _hp_fill: Polygon2D = $HpBar/Fill
@onready var _hp_label: Label = $HpLabel


func bind_monster(def: Dictionary) -> void:
	monster_id = str(def.get("id", ""))
	display_name = str(def.get("name", monster_id))
	hp_max = float(def.get("hp", 1))
	hp = hp_max
	atk = int(def.get("atk", 1))
	defense = int(def.get("def", 0))
	tier = int(def.get("tier", 1))
	attack_range = float(def.get("attack_range", 90.0))
	is_boss = bool(def.get("is_boss", false))
	skills = def.get("skills", []) if def.get("skills") is Array else []
	cds.clear()
	if is_boss:
		move_speed = 72.0
	_sync_mob_vfx()
	_apply_look()
	refresh_alive()
	_update_hp_display()


func get_attack_range() -> float:
	return attack_range


func get_mob_vfx() -> MobVfx:
	return _mob_vfx


func play_combat_anim(skill_id: String = "") -> void:
	var is_skill := skill_id != ""
	if skill_id in ["shadow_mend", "scorched_earth", "crystal_volley"]:
		is_skill = true
	elif skill_id == "flame_earth":
		is_skill = false
	_animator.play_attack(is_skill)


func play_hit_anim() -> void:
	_animator.play_hit()


func refresh_motion_anim() -> void:
	_animator.update_motion(velocity, 0.0)


func _ready() -> void:
	if _anim_sprite != null:
		_animator.setup(_anim_sprite, self)
	_sync_mob_vfx()
	if monster_id != "":
		_apply_look()
	_update_hp_display()


func _process(delta: float) -> void:
	_animator.update_motion(velocity, delta)


func to_combatant() -> Dictionary:
	var pos := global_position if is_inside_tree() else position
	return {
		"pos": pos,
		"hp": hp,
		"hp_max": hp_max,
		"atk": atk,
		"def": defense,
		"attack_range": attack_range,
		"skills": skills,
		"monster_id": monster_id,
	}


func refresh_alive() -> void:
	var alive := hp > 0.0
	visible = alive
	var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		shape.disabled = not alive
	if not alive:
		_update_hp_display()


func set_hp_value(value: float) -> void:
	hp = value
	_update_hp_display()


func _update_hp_display() -> void:
	var pct := clampf(hp / hp_max, 0.0, 1.0) if hp_max > 0.0 else 0.0
	if _hp_fill != null:
		var w := HP_BAR_HALF_W * 2.0 * pct
		_hp_fill.polygon = PackedVector2Array([
			Vector2(-HP_BAR_HALF_W, -HP_BAR_H / 2.0),
			Vector2(-HP_BAR_HALF_W + w, -HP_BAR_H / 2.0),
			Vector2(-HP_BAR_HALF_W + w, HP_BAR_H / 2.0),
			Vector2(-HP_BAR_HALF_W, HP_BAR_H / 2.0),
		])
		if is_boss:
			_hp_fill.color = Color(1.0, 0.55, 0.35, 1.0)
		else:
			_hp_fill.color = Color(0.35, 0.88, 0.42, 1.0)
	if _hp_label != null:
		_hp_label.text = "%d/%d" % [maxi(0, int(ceil(hp))), int(hp_max)]
		_hp_label.visible = hp > 0.0 and hp < hp_max


func _sync_mob_vfx() -> void:
	if skills.is_empty():
		if _mob_vfx != null:
			_mob_vfx.queue_free()
			_mob_vfx = null
		return
	if _mob_vfx == null:
		_mob_vfx = MobVfx.new()
		_mob_vfx.name = "MobVfx"
		add_child(_mob_vfx)


func _apply_look() -> void:
	if _anim_sprite == null:
		return
	var frames := SpriteFramesFactory.monster_frames(monster_id)
	if frames != null:
		var target := SpriteCatalog.target_height_for_monster(monster_id)
		_animator.apply_sprite_frames(frames, target)
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
		"angel_mvp", "act_boss":
			body.color = Color(0.62, 0.38, 0.78, 1)
			scale = Vector2(1.85, 1.85)
		"lunatic":
			body.color = Color(0.82, 0.45, 0.28, 1)
		"drops":
			body.color = Color(0.55, 0.32, 0.72, 1)
		_:
			body.color = Color(0.38, 0.72, 0.42, 1)
			scale = Vector2.ONE

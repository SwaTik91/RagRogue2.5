extends CharacterBody3D

var monster_id: String = ""
var display_name: String = ""
var hp: float = 1.0
var hp_max: float = 1.0
var atk: int = 1
var defense: int = 0
var tier: int = 1
var move_speed: float = 80.0
var cds: Dictionary = {}

@onready var _visual: Node3D = $MobVisual3D


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
	if _visual == null:
		return
	var base_scale := _visual.scale
	var tween := create_tween()
	tween.tween_property(_visual, "scale", base_scale * 1.08, 0.06)
	tween.tween_property(_visual, "scale", base_scale, 0.1)


func play_hit_anim() -> void:
	if _visual != null and _visual.has_method("play_hit_flash"):
		_visual.play_hit_flash()


func to_combatant() -> Dictionary:
	return {"pos": PlaneCoords.from_node(self), "hp": hp}


func refresh_alive() -> void:
	var alive := hp > 0.0
	visible = alive
	var shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape != null:
		shape.disabled = not alive


func _ready() -> void:
	if monster_id != "":
		_apply_look()


func _physics_process(_delta: float) -> void:
	if velocity.length_squared() > 1.0 and _visual != null and _visual.has_method("face_plane_direction"):
		_visual.face_plane_direction(Vector2(velocity.x, velocity.z))


func _apply_look() -> void:
	if _visual != null and _visual.has_method("apply_monster"):
		_visual.apply_monster(monster_id)

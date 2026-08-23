class_name SpriteHitFlash
extends RefCounted
## Per-sprite hit flash via canvas instance uniforms (batch-safe shared ShaderMaterial).

const SHADER_PATH := "res://assets/shaders/canvas_hit_flash.gdshader"

static var _shader: Shader = null
static var _shared_material: ShaderMaterial = null


static func ensure_material(sprite: CanvasItem) -> ShaderMaterial:
	if sprite == null:
		return null
	var existing := sprite.material as ShaderMaterial
	if existing != null and existing.shader != null:
		return existing
	if _shared_material == null:
		_shader = load(SHADER_PATH) as Shader
		if _shader == null:
			return null
		_shared_material = ShaderMaterial.new()
		_shared_material.shader = _shader
	sprite.material = _shared_material
	return _shared_material


static func flash(sprite: CanvasItem, host: Node, duration := 0.18) -> void:
	if sprite == null or host == null or not is_instance_valid(host):
		return
	if ensure_material(sprite) == null:
		_modulate_flash(sprite, host, duration)
		return
	sprite.set_instance_shader_parameter("hit_flash", 1.0)
	var tween := host.create_tween()
	tween.tween_method(
		func(v: float): sprite.set_instance_shader_parameter("hit_flash", v),
		1.0,
		0.0,
		duration
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


static func _modulate_flash(sprite: CanvasItem, host: Node, duration: float) -> void:
	var tween := host.create_tween()
	tween.tween_property(sprite, "modulate", Color(1.45, 0.5, 0.5, 1), duration * 0.3)
	tween.tween_property(sprite, "modulate", Color.WHITE, duration * 0.7)

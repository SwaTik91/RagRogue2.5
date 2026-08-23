extends Node
## Dungeon atmosphere: screen postFX + edge fog overlay (no extra art assets).

const POST_SHADER := "res://assets/shaders/dungeon_post_fx.gdshader"
const FOG_SHADER := "res://assets/shaders/dungeon_edge_fog.gdshader"


func _ready() -> void:
	_setup_post_fx()
	_setup_edge_fog()


func _setup_post_fx() -> void:
	var layer := CanvasLayer.new()
	layer.name = "PostFX"
	layer.layer = 8
	add_child(layer)
	var rect := ColorRect.new()
	rect.name = "Grade"
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.anchor_right = 1.0
	rect.anchor_bottom = 1.0
	rect.grow_horizontal = Control.GROW_DIRECTION_BOTH
	rect.grow_vertical = Control.GROW_DIRECTION_BOTH
	var shader := load(POST_SHADER) as Shader
	if shader != null:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		rect.material = mat
	layer.add_child(rect)


func _setup_edge_fog() -> void:
	var layer := CanvasLayer.new()
	layer.name = "EdgeFog"
	layer.layer = -2
	add_child(layer)
	var rect := ColorRect.new()
	rect.name = "Fog"
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.anchor_right = 1.0
	rect.anchor_bottom = 1.0
	rect.grow_horizontal = Control.GROW_DIRECTION_BOTH
	rect.grow_vertical = Control.GROW_DIRECTION_BOTH
	var shader := load(FOG_SHADER) as Shader
	if shader != null:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		rect.material = mat
	layer.add_child(rect)

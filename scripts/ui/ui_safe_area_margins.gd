extends MarginContainer
class_name UISafeAreaMargins

## Applies OS safe-area insets for notches / hole-punch on mobile.


func _ready() -> void:
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()


func _apply_safe_area() -> void:
	if not OS.has_feature("mobile"):
		return

	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	var window_size: Vector2i = DisplayServer.window_get_size()

	add_theme_constant_override("margin_left", safe_area.position.x)
	add_theme_constant_override("margin_top", safe_area.position.y)
	add_theme_constant_override("margin_right", window_size.x - safe_area.end.x)
	add_theme_constant_override("margin_bottom", window_size.y - safe_area.end.y)

extends Node

## Boots Mage into a short dungeon act and auto-walks toward enemies for capture.


func _ready() -> void:
	call_deferred("_boot")


func _boot() -> void:
	var session := get_node_or_null("/root/GameSession")
	if session == null:
		push_error("GameSession missing")
		return
	session.debug_short_act = true
	session.active_class = ClassId.Value.MAGE
	session.persist()
	session.start_run()
	get_tree().change_scene_to_file("res://scenes/demo/capture_dungeon.tscn")

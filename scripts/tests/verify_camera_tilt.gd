extends SceneTree

var _dungeon: Node = null


func _init() -> void:
	_dungeon = (load("res://scenes/dungeon/dungeon.tscn") as PackedScene).instantiate()
	root.add_child(_dungeon)
	call_deferred("_check")


func _check() -> void:
	var cam := _dungeon.get_node("CameraRig25D/Camera3D") as Camera3D
	print("cam rot deg", cam.global_rotation_degrees)
	if absf(cam.global_rotation_degrees.x) < 5.0:
		print("FAIL flat camera")
		quit(1)
	print("PASS")
	quit(0)

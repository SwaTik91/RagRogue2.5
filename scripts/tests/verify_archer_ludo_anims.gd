extends SceneTree

func _init() -> void:
	var scene := load("res://scenes/dungeon/archer_ludo_visual_3d.tscn") as PackedScene
	var vis := scene.instantiate()
	root.add_child(vis)
	call_deferred("_run_test", vis)


func _run_test(vis: Node) -> void:
	var ap := _find_ap(vis)
	if ap == null:
		print("FAIL: no AnimationPlayer")
		quit(1)
		return
	var lib := ap.get_animation_library("")
	var expected := ["idle", "walk", "attack", "skill", "hit"]
	for name in expected:
		if not lib.has_animation(name):
			print("FAIL: missing anim ", name)
			quit(1)
			return
		var anim := lib.get_animation(name)
		print("OK ", name, " tracks=", anim.get_track_count(), " len=", anim.length)
	print("PASS archer anims")
	vis.queue_free()
	quit(0)


func _find_ap(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for c in node.get_children():
		var f := _find_ap(c)
		if f:
			return f
	return null

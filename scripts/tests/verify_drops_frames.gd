extends SceneTree

func _init() -> void:
	var frames := SpriteFramesFactory.monster_frames("drops")
	if frames == null:
		print("FAIL: no frames")
		quit(1)
		return
	var names := frames.get_animation_names()
	print("drops anims: ", names)
	var required := ["idle_down", "idle_up", "idle_left", "idle_right", "walk_down", "attack_down", "skill_down"]
	for key in required:
		if not frames.has_animation(key):
			print("FAIL: missing ", key)
			quit(1)
			return
		var tex := frames.get_frame_texture(key, 0)
		if tex == null:
			print("FAIL: null texture ", key)
			quit(1)
			return
		print("OK ", key, " ", tex.get_size())
	print("PASS drops sprite frames")
	quit()

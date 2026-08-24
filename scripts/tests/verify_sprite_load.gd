extends SceneTree

func _init() -> void:
	var dir := "res://assets/art/anim/mage/idle"
	var abs := ProjectSettings.globalize_path(dir)
	print("globalize_path: ", abs)
	print("dir_exists_absolute: ", DirAccess.dir_exists_absolute(abs))
	print("get_files_at(res): ", DirAccess.get_files_at(dir))
	print("get_files_at(abs): ", DirAccess.get_files_at(abs) if abs != "" else "empty")
	var tex := load("%s/frame_00.webp" % dir) as Texture2D
	print("load tex: ", tex, " size: ", tex.get_size() if tex else "null")
	var frames := SpriteFramesFactory.player_frames(ClassId.Value.MAGE)
	if frames == null:
		print("frames: null")
	else:
		print("anims: ", frames.get_animation_names())
		var t := frames.get_frame_texture("idle", 0)
		print("idle frame0: ", t, " ", t.get_size() if t else "")
	quit()

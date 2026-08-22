extends SceneTree

func _init() -> void:
	var frames := SpriteFramesFactory.player_frames(ClassId.Value.MAGE)
	for anim_name in ["idle", "walk", "attack", "skill"]:
		if not frames.has_animation(anim_name):
			print("MISSING:", anim_name)
			continue
		var count := frames.get_frame_count(anim_name)
		var speed := frames.get_animation_speed(anim_name)
		var loop := frames.get_animation_loop(anim_name)
		print(anim_name, "frames=", count, "fps=", speed, "loop=", loop)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.play("walk")
	print("playing walk, anim=", sprite.animation, " is_playing=", sprite.is_playing())
	# simulate a few frame advances
	for i in 5:
		sprite._process(0.1)
		print(" frame=", sprite.frame)
	quit()

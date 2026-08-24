extends SceneTree

func _init() -> void:
	var sprite := AnimatedSprite2D.new()
	var animator := ActorAnimator.new()
	var frames := SpriteFramesFactory.player_frames(ClassId.Value.SWORDMAN)
	animator.apply_sprite_frames(frames, SpriteCatalog.PLAYER_TARGET_HEIGHT)
	animator.setup(sprite, null)
	if sprite.sprite_frames == null:
		print("FAIL: sprite_frames still null after deferred apply")
		quit(1)
	var tex := sprite.sprite_frames.get_frame_texture("idle", 0)
	if tex == null:
		print("FAIL: idle frame texture null")
		quit(1)
	print("OK: deferred apply_sprite_frames works, tex size=", tex.get_size())
	quit()

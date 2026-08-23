extends SceneTree

func _init() -> void:
	var animator := ActorAnimator.new()
	var sprite := AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.add_frame("idle", load("res://assets/art/game/mage-idle.png"), 0.5)
	animator.setup(sprite, null)
	animator.apply_sprite_frames(frames, 64.0)
	animator.play_attack(false)
	if animator._busy:
		print("FAIL: _busy must stay false when attack animation missing")
		quit(1)
	animator.update_motion(Vector2(200, 0), 0.1)
	if sprite.animation != "idle":
		print("FAIL: should stay idle when attack missing, got ", sprite.animation)
		quit(1)
	# real frames
	var real := SpriteFramesFactory.player_frames(ClassId.Value.MAGE)
	animator.apply_sprite_frames(real, SpriteCatalog.PLAYER_TARGET_HEIGHT)
	animator.play_attack(false)
	var atk := String(sprite.animation)
	if not atk.begins_with("attack"):
		print("FAIL: expected attack_*, got ", sprite.animation)
		quit(1)
	print("OK: attack/walk animator logic")
	quit()

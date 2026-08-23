extends Node2D

## Instantiates the normal dungeon and drives the player toward foes for a short capture.


func _ready() -> void:
	var packed := load("res://scenes/dungeon/dungeon.tscn") as PackedScene
	if packed == null:
		push_error("dungeon.tscn missing")
		return
	var dungeon := packed.instantiate()
	dungeon.name = "Dungeon"
	add_child(dungeon)
	var driver := Node.new()
	driver.set_script(load("res://scripts/demo/capture_driver.gd"))
	add_child(driver)

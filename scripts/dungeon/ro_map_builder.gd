class_name RoMapBuilder
extends RefCounted
## Procedural Ragnarok-style field via TileMapLayer stacks (floor / paths / decor).

const FIELD_W := 3920.0
const FIELD_H := 2480.0
const TILE := 64

const ORIGIN_CELL := Vector2i(-31, -20)
const MAP_COLS := 62
const MAP_ROWS := 39

const DECOR_SPOTS: Array[Vector2] = [
	Vector2(-780, -520), Vector2(620, -380), Vector2(-420, 280), Vector2(840, 460),
	Vector2(-1100, 120), Vector2(300, -620), Vector2(-200, 620), Vector2(1100, -200),
	Vector2(-900, 700), Vector2(950, 80), Vector2(-550, -80), Vector2(450, 320),
]


static func build(parent: Node2D) -> void:
	if parent == null:
		return
	var root := Node2D.new()
	root.name = "RoMap"
	parent.add_child(root)
	parent.move_child(root, 0)
	var tile_set := DungeonTilesetFactory.make_tileset()
	var floor_layer := _make_layer(root, "Floor", -20, tile_set)
	var path_layer := _make_layer(root, "Paths", -15, tile_set)
	var decor_layer := _make_layer(root, "Decor", -8, tile_set)
	_fill_grass(floor_layer)
	_paint_paths(path_layer)
	_paint_decor(decor_layer)
	_paint_wall_trim(parent, tile_set)
	_add_atmosphere(parent)


static func _make_layer(root: Node2D, layer_name: String, z: int, tile_set: TileSet) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.z_index = z
	layer.tile_set = tile_set
	root.add_child(layer)
	return layer


static func _fill_grass(layer: TileMapLayer) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 90210
	var grass_cells: Array[Vector2i] = []
	for y in MAP_ROWS:
		for x in MAP_COLS:
			grass_cells.append(ORIGIN_CELL + Vector2i(x, y))
	layer.set_cells_terrain_connect(
		grass_cells,
		DungeonTilesetFactory.TERRAIN_SET,
		DungeonTilesetFactory.TERRAIN_GRASS,
		false
	)
	# Subtle grass variation on top of terrain fill.
	for cell in grass_cells:
		if rng.randf() > 0.35:
			continue
		var variant := DungeonTilesetFactory.grass_variants()[
			rng.randi_range(0, DungeonTilesetFactory.grass_variants().size() - 1)
		]
		layer.set_cell(cell, DungeonTilesetFactory.SOURCE_ID, variant)


static func _paint_paths(layer: TileMapLayer) -> void:
	var path_cells: Array[Vector2i] = []
	var mid_x := ORIGIN_CELL.x + MAP_COLS / 2
	var mid_y := ORIGIN_CELL.y + MAP_ROWS / 2
	var half_w := int(MAP_COLS * 0.11)
	var half_h := int(MAP_ROWS * 0.11)
	for x in range(ORIGIN_CELL.x, ORIGIN_CELL.x + MAP_COLS):
		if abs(x - mid_x) <= half_w:
			path_cells.append(Vector2i(x, mid_y))
	for y in range(ORIGIN_CELL.y, ORIGIN_CELL.y + MAP_ROWS):
		if abs(y - mid_y) <= half_h:
			path_cells.append(Vector2i(mid_x, y))
	if path_cells.is_empty():
		return
	layer.set_cells_terrain_connect(
		path_cells,
		DungeonTilesetFactory.TERRAIN_SET,
		DungeonTilesetFactory.TERRAIN_PATH,
		false
	)


static func _paint_decor(layer: TileMapLayer) -> void:
	for i in DECOR_SPOTS.size():
		var world := DECOR_SPOTS[i]
		var cell := layer.local_to_map(world)
		var atlas: Vector2i
		if i % 3 == 0:
			atlas = DungeonTilesetFactory.atlas_tree
		elif i % 3 == 1:
			atlas = DungeonTilesetFactory.atlas_rock
		else:
			atlas = DungeonTilesetFactory.atlas_barrel
		layer.set_cell(cell, DungeonTilesetFactory.SOURCE_ID, atlas)


static func _paint_wall_trim(parent: Node2D, tile_set: TileSet) -> void:
	var wall_layer := _make_layer(parent.get_node("RoMap") as Node2D, "WallsTrim", -5, tile_set)
	var top := ORIGIN_CELL.y - 1
	var bottom := ORIGIN_CELL.y + MAP_ROWS
	var left := ORIGIN_CELL.x - 1
	var right := ORIGIN_CELL.x + MAP_COLS
	for x in range(ORIGIN_CELL.x - 1, ORIGIN_CELL.x + MAP_COLS + 1):
		wall_layer.set_cell(Vector2i(x, top), DungeonTilesetFactory.SOURCE_ID, DungeonTilesetFactory.atlas_wall)
		wall_layer.set_cell(Vector2i(x, bottom), DungeonTilesetFactory.SOURCE_ID, DungeonTilesetFactory.atlas_wall)
	for y in range(ORIGIN_CELL.y - 1, ORIGIN_CELL.y + MAP_ROWS + 1):
		wall_layer.set_cell(Vector2i(left, y), DungeonTilesetFactory.SOURCE_ID, DungeonTilesetFactory.atlas_wall)
		wall_layer.set_cell(Vector2i(right, y), DungeonTilesetFactory.SOURCE_ID, DungeonTilesetFactory.atlas_wall)


static func _add_atmosphere(parent: Node2D) -> void:
	var atmo: Node = load("res://scripts/dungeon/dungeon_atmosphere.gd").new()
	atmo.name = "Atmosphere"
	parent.add_child(atmo)

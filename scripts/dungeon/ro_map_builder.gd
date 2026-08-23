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
	if DungeonTilesetFactory.using_pixellab:
		var grass_layer := _make_layer(root, "Grass", -20, tile_set)
		var path_layer := _make_layer(root, "PathOverlay", -18, tile_set)
		_paint_pixellab_ground(grass_layer, path_layer)
	else:
		var ground_layer := _make_layer(root, "Ground", -20, tile_set)
		_paint_procedural_ground(ground_layer)
	var decor_layer := _make_layer(root, "Decor", -8, tile_set)
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


static func _paint_pixellab_ground(grass_layer: TileMapLayer, path_layer: TileMapLayer) -> void:
	var ground_cells: Array[Vector2i] = []
	for y in MAP_ROWS:
		for x in MAP_COLS:
			ground_cells.append(ORIGIN_CELL + Vector2i(x, y))
	var grass_tile := DungeonTilesetFactory.atlas_grass_fill
	for cell in ground_cells:
		grass_layer.set_cell(cell, DungeonTilesetFactory.SOURCE_ID, grass_tile)
	var path_cells := _path_cells()
	if path_cells.is_empty():
		return
	var path_set: Dictionary = {}
	for cell in path_cells:
		path_set[cell] = true
	for cell in path_cells:
		var wang_id := _wang_id_for_cell(cell, path_set)
		path_layer.set_cell(
			cell,
			DungeonTilesetFactory.SOURCE_ID,
			DungeonTilesetFactory.wang_atlas_for_id(wang_id),
		)


static func _paint_procedural_ground(layer: TileMapLayer) -> void:
	var ground_cells: Array[Vector2i] = []
	for y in MAP_ROWS:
		for x in MAP_COLS:
			ground_cells.append(ORIGIN_CELL + Vector2i(x, y))
	layer.set_cells_terrain_connect(
		ground_cells,
		DungeonTilesetFactory.TERRAIN_SET,
		DungeonTilesetFactory.TERRAIN_GRASS,
		false,
	)
	var path_cells := _path_cells()
	if not path_cells.is_empty():
		layer.set_cells_terrain_connect(
			path_cells,
			DungeonTilesetFactory.TERRAIN_SET,
			DungeonTilesetFactory.TERRAIN_PATH,
			false,
		)
	_sprinkle_grass_variants(layer, ground_cells)


static func _wang_id_for_cell(cell: Vector2i, path_set: Dictionary) -> int:
	var nw := _corner_is_path(cell, path_set, &"NW")
	var ne := _corner_is_path(cell, path_set, &"NE")
	var sw := _corner_is_path(cell, path_set, &"SW")
	var se := _corner_is_path(cell, path_set, &"SE")
	var id := 0
	if nw:
		id |= 8
	if ne:
		id |= 4
	if sw:
		id |= 2
	if se:
		id |= 1
	return id


static func _corner_is_path(cell: Vector2i, path_set: Dictionary, corner: StringName) -> bool:
	var offsets: Array[Vector2i] = []
	match corner:
		&"NW":
			offsets = [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, -1)]
		&"NE":
			offsets = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(1, -1)]
		&"SW":
			offsets = [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(-1, 1)]
		&"SE":
			offsets = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
	if offsets.is_empty():
		return false
	for off in offsets:
		if path_set.has(cell + off):
			return true
	return false


static func _path_cells() -> Array[Vector2i]:
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
	return path_cells


static func _sprinkle_grass_variants(layer: TileMapLayer, ground_cells: Array[Vector2i]) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 90210
	var path_set := {}
	for cell in _path_cells():
		path_set[cell] = true
	var variants := DungeonTilesetFactory.grass_variants()
	for cell in ground_cells:
		if path_set.has(cell):
			continue
		if rng.randf() > 0.35:
			continue
		var variant := variants[rng.randi_range(0, variants.size() - 1)]
		layer.set_cell(cell, DungeonTilesetFactory.SOURCE_ID, variant)


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

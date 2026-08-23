class_name DungeonTilesetFactory
extends RefCounted
## Dungeon TileSet — PixelLab Wang tileset when exported, else procedural fallback.

const TILE_SIZE := 64
const SOURCE_ID := 0

const ATLAS_GRASS_A := Vector2i(0, 0)
const ATLAS_GRASS_B := Vector2i(1, 0)
const ATLAS_GRASS_C := Vector2i(2, 0)
const ATLAS_GRASS_D := Vector2i(3, 0)
const ATLAS_PATH := Vector2i(0, 1)
const ATLAS_TREE := Vector2i(0, 2)
const ATLAS_ROCK := Vector2i(1, 2)
const ATLAS_BARREL := Vector2i(2, 2)
const ATLAS_WALL := Vector2i(3, 2)

const GRASS_VARIANTS: Array[Vector2i] = [
	ATLAS_GRASS_A,
	ATLAS_GRASS_B,
	ATLAS_GRASS_C,
	ATLAS_GRASS_D,
]

const TERRAIN_SET := 0
const TERRAIN_GRASS := 0
const TERRAIN_PATH := 1

const PIXELLAB_META := "res://assets/art/pixellab/dungeon/meta.json"
const PIXELLAB_ATLAS := "res://assets/art/pixellab/dungeon/atlas.png"

static var atlas_tree := ATLAS_TREE
static var atlas_rock := ATLAS_ROCK
static var atlas_barrel := ATLAS_BARREL
static var atlas_wall := ATLAS_WALL
static var grass_variants_runtime: Array[Vector2i] = GRASS_VARIANTS.duplicate()
static var using_pixellab := false


static func grass_variants() -> Array[Vector2i]:
	return grass_variants_runtime


static func make_tileset() -> TileSet:
	if _pixellab_available():
		return _make_pixellab_tileset()
	return _make_procedural_tileset()


static func _pixellab_available() -> bool:
	return ResourceLoader.exists(PIXELLAB_META) and ResourceLoader.exists(PIXELLAB_ATLAS)


static func _load_pixellab_meta() -> Dictionary:
	var text := FileAccess.get_file_as_string(PIXELLAB_META)
	var parsed: Variant = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {}


static func _make_pixellab_tileset() -> TileSet:
	using_pixellab = true
	var meta := _load_pixellab_meta()
	var atlas_tex := load(PIXELLAB_ATLAS) as Texture2D
	if atlas_tex == null:
		return _make_procedural_tileset()
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var source := TileSetAtlasSource.new()
	source.texture = atlas_tex
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var source_id := tile_set.add_source(source, SOURCE_ID)
	var atlas := tile_set.get_source(source_id) as TileSetAtlasSource
	var tiles: Array = meta.get("tiles", [])
	for entry in tiles:
		if not entry is Dictionary:
			continue
		var at: Array = entry.get("atlas", [])
		if at.size() < 2:
			continue
		var coord := Vector2i(int(at[0]), int(at[1]))
		atlas.create_tile(coord)
	_register_decor_tiles(atlas, meta.get("decor_atlas", {}))
	_configure_pixellab_terrains(tile_set, atlas, tiles)
	_apply_pixellab_decor(meta.get("decor_atlas", {}))
	_cache_grass_variants(tiles)
	return tile_set


static func _register_decor_tiles(atlas: TileSetAtlasSource, decor: Variant) -> void:
	if not decor is Dictionary:
		return
	for key in decor.keys():
		var at: Variant = decor[key]
		if at is Array and at.size() >= 2:
			var coord := Vector2i(int(at[0]), int(at[1]))
			if not atlas.has_tile(coord):
				atlas.create_tile(coord)


static func _configure_pixellab_terrains(
	tile_set: TileSet,
	atlas: TileSetAtlasSource,
	tiles: Array,
) -> void:
	tile_set.add_terrain_set()
	tile_set.set_terrain_set_mode(TERRAIN_SET, TileSet.TERRAIN_MODE_MATCH_CORNERS)
	tile_set.add_terrain(TERRAIN_SET)
	tile_set.add_terrain(TERRAIN_SET)
	tile_set.set_terrain_name(TERRAIN_SET, TERRAIN_GRASS, &"grass")
	tile_set.set_terrain_name(TERRAIN_SET, TERRAIN_PATH, &"path")
	for entry in tiles:
		if not entry is Dictionary:
			continue
		var at: Array = entry.get("atlas", [])
		if at.size() < 2:
			continue
		var coord := Vector2i(int(at[0]), int(at[1]))
		var corners: Dictionary = entry.get("corners", {})
		_paint_corner_terrain(atlas, coord, corners)


static func _paint_corner_terrain(atlas: TileSetAtlasSource, coord: Vector2i, corners: Dictionary) -> void:
	var tile_data := atlas.get_tile_data(coord, 0)
	if tile_data == null:
		return
	tile_data.set_terrain_set(TERRAIN_SET)
	var nw := _terrain_for_corner(str(corners.get("NW", "lower")))
	var ne := _terrain_for_corner(str(corners.get("NE", "lower")))
	var sw := _terrain_for_corner(str(corners.get("SW", "lower")))
	var se := _terrain_for_corner(str(corners.get("SE", "lower")))
	tile_data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER, nw)
	tile_data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER, ne)
	tile_data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER, sw)
	tile_data.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER, se)


static func _terrain_for_corner(corner_val: String) -> int:
	if corner_val == "upper":
		return TERRAIN_PATH
	return TERRAIN_GRASS


static func _apply_pixellab_decor(decor: Dictionary) -> void:
	if decor is Dictionary and not decor.is_empty():
		if decor.has("tree"):
			atlas_tree = _vec_from_array(decor["tree"], ATLAS_TREE)
		if decor.has("rock"):
			atlas_rock = _vec_from_array(decor["rock"], ATLAS_ROCK)
		if decor.has("barrel"):
			atlas_barrel = _vec_from_array(decor["barrel"], ATLAS_BARREL)
		if decor.has("wall"):
			atlas_wall = _vec_from_array(decor["wall"], ATLAS_WALL)


static func _vec_from_array(at: Variant, fallback: Vector2i) -> Vector2i:
	if at is Array and at.size() >= 2:
		return Vector2i(int(at[0]), int(at[1]))
	return fallback


static func _cache_grass_variants(tiles: Array) -> void:
	var pure: Array[Vector2i] = []
	for entry in tiles:
		if not entry is Dictionary:
			continue
		var corners: Dictionary = entry.get("corners", {})
		if not _is_pure_lower(corners):
			continue
		var at: Array = entry.get("atlas", [])
		if at.size() >= 2:
			pure.append(Vector2i(int(at[0]), int(at[1])))
	if pure.size() >= 1:
		grass_variants_runtime = pure.slice(0, mini(4, pure.size()))


static func _is_pure_lower(corners: Dictionary) -> bool:
	for key in ["NW", "NE", "SW", "SE"]:
		if str(corners.get(key, "lower")) != "lower":
			return false
	return true


static func _make_procedural_tileset() -> TileSet:
	using_pixellab = false
	atlas_tree = ATLAS_TREE
	atlas_rock = ATLAS_ROCK
	atlas_barrel = ATLAS_BARREL
	atlas_wall = ATLAS_WALL
	grass_variants_runtime = GRASS_VARIANTS.duplicate()
	var atlas_tex := _build_atlas_texture()
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var source := TileSetAtlasSource.new()
	source.texture = atlas_tex
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var source_id := tile_set.add_source(source, SOURCE_ID)
	var atlas := tile_set.get_source(source_id) as TileSetAtlasSource
	for coord in _all_atlas_coords():
		atlas.create_tile(coord)
	_configure_side_terrains(tile_set, atlas)
	return tile_set


static func _all_atlas_coords() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in 3:
		for x in 4:
			out.append(Vector2i(x, y))
	return out


static func _configure_side_terrains(tile_set: TileSet, atlas: TileSetAtlasSource) -> void:
	tile_set.add_terrain_set()
	tile_set.set_terrain_set_mode(TERRAIN_SET, TileSet.TERRAIN_MODE_MATCH_SIDES)
	tile_set.add_terrain(TERRAIN_SET)
	tile_set.add_terrain(TERRAIN_SET)
	tile_set.set_terrain_name(TERRAIN_SET, TERRAIN_GRASS, &"grass")
	tile_set.set_terrain_name(TERRAIN_SET, TERRAIN_PATH, &"path")
	for variant in GRASS_VARIANTS:
		_paint_side_terrain(atlas, variant, TERRAIN_GRASS)
	_paint_side_terrain(atlas, ATLAS_PATH, TERRAIN_PATH)


static func _paint_side_terrain(atlas: TileSetAtlasSource, coord: Vector2i, terrain_id: int) -> void:
	var tile_data := atlas.get_tile_data(coord, 0)
	if tile_data == null:
		return
	tile_data.set_terrain_set(TERRAIN_SET)
	tile_data.set_terrain(terrain_id)
	for peering in _terrain_peering_bits():
		tile_data.set_terrain_peering_bit(peering, terrain_id)


static func _terrain_peering_bits() -> Array:
	return [
		TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
		TileSet.CELL_NEIGHBOR_LEFT_SIDE,
		TileSet.CELL_NEIGHBOR_TOP_SIDE,
		TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
	]


static func _build_atlas_texture() -> Texture2D:
	var cols := 4
	var rows := 3
	var w := cols * TILE_SIZE
	var h := rows * TILE_SIZE
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	_paint_grass_tile(img, 0, 0, 0.06)
	_paint_grass_tile(img, 1, 0, 0.0)
	_paint_grass_tile(img, 2, 0, -0.04)
	_paint_grass_tile(img, 3, 0, 0.03)
	_paint_stone_tile(img, 0, 1)
	_paint_tree_tile(img, 0, 2)
	_paint_rock_tile(img, 1, 2)
	_paint_barrel_tile(img, 2, 2)
	_paint_wall_tile(img, 3, 2)
	return ImageTexture.create_from_image(img)


static func _paint_grass_tile(img: Image, col: int, row: int, bias: float) -> void:
	var ox := col * TILE_SIZE
	var oy := row * TILE_SIZE
	var c1 := Color(0.34, 0.58, 0.32, 1).lightened(bias)
	var c2 := Color(0.28, 0.5, 0.26, 1).lightened(bias)
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			var t := (float(x) + float(y)) / (TILE_SIZE * 2.0)
			var c := c1.lerp(c2, t)
			if (x / 8 + y / 8) % 2 == 0:
				c = c.lightened(0.06)
			img.set_pixel(ox + x, oy + y, c)
	for i in 3:
		var fx := 8 + i * 18
		var fy := 10 + (i * 11) % (TILE_SIZE - 12)
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if fx + dx < TILE_SIZE and fy + dy < TILE_SIZE:
					img.set_pixel(ox + fx + dx, oy + fy + dy, Color(0.75, 0.82, 0.45, 0.8))


static func _paint_stone_tile(img: Image, col: int, row: int) -> void:
	var ox := col * TILE_SIZE
	var oy := row * TILE_SIZE
	var base := Color(0.58, 0.54, 0.48, 1)
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			var n := sin(x * 0.35) * cos(y * 0.28) * 0.04
			img.set_pixel(ox + x, oy + y, base.lightened(n))
	for i in 6:
		var px := (i * 17 + 5) % TILE_SIZE
		var py := (i * 23 + 9) % TILE_SIZE
		img.set_pixel(ox + px, oy + py, base.darkened(0.12))


static func _paint_tree_tile(img: Image, col: int, row: int) -> void:
	var ox := col * TILE_SIZE
	var oy := row * TILE_SIZE
	_fill_rect(img, ox, oy, TILE_SIZE, TILE_SIZE, Color(0.3, 0.52, 0.3, 0.15))
	_fill_polygon(img, ox, oy, [
		Vector2(32, 8), Vector2(52, 34), Vector2(42, 54), Vector2(22, 54), Vector2(12, 34),
	], Color(0.22, 0.52, 0.28, 1))
	_fill_polygon(img, ox, oy, [
		Vector2(24, 20), Vector2(38, 28), Vector2(32, 44), Vector2(18, 36),
	], Color(0.38, 0.68, 0.38, 0.55))
	_fill_rect(img, ox + 26, oy + 44, 12, 16, Color(0.35, 0.22, 0.14, 1))


static func _paint_rock_tile(img: Image, col: int, row: int) -> void:
	var ox := col * TILE_SIZE
	var oy := row * TILE_SIZE
	_fill_polygon(img, ox, oy, [
		Vector2(10, 40), Vector2(24, 16), Vector2(50, 22), Vector2(56, 42), Vector2(34, 54), Vector2(12, 48),
	], Color(0.48, 0.46, 0.42, 1))


static func _paint_barrel_tile(img: Image, col: int, row: int) -> void:
	var ox := col * TILE_SIZE
	var oy := row * TILE_SIZE
	_fill_rect(img, ox + 18, oy + 18, 28, 34, Color(0.52, 0.34, 0.2, 1))
	_fill_rect(img, ox + 16, oy + 30, 32, 8, Color(0.28, 0.2, 0.12, 1))


static func _paint_wall_tile(img: Image, col: int, row: int) -> void:
	var ox := col * TILE_SIZE
	var oy := row * TILE_SIZE
	var base := Color(0.42, 0.38, 0.32, 1)
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			var n := sin(x * 0.2) * 0.03
			img.set_pixel(ox + x, oy + y, base.lightened(n))


static func _fill_rect(img: Image, ox: int, oy: int, w: int, h: int, color: Color) -> void:
	for y in h:
		for x in w:
			img.set_pixel(ox + x, oy + y, color)


static func _fill_polygon(img: Image, ox: int, oy: int, points: Array, color: Color) -> void:
	var min_y := int(points[0].y)
	var max_y := int(points[0].y)
	for p in points:
		min_y = mini(min_y, int(p.y))
		max_y = maxi(max_y, int(p.y))
	for y in range(max(min_y, 0), min(max_y + 1, TILE_SIZE)):
		var intersections: Array = []
		for i in points.size():
			var a: Vector2 = points[i]
			var b: Vector2 = points[(i + 1) % points.size()]
			if (a.y <= y and b.y > y) or (b.y <= y and a.y > y):
				var t := (y - a.y) / (b.y - a.y)
				intersections.append(a.x + t * (b.x - a.x))
		intersections.sort()
		for i in range(0, intersections.size() - 1, 2):
			var x0 := int(intersections[i])
			var x1 := int(intersections[i + 1])
			for x in range(max(x0, 0), min(x1 + 1, TILE_SIZE)):
				img.set_pixel(ox + x, oy + y, color)

#!/usr/bin/env python3
"""PixelLab top-down Wang tileset + decor props → assets/art/pixellab/dungeon/.

Usage:
  python3 scripts/art/pixellab_tileset_batch.py --balance
  python3 scripts/art/pixellab_tileset_batch.py dungeon
  python3 scripts/art/pixellab_tileset_batch.py dungeon --force
"""
import argparse
import base64
import io
import json
import os
import time
import urllib.error
import urllib.request

from PIL import Image

API_BASE = "https://api.pixellab.ai/v2"
WORKSPACE = "/workspace"
OUT_ROOT = f"{WORKSPACE}/assets/art/pixellab/dungeon"
TILES_DIR = f"{OUT_ROOT}/tiles"
GAME_TILE = 64
SRC_TILE = 32

# Sampled from opaque pixels in wang_0 / wang_15 after export.
GRASS_RGB = (26, 200, 2)
PATH_RGB = (74, 63, 73)
SOLID_ALPHA_CUT = 48


def solidify_wang_rgba(
	w: int,
	h: int,
	rgba: list,
	corners: dict,
	grass_rgb: tuple[int, int, int] = GRASS_RGB,
	path_rgb: tuple[int, int, int] = PATH_RGB,
) -> list:
	"""PixelLab Wang tiles are corner overlays with large transparent regions.
	Godot terrain needs fully opaque cells — fill each quadrant with its terrain base."""
	out = list(rgba)
	quads = {
		"NW": (0, 0, w // 2, h // 2),
		"NE": (w // 2, 0, w, h // 2),
		"SW": (0, h // 2, w // 2, h),
		"SE": (w // 2, h // 2, w, h),
	}
	for corner, (x0, y0, x1, y1) in quads.items():
		fill = path_rgb if corners.get(corner, "lower") == "upper" else grass_rgb
		for y in range(y0, y1):
			for x in range(x0, x1):
				i = (y * w + x) * 4
				if out[i + 3] < SOLID_ALPHA_CUT:
					out[i] = fill[0]
					out[i + 1] = fill[1]
					out[i + 2] = fill[2]
					out[i + 3] = 255
	return out


def solidify_decor_rgba(
	w: int,
	h: int,
	rgba: list,
	ground_rgb: tuple[int, int, int] = GRASS_RGB,
) -> list:
	"""Props are cutouts; fill transparent pixels with grass so holes don't show on paths."""
	out = list(rgba)
	for y in range(h):
		for x in range(w):
			i = (y * w + x) * 4
			a = out[i + 3]
			if a == 0:
				out[i] = ground_rgb[0]
				out[i + 1] = ground_rgb[1]
				out[i + 2] = ground_rgb[2]
				out[i + 3] = 255
			elif a < 220:
				t = a / 255.0
				for c in range(3):
					out[i + c] = int(out[i + c] * t + ground_rgb[c] * (1.0 - t))
				out[i + 3] = 255
	return out


def load_api_key() -> str:
	key = os.environ.get("PIXELLAB_API_KEY", "").strip()
	if key:
		return key
	for path in (
		"/cursor/stores/self/pixellab/api_key.txt",
		os.path.join(WORKSPACE, ".pixellab_api_key"),
	):
		if os.path.isfile(path):
			return open(path).read().strip()
	raise RuntimeError("Missing PixelLab API key")


def api(method: str, path: str, body: dict | None = None, timeout: int = 120) -> dict:
	key = load_api_key()
	url = API_BASE + path
	data = json.dumps(body).encode() if body is not None else None
	req = urllib.request.Request(
		url,
		data=data,
		headers={
			"Authorization": f"Bearer {key}",
			"Content-Type": "application/json",
			"Accept": "application/json",
		},
		method=method,
	)
	try:
		with urllib.request.urlopen(req, timeout=timeout) as resp:
			raw = resp.read().decode()
			return json.loads(raw) if raw else {}
	except urllib.error.HTTPError as exc:
		err_body = exc.read().decode()[:1200]
		raise RuntimeError(f"PixelLab {path} HTTP {exc.code}: {err_body}") from exc


def poll_job(job_id: str, label: str, max_wait: int = 600) -> dict:
	deadline = time.time() + max_wait
	while time.time() < deadline:
		status = api("GET", f"/background-jobs/{job_id}")
		state = str(status.get("status", "")).lower()
		print(f"  job {label}: {state}", flush=True)
		if state in ("completed", "succeeded", "success"):
			return status
		if state in ("failed", "error"):
			raise RuntimeError(f"Job {job_id} failed: {status}")
		time.sleep(6)
	raise TimeoutError(f"Job {job_id} timed out")


def poll_tileset(tileset_id: str, max_wait: int = 600) -> dict:
	deadline = time.time() + max_wait
	while time.time() < deadline:
		try:
			return api("GET", f"/tilesets/{tileset_id}")
		except urllib.error.HTTPError as exc:
			if exc.code == 423:
				print("  tileset processing...", flush=True)
				time.sleep(8)
				continue
			raise
	raise TimeoutError(f"tileset {tileset_id} not ready")


def create_tileset(force: bool) -> str:
	meta_path = f"{OUT_ROOT}/meta.json"
	if not force and os.path.isfile(meta_path):
		meta = json.load(open(meta_path))
		tid = meta.get("tileset_id")
		if tid:
			try:
				data = api("GET", f"/tilesets/{tid}")
				if data.get("tileset", {}).get("tiles"):
					print(f"reuse tileset {tid}", flush=True)
					return tid
			except urllib.error.HTTPError:
				pass
	body = {
		"lower_description": (
			"lush fantasy grass field, bright green roguelike outdoor terrain, "
			"ragnarok online pront field style"
		),
		"upper_description": (
			"worn dirt and cobblestone path, fantasy roguelike road tiles"
		),
		"transition_description": "grass blades fading into packed dirt at path edge",
		"tile_size": {"width": SRC_TILE, "height": SRC_TILE},
		"transition_size": 0.25,
		"view": "low top-down",
		"outline": "single color black outline",
		"shading": "medium shading",
		"detail": "medium detail",
		"text_guidance_scale": 8.0,
	}
	print("create-tileset (grass + path)...", flush=True)
	resp = api("POST", "/create-tileset", body)
	tid = resp["tileset_id"]
	job_id = resp["background_job_id"]
	poll_job(job_id, "tileset")
	return tid


def _decode_b64(data: str) -> bytes:
	if data.startswith("data:"):
		data = data.split(",", 1)[-1]
	return base64.b64decode(data)


def create_decor_pixflux(name: str, description: str) -> bytes:
	print(f"pixflux decor {name}...", flush=True)
	resp = api(
		"POST",
		"/create-image-pixflux",
		{
			"description": description,
			"image_size": {"width": GAME_TILE, "height": GAME_TILE},
			"no_background": True,
			"view": "low top-down",
			"outline": "single color black outline",
			"shading": "medium shading",
			"detail": "medium detail",
		},
		timeout=180,
	)
	img = resp.get("image", {})
	b64 = img.get("base64")
	if not b64:
		raise RuntimeError(f"no image for decor {name}")
	return _decode_b64(b64)


def decode_png_rgba(raw: bytes) -> tuple[int, int, list]:
	img = Image.open(io.BytesIO(raw)).convert("RGBA")
	w, h = img.size
	return w, h, list(img.tobytes())


def scale_rgba(w: int, h: int, pixels: list, out_w: int, out_h: int) -> list:
	img = Image.frombytes("RGBA", (w, h), bytes(pixels))
	resized = img.resize((out_w, out_h), Image.Resampling.NEAREST)
	return list(resized.tobytes())


def write_png(path: str, w: int, h: int, rgba: list) -> None:
	os.makedirs(os.path.dirname(path), exist_ok=True)
	img = Image.frombytes("RGBA", (w, h), bytes(rgba))
	img.save(path, format="PNG", compress_level=9)


def tile_image_bytes(tile: dict) -> bytes:
	img = tile.get("image", {})
	b64 = img.get("base64")
	if not b64:
		raise RuntimeError(f"tile {tile.get('id')} missing image")
	return _decode_b64(b64)


def export_tileset(tileset_id: str) -> dict:
	data = poll_tileset(tileset_id)
	tileset = data["tileset"]
	tiles = tileset["tiles"]
	os.makedirs(TILES_DIR, exist_ok=True)
	exported = []
	for tile in tiles:
		# PixelLab original_position can collide — Wang ids 0–15 map to a unique 4×4 grid.
		tid = int(tile.get("id", len(exported)))
		col = tid % 4
		row = tid // 4
		raw = tile_image_bytes(tile)
		tile_path = f"{TILES_DIR}/{tile['id']}.png"
		with open(tile_path, "wb") as f:
			f.write(raw)
		corners = tile.get("corners", {})
		entry = {
			"id": tile["id"],
			"name": tile.get("name"),
			"atlas": [col, row],
			"corners": {
				"NW": corners.get("NW", "lower"),
				"NE": corners.get("NE", "lower"),
				"SW": corners.get("SW", "lower"),
				"SE": corners.get("SE", "lower"),
			},
		}
		exported.append(entry)

	decor_defs = {
		"tree": (
			"pixel art lush fantasy oak tree, top-down roguelike field decor, "
			"round green canopy centered in frame, short brown trunk, black outline, "
			"vibrant game sprite on transparent background"
		),
		"rock": "pixel art gray boulder rock, top-down field decor",
		"barrel": (
			"pixel art wooden storage barrel, top-down roguelike prop, "
			"centered brown barrel with dark metal bands, black outline, "
			"game icon on transparent background"
		),
		"wall": "pixel art stone wall trim segment, top-down dungeon border",
	}
	decor_atlas = {}
	decor_row = 4
	for i, (name, desc) in enumerate(decor_defs.items()):
		try:
			raw = create_decor_pixflux(name, desc)
			w, h, px = decode_png_rgba(raw)
			scaled = scale_rgba(w, h, px, GAME_TILE, GAME_TILE)
			path = f"{OUT_ROOT}/decor_{name}.png"
			write_png(path, GAME_TILE, GAME_TILE, scaled)
			decor_atlas[name] = [i, decor_row]
		except Exception as exc:
			print(f"  decor {name} skipped: {exc}", flush=True)

	meta = {
		"tileset_id": tileset_id,
		"source_tile_size": SRC_TILE,
		"game_tile_size": GAME_TILE,
		"terrain": {"lower": "grass", "upper": "path"},
		"render_mode": "overlay",
		"tiles": exported,
		"decor_atlas": decor_atlas,
		"grass_fill_atlas": [0, 5],
		"atlas_cols": 4,
		"atlas_rows": 6,
	}
	build_atlas(meta)
	json.dump(meta, open(f"{OUT_ROOT}/meta.json", "w"), indent=2)
	print(f"exported {len(exported)} wang tiles + {len(decor_atlas)} decor", flush=True)
	return meta


def build_atlas(meta: dict, solidify_decor_names: set[str] | None = None) -> None:
	cols = meta["atlas_cols"]
	rows = meta["atlas_rows"]
	tile = meta["game_tile_size"]
	w = cols * tile
	h = rows * tile
	canvas = [0, 0, 0, 0] * (w * h)
	solidify_decor_names = solidify_decor_names or set()

	# Wang grid: keep raw overlay tiles (transparent quadrants) for path layer.
	for entry in meta["tiles"]:
		col, row = entry["atlas"]
		raw = open(f"{TILES_DIR}/{entry['id']}.png", "rb").read()
		sw, sh, px = decode_png_rgba(raw)
		scaled = scale_rgba(sw, sh, px, tile, tile)
		_blit(canvas, w, h, col * tile, row * tile, tile, tile, scaled)

	# Solid grass fill tile for the base layer under path overlays.
	grass_corners = {"NW": "lower", "NE": "lower", "SW": "lower", "SE": "lower"}
	for entry in meta["tiles"]:
		if str(entry.get("id")) == "0":
			grass_corners = entry.get("corners", grass_corners)
			break
	raw0 = open(f"{TILES_DIR}/0.png", "rb").read()
	sw, sh, px = decode_png_rgba(raw0)
	grass_scaled = scale_rgba(sw, sh, px, tile, tile)
	grass_scaled = solidify_wang_rgba(tile, tile, grass_scaled, grass_corners)
	gf = meta.get("grass_fill_atlas", [0, 5])
	gx, gy = int(gf[0]), int(gf[1])
	write_png(f"{OUT_ROOT}/grass_fill.png", tile, tile, grass_scaled)
	_blit(canvas, w, h, gx * tile, gy * tile, tile, tile, grass_scaled)

	for name, (col, row) in meta.get("decor_atlas", {}).items():
		path = f"{OUT_ROOT}/decor_{name}.png"
		if not os.path.isfile(path):
			continue
		raw = open(path, "rb").read()
		dw, dh, px = decode_png_rgba(raw)
		scaled = scale_rgba(dw, dh, px, tile, tile)
		if name in solidify_decor_names:
			scaled = solidify_decor_rgba(tile, tile, scaled)
			write_png(path, tile, tile, scaled)
		_blit(canvas, w, h, col * tile, row * tile, tile, tile, scaled)

	out_path = f"{OUT_ROOT}/atlas.png"
	write_png(out_path, w, h, canvas)
	print(f"atlas {out_path} ({w}x{h})", flush=True)


def _blit(canvas: list, cw: int, ch: int, ox: int, oy: int, tw: int, th: int, rgba: list) -> None:
	for y in range(th):
		for x in range(tw):
			si = (y * tw + x) * 4
			a = rgba[si + 3]
			if a == 0:
				continue
			cx = ox + x
			cy = oy + y
			if cx >= cw or cy >= ch:
				continue
			di = (cy * cw + cx) * 4
			canvas[di:di + 4] = rgba[si:si + 4]


def run_dungeon(force: bool) -> None:
	tid = create_tileset(force)
	export_tileset(tid)


def redraw_decor(names: list[str]) -> None:
	meta_path = f"{OUT_ROOT}/meta.json"
	if not os.path.isfile(meta_path):
		raise SystemExit(f"missing {meta_path}")
	meta = json.load(open(meta_path))
	decor_defs = {
		"tree": (
			"pixel art lush fantasy oak tree, top-down roguelike field decor, "
			"round green canopy centered in frame, short brown trunk, black outline, "
			"vibrant game sprite on transparent background"
		),
		"barrel": (
			"pixel art wooden storage barrel, top-down roguelike prop, "
			"centered brown barrel with dark metal bands, black outline, "
			"game icon on transparent background"
		),
		"rock": "pixel art gray boulder rock, top-down field decor",
		"wall": "pixel art stone wall trim segment, top-down dungeon border",
	}
	decor_atlas = meta.get("decor_atlas", {})
	for name in names:
		if name not in decor_defs:
			raise SystemExit(f"unknown decor {name}")
		print(f"pixflux decor {name}...", flush=True)
		raw = create_decor_pixflux(name, decor_defs[name])
		w, h, px = decode_png_rgba(raw)
		scaled = scale_rgba(w, h, px, GAME_TILE, GAME_TILE)
		write_png(f"{OUT_ROOT}/decor_{name}.png", GAME_TILE, GAME_TILE, scaled)
		if name not in decor_atlas:
			decor_atlas[name] = [len(decor_atlas) % 4, 4]
	meta["decor_atlas"] = decor_atlas
	build_atlas(meta)
	json.dump(meta, open(meta_path, "w"), indent=2)
	print(f"redrew decor: {', '.join(names)}", flush=True)


def rebuild_local_atlas() -> None:
	"""Re-solidify and rebuild atlas from existing tiles/decor without API calls."""
	meta_path = f"{OUT_ROOT}/meta.json"
	if not os.path.isfile(meta_path):
		raise SystemExit(f"missing {meta_path}")
	meta = json.load(open(meta_path))
	build_atlas(meta)
	json.dump(meta, open(meta_path, "w"), indent=2)
	print("rebuilt local dungeon atlas", flush=True)


def main() -> None:
	parser = argparse.ArgumentParser()
	parser.add_argument("target", nargs="?", default="dungeon")
	parser.add_argument("--force", action="store_true")
	parser.add_argument("--balance", action="store_true")
	parser.add_argument(
		"--rebuild-local",
		action="store_true",
		help="re-solidify tiles and rebuild atlas from existing dungeon assets",
	)
	parser.add_argument(
		"--redraw-decor",
		nargs="+",
		metavar="NAME",
		help="regenerate decor props via PixelLab (tree, barrel, rock, wall)",
	)
	args = parser.parse_args()
	if args.balance:
		print(json.dumps(api("GET", "/balance"), indent=2))
		return
	if args.redraw_decor:
		redraw_decor(args.redraw_decor)
		return
	if args.rebuild_local:
		rebuild_local_atlas()
		return
	if args.target == "dungeon":
		run_dungeon(args.force)
	else:
		raise SystemExit(f"unknown target {args.target}")


if __name__ == "__main__":
	main()

#!/usr/bin/env python3
"""PixelLab top-down Wang tileset + decor props → assets/art/pixellab/dungeon/.

Usage:
  python3 scripts/art/pixellab_tileset_batch.py --balance
  python3 scripts/art/pixellab_tileset_batch.py dungeon
  python3 scripts/art/pixellab_tileset_batch.py dungeon --force
"""
import argparse
import base64
import json
import os
import struct
import time
import urllib.error
import urllib.request
import zlib

API_BASE = "https://api.pixellab.ai/v2"
WORKSPACE = "/workspace"
OUT_ROOT = f"{WORKSPACE}/assets/art/pixellab/dungeon"
TILES_DIR = f"{OUT_ROOT}/tiles"
GAME_TILE = 64
SRC_TILE = 32


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
	# Minimal PNG decoder (RGBA8, filter type 0 only paths) — fallback to empty
	if raw[:8] != b"\x89PNG\r\n\x1a\n":
		raise ValueError("not png")
	pos = 8
	w, h = 0, 0
	idata = b""
	while pos < len(raw):
		length = struct.unpack(">I", raw[pos:pos + 4])[0]
		chunk = raw[pos + 4:pos + 8]
		data = raw[pos + 8:pos + 8 + length]
		pos += 12 + length
		if chunk == b"IHDR":
			w, h = struct.unpack(">II", data[:8])
		elif chunk == b"IDAT":
			idata += data
		elif chunk == b"IEND":
			break
	if not idata:
		raise ValueError("no IDAT")
	decomp = zlib.decompress(idata)
	stride = w * 4 + 1
	pixels = []
	prev = [0] * (w * 4)
	for y in range(h):
		row_start = y * stride
		filter_type = decomp[row_start]
		row = list(decomp[row_start + 1:row_start + stride - 1 + 1][: w * 4])
		if filter_type == 0:
			cur = row
		elif filter_type == 1:
			cur = []
			for i, b in enumerate(row):
				left = cur[i - 4] if i >= 4 else 0
				cur.append((b + left) & 255)
		elif filter_type == 2:
			cur = [(row[i] + prev[i]) & 255 for i in range(len(row))]
		else:
			cur = row
		pixels.extend(cur)
		prev = cur
	return w, h, pixels


def scale_rgba(w: int, h: int, pixels: list, out_w: int, out_h: int) -> list:
	out = []
	for y in range(out_h):
		sy = int(y * h / out_h)
		for x in range(out_w):
			sx = int(x * w / out_w)
			i = (sy * w + sx) * 4
			out.extend(pixels[i:i + 4])
	return out


def write_png(path: str, w: int, h: int, rgba: list) -> None:
	def chunk(tag: bytes, data: bytes) -> bytes:
		crc = zlib.crc32(tag + data) & 0xffffffff
		return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", crc)

	raw_rows = []
	for y in range(h):
		row = bytes([0])
		start = y * w * 4
		for x in range(w * 4):
			row += bytes([rgba[start + x]])
		raw_rows.append(row)
	compressed = zlib.compress(b"".join(raw_rows), 9)
	ihdr = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)
	out = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", compressed) + chunk(b"IEND", b"")
	os.makedirs(os.path.dirname(path), exist_ok=True)
	with open(path, "wb") as f:
		f.write(out)


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
		"tree": "pixel art fantasy tree, top-down roguelike decor, green canopy brown trunk",
		"rock": "pixel art gray boulder rock, top-down field decor",
		"barrel": "pixel art wooden barrel, top-down roguelike prop",
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
		"tiles": exported,
		"decor_atlas": decor_atlas,
		"atlas_cols": 4,
		"atlas_rows": 5,
	}
	build_atlas(meta)
	json.dump(meta, open(f"{OUT_ROOT}/meta.json", "w"), indent=2)
	print(f"exported {len(exported)} wang tiles + {len(decor_atlas)} decor", flush=True)
	return meta


def build_atlas(meta: dict) -> None:
	cols = meta["atlas_cols"]
	rows = meta["atlas_rows"]
	tile = meta["game_tile_size"]
	w = cols * tile
	h = rows * tile
	canvas = [0, 0, 0, 0] * (w * h)

	for entry in meta["tiles"]:
		col, row = entry["atlas"]
		raw = open(f"{TILES_DIR}/{entry['id']}.png", "rb").read()
		sw, sh, px = decode_png_rgba(raw)
		scaled = scale_rgba(sw, sh, px, tile, tile)
		_blit(canvas, w, h, col * tile, row * tile, tile, tile, scaled)

	for name, (col, row) in meta.get("decor_atlas", {}).items():
		path = f"{OUT_ROOT}/decor_{name}.png"
		if not os.path.isfile(path):
			continue
		raw = open(path, "rb").read()
		dw, dh, px = decode_png_rgba(raw)
		scaled = scale_rgba(dw, dh, px, tile, tile)
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


def main() -> None:
	parser = argparse.ArgumentParser()
	parser.add_argument("target", nargs="?", default="dungeon")
	parser.add_argument("--force", action="store_true")
	parser.add_argument("--balance", action="store_true")
	args = parser.parse_args()
	if args.balance:
		print(json.dumps(api("GET", "/balance"), indent=2))
		return
	if args.target == "dungeon":
		run_dungeon(args.force)
	else:
		raise SystemExit(f"unknown target {args.target}")


if __name__ == "__main__":
	main()

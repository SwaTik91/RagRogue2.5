#!/usr/bin/env python3
"""PixelLab.ai batch: 4-dir character + idle/walk/attack animations → assets/art/anim/{actor}/.

Requires API token: https://pixellab.ai/account
  export PIXELLAB_API_KEY=...   OR   /cursor/stores/self/pixellab/api_key.txt

Docs: https://api.pixellab.ai/v2/docs
"""
import argparse
import base64
import json
import os
import sys
import time
import urllib.error
import urllib.request
import zipfile
from io import BytesIO

API_BASE = "https://api.pixellab.ai/v2"
WORKSPACE = "/workspace"
ANIM_ROOT = f"{WORKSPACE}/assets/art/anim"
META_ROOT = f"{WORKSPACE}/assets/art/pixellab"
GAME_ART = f"{WORKSPACE}/assets/art/game"

# PixelLab compass → RagRogue screen-facing folder names
DIR_MAP = {
	"south": "down",
	"north": "up",
	"east": "right",
	"west": "left",
}
# PixelLab breathing-idle north frames stack two sprites — animate/export south only.
ANIM_DIRECTIONS = ["south"]

# Mannequin ZIP folders (web UI) → game animation names
MANNEQUIN_ZIP_ANIM = {
	"Idle": "idle",
	"Walking": "walk",
	"Attacking_with_a_bow": "attack",
}
# create-character-with-4-directions ZIP layout
ZIP_ANIM_MAP = {
	"animating": "idle",
	"breathing-idle": "idle",
	"idle": "idle",
	"walking": "walk",
	"walk": "walk",
	"attack": "attack",
	"skill": "skill",
}
CARDINAL_DIRS = ("south", "north", "east", "west")

ACTOR_PROMPTS = {
	"archer": (
		"young fantasy archer, green hooded cloak, white hair, leather quiver on back, "
		"wooden recurve bow in left hand, white shirt and grey pants, brown boots, "
		"top-down roguelike hero, readable silhouette, 16-bit pixel art style"
	),
	"swordman": (
		"fantasy sword warrior, plate and leather armor, sword at side, "
		"top-down roguelike hero, 16-bit pixel art"
	),
	"mage": (
		"fantasy mage with staff and robes, magic glow, "
		"top-down roguelike hero, 16-bit pixel art"
	),
	"lunatic": (
		"ragnarok online lunatic monster, wild humanoid boy with messy brown hair, "
		"ragged clothes, angry expression, holding orange carrot, top-down roguelike enemy, "
		"high quality 16-bit pixel art, black outline, readable silhouette"
	),
	"drops": (
		"ragnarok online drops monster, ONE single floating brown jelly blob only, "
		"cute round face, small wings, solitary creature centered alone in frame, "
		"no duplicate, no second character, no pair, top-down roguelike enemy, "
		"high quality 16-bit pixel art, black outline"
	),
	"angel_mvp": (
		"ragnarok online angeling MVP boss, large fluffy white angel blob with golden halo, "
		"small wings, cute but powerful, top-down roguelike boss monster, "
		"high detail premium pixel art, black outline, imposing size"
	),
}

MOB_IMAGE_SIZE = {
	"lunatic": (96, 96),
	"drops": (128, 128),
	"angel_mvp": (128, 128),
}

MOB_ANIM_JOBS = {
	"lunatic": [
		{"id": "idle", "mode": "template", "template_animation_id": "breathing-idle"},
		{"id": "walk", "mode": "template", "template_animation_id": "walk"},
		{
			"id": "attack",
			"mode": "v3",
			"action_description": (
				"lunatic throws small orange carrot forward from right hand, "
				"quick wind-up and release toward camera, top-down roguelike attack"
			),
			"frame_count": 8,
		},
		{
			"id": "skill",
			"mode": "v3",
			"action_description": (
				"lunatic pulls out large carrot and hurls it forward with full body throw, "
				"dramatic wind-up, spitting projectile special attack"
			),
			"frame_count": 8,
		},
	],
	"drops": [
		{"id": "idle", "mode": "template", "template_animation_id": "breathing-idle"},
		{"id": "walk", "mode": "template", "template_animation_id": "walk"},
		{
			"id": "attack",
			"mode": "v3",
			"action_description": (
				"ONE single drops jelly monster spits one small red apple forward from mouth, "
				"solo creature centered, no duplicate bodies, top-down roguelike attack"
			),
			"frame_count": 8,
		},
		{
			"id": "skill",
			"mode": "v3",
			"action_description": (
				"ONE single drops monster opens mouth and spits apple forward, "
				"solo jelly blob only, no second creature, special spit attack"
			),
			"frame_count": 8,
		},
	],
	"angel_mvp": [
		{"id": "idle", "mode": "template", "template_animation_id": "breathing-idle"},
		{"id": "walk", "mode": "template", "template_animation_id": "walk"},
		{
			"id": "attack",
			"mode": "v3",
			"action_description": (
				"angeling boss fires holy light bolt forward from body glow, "
				"wings flare, gentle but powerful ranged attack"
			),
			"frame_count": 8,
		},
		{
			"id": "skill",
			"mode": "v3",
			"action_description": (
				"angeling MVP channels radiant healing light upward then smites with holy burst, "
				"boss special cast animation, wings spread wide"
			),
			"frame_count": 10,
		},
	],
}

ANIM_JOBS = [
	{
		"id": "idle",
		"mode": "template",
		"template_animation_id": "breathing-idle",
	},
	{
		"id": "walk",
		"mode": "template",
		"template_animation_id": "walk",
	},
	{
		"id": "attack",
		"mode": "v3",
		"action_description": (
			"archer draws bowstring back to cheek with right hand, holds tension, "
			"releases arrow forward, clear bow draw and follow-through, left hand holds bow"
		),
		"frame_count": 8,
	},
	{
		"id": "skill",
		"mode": "v3",
		"action_description": (
			"archer raises bow overhead and fires volley upward, dramatic special attack pose"
		),
		"frame_count": 8,
	},
]


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
	raise RuntimeError(
		"Missing PixelLab API key. Set PIXELLAB_API_KEY or create "
		"/cursor/stores/self/pixellab/api_key.txt (token from pixellab.ai/account)"
	)


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


def poll_job(job_id: str, label: str, max_wait: int = 900) -> dict:
	deadline = time.time() + max_wait
	while time.time() < deadline:
		status = api("GET", f"/background-jobs/{job_id}")
		state = str(status.get("status", "")).lower()
		print(f"  job {label}: {state}", flush=True)
		if state in ("completed", "succeeded", "success"):
			return status
		if state in ("failed", "error"):
			raise RuntimeError(f"Job {job_id} failed: {status}")
		time.sleep(8)
	raise TimeoutError(f"Job {job_id} timed out")


def b64_image(path: str) -> dict:
	with open(path, "rb") as f:
		raw = base64.b64encode(f.read()).decode()
	return {"type": "base64", "base64": raw, "format": "png"}


def _decode_b64(b64: str) -> bytes:
	if "," in b64[:80]:
		b64 = b64.split(",", 1)[1]
	return base64.b64decode(b64)


def preferred_ref_image(actor: str) -> str | None:
	anim_ref = f"{ANIM_ROOT}/{actor}/down/idle/frame_00.png"
	if os.path.isfile(anim_ref):
		return anim_ref
	ref = f"{GAME_ART}/{actor}-idle.png"
	if os.path.isfile(ref):
		return ref
	portrait = f"{GAME_ART}/{actor}.png"
	if os.path.isfile(portrait):
		return portrait
	return None


def create_character(actor: str, ref_image: str | None, force: bool = False) -> str:
	meta_path = f"{META_ROOT}/{actor}/meta.json"
	if not force and os.path.isfile(meta_path):
		meta = json.load(open(meta_path))
		cid = meta.get("character_id")
		if cid:
			detail = api("GET", f"/characters/{cid}")
			if detail.get("status") == "completed":
				print(f"reuse character {cid}", flush=True)
				return cid
	body = {
		"description": ACTOR_PROMPTS.get(actor, f"top-down roguelike {actor}"),
		"view": "low top-down",
		"outline": "single color black outline",
		"shading": "medium shading",
		"detail": "medium detail",
		"text_guidance_scale": 8.0,
	}
	w, h = MOB_IMAGE_SIZE.get(actor, (96, 96))
	body["image_size"] = {"width": w, "height": h}
	if ref_image and os.path.isfile(ref_image):
		body["color_image"] = b64_image(ref_image)
		body["force_colors"] = False
	print("create-character-with-4-directions...", flush=True)
	resp = api("POST", "/create-character-with-4-directions", body)
	cid = resp["character_id"]
	job_id = resp["background_job_id"]
	poll_job(job_id, "character")
	os.makedirs(f"{META_ROOT}/{actor}", exist_ok=True)
	json.dump(
		{
			"character_id": cid,
			"background_job_id": job_id,
			"actor": actor,
		},
		open(meta_path, "w"),
		indent=2,
	)
	return cid


def wait_character_ready(character_id: str) -> dict:
	for _ in range(120):
		detail = api("GET", f"/characters/{character_id}")
		if detail.get("status") == "completed" and detail.get("rotation_urls"):
			return detail
		if detail.get("status") == "failed":
			raise RuntimeError(f"Character failed: {detail}")
		time.sleep(5)
	raise TimeoutError("character not ready")


def request_animation(character_id: str, job: dict) -> list[str]:
	body = {
		"character_id": character_id,
		"animation_name": job["id"],
		"directions": ANIM_DIRECTIONS,
		"async_mode": True,
	}
	if job.get("mode") == "template":
		body["mode"] = "template"
		body["template_animation_id"] = job["template_animation_id"]
	else:
		body["mode"] = "v3"
		body["action_description"] = job["action_description"]
		body["frame_count"] = job.get("frame_count", 8)
	print(f"animate {job['id']} ({job.get('mode', 'v3')})...", flush=True)
	resp = api("POST", "/animate-character", body)
	job_ids = resp.get("background_job_ids", [])
	for i, jid in enumerate(job_ids):
		poll_job(jid, f"{job['id']}/{resp.get('directions', [i])[i] if i < len(resp.get('directions', [])) else i}")
	return job_ids


def download(url: str, dest: str) -> None:
	os.makedirs(os.path.dirname(dest), exist_ok=True)
	urllib.request.urlretrieve(url, dest)


def fetch_character_zip(character_id: str) -> bytes:
	key = load_api_key()
	zip_url = f"{API_BASE}/characters/{character_id}/zip"
	req = urllib.request.Request(
		zip_url,
		headers={"Authorization": f"Bearer {key}"},
	)
	with urllib.request.urlopen(req, timeout=300) as resp:
		return resp.read()


def export_frames_from_zip(actor: str, character_id: str, zdata: bytes) -> int:
	zf = zipfile.ZipFile(BytesIO(zdata))
	imported = 0
	for inner in zf.namelist():
		if "/animations/" not in inner or not inner.endswith(".png"):
			continue
		parts = inner.split("/")
		try:
			anim_idx = parts.index("animations")
			pl_anim = parts[anim_idx + 1]
			pl_dir_raw = parts[anim_idx + 2]
			pl_dir = pl_dir_raw.split("-")[0]
			fname = parts[anim_idx + 3]
		except (ValueError, IndexError):
			continue
		game_anim = ZIP_ANIM_MAP.get(pl_anim.lower())
		if not game_anim:
			game_anim = _map_anim_name(pl_anim)
		if not game_anim or game_anim == "idle":
			continue
		if pl_dir not in ANIM_DIRECTIONS:
			continue
		game_dir = DIR_MAP.get(pl_dir, pl_dir)
		if not fname.startswith("frame_"):
			continue
		frame_num = int(fname.replace("frame_", "").replace(".png", ""))
		folder = f"{ANIM_ROOT}/{actor}/{game_dir}/{game_anim}"
		os.makedirs(folder, exist_ok=True)
		dest = f"{folder}/frame_{frame_num:02d}.png"
		with open(dest, "wb") as out:
			out.write(zf.read(inner))
		imported += 1
	print(f"  zip export: {imported} frames", flush=True)
	return imported


def export_frames(actor: str, character_id: str) -> None:
	detail = wait_character_ready(character_id)
	animations = detail.get("animations", [])
	if animations:
		try:
			exported = 0
			for group in animations:
				anim_type = str(group.get("animation_type", "")).lower()
				display = str(group.get("display_name", "")).lower()
				game_anim = _map_anim_name(display) or _map_anim_name(anim_type)
				if not game_anim or game_anim == "idle":
					continue
				for dir_entry in group.get("directions", []):
					pl_dir = str(dir_entry.get("direction", ""))
					if pl_dir not in ANIM_DIRECTIONS:
						continue
					game_dir = DIR_MAP.get(pl_dir, pl_dir)
					frames = dir_entry.get("frames", [])
					folder = f"{ANIM_ROOT}/{actor}/{game_dir}/{game_anim}"
					os.makedirs(folder, exist_ok=True)
					for old in os.listdir(folder):
						if old.startswith("frame_") and (
							old.endswith(".png") or old.endswith(".webp")
						):
							os.remove(os.path.join(folder, old))
					for i, url in enumerate(frames):
						dest = f"{folder}/frame_{i:02d}.png"
						download(url, dest)
						exported += 1
					print(f"  {game_anim}/{game_dir}: {len(frames)} frames", flush=True)
			if exported > 0:
				return
		except urllib.error.HTTPError as exc:
			print(f"frame URL download failed ({exc.code}), using ZIP export...", flush=True)
	print("export via character ZIP...", flush=True)
	zdata = fetch_character_zip(character_id)
	out_zip = f"{META_ROOT}/{actor}/export.zip"
	os.makedirs(os.path.dirname(out_zip), exist_ok=True)
	with open(out_zip, "wb") as f:
		f.write(zdata)
	for game_dir in ("down", "up", "left", "right"):
		for game_anim in ("walk", "attack", "skill"):
			folder = f"{ANIM_ROOT}/{actor}/{game_dir}/{game_anim}"
			if os.path.isdir(folder):
				for old in os.listdir(folder):
					if old.startswith("frame_") and (
						old.endswith(".png") or old.endswith(".webp")
					):
						os.remove(os.path.join(folder, old))
	export_frames_from_zip(actor, character_id, zdata)


def _map_anim_name(pl_type: str) -> str | None:
	aliases = {
		"breathing-idle": "idle",
		"idle": "idle",
		"walk": "walk",
		"walking": "walk",
		"attack": "attack",
		"bow": "attack",
		"shoot": "attack",
	}
	for key, val in aliases.items():
		if key in pl_type:
			return val
	if pl_type in ("idle", "walk", "attack", "skill"):
		return pl_type
	return None


def import_mannequin_zip(character_id: str, actor: str, copy_skill_from_attack: bool = True) -> None:
	"""Import static 4-dir rotations from a PixelLab mannequin group ZIP (no new generations)."""
	key = load_api_key()
	zip_url = f"{API_BASE}/characters/{character_id}/zip"
	req = urllib.request.Request(
		zip_url,
		headers={"Authorization": f"Bearer {key}"},
	)
	print(f"download ZIP for {character_id}...", flush=True)
	with urllib.request.urlopen(req, timeout=300) as resp:
		zdata = resp.read()
	out_zip = f"{META_ROOT}/{actor}/import.zip"
	os.makedirs(os.path.dirname(out_zip), exist_ok=True)
	with open(out_zip, "wb") as f:
		f.write(zdata)
	zf = zipfile.ZipFile(BytesIO(zdata))
	imported = 0
	for zip_anim, game_anim in MANNEQUIN_ZIP_ANIM.items():
		for pl_dir in CARDINAL_DIRS:
			game_dir = DIR_MAP[pl_dir]
			inner = f"{zip_anim}/rotations/{pl_dir}.png"
			if inner not in zf.namelist():
				print(f"  skip missing {inner}", flush=True)
				continue
			folder = f"{ANIM_ROOT}/{actor}/{game_dir}/{game_anim}"
			os.makedirs(folder, exist_ok=True)
			dest = f"{folder}/frame_00.png"
			with open(dest, "wb") as out:
				out.write(zf.read(inner))
			imported += 1
			print(f"  {game_anim}/{game_dir}", flush=True)
	if copy_skill_from_attack:
		for pl_dir in CARDINAL_DIRS:
			game_dir = DIR_MAP[pl_dir]
			src = f"{ANIM_ROOT}/{actor}/{game_dir}/attack/frame_00.png"
			dst_folder = f"{ANIM_ROOT}/{actor}/{game_dir}/skill"
			if os.path.isfile(src):
				os.makedirs(dst_folder, exist_ok=True)
				with open(src, "rb") as s, open(f"{dst_folder}/frame_00.png", "wb") as d:
					d.write(s.read())
	json.dump(
		{
			"source": "mannequin_zip",
			"character_id": character_id,
			"actor": actor,
			"imported_rotations": imported,
			"note": "static single-frame per direction; run full batch when generations available",
		},
		open(f"{META_ROOT}/{actor}/meta.json", "w"),
		indent=2,
	)
	print(f"imported {imported} rotations → {ANIM_ROOT}/{actor}/", flush=True)


def find_character_by_tag(tag: str) -> str | None:
	tag_l = tag.strip().lower()
	resp = api("GET", "/characters?limit=100")
	for ch in resp.get("characters", []):
		if ch.get("status") != "completed":
			continue
		tags = ch.get("tags", []) or []
		if any(str(t).lower() == tag_l for t in tags):
			return ch["id"]
	return None


MANNEQUIN_STATE_ANIM_PREFIX = {
	"breath_idle": "idle",
	"breathing-idle": "idle",
	"the_purple_slime": "walk",
	"walking": "walk",
	"walk": "walk",
	"a_ranged_attack": "skill",
	"attack": "attack",
}


def _map_mannequin_anim_folder(folder_name: str) -> str | None:
	low = folder_name.lower().replace("-", "_")
	if "taking_punch" in low or "taking-punch" in low:
		return None
	for prefix, game_anim in MANNEQUIN_STATE_ANIM_PREFIX.items():
		if low.startswith(prefix) or prefix in low:
			return game_anim
	return None


def import_mannequin_state_zip(
	character_id: str,
	actor: str,
	state_folder: str = "Idle",
	copy_attack_from_skill: bool = True,
) -> None:
	"""Import mannequin ZIP with animations/* (PixelLab web UI Drops2 layout)."""
	key = load_api_key()
	zip_url = f"{API_BASE}/characters/{character_id}/zip"
	req = urllib.request.Request(zip_url, headers={"Authorization": f"Bearer {key}"})
	print(f"download ZIP for {character_id}...", flush=True)
	with urllib.request.urlopen(req, timeout=300) as resp:
		zdata = resp.read()
	out_zip = f"{META_ROOT}/{actor}/import.zip"
	os.makedirs(os.path.dirname(out_zip), exist_ok=True)
	with open(out_zip, "wb") as f:
		f.write(zdata)
	zf = zipfile.ZipFile(BytesIO(zdata))
	imported = 0
	prefix = f"{state_folder}/animations/"
	for inner in zf.namelist():
		if not inner.startswith(prefix) or not inner.endswith(".png"):
			continue
		parts = inner.split("/")
		try:
			anim_idx = parts.index("animations")
			pl_anim_folder = parts[anim_idx + 1]
			pl_dir_raw = parts[anim_idx + 2]
			fname = parts[anim_idx + 3]
		except (ValueError, IndexError):
			continue
		game_anim = _map_mannequin_anim_folder(pl_anim_folder)
		if not game_anim:
			continue
		pl_dir = pl_dir_raw.split("-")[0]
		if pl_dir not in DIR_MAP:
			continue
		game_dir = DIR_MAP[pl_dir]
		if not fname.startswith("frame_"):
			continue
		frame_num = int(fname.replace("frame_", "").replace(".png", ""))
		folder = f"{ANIM_ROOT}/{actor}/{game_dir}/{game_anim}"
		os.makedirs(folder, exist_ok=True)
		dest = f"{folder}/frame_{frame_num:02d}.png"
		with open(dest, "wb") as out:
			out.write(zf.read(inner))
		imported += 1
	# per-folder frame counts
	for game_dir in ("down", "up", "left", "right"):
		for game_anim in ("idle", "walk", "skill"):
			folder = f"{ANIM_ROOT}/{actor}/{game_dir}/{game_anim}"
			if os.path.isdir(folder):
				frames = sorted(
					f for f in os.listdir(folder)
					if f.startswith("frame_") and f.endswith(".png")
				)
				if frames:
					print(f"  {game_anim}/{game_dir}: {len(frames)} frames", flush=True)
	if copy_attack_from_skill:
		for game_dir in ("down", "up", "left", "right"):
			skill_dir = f"{ANIM_ROOT}/{actor}/{game_dir}/skill"
			attack_dir = f"{ANIM_ROOT}/{actor}/{game_dir}/attack"
			if not os.path.isdir(skill_dir):
				continue
			os.makedirs(attack_dir, exist_ok=True)
			for fname in os.listdir(skill_dir):
				if fname.startswith("frame_") and fname.endswith(".png"):
					with open(
						os.path.join(skill_dir, fname), "rb"
					) as s, open(os.path.join(attack_dir, fname), "wb") as d:
						d.write(s.read())
	json.dump(
		{
			"source": "mannequin_state_zip",
			"character_id": character_id,
			"actor": actor,
			"state_folder": state_folder,
			"imported_frames": imported,
		},
		open(f"{META_ROOT}/{actor}/meta.json", "w"),
		indent=2,
	)
	_copy_idle_portrait(actor)
	print(f"imported {imported} frames → {ANIM_ROOT}/{actor}/", flush=True)


def import_by_tag(tag: str, actor: str) -> None:
	cid = find_character_by_tag(tag)
	if not cid:
		raise RuntimeError(f"no completed character with tag {tag!r}")
	print(f"import tag {tag} → {actor} ({cid})", flush=True)
	import_mannequin_state_zip(cid, actor)
	write_preview_sheet(actor)


def find_mannequin_character_id(actor: str) -> str | None:
	"""Pick a completed mannequin character from the account (Walking state preferred for ZIP bundle)."""
	resp = api("GET", "/characters?limit=50")
	for ch in resp.get("characters", []):
		if ch.get("status") != "completed":
			continue
		if ch.get("template_id") != "mannequin":
			continue
		state = str(ch.get("state_name", "")).lower()
		if actor == "archer" and "sniper" in str(ch.get("prompt", "")).lower():
			if "walking" in state:
				return ch["id"]
	for ch in resp.get("characters", []):
		if ch.get("status") == "completed" and ch.get("template_id") == "mannequin":
			return ch["id"]
	return None


PHASE_ORDER = ("idle", "walk", "attack", "skill")


def anim_jobs_for(actor: str) -> list:
	if actor in MOB_ANIM_JOBS:
		return MOB_ANIM_JOBS[actor]
	if actor == "archer":
		return ANIM_JOBS
	return [
		{"id": "idle", "mode": "template", "template_animation_id": "breathing-idle"},
		{"id": "walk", "mode": "template", "template_animation_id": "walk"},
		{"id": "attack", "mode": "template", "template_animation_id": "attack"},
	]


def create_pixflux_image(description: str, width: int, height: int) -> bytes:
	print(f"pixflux {width}x{height}...", flush=True)
	resp = api(
		"POST",
		"/create-image-pixflux",
		{
			"description": description,
			"image_size": {"width": width, "height": height},
			"no_background": True,
			"view": "low top-down",
			"outline": "single color black outline",
			"shading": "medium shading",
			"detail": "medium detail",
		},
		timeout=180,
	)
	b64 = resp.get("image", {}).get("base64")
	if not b64:
		raise RuntimeError("pixflux returned no image")
	return _decode_b64(b64)


def rotate_from_south(
	from_png: bytes,
	to_direction: str,
	width: int,
	height: int,
) -> bytes:
	print(f"rotate south→{to_direction}...", flush=True)
	resp = api(
		"POST",
		"/rotate",
		{
			"from_image": {
				"type": "base64",
				"base64": base64.b64encode(from_png).decode(),
				"format": "png",
			},
			"image_size": {"width": width, "height": height},
			"from_view": "low top-down",
			"to_view": "low top-down",
			"from_direction": "south",
			"to_direction": to_direction,
			"image_guidance_scale": 8.0,
		},
		timeout=180,
	)
	b64 = resp.get("image", {}).get("base64")
	if not b64:
		raise RuntimeError(f"rotate to {to_direction} returned no image")
	return _decode_b64(b64)


IDLE_ROTATE_DIRS = {
	"down": None,
	"up": "north",
	"right": "east",
	"left": "west",
}


def run_idle_pixflux(actor: str) -> None:
	"""South pixflux still + rotate API for other dirs — avoids twin sprites."""
	base = ACTOR_PROMPTS.get(actor, f"top-down roguelike {actor}")
	w, h = MOB_IMAGE_SIZE.get(actor, (96, 96))
	south_desc = (
		f"{base}, front view facing south toward camera, "
		"ONE single creature alone centered in frame, no duplicate, no pair"
	)
	south_png = create_pixflux_image(south_desc, w, h)
	for game_dir, pl_dir in IDLE_ROTATE_DIRS.items():
		if pl_dir is None:
			raw = south_png
		else:
			raw = rotate_from_south(south_png, pl_dir, w, h)
		folder = f"{ANIM_ROOT}/{actor}/{game_dir}/idle"
		os.makedirs(folder, exist_ok=True)
		dest = f"{folder}/frame_00.png"
		with open(dest, "wb") as f:
			f.write(raw)
		for i in range(1, 4):
			with open(f"{folder}/frame_{i:02d}.png", "wb") as out:
				out.write(raw)
		print(f"  idle/{game_dir}", flush=True)
	_copy_idle_portrait(actor)
	print(
		f"IDLE PIXFLUX READY — review assets/art/anim/{actor}/ then "
		f"python3 scripts/art/pixellab_batch.py {actor} --phase rest",
		flush=True,
	)


def write_preview_sheet(actor: str) -> str:
	"""4-dir idle + down walk/attack/skill contact sheet for quick review."""
	try:
		from PIL import Image, ImageDraw, ImageFont
	except ImportError:
		print("preview skipped (install Pillow)", flush=True)
		return ""
	rows: list[tuple[str, list[str]]] = []
	for game_dir in ("down", "up", "left", "right"):
		idle = f"{ANIM_ROOT}/{actor}/{game_dir}/idle/frame_00.png"
		if os.path.isfile(idle):
			rows.append((f"idle {game_dir}", [idle]))
	for anim in ("walk", "attack", "skill"):
		folder = f"{ANIM_ROOT}/{actor}/down/{anim}"
		if not os.path.isdir(folder):
			continue
		paths = sorted(
			[
				os.path.join(folder, f)
				for f in os.listdir(folder)
				if f.startswith("frame_") and f.endswith(".png")
			]
		)
		if paths:
			rows.append((f"{anim} down", paths[:8]))
	if not rows:
		return ""
	cell = 128
	pad = 8
	label_h = 22
	row_h = cell + label_h + pad
	w = max(len(p) for _, p in rows) * (cell + pad) + pad
	h = len(rows) * row_h + pad
	sheet = Image.new("RGBA", (w, h), (32, 32, 40, 255))
	draw = ImageDraw.Draw(sheet)
	y = pad
	for label, paths in rows:
		draw.text((pad, y), label, fill=(220, 220, 220))
		y += label_h
		x = pad
		for path in paths:
			img = Image.open(path).convert("RGBA")
			img.thumbnail((cell, cell), Image.Resampling.NEAREST)
			ox = x + (cell - img.width) // 2
			oy = y + (cell - img.height) // 2
			sheet.paste(img, (ox, oy), img)
			x += cell + pad
		y += cell + pad
	out_dir = f"{META_ROOT}/{actor}"
	os.makedirs(out_dir, exist_ok=True)
	out = f"{out_dir}/preview_sheet.png"
	sheet.save(out, format="PNG")
	print(f"preview → {out}", flush=True)
	return out


def run_full_pixflux(actor: str) -> None:
	"""Idle pixflux+rotate, then walk/attack/skill (south) with fresh character ref."""
	run_idle_pixflux(actor)
	write_preview_sheet(actor)
	run_actor(actor, force=True, phase="rest")
	write_preview_sheet(actor)
	print(f"FULL PIXFLUX DONE — {META_ROOT}/{actor}/preview_sheet.png", flush=True)


def jobs_for_phase(actor: str, phase: str) -> list:
	jobs = anim_jobs_for(actor)
	if phase == "all":
		return jobs
	if phase == "rest":
		return [j for j in jobs if str(j.get("id", "")) != "idle"]
	if phase in PHASE_ORDER:
		return [j for j in jobs if str(j.get("id", "")) == phase]
	raise SystemExit(f"unknown phase {phase!r}; use idle|idle-pixflux|walk|attack|skill|rest|all")


def run_actor(actor: str, force: bool = False, phase: str = "all") -> None:
	if phase in ("idle", "idle-pixflux"):
		run_idle_pixflux(actor)
		write_preview_sheet(actor)
		return
	ref = preferred_ref_image(actor)
	meta_path = f"{META_ROOT}/{actor}/meta.json"
	cid = None
	if not force and os.path.isfile(meta_path):
		cid = json.load(open(meta_path)).get("character_id")
	needs_character = phase in ("all", "rest", "walk", "attack", "skill") and not cid
	if needs_character or (force and phase == "rest"):
		if force or not cid:
			cid = create_character(actor, ref, force=force)
	elif cid is None:
		raise SystemExit(
			f"no character_id in {meta_path}; run --phase idle first (or --force)"
		)
	jobs = jobs_for_phase(actor, phase)
	if not jobs:
		raise SystemExit(f"no animation jobs for actor={actor} phase={phase}")
	for job in jobs:
		request_animation(cid, job)
	export_frames(actor, cid)
	if phase in ("all", "rest"):
		_copy_idle_portrait(actor)
	print(f"done {actor} phase={phase}", flush=True)


def _copy_idle_portrait(actor: str) -> None:
	src = f"{ANIM_ROOT}/{actor}/down/idle/frame_00.png"
	if not os.path.isfile(src):
		return
	name_map = {
		"angel_mvp": "angel-mvp.png",
		"lunatic": "lunatic.png",
		"drops": "drops.png",
	}
	dst_name = name_map.get(actor, f"{actor}.png")
	dst = f"{GAME_ART}/{dst_name}"
	os.makedirs(GAME_ART, exist_ok=True)
	with open(src, "rb") as s, open(dst, "wb") as d:
		d.write(s.read())
	print(f"  portrait → {dst}", flush=True)


def main() -> None:
	parser = argparse.ArgumentParser(description="PixelLab 4-dir character + anims")
	parser.add_argument("actor", nargs="?", default="archer", help="archer|lunatic|drops|angel_mvp|...")
	parser.add_argument("--force", action="store_true", help="recreate character")
	parser.add_argument("--balance", action="store_true", help="print API balance only")
	parser.add_argument(
		"--import-existing",
		action="store_true",
		help="import completed mannequin ZIP from account (no generations used)",
	)
	parser.add_argument(
		"--import-tag",
		default="",
		help="import completed mannequin character by PixelLab tag (e.g. Drops2)",
	)
	parser.add_argument(
		"--character-id",
		default="",
		help="PixelLab character id for --import-existing ZIP download",
	)
	parser.add_argument(
		"--phase",
		default="all",
		choices=["idle", "idle-pixflux", "full-pixflux", "walk", "attack", "skill", "rest", "all"],
		help=(
			"idle / idle-pixflux: 4-dir pixflux+rotate idle + preview_sheet; "
			"full-pixflux: idle + walk/attack/skill; rest: anims only (needs idle)"
		),
	)
	args = parser.parse_args()
	if args.balance:
		print(json.dumps(api("GET", "/balance"), indent=2))
		return
	if args.import_existing:
		cid = args.character_id.strip()
		if not cid:
			cid = find_mannequin_character_id(args.actor)
		if not cid:
			raise RuntimeError("no completed mannequin character found on account")
		import_mannequin_zip(cid, args.actor)
		return
	if args.import_tag.strip():
		import_by_tag(args.import_tag.strip(), args.actor)
		return
	_dispatch(args.actor, force=args.force, phase=args.phase)


def _dispatch(actor: str, force: bool, phase: str) -> None:
	if phase == "full-pixflux":
		run_full_pixflux(actor)
		return
	run_actor(actor, force=force, phase=phase)


if __name__ == "__main__":
	main()

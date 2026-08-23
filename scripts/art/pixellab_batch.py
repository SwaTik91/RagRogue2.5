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
ALL_DIRS = list(DIR_MAP.keys())

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
	path = "/cursor/stores/self/pixellab/api_key.txt"
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
	return {"base64": raw, "mime_type": "image/png"}


def create_character(actor: str, ref_image: str | None) -> str:
	meta_path = f"{META_ROOT}/{actor}/meta.json"
	if os.path.isfile(meta_path):
		meta = json.load(open(meta_path))
		cid = meta.get("character_id")
		if cid:
			detail = api("GET", f"/characters/{cid}")
			if detail.get("status") == "completed":
				print(f"reuse character {cid}", flush=True)
				return cid
	body = {
		"description": ACTOR_PROMPTS.get(actor, f"top-down roguelike {actor}"),
		"image_size": {"width": 96, "height": 96},
		"view": "low top-down",
		"outline": "single color black outline",
		"shading": "medium shading",
		"detail": "medium detail",
		"text_guidance_scale": 8.0,
	}
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
		"directions": ALL_DIRS,
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


def export_frames(actor: str, character_id: str) -> None:
	detail = wait_character_ready(character_id)
	animations = detail.get("animations", [])
	if not animations:
		# Fallback: download ZIP export
		print("no animations in API response, trying ZIP export...", flush=True)
		zip_url = f"{API_BASE}/characters/{character_id}/zip"
		key = load_api_key()
		req = urllib.request.Request(
			zip_url,
			headers={"Authorization": f"Bearer {key}"},
		)
		with urllib.request.urlopen(req, timeout=300) as resp:
			zdata = resp.read()
		zf = zipfile.ZipFile(BytesIO(zdata))
		out_zip = f"{META_ROOT}/{actor}/export.zip"
		os.makedirs(os.path.dirname(out_zip), exist_ok=True)
		with open(out_zip, "wb") as f:
			f.write(zdata)
		print(f"saved zip {out_zip} — unpack manually if needed", flush=True)
		return
	for group in animations:
		anim_type = str(group.get("animation_type", "")).lower()
		game_anim = _map_anim_name(anim_type)
		if not game_anim:
			continue
		for dir_entry in group.get("directions", []):
			pl_dir = str(dir_entry.get("direction", ""))
			game_dir = DIR_MAP.get(pl_dir, pl_dir)
			frames = dir_entry.get("frames", [])
			folder = f"{ANIM_ROOT}/{actor}/{game_dir}/{game_anim}"
			os.makedirs(folder, exist_ok=True)
			for i, url in enumerate(frames):
				ext = ".png"
				dest = f"{folder}/frame_{i:02d}.png"
				download(url, dest)
			print(f"  {game_anim}/{game_dir}: {len(frames)} frames", flush=True)


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


def run_actor(actor: str, force: bool = False) -> None:
	ref = f"{GAME_ART}/{actor}-idle.png"
	if not os.path.isfile(ref):
		ref = None
	meta_path = f"{META_ROOT}/{actor}/meta.json"
	cid = None
	if not force and os.path.isfile(meta_path):
		cid = json.load(open(meta_path)).get("character_id")
	if not cid:
		cid = create_character(actor, ref)
	for job in ANIM_JOBS:
		if actor != "archer" and job["id"] in ("skill",):
			if "archer" not in job.get("action_description", ""):
				pass
		# Only archer-specific attack prompts for archer actor
		if actor != "archer" and job["id"] in ("attack", "skill"):
			job = dict(job)
			if job["id"] == "attack":
				job["mode"] = "template"
				job["template_animation_id"] = "attack"
				job.pop("action_description", None)
			else:
				continue
		request_animation(cid, job)
	export_frames(actor, cid)
	print(f"done {actor}", flush=True)


def main() -> None:
	parser = argparse.ArgumentParser(description="PixelLab 4-dir character + anims")
	parser.add_argument("actor", nargs="?", default="archer", help="archer|swordman|mage")
	parser.add_argument("--force", action="store_true", help="recreate character")
	parser.add_argument("--balance", action="store_true", help="print API balance only")
	args = parser.parse_args()
	if args.balance:
		print(json.dumps(api("GET", "/balance"), indent=2))
		return
	run_actor(args.actor, force=args.force)


if __name__ == "__main__":
	main()

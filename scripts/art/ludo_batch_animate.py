#!/usr/bin/env python3
"""Batch Ludo animateSprite for RagRogue actors."""
import argparse
import base64
import json
import mimetypes
import os
import shutil
import sys
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed

API_KEY = open("/cursor/stores/self/ludo/api_key.txt").read().strip()
MCP_URL = "https://mcp.ludo.ai/mcp"
WORKSPACE = "/workspace"
ROOT = f"{WORKSPACE}/assets/art/anim"
GAME_ART = f"{WORKSPACE}/assets/art/game"

# Ludo accepts 4, 9, 16, 25, 36, 49, 64 — use 16 (closest to requested 12).
FRAMES = 16
FRAME_SIZE = 384
DURATION = 3
MODEL = "forge"


def mcp_call(tool: str, request_body: dict, retries: int = 3) -> dict:
    last_err: Exception | None = None
    for attempt in range(retries):
        try:
            payload = {
                "jsonrpc": "2.0",
                "id": int(time.time() * 1000) % 1000000,
                "method": "tools/call",
                "params": {"name": tool, "arguments": {"requestBody": request_body}},
            }
            req = urllib.request.Request(
                MCP_URL,
                data=json.dumps(payload).encode(),
                headers={
                    "Authorization": f"ApiKey {API_KEY}",
                    "Content-Type": "application/json",
                },
                method="POST",
            )
            with urllib.request.urlopen(req, timeout=600) as resp:
                raw = json.loads(resp.read().decode())
            content = raw.get("result", {}).get("content", [])
            texts = [c.get("text", "") for c in content if c.get("type") == "text"]
            merged = "\n".join(texts)
            if "API Error" in merged:
                raise RuntimeError(merged[:800])
            start = merged.find("{")
            if start >= 0:
                return json.loads(merged[start:])
            raise RuntimeError(merged[:500])
        except Exception as exc:
            last_err = exc
            if attempt + 1 < retries:
                wait = 4 * (2**attempt)
                print(f"retry {attempt + 1}/{retries - 1} after error: {exc}", flush=True)
                time.sleep(wait)
    raise last_err  # type: ignore[misc]


def local_image_uri(path: str) -> str:
    """Encode a workspace image as a data URI for Ludo initial_image."""
    abs_path = path if os.path.isabs(path) else os.path.join(WORKSPACE, path)
    mime, _ = mimetypes.guess_type(abs_path)
    mime = mime or "image/png"
    with open(abs_path, "rb") as f:
        encoded = base64.b64encode(f.read()).decode()
    return f"data:{mime};base64,{encoded}"


def download(url: str, dest: str) -> None:
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    ext = ".webp" if ".webp" in url.split("?")[0] else ".png"
    if not dest.endswith(ext):
        dest = os.path.splitext(dest)[0] + ext
    urllib.request.urlretrieve(url, dest)


DIR_FACING = {
    "down": (
        "facing south toward camera, front of body visible, moves toward bottom of screen"
    ),
    "up": (
        "facing north away from camera, back of body visible, moves toward top of screen"
    ),
    "right": (
        "facing east, right side profile, body oriented to the right, moves right on screen"
    ),
    "left": (
        "facing west, left side profile, body oriented to the left, moves left on screen"
    ),
}


def motion_prompt(actor: str, anim: str, facing: str) -> str:
    """Per-actor animation + explicit screen-facing direction (top-down 4-way)."""
    facing_line = DIR_FACING.get(facing, "")
    base_prompts: dict[str, dict[str, str]] = {
        "swordman": {
            "idle": (
                "idle breathing loop, subtle chest rise and fall, slight weight shift between legs, "
                "sword arm relaxed at side with tiny bob, cape flutter, top-down roguelike warrior"
            ),
            "walk": (
                "walking cycle, left leg steps forward while right leg pushes back then alternates, "
                "clear alternating footfalls, hips sway side to side, free arm swings opposite to legs, "
                "sword arm bobs with gait, smooth seamless loop, top-down roguelike fantasy warrior"
            ),
            "attack": (
                "sword slash attack, wind-up raising sword overhead, powerful horizontal slash with "
                "extended sword arm sweeping arc, torso rotates into strike, follow-through, "
                "legs brace and shift weight, top-down melee combat"
            ),
            "skill": (
                "special spinning slash skill, crouch wind-up, explosive 360-degree sword whirl, "
                "both arms extend sword in wide arc, dramatic power move, legs pivot, top-down warrior"
            ),
        },
        "mage": {
            "idle": (
                "idle breathing loop, staff held upright, subtle robe and hair flutter, "
                "magic orb faint pulse on staff tip, gentle weight shift, top-down roguelike mage"
            ),
            "walk": (
                "walking cycle, robes flow with motion, staff held in one hand, alternating legs "
                "stepping forward and back, clear footfalls, arms sway, seamless loop, top-down mage"
            ),
            "attack": (
                "staff magic bolt attack, raise staff, cast forward with extended arm, "
                "magic projectile release from staff tip, torso leans into cast, top-down spell combat"
            ),
            "skill": (
                "area explosion spell, staff raised high, both hands channel magic, "
                "ground burst radiates outward, dramatic spell casting pose, top-down mage skill"
            ),
        },
        "archer": {
            "idle": (
                "idle breathing loop, bow held at rest, quiver slight sway, subtle leg weight shift, "
                "cloak flutter, top-down roguelike archer"
            ),
            "walk": (
                "walking cycle, bow held in one hand, alternating legs stepping, clear footfalls, "
                "free arm swings, quiver bounces, seamless loop, top-down archer"
            ),
            "attack": (
                "bow shoot attack, draw bowstring back with both arms, aim and release arrow forward, "
                "elbow extends on release, legs brace, top-down ranged combat"
            ),
            "skill": (
                "multi-arrow rain skill, draw bow overhead, rapid volley release upward, "
                "arrows fan out, dramatic pose, top-down archer special"
            ),
        },
        "cave_slime": {
            "idle": "slime monster idle wobble, body squashes and stretches, top-down",
            "walk": "slime hop walk cycle, body compresses then launches forward, alternating hops",
            "attack": "slime lunge attack, body stretches forward then snaps back, blob strike",
        },
        "stone_beetle": {
            "idle": "beetle monster idle, shell subtle shift, legs twitch, top-down",
            "walk": "beetle scuttle walk, six legs alternate in ripple pattern, shell steady",
            "attack": "beetle charge attack, legs dig in then lunge forward with horn",
        },
        "vault_warden": {
            "idle": "boss warden idle, heavy breathing, armor gleam, imposing stance, top-down",
            "walk": "boss warden stomping walk, heavy alternating steps, weapon drags",
            "attack": "boss warden heavy weapon slam, wind-up overhead, crushing downward strike",
        },
    }
    base = base_prompts.get(actor, {}).get(
        anim,
        f"{anim} animation, clear body motion, top-down roguelike fantasy {actor}",
    )
    return f"{base}, {facing_line}"


def margin_for(actor: str, anim: str) -> dict:
    """Extra horizontal margin for wide attacks; vertical for jumps/skills."""
    if anim in ("attack", "skill"):
        return {
            "margin_ratio_mode": "manual",
            "margin_ratio_horizontal": 0.35,
            "margin_ratio_vertical": 0.2,
        }
    if anim == "walk":
        return {
            "margin_ratio_mode": "manual",
            "margin_ratio_horizontal": 0.25,
            "margin_ratio_vertical": 0.15,
        }
    return {"margin_ratio_mode": "auto"}


ACTORS = [
    ("mage", "mage-idle.png"),
    ("swordman", "swordman-idle.png"),
    ("archer", "archer-idle.png"),
    ("cave_slime", "cave-slime.png"),
    ("stone_beetle", "stone-beetle.png"),
    ("vault_warden", "vault-warden.png"),
]

JOBS = []
DIRECTIONS = ["down", "up", "right", "left"]
for actor, img_file in ACTORS:
    img_path = f"{GAME_ART}/{img_file}"
    is_hero = actor in ("mage", "swordman", "archer")
    anims = ["idle", "walk", "attack"]
    if is_hero:
        anims.append("skill")
    for facing in DIRECTIONS:
        for anim in anims:
            loop = anim in ("idle", "walk")
            body = {
                "initial_image": local_image_uri(img_path),
                "motion_prompt": motion_prompt(actor, anim, facing),
                "image_type": "sprite",
                "frames": FRAMES,
                "frame_size": FRAME_SIZE,
                "model": MODEL,
                "duration": DURATION,
                "loop": loop,
                "individual_frames": True,
                "crop": True,
                "augment_prompt": True,
                "request_id": f"ragrogue-v3-{actor}-{facing}-{anim}",
                **margin_for(actor, anim),
            }
            JOBS.append(
                {
                    "id": f"{actor}_{facing}_{anim}",
                    "out": f"{ROOT}/{actor}/{facing}/{anim}",
                    "body": body,
                }
            )


def backup_dir(out_dir: str) -> str:
    stamp = time.strftime("%Y%m%d-%H%M%S")
    backup = f"{out_dir}_backup_{stamp}"
    if os.path.isdir(out_dir):
        shutil.move(out_dir, backup)
        print(f"backed up {out_dir} -> {backup}")
    return backup


def run_job(job: dict, force: bool = False) -> str:
    out_dir = job["out"]
    has_frames = any(
        os.path.exists(f"{out_dir}/frame_{i:02d}.webp")
        or os.path.exists(f"{out_dir}/frame_{i:02d}.png")
        for i in range(FRAMES)
    )
    if has_frames and not force:
        return f"skip {job['id']}"
    print("start", job["id"], flush=True)
    result = mcp_call("animateSprite", job["body"])
    os.makedirs(out_dir, exist_ok=True)
    with open(f"{out_dir}/ludo_meta.json", "w") as f:
        json.dump(result, f, indent=2)
    sheet_url = result.get("spritesheet_url")
    if sheet_url:
        download(sheet_url, f"{out_dir}/sheet")
    for i, u in enumerate(result.get("individual_frame_urls", [])):
        download(u, f"{out_dir}/frame_{i:02d}")
    n = len(result.get("individual_frame_urls", []))
    return f"done {job['id']} ({n} frames)"


def main() -> None:
    parser = argparse.ArgumentParser(description="Batch Ludo animateSprite for RagRogue")
    parser.add_argument(
        "jobs",
        nargs="*",
        help="Job ids or substrings to run (default: all missing)",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Regenerate even if frames already exist",
    )
    parser.add_argument(
        "--backup",
        action="store_true",
        help="Move existing output dirs to timestamped backups before regenerating",
    )
    parser.add_argument(
        "--workers",
        type=int,
        default=2,
        help="Parallel API workers (default 2)",
    )
    args = parser.parse_args()

    jobs = JOBS
    if args.jobs:
        jobs = [
            j
            for j in JOBS
            if j["id"] in args.jobs or any(x in j["id"] for x in args.jobs)
        ]

    if args.backup:
        for job in jobs:
            backup_dir(job["out"])

    print(
        f"running {len(jobs)} jobs (model={MODEL}, frames={FRAMES}, "
        f"size={FRAME_SIZE}, duration={DURATION}s, force={args.force})"
    )
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = [pool.submit(run_job, j, args.force) for j in jobs]
        for fut in as_completed(futures):
            print(fut.result(), flush=True)


if __name__ == "__main__":
    main()

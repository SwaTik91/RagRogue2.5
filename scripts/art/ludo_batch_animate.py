#!/usr/bin/env python3
"""Batch Ludo animateSprite for RagRogue actors."""
import json
import os
import sys
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed

API_KEY = open("/cursor/stores/self/ludo/api_key.txt").read().strip()
MCP_URL = "https://mcp.ludo.ai/mcp"
CDN_SHA = "13ffdca"
ROOT = "/workspace/assets/art/anim"


def mcp_call(tool: str, request_body: dict) -> dict:
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
    start = merged.find("{")
    if start >= 0:
        return json.loads(merged[start:])
    raise RuntimeError(merged[:500])


def download(url: str, dest: str) -> None:
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    ext = ".webp" if ".webp" in url.split("?")[0] else ".png"
    if not dest.endswith(ext):
        dest = os.path.splitext(dest)[0] + ext
    urllib.request.urlretrieve(url, dest)


def cdn(path: str) -> str:
    return f"https://cdn.jsdelivr.net/gh/SwaTik91/RagRogue2.5@{CDN_SHA}/{path}"


JOBS = []
for actor, img in [
    ("mage", "assets/art/game/mage-idle.png"),
    ("swordman", "assets/art/game/swordman-idle.png"),
    ("archer", "assets/art/game/archer-idle.png"),
    ("cave_slime", "assets/art/game/cave-slime.png"),
    ("stone_beetle", "assets/art/game/stone-beetle.png"),
    ("vault_warden", "assets/art/game/vault-warden.png"),
]:
    is_hero = actor in ("mage", "swordman", "archer")
    prompts = {
        "idle": "idle breathing subtle loop top-down roguelike fantasy",
        "walk": "walk cycle top-down roguelike smooth looping steps",
        "attack": "melee or weapon attack slash forward combat hit",
    }
    if is_hero:
        prompts["skill"] = "special skill cast dramatic magic or arrow burst"
    for anim, prompt in prompts.items():
        loop = anim in ("idle", "walk")
        extra = ""
        if actor == "mage" and anim == "attack":
            extra = " magic staff spell"
        elif actor == "mage" and anim == "skill":
            extra = " area explosion spell"
        elif actor == "archer" and anim == "attack":
            extra = " bow shoot arrow"
        elif actor == "swordman" and anim == "attack":
            extra = " sword slash"
        elif actor == "cave_slime":
            extra = " slime monster " + anim
        elif actor == "stone_beetle":
            extra = " beetle monster " + anim
        elif actor == "vault_warden":
            extra = " boss warden " + anim
        JOBS.append(
            {
                "id": f"{actor}_{anim}",
                "out": f"{ROOT}/{actor}/{anim}",
                "body": {
                    "initial_image": cdn(img),
                    "motion_prompt": prompt + extra + ", anime fantasy game sprite",
                    "image_type": "sprite",
                    "frames": 9,
                    "frame_size": 256,
                    "model": "eagle",
                    "duration": 2,
                    "loop": loop,
                    "individual_frames": True,
                    "crop": True,
                    "request_id": f"ragrogue-{actor}-{anim}",
                },
            }
        )


def run_job(job: dict) -> str:
    out_dir = job["out"]
    if os.path.exists(f"{out_dir}/frame_00.webp") or os.path.exists(f"{out_dir}/frame_00.png"):
        return f"skip {job['id']}"
    print("start", job["id"])
    result = mcp_call("animateSprite", job["body"])
    os.makedirs(out_dir, exist_ok=True)
    with open(f"{out_dir}/ludo_meta.json", "w") as f:
        json.dump(result, f, indent=2)
    sheet_url = result.get("spritesheet_url")
    if sheet_url:
        download(sheet_url, f"{out_dir}/sheet")
    for i, u in enumerate(result.get("individual_frame_urls", [])):
        download(u, f"{out_dir}/frame_{i:02d}")
    return f"done {job['id']}"


def main() -> None:
    only = sys.argv[1:] if len(sys.argv) > 1 else []
    jobs = [j for j in JOBS if not only or j["id"] in only or any(x in j["id"] for x in only)]
    print(f"running {len(jobs)} jobs")
    with ThreadPoolExecutor(max_workers=3) as pool:
        futures = [pool.submit(run_job, j) for j in jobs]
        for fut in as_completed(futures):
            print(fut.result())


if __name__ == "__main__":
    main()

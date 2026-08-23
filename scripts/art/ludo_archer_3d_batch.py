#!/usr/bin/env python3
"""Ludo 3D archer: create3DModel → rigModel → animate3DModelPreset for all combat moves."""
import base64
import json
import os
import sys
import time
import urllib.request

API_KEY = open("/cursor/stores/self/ludo/api_key.txt").read().strip()
MCP_URL = "https://mcp.ludo.ai/mcp"
WORKSPACE = "/workspace"
OUT = f"{WORKSPACE}/assets/art/3d/archer"
ANIM_OUT = f"{OUT}/anims"
SOURCE_IMAGE = f"{WORKSPACE}/assets/art/game/archer-idle.png"
META_PATH = f"{OUT}/ludo_3d_meta.json"

# Game animation name → Ludo preset
ANIM_JOBS = [
    {
        "id": "idle",
        "preset_id": "idle_combat",
        "crop_loop": True,
        "in_place": True,
    },
    {
        "id": "walk",
        "preset_id": "walk_forward",
        "crop_loop": True,
        "in_place": True,
    },
    {
        "id": "attack",
        "preset_id": "bow_shot",
        "crop_loop": False,
        "in_place": True,
    },
    {
        "id": "skill",
        "preset_id": "bow_shot_sky",
        "crop_loop": False,
        "in_place": True,
    },
    {
        "id": "hit",
        "preset_id": "hit_front_heavy",
        "crop_loop": False,
        "in_place": True,
    },
]


def mcp_call(tool: str, body: dict, retries: int = 3, timeout: int = 600) -> dict:
    last_err: Exception | None = None
    for attempt in range(retries):
        try:
            payload = {
                "jsonrpc": "2.0",
                "id": int(time.time() * 1000) % 1000000,
                "method": "tools/call",
                "params": {"name": tool, "arguments": {"requestBody": body}},
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
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                raw = json.loads(resp.read().decode())
            texts = [
                c.get("text", "")
                for c in raw.get("result", {}).get("content", [])
                if c.get("type") == "text"
            ]
            merged = "\n".join(texts)
            if "API Error" in merged and "Status: 200" not in merged:
                raise RuntimeError(merged[:1200])
            start = merged.find("{")
            if start < 0:
                raise RuntimeError(merged[:500])
            return json.loads(merged[start:merged.rfind("}") + 1])
        except Exception as exc:
            last_err = exc
            if attempt + 1 < retries:
                time.sleep(4 * (2 ** attempt))
    raise last_err  # type: ignore[misc]


def local_image_data_uri(path: str) -> str:
    with open(path, "rb") as f:
        encoded = base64.b64encode(f.read()).decode()
    return f"data:image/png;base64,{encoded}"


def download(url: str, dest: str) -> str:
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    urllib.request.urlretrieve(url, dest)
    return dest


def load_meta() -> dict:
    if os.path.isfile(META_PATH):
        with open(META_PATH) as f:
            return json.load(f)
    return {}


def save_meta(meta: dict) -> None:
    os.makedirs(OUT, exist_ok=True)
    with open(META_PATH, "w") as f:
        json.dump(meta, f, indent=2)


def ensure_model(meta: dict) -> str:
    rig_path = f"{OUT}/archer_rigged.glb"
    if os.path.isfile(rig_path) and meta.get("rigged_model_url"):
        print(f"reuse rigged model {rig_path}", flush=True)
        return meta["rigged_model_url"]
    print("create3DModel...", flush=True)
    created = mcp_call(
        "create3DModel",
        {
            "image": local_image_data_uri(SOURCE_IMAGE),
            "texture_type": "pbr",
            "texture_size": 1024,
            "target_num_faces": 40000,
            "request_id": "ragrogue-archer-3d-base-v2",
        },
        timeout=900,
    )
    raw_url = created.get("model_url")
    if not raw_url:
        raise RuntimeError(f"create3DModel missing model_url: {created}")
    download(raw_url, f"{OUT}/archer_raw.glb")
    meta["raw_model_url"] = raw_url
    print("rigModel...", flush=True)
    rigged = mcp_call(
        "rigModel",
        {
            "model": raw_url,
            "rig_type": "humanoid_template_hands",
            "request_id": "ragrogue-archer-3d-rig-v2",
        },
        timeout=900,
    )
    rig_url = rigged.get("model_url")
    if not rig_url:
        raise RuntimeError(f"rigModel missing model_url: {rigged}")
    download(rig_url, rig_path)
    meta["rigged_model_url"] = rig_url
    save_meta(meta)
    print(f"rigged -> {rig_path}", flush=True)
    return rig_url


def run_anim_job(meta: dict, rig_url: str, job: dict, force: bool = False) -> None:
    anim_id = job["id"]
    dest = f"{ANIM_OUT}/{anim_id}.glb"
    if os.path.isfile(dest) and not force:
        print(f"skip {anim_id} (exists)", flush=True)
        return
    print(f"animate preset {anim_id} ({job['preset_id']})...", flush=True)
    body = {
        "model": rig_url,
        "preset_id": job["preset_id"],
        "in_place": job.get("in_place", True),
        "request_id": f"ragrogue-archer-3d-{anim_id}-v1",
    }
    if job.get("crop_loop"):
        body["crop_loop"] = True
    result = mcp_call("animate3DModelPreset", body, timeout=900)
    anims = result.get("animations", [])
    if not anims:
        raise RuntimeError(f"no animations returned for {anim_id}: {result}")
    entry = anims[0]
    glb_url = entry.get("glb_url")
    if not glb_url:
        raise RuntimeError(f"no glb_url for {anim_id}: {entry}")
    download(glb_url, dest)
    meta.setdefault("animations", {})[anim_id] = {
        "preset_id": job["preset_id"],
        "glb_url": glb_url,
        "preview_url": entry.get("preview_url"),
        "clip_name": entry.get("clip_name"),
    }
    save_meta(meta)
    print(f"done {anim_id} -> {dest}", flush=True)


def main() -> None:
    force = "--force" in sys.argv
    os.makedirs(ANIM_OUT, exist_ok=True)
    meta = load_meta()
    rig_url = ensure_model(meta)
    for job in ANIM_JOBS:
        run_anim_job(meta, rig_url, job, force=force)
    print("all archer 3D animations complete", flush=True)


if __name__ == "__main__":
    main()

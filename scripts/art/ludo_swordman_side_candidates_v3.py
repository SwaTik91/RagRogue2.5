#!/usr/bin/env python3
"""Generate second batch of swordman side-view style candidates (v3)."""
import json
import os
import sys
import time
import urllib.request

# Reuse MCP helpers from v2 script
sys.path.insert(0, os.path.dirname(__file__))
from ludo_swordman_side_candidates import (
    BASE_PROMPT,
    download,
    extract_url,
    mcp_call,
)

OUT = "/workspace/assets/art/candidates/swordman-side-v3"

VARIANTS = [
    {
        "id": "v5-hibit-pixel",
        "label": "Hi-Bit pixel (fine)",
        "body": {
            "prompt": (
                f"{BASE_PROMPT}, hi-bit pixel art, very fine pixels, vibrant fantasy colors, "
                "Ragnarok Online inspired knight, detailed armor shine, game sprite masterpiece"
            ),
            "image_type": "sprite",
            "art_style": "Hi-Bit",
            "perspective": "Side-Scroll",
            "aspect_ratio": "ar_1_1",
            "n": 1,
            "request_id": "ragrogue-swordman-side-v5-hibit",
        },
    },
    {
        "id": "v6-cel-shaded",
        "label": "Cel-Shaded mobile",
        "body": {
            "prompt": (
                f"{BASE_PROMPT}, cel-shaded 2D game art, bold colors, clean shadows, "
                "mobile roguelike hero, heroic fantasy swordsman, crisp edges"
            ),
            "image_type": "sprite",
            "art_style": "Cel-Shaded",
            "perspective": "Side-Scroll",
            "aspect_ratio": "ar_1_1",
            "n": 1,
            "request_id": "ragrogue-swordman-side-v6-cel",
        },
    },
    {
        "id": "v7-western-cartoon",
        "label": "Western Cartoon",
        "body": {
            "prompt": (
                f"{BASE_PROMPT}, western cartoon style, thick outlines, expressive hero, "
                "Disney-Pixar fantasy warrior energy, readable silhouette, fun but epic"
            ),
            "image_type": "sprite",
            "art_style": "Western Cartoon",
            "perspective": "Side-Scroll",
            "aspect_ratio": "ar_1_1",
            "n": 1,
            "request_id": "ragrogue-swordman-side-v7-cartoon",
        },
    },
    {
        "id": "v8-watercolor",
        "label": "Watercolor fantasy",
        "body": {
            "prompt": (
                f"{BASE_PROMPT}, watercolor fantasy illustration, soft edges, painterly wash, "
                "storybook knight, gentle lighting, artistic game concept sprite"
            ),
            "image_type": "sprite",
            "art_style": "Watercolor",
            "perspective": "Side-Scroll",
            "aspect_ratio": "ar_1_1",
            "n": 1,
            "request_id": "ragrogue-swordman-side-v8-watercolor",
        },
    },
]


def build_compare(meta: list) -> None:
    try:
        from PIL import Image, ImageDraw

        imgs = []
        for m in meta:
            label = m["label"]
            im = Image.open(m["path"]).convert("RGBA")
            imgs.append((label, im))
        w = max(im.size[0] for _, im in imgs)
        h = max(im.size[1] for _, im in imgs)
        pad = 8
        label_h = 28
        cols = 2
        rows = 2
        sheet = Image.new(
            "RGBA",
            (cols * (w + pad) + pad, rows * (h + label_h + pad) + pad),
            (28, 30, 36, 255),
        )
        draw = ImageDraw.Draw(sheet)
        for i, (label, im) in enumerate(imgs):
            col = i % cols
            row = i // cols
            ox = pad + col * (w + pad) + (w - im.size[0]) // 2
            oy = pad + row * (h + label_h + pad) + label_h + (h - im.size[1]) // 2
            sheet.paste(im, (ox, oy), im)
            tx = pad + col * (w + pad) + 4
            ty = pad + row * (h + label_h + pad) + 4
            draw.text((tx, ty), label, fill=(220, 220, 230, 255))
        sheet.save(f"{OUT}/compare.png")
        print("compare.png written", flush=True)
    except Exception as exc:
        print(f"compare sheet skipped: {exc}", flush=True)


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    meta = []
    for var in VARIANTS:
        vid = var["id"]
        dest_base = f"{OUT}/{vid}"
        if os.path.exists(f"{dest_base}.webp") or os.path.exists(f"{dest_base}.png"):
            path = f"{dest_base}.webp" if os.path.exists(f"{dest_base}.webp") else f"{dest_base}.png"
            print(f"skip {vid} exists", flush=True)
            meta.append({"id": vid, "label": var["label"], "path": path})
            continue
        print(f"generating {vid}...", flush=True)
        result = mcp_call("createImage", var["body"])
        url = extract_url(result)
        path = download(url, dest_base)
        with open(f"{dest_base}.meta.json", "w") as f:
            json.dump({"label": var["label"], "url": url, "result": result}, f, indent=2)
        meta.append({"id": vid, "label": var["label"], "path": path})
        print(f"done {vid} -> {path}", flush=True)
        time.sleep(1)

    with open(f"{OUT}/README.md", "w") as f:
        f.write("# Swordman side-view candidates (v3 — second batch)\n\n")
        f.write("Styles: Hi-Bit, Cel-Shaded, Western Cartoon, Watercolor.\n\n")
        for m in meta:
            f.write(f"- **{m['id']}** — {m['label']}: `{os.path.basename(m['path'])}`\n")

    build_compare(meta)


if __name__ == "__main__":
    main()

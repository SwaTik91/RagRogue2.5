#!/usr/bin/env python3
"""Derive walk/attack/skill frame sequences from idle breathing loops (offline fallback)."""

from __future__ import annotations

import math
import os
import sys

from PIL import Image, ImageEnhance

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ANIM_ROOT = os.path.join(ROOT, "assets", "art", "anim")

DIRS = ("down", "up", "left", "right")
DIR_OFFSET = {
	"down": (0, 1),
	"up": (0, -1),
	"left": (-1, 0),
	"right": (1, 0),
}


def _load_idle_frames(actor: str, game_dir: str) -> list[Image.Image]:
	folder = os.path.join(ANIM_ROOT, actor, game_dir, "idle")
	if not os.path.isdir(folder):
		return []
	frames: list[Image.Image] = []
	for i in range(32):
		path = os.path.join(folder, f"frame_{i:02d}.png")
		if not os.path.isfile(path):
			break
		frames.append(Image.open(path).convert("RGBA"))
	if not frames:
		for fname in sorted(os.listdir(folder)):
			if fname.startswith("frame_") and fname.endswith(".png"):
				frames.append(Image.open(os.path.join(folder, fname)).convert("RGBA"))
	return frames


def _paste_center(canvas: Image.Image, sprite: Image.Image, ox: int, oy: int) -> None:
	x = (canvas.width - sprite.width) // 2 + ox
	y = (canvas.height - sprite.height) // 2 + oy
	canvas.paste(sprite, (x, y), sprite)


def _walk_frame(base: Image.Image, phase: float) -> Image.Image:
	w, h = base.size
	bob = int(round(math.sin(phase) * 3.0))
	sway = int(round(math.sin(phase * 0.5) * 2.0))
	scale = 1.0 + math.sin(phase) * 0.04
	nw = max(1, int(w * scale))
	nh = max(1, int(h * scale))
	scaled = base.resize((nw, nh), Image.Resampling.LANCZOS)
	out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	_paste_center(out, scaled, sway, bob)
	return out


def _attack_frame(base: Image.Image, game_dir: str, t: float) -> Image.Image:
	w, h = base.size
	dx, dy = DIR_OFFSET.get(game_dir, (0, 1))
	lunge = int(round(10.0 * math.sin(t * math.pi)))
	sx = 1.0 + 0.12 * math.sin(t * math.pi)
	sy = 1.0 - 0.06 * math.sin(t * math.pi)
	nw = max(1, int(w * sx))
	nh = max(1, int(h * sy))
	scaled = base.resize((nw, nh), Image.Resampling.LANCZOS)
	out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	_paste_center(out, scaled, dx * lunge, dy * lunge)
	return out


def _skill_frame(base: Image.Image, t: float) -> Image.Image:
	w, h = base.size
	pulse = 1.0 + 0.18 * math.sin(t * math.pi)
	nw = max(1, int(w * pulse))
	nh = max(1, int(h * pulse))
	scaled = base.resize((nw, nh), Image.Resampling.LANCZOS)
	out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	_paste_center(out, scaled, 0, int(round(-4.0 * math.sin(t * math.pi))))
	tinted = ImageEnhance.Color(out).enhance(1.25)
	bright = ImageEnhance.Brightness(tinted).enhance(1.0 + 0.15 * math.sin(t * math.pi))
	return bright


def _write_frames(folder: str, frames: list[Image.Image]) -> None:
	os.makedirs(folder, exist_ok=True)
	for old in os.listdir(folder):
		if old.startswith("frame_") and old.endswith(".png"):
			os.remove(os.path.join(folder, old))
	for i, img in enumerate(frames):
		img.save(os.path.join(folder, f"frame_{i:02d}.png"))


def fill_actor(actor: str) -> int:
	written = 0
	for game_dir in DIRS:
		idle = _load_idle_frames(actor, game_dir)
		if not idle:
			print(f"skip {actor}/{game_dir}: no idle frames", flush=True)
			continue
		walk_frames = [_walk_frame(idle[i % len(idle)], i * 0.9) for i in range(8)]
		attack_frames = [
			_attack_frame(idle[min(i, len(idle) - 1)], game_dir, i / 7.0) for i in range(8)
		]
		skill_frames = [
			_skill_frame(idle[min(i, len(idle) - 1)], i / 9.0) for i in range(10)
		]
		_write_frames(os.path.join(ANIM_ROOT, actor, game_dir, "walk"), walk_frames)
		_write_frames(os.path.join(ANIM_ROOT, actor, game_dir, "attack"), attack_frames)
		_write_frames(os.path.join(ANIM_ROOT, actor, game_dir, "skill"), skill_frames)
		written += len(walk_frames) + len(attack_frames) + len(skill_frames)
		print(
			f"{actor}/{game_dir}: walk={len(walk_frames)} attack={len(attack_frames)} skill={len(skill_frames)}",
			flush=True,
		)
	return written


def main() -> None:
	actors = sys.argv[1:] or ["angel_mvp"]
	total = 0
	for actor in actors:
		total += fill_actor(actor)
	print(f"done, wrote {total} frames", flush=True)


if __name__ == "__main__":
	main()

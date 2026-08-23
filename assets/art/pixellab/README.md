# PixelLab pipeline

Generate 4-direction pixel characters + animations via [PixelLab API](https://api.pixellab.ai/v2/docs).

## Setup

1. Create token at https://pixellab.ai/account
2. Save token to `/cursor/stores/self/pixellab/api_key.txt` or `export PIXELLAB_API_KEY=...`

## Generate archer (test)

```bash
python3 scripts/art/pixellab_batch.py archer
python3 scripts/art/pixellab_batch.py --balance
```

### Import existing web UI characters (no generations)

If the trial generations are exhausted, completed mannequin characters on the account
can be imported as static 4-dir rotations (one frame per direction):

```bash
python3 scripts/art/pixellab_batch.py archer --import-existing
python3 scripts/art/pixellab_batch.py archer --import-existing --character-id <uuid>
```

Full animated idle/walk/attack cycles require available generations on the account.

Output frames: `assets/art/anim/{actor}/{down|up|left|right}/{idle|walk|attack|skill}/frame_XX.png`

Meta: `assets/art/pixellab/{actor}/meta.json`

## Game integration

- Dungeon uses **2D** `player.tscn` + `ActorAnimator` + `SpriteFramesFactory`
- Same folder layout as Ludo batch (`assets/art/anim/archer/...`)
- Hub portraits still from `assets/art/game/`

## MCP (optional)

PixelLab also ships an MCP server for Cursor: https://www.pixellab.ai/docs/ways-to-use-pixellab

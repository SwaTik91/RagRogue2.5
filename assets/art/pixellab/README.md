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

## MCP + Cursor

PixelLab exposes a **remote HTTP MCP server** (“Vibe Coding”) so you can generate characters,
animations, and tilesets from Cursor without running the Python batch script.

Docs: https://api.pixellab.ai/mcp/docs  
Setup wizard (token pre-filled): https://www.pixellab.ai/vibe-coding

### When to use MCP vs batch script

| | MCP (Cursor) | `pixellab_batch.py` (REST) |
|--|--------------|----------------------------|
| Best for | Interactive tweaks in IDE | CI, repeatable full actor export |
| Auth | Bearer token in MCP config | `PIXELLAB_API_KEY` or agent store file |
| Export to game | Ask agent to download into `assets/art/anim/` | Automatic → `assets/art/anim/{actor}/` |
| Same account | Yes — characters appear in Character Creator web UI |

Use **one token** from https://pixellab.ai/account (or https://api.pixellab.ai/mcp).

### Cursor configuration

Open **Cursor Settings → MCP** (or edit your MCP config file) and add:

```json
{
  "mcpServers": {
    "pixellab": {
      "url": "https://api.pixellab.ai/mcp",
      "transport": "http",
      "headers": {
        "Authorization": "Bearer YOUR_API_TOKEN"
      }
    }
  }
}
```

Replace `YOUR_API_TOKEN` with your PixelLab API token. Do not commit the token to git.

After saving, restart Cursor or reload MCP servers. Tool names may appear as
`create_character` or `mcp__pixellab__create_character` depending on the client.

**Cloud Agents** in Cursor do not inherit your local MCP config — use the batch script
or REST API there unless PixelLab MCP is added to the cloud environment separately.

### MCP workflow (non-blocking)

Creation tools return immediately with IDs; generation runs in the background (~2–5 min).

1. `create_character` — base sprite (4 or 8 directions, `view: low top-down`)
2. `animate_character` — queue idle / walk / attack (can call before character is done)
3. `get_character` — poll status, rotation URLs, animation frames, download link
4. `get_balance` — check subscription generations

Example prompts in Cursor:

- “Create a top-down roguelike archer with green hood and bow, 4 directions, 48px”
- “Animate walk and breathing-idle on character `<uuid>`”
- “Custom v3 attack: draw bowstring with right hand, release arrow, 8 frames, south”
- “Export frames into `assets/art/anim/archer/` using the same layout as SpriteFramesFactory”

### Direction mapping (PixelLab → RagRogue)

| PixelLab | Game folder |
|----------|---------------|
| `south` | `down` |
| `north` | `up` |
| `east` | `right` |
| `west` | `left` |

### RagRogue-relevant MCP tools

- **Characters:** `create_character`, `create_character_state`, `animate_character`, `get_character`, `list_characters`
- **Balance:** `get_balance`
- **Tilesets (dungeon):** `create_topdown_tileset`, `get_topdown_tileset`
- **Help:** `agent_help` — ask about tools, billing, workflows

For archer attack/skill, prefer `animate_character` with `action_description` (v3) or
templates `breathing-idle`, `walking` / `walk`. Use **URLs** for reference images when
possible — large base64 in MCP calls is often truncated by clients.

### Godot resources (via MCP)

MCP also lists implementation guides as resources, e.g.:

- `pixellab://docs/godot/wang-tilesets` — Wang tilesets + headless converter
- `pixellab://docs/godot/isometric-tiles`
- `pixellab://docs/overview` — full platform overview

### REST fallback

If MCP is not configured, the batch script uses the same account via REST v2:

```bash
python3 scripts/art/pixellab_batch.py --balance
python3 scripts/art/pixellab_batch.py archer
python3 scripts/art/pixellab_batch.py archer --force   # new character
```

REST LLM-oriented catalog: https://api.pixellab.ai/v2/llms.txt

## Game integration

- Dungeon uses **2D** `player.tscn` + `ActorAnimator` + `SpriteFramesFactory`
- Same folder layout as Ludo batch (`assets/art/anim/archer/...`)
- Hub portraits still from `assets/art/game/`

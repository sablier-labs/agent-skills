---
name: sablier-assets
description: This skill should be used when the user asks to "generate a Sablier asset", "create a 3D asset", "render a 3D image", "make a visual asset", "design an icon", or any 3D visual asset creation task for Sablier branded content.
---

# 3D Assets Skill

Generate Sablier-branded 3D assets using Google Gemini.

## Prerequisites

- `GEMINI_API_KEY` environment variable — Get at https://aistudio.google.com/apikey

Validate:

```bash
./scripts/check-gemini-api.sh
```

## Usage

```bash
# Output to ./output/ with timestamp filename (default)
./scripts/generate-image.sh "prompt"

# Or specify output path
./scripts/generate-image.sh "prompt" ./output/my-asset.png
```

Generated images go to `./output/` which is gitignored.

## Workflow

### 1. Load References

- `./references/STYLE_GUIDE.md` — Official Sablier colors and styles
- `./references/PROMPTING.md` — Working prompt patterns
- `./examples/` — Reference images (view to understand target aesthetic)

### 2. Construct Prompt

Template:

```
3D [color] [object], matte plastic finish, soft lighting, solid uniform
dark navy background #14161f, [composition], stylized 3D render, smooth rounded edges
```

**Key style keywords:**

- `matte plastic finish`
- `stylized 3D render`
- `soft lighting`
- `solid uniform dark navy background #14161f`
- `smooth rounded edges`
- `floating` or `tilted angle`

**Official colors:**

- Orange: `#ff7300` to `#ffb800`
- Blue: `#003dff` to `#00b7ff`

### 3. Generate

```bash
./scripts/generate-image.sh "3D orange lock with key..."
```

Output: `./output/<timestamp>.png`

### 4. Post-Processing

Remove background in Figma or Photoshop. The consistent dark navy background (`#14161f`) makes selection easy.

## Working Prompts

See `./references/PROMPTING.md` for the full prompt catalog.

### Quick Example (Airdrop Gift Box)

```
3D orange gift box open with lid, blue crypto coins with white logo inside,
matte plastic finish, soft lighting, solid uniform dark navy background
#14161f, floating tilted angle, smooth rounded edges, stylized 3D render
```

## Color by Concept

| Concept       | Color  | Example Objects          |
| ------------- | ------ | ------------------------ |
| Vesting       | Orange | Locks, safes, bars       |
| Airdrops      | Orange | Gift boxes, parachutes   |
| Streaming     | Orange | Flowing waves, ribbons   |
| Crypto tokens | Blue   | Coins with ETH/SOL logos |
| Analysis      | Blue   | Binoculars, charts       |
| Characters    | Orange | People in orange jackets |

## Troubleshooting

| Issue            | Solution                         |
| ---------------- | -------------------------------- |
| Wrong colors     | Use explicit hex codes in prompt |
| Too shiny/glossy | Add "matte plastic" not "glossy" |
| Cluttered        | Simplify prompt, fewer objects   |

## Cost

~$0.039 per image.

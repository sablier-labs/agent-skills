---
name: sablier-icon
argument-hint: <color> [--format png|jpg]
description: This skill should be used when the user asks to "recolor the Sablier icon", "Sablier icon in orange", "Sablier logo in primary color", "generate Sablier hourglass variant", "change Sablier icon color", or "export Sablier icon as PNG". Converts the Sablier white SVG icon to any color using brand palette names, hex values, or CSS color names, with optional PNG/JPG raster export.
---

Recolor the Sablier icon SVG to a user-specified color and optionally export to PNG or JPG.

## Source

The base icon is at `assets/white-icon.svg` (relative to this skill directory). It is a single-path SVG with
`fill="white"`. To recolor, replace the `fill` attribute value with the target hex color.

## Color Resolution

Resolve the user's color input in this order:

1. **Brand color name** — match against the Sablier palette below (case-insensitive, partial match OK)
2. **Raw hex** — accept `#RRGGBB` or `RRGGBB` directly
3. **CSS color name** — accept standard CSS named colors (e.g. `red`, `teal`, `cornflowerblue`)

### Sablier Brand Palette

Source: [sablier-labs/branding](https://github.com/sablier-labs/branding)

| Name                  | Hex       | Notes                           |
| --------------------- | --------- | ------------------------------- |
| primary-start         | `#ff7300` | Orange gradient start           |
| primary-end           | `#ffb800` | Orange gradient end             |
| primary / orange      | `#ff9c00` | Median orange (default primary) |
| secondary-start       | `#003dff` | Blue gradient start             |
| secondary-end         | `#00b7ff` | Blue gradient end               |
| secondary / blue      | `#0063ff` | Median blue (default secondary) |
| secondary-desaturated | `#266cd9` | Desaturated blue                |
| dark                  | `#14161f` | Darkest background              |
| dark-100              | `#1e212f` | App background                  |
| dark-300              | `#2a2e41` | Card borders                    |
| dark-400              | `#30354a` | Input borders                   |
| gray-100              | `#e1e4ea` | Body text                       |
| gray-400              | `#8792ab` | Labels                          |
| red                   | `#e52e52` | Error / destructive             |
| white                 | `#ffffff` | Original icon color             |
| black                 | `#000000` | Pure black (rarely used)        |

When the user says "primary", use `#ff9c00`. When they say "secondary", use `#0063ff`.

## SVG Generation

1. Read `assets/white-icon.svg`
2. Replace `fill="white"` with `fill="<resolved-hex>"`
3. Write the result to the user's working directory as `sablier-icon-<color-name>.svg`

For filenames: use the brand alias when matched by name (e.g. `primary`), otherwise strip the `#` prefix and lowercase
the hex value (e.g. `#E52E52` → `e52e52`). If the color cannot be resolved, ask the user to provide a valid hex code.

## PNG / JPG Export

If the user passes `--format png` or `--format jpg`:

1. Generate the recolored SVG first
2. Verify `magick` is available: `command -v magick >/dev/null 2>&1 || { echo "Error: ImageMagick not found. Install with: brew install imagemagick"; exit 1; }`
3. Use `magick` to convert:

```bash
# PNG (transparent background, 1024px height)
magick -background none -density 300 "<input>.svg" -resize x1024 "<output>.png"

# JPG (dark background since JPG has no transparency, 1024px height)
magick -background "#14161f" -density 300 "<input>.svg" -resize x1024 -flatten "<output>.jpg"
```

The output filename follows the same `sablier-icon-<color-name>.<ext>` pattern.

## Examples

- `primary` → `sablier-icon-primary.svg` with `fill="#ff9c00"`
- `secondary --format png` → `sablier-icon-secondary.svg` + `sablier-icon-secondary.png`
- `#e52e52` → `sablier-icon-e52e52.svg` with `fill="#e52e52"`
- `red --format jpg` → `sablier-icon-red.svg` + `sablier-icon-red.jpg`

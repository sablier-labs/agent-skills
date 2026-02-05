# Prompt Engineering Guide

Tips for generating Sablier-style 3D assets with Gemini 2.5 Flash Image.

## Core Style Keywords

### Must Include

- `matte plastic finish`
- `soft lighting`
- `solid uniform dark navy background #14161f`
- `stylized 3D render`
- `smooth rounded edges`

### Composition

- `floating tilted angle`
- `simple clean design`

### Color Specification

```
Orange objects: "3D orange [object]"
Blue objects:   "3D blue [object]"
Gold accents:   "gold coins" or "gold color #ffb800"
```

### Avoid

- `black background` — use `solid uniform dark navy #14161f`
- `cinematic lighting` — too dramatic
- `realistic` or `photorealistic` — wrong aesthetic
- `metallic` or `glossy` — too reflective
- `detailed` or `intricate` — over-complicated
- `toy-like` — use `stylized` instead

## Prompt Template

```
3D [color] [object], matte plastic finish, soft lighting, solid uniform
dark navy background #14161f, floating tilted angle, stylized 3D render,
smooth rounded edges
```

## Working Examples

### Gift Box (Airdrop)

```
3D orange gift box open with lid, blue crypto coins with white logo inside,
matte plastic finish, soft lighting, solid uniform dark navy background
#14161f, floating tilted angle, smooth rounded edges, stylized 3D render
```

### Lock with Coins (Vesting)

```
3D orange lock with key, surrounded by floating gold coins, matte plastic
finish, soft lighting, solid uniform dark navy background #14161f,
floating tilted angle, stylized 3D render
```

### Flowing Wave (Streaming)

```
3D orange flowing wave ribbon with blue crypto coins floating along it,
matte plastic finish, soft lighting, solid uniform dark navy background
#14161f, dynamic curved motion, stylized 3D render
```

### Safe/Vault

```
3D orange vault safe with round dial, matte plastic finish, soft lighting,
solid uniform dark navy background #14161f, tilted angle view,
smooth rounded edges, stylized 3D render
```

### Binoculars (Analysis)

```
3D orange and blue binoculars, matte plastic finish, soft lighting,
solid uniform dark navy background #14161f, floating tilted angle,
stylized 3D render, smooth rounded edges
```

### Character

```
3D stylized character person wearing orange puffer jacket, looking through
binoculars, matte plastic finish, soft lighting, solid uniform dark navy
background #14161f, simple clean stylized 3D render
```

### Bar Chart

```
3D blue bar chart with rising bars and floating data points, matte plastic
finish, soft lighting, solid uniform dark navy background #14161f,
isometric view, stylized 3D render
```

## Color by Concept

| Concept       | Color  |
| ------------- | ------ |
| Vesting       | Orange |
| Airdrops      | Orange |
| Streaming     | Orange |
| Crypto tokens | Blue   |
| Analysis      | Blue   |
| Characters    | Orange |

## Iteration Tips

If results don't match Sablier style:

1. Check background — must be `solid uniform dark navy #14161f`, not black
1. Use "matte plastic finish" not pure "matte"
1. Add "stylized 3D render"
1. Simplify the prompt — fewer objects
1. Add "smooth rounded edges"

## Cost

~$0.039 per image.

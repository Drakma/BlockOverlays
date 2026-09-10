# BlockOverlays Plugin — How-To Guide

A guide on how to render world-space overlays (text, numbers, items, textures, and outlines) in Minecraft using the **BlockOverlays** plugin in MCreator for NeoForge 26.1.2 and 26.2.

---

## Table of Contents

1. [Overview](#1-overview)
2. [The Texture Datatype](#2-the-texture-datatype)
3. [The Texture Selector](#3-the-texture-selector)
4. [The Screen Texture Selector](#4-the-screen-texture-selector)
5. [The Overlay Placement Dropdown](#5-the-overlay-placement-dropdown)
6. [Direction Helpers](#6-direction-helpers)
7. [The Looked-At Block Vector](#7-the-looked-at-block-vector)
8. [Overlay Builder Blocks](#8-overlay-builder-blocks)
9. [Hiding and Restoring Overlays](#9-hiding-and-restoring-overlays)
10. [The 3×3 Anchor Grid](#10-the-3×3-anchor-grid)
11. [Match Conditions (SNBT Gating)](#11-match-conditions-snbt-gating)
12. [Setting Up a Block Overlay Workspace](#12-setting-up-a-block-overlay-workspace)
13. [Biome Tint Colors](#13-biome-tint-colors)

---

## 1. Overview

**BlockOverlays** is an MCreator plugin that gives you procedure blocks to render temporary, world-space visual markers on top of a target block. All overlay rendering is driven by a single Blockly procedure (`Overlay logic`) attached to a **Block Overlay** workspace element.

The plugin adds:

- A native **`Texture`** Blockly datatype with a workspace image picker.
- A **Texture selector** and **Screen texture selector** block for converting between textures and resource-location strings.
- A reusable **9-position anchor grid** (`overlay placement`) for face-aligned overlays.
- **Direction helpers** that resolve a block-facing `Direction` to `{front}` / `{back}` / `{left}` / `{right}`.
- Builder blocks for **text, number, item, texture, outline, and spinning variants** that all read from a shared `OverlayPlacement`.
- A **Blockly trigger** (`When block overlays are rendered`) fired every render tick on the client.
- **Hide / show** controls for per-position visibility.
- **Optional SNBT matching** for gating overlays on held item or targeted block-entity NBT.

All overlays render through the `render_block_overlays` Blockly trigger at world position — they don't need coordinate inputs and they automatically attach to the Block Overlay element's target block.

---

## 2. The Texture Datatype

`Texture` is a first-class Blockly datatype the plugin adds. It is a thin wrapper around a Minecraft resource location string (`minecraft:oak_planks`, `mymod:block/furnace_side`, etc.) that MCreator will validate against the workspace asset library.

Use a Texture anywhere a `Texture` input is requested (the **render texture** block, the **texture from text** / **texture to text** converters, etc.).

---

## 3. The Texture Selector

The **Texture selector** block opens a visual picker that lists every block, item, entity, effect, particle, screen, armor, and other image asset in the workspace. It returns a `Texture`.

```
select texture
```

Use it anywhere you would otherwise type a resource location by hand — the picker prevents typos and keeps the texture name in sync when the underlying asset is renamed.

---

## 4. The Screen Texture Selector

The **Screen texture selector** is a sibling of the texture selector but scoped to **screen / GUI** textures (anything registered as a screen background or widget). It returns a `Texture`.

```
select screen texture
```

Useful for tooltips, popup labels, and HUD-style overlays rendered on a block face.

---

## 5. The Overlay Placement Dropdown

`Overlay placement` is a dropdown that returns one of nine anchor positions on a block (or on a single block face):

| Anchor         | When used on a full block                  | When used on a single face   |
| -------------- | ------------------------------------------ | ---------------------------- |
| `TOP_LEFT`     | top-left corner of the block bounds       | top-left of the face         |
| `TOP_CENTER`   | top edge, centered                         | top of the face              |
| `TOP_RIGHT`    | top-right corner                           | top-right of the face        |
| `MIDDLE_LEFT`  | middle-left edge                           | middle-left of the face      |
| `MIDDLE_CENTER`| block center                               | face center                  |
| `MIDDLE_RIGHT` | middle-right edge                          | middle-right of the face     |
| `BOTTOM_LEFT`  | bottom-left corner                         | bottom-left of the face      |
| `BOTTOM_CENTER`| bottom edge, centered                      | bottom of the face           |
| `BOTTOM_RIGHT` | bottom-right corner                        | bottom-right of the face     |

You can pass a fixed dropdown value, or wire the placement to a `Variable` so the anchor can be changed at runtime by other procedures.

---

## 6. Direction Helpers

Blocks that take a `Direction` input support the four **relative** constants:

```
{front}  → the face of the block the player is currently looking at
{back}   → the opposite face
{left}   → 90° counter-clockwise from {front}
{right}  → 90° clockwise from {front}
```

These are stable relative to the player view, so an overlay labeled "top-right" still reads correctly no matter which way the block is facing. The helpers expect a block-relative `Direction` (e.g. from `overlay_direction_front` / `overlay_direction_back` / `overlay_direction_left` / `overlay_direction_right`).

---

## 7. The Looked-At Block Vector

```
get the block the player is looking at
```

Returns a `Vector3d` (BlockPos as a vector) of the block the player is currently targeting with their crosshair. Useful for "draw an overlay on whatever block I just clicked" workflows.

---

## 8. Overlay Builder Blocks

All builder blocks live in the **Overlay Builder** category and read from a shared `OverlayPlacement`. They do not need coordinate inputs — the Block Overlay element supplies the target block automatically.

### Render Text

```
render text %text at %placement on %side color %color scale %scale transparency %transparency padding %padding on shape bounds %bounds
```

- `text` — string to display.
- `placement` — `OverlayPlacement` (one of the 9 anchors).
- `side` — `Direction` (use `{front}` for the face the player sees, or a fixed constant).
- `color` — color picker.
- `scale` — multiplier (1 = native size).
- `transparency` — `0` (invisible) to `1` (opaque).
- `padding` — pixels inset from the anchored edge.
- `bounds` — `true` clips to the block bounds, `false` can spill over the face edges.

### Render Number

Same shape as **Render text** but takes a `Number` instead of a `String`. Useful for debug readouts (e.g. "Energy: 42").

### Render Item

```
render item %item at %placement on %side
```

Renders a 3D item graphic. If you want the item to spin, use the **spinning item** variant instead.

### Render Texture

```
render texture %texture at %placement on %side
```

Renders a workspace texture (block face, item, screen, etc.) on the chosen face. The texture is tinted to white and uses the same face lighting as items in the world.

### Render Outline

```
render target block outline color %color line width %width width units %units transparency %transparency through walls %through_walls on shape bounds %bounds pulse %pulse rainbow %rainbow glow %glow wave %wave marquee %marquee ...
```

Renders a colored wireframe outline around the target block's bounds. `transparency` is `0`–`1` (1 = fully opaque). `width units` chooses whether `line width` is measured in `1/16 block` or `pixel` units. Optional toggles layer animated effects on top of the base outline — `pulse` (breathing opacity), `rainbow` (cycling hue), `glow` (soft additive glow with its own color/falloff), `wave` (traveling brightness wave with phase/speed/intensity and its own color), and `marquee` (a moving dashed/scanning band with its own speed) — each with its own color and tempo inputs so effects can be combined and tuned independently.

### Render Crop Growth / Render Tree Growth

```
render crop growth ...
render tree growth ...
```

Purpose-built overlay builders for showing a growth-stage indicator (e.g. a percent-complete texture or model) on farmland crops and sapling/tree-type blocks, without you having to hand-roll the growth-stage math yourself.

### Spinning Variants

- **Center spinning item** — an item graphic rendered at the block center, rotating each tick.
- **Spinning item** — same as the center spinner but anchored to a `placement`.
- **Spinning tree** — renders a 3D tree model at the placement, rotating each tick. Use the **tree species** block to choose oak / spruce / birch / jungle / acacia / dark oak / mangrove / cherry / azalea / flowering.

### Variable Item

```
render variable item %itemVar at %placement on %side
```

Renders a live variable item — handy when the displayed item changes over time (e.g. a battery indicator that switches between iron, gold, and diamond ingots depending on charge level).

### Precise Text

Like **Render text** but with sub-pixel positioning and rotation, intended for decals where you need full control over transform.

### Center Spinning Item

A specialized spinner that always renders at the block center, regardless of placement, and rotates each tick. Best for fully symmetrical items (coins, ingots, gears).

---

## 9. Hiding and Restoring Overlays

```
hide all overlays on block at x: %x y: %y z: %z
show all overlays on block at x: %x y: %y z: %z
```

- `hide` clears every active overlay on a specific block and prevents the Block Overlay's `Overlay logic` from rendering there until you `show` it again.
- `show` re-enables the overlay pipeline for that block.

Useful for state-driven UI: hide the "ENERGY: 42" overlay when the block is broken or out of power, then re-show it when conditions are met.

---

## 10. The 3×3 Anchor Grid

The 9 anchor positions in the **overlay placement** dropdown (see §5) form a **reusable 3×3 grid**:

```
TOP_LEFT     TOP_CENTER     TOP_RIGHT
MIDDLE_LEFT  MIDDLE_CENTER  MIDDLE_RIGHT
BOTTOM_LEFT  BOTTOM_CENTER  BOTTOM_RIGHT
```

You can build layered UIs by combining multiple anchor slots in a single `Overlay logic` procedure:

- **Status HUD:** `TOP_LEFT` = item icon, `TOP_CENTER` = name, `TOP_RIGHT` = charge bar.
- **Compact label:** `MIDDLE_CENTER` = text + `MIDDLE_RIGHT` = number readout.
- **Warning indicator:** `BOTTOM_LEFT` = colored outline, `BOTTOM_CENTER` = warning text.

The grid is consistent across full-block and per-face placements, so once you set up a layout, switching between "overlay on the whole block" and "overlay on a single face" doesn't require recomputing positions.

---

## 11. Match Conditions (SNBT Gating)

Each overlay can be gated on the **held item** or the **looked-at block entity's NBT** using an SNBT match string:

```
match held item with SNBT: {tag:{display:{Name:'{"text":"Wrench"}'}}}
match looked-at block entity NBT with SNBT: {Energy:42}
```

When the match expression is empty, the overlay always renders. When it is set, the overlay only renders while the held item or the targeted block entity's serialized NBT contains the pattern.

Typical uses:

- Show a "Compatible with Wrench" overlay only when the player is holding your custom wrench.
- Show a power-level overlay only when looking at a block entity whose NBT contains a `Power` tag.

---

## 12. Setting Up a Block Overlay Workspace

1. In MCreator, create a new workspace element of type **Block Overlay**.
2. Associate it with a block in your mod (the "target block"). The overlay's render procedure will be invoked for every instance of this block.
3. Open the **Overlay logic** procedure editor. This is the Blockly canvas that fires every render tick on the client.
4. Drag **Overlay Builder** blocks from the toolbox into the procedure:
   - Pick a placement (§5).
   - Pick a side (§6) — use `{front}` for player-facing overlays, or a fixed `Direction` for orientation-stable UI.
   - Wire in the text / number / item / texture / outline you want to render.
5. (Optional) Use **hide** / **show** blocks to gate visibility based on game state.
6. (Optional) Add **SNBT match conditions** to make the overlay contextual.
7. Save and test in the MCreator test environment — overlays should appear in-world on the target block.

That's it — no coordinates, no manual matrix math. The plugin handles the isometric extrusion, face alignment, and lighting.

---

## 13. Biome Tint Colors

```
biome [Water / Grass / Foliage (Leaves)] tint
```

Returns the current biome's smoothed tint color at the Block Overlay element's target block, as a hex color string (e.g. `#5f9c46`) — the same blended water/grass/foliage color vanilla uses when tinting those blocks, so it matches what the biome actually looks like at that spot instead of a flat per-biome constant.

Plug this block directly into any **color** input on an overlay builder block (see §8) — no wiring needed, it reads the target block's `x`/`y`/`z` automatically. Because of that, it's only usable inside a Block Overlay element's **Overlay logic** procedure, where a target block position is defined; dropping it into an unrelated procedure will fail to generate.

Typical uses:

- Tint a texture overlay on a water-adjacent block so it visually matches the surrounding water color.
- Color a leaves/foliage-themed overlay to match the current biome's foliage tint instead of a fixed green.

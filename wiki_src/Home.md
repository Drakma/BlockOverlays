# Block Overlays

**Block Overlays** is an MCreator plugin that renders temporary, world-space visual markers (text, numbers, items, textures, entities, growth stages, outlines, and captured tree structures) directly on top of a target block — no coordinate math, no manual matrix work.

Supported generators: **Forge 1.20.1**, **NeoForge 1.21.1**, **NeoForge 26.1.2**, **NeoForge 26.2**.

This wiki has two parts:

## 📘 [How It Works](How-It-Works)
The technical section — plugin architecture, how a Blockly procedure becomes generated Java across four different generators, the render event pipeline, and the caching strategy that keeps overlays cheap to render.

## 🧩 Blockly How-To
A visual, block-by-block reference for every block the plugin adds, organized by toolbox category:

- **[Getting Started](Getting-Started)** — creating a Block Overlay element and wiring up your first overlay.
- **[Renderers](Renderers)** — every `Render ...` block that actually draws something on a block.
- **[Generation](Generation)** — dev-time tools for capturing `.nbt` tree structures.
- **[Utils](Utils)** — placement, direction, texture/structure selectors, and biome tint helpers used to feed the Renderer blocks.

---

See also: [README](https://github.com/Drakma/BlockOverlays/blob/main/README.md) · [Changelog](https://github.com/Drakma/BlockOverlays/blob/main/CHANGE_LOG.md)

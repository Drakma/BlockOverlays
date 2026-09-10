# Changelog - Block Overlays

## 2026.2.215 - 2026-09-10

### Added

- New **Render tree structure overlay** block: renders a captured multi-block tree structure (`.nbt`, imported via MCreator's Structures panel) as an in-world hologram, instead of the earlier single-scaled-block tree preview.
  - `scale` is the size of the structure's longest axis in blocks (scale 1 = the whole structure fits in one block), matching how scale already worked on the single-block tree overlay.
  - Two growth modes: `uniform scale` (whole structure grows/shrinks with percentage) and `bottom-up reveal` (structure stays full size, more of it is revealed from the ground up as percentage increases).
  - Automatically centers on the target block regardless of canopy asymmetry (centers on the structure's own declared capture size, not the bounding box of placed blocks).
  - Applies biome-correct leaf/vine tint per block (vanilla `BlockColors`/`BlockTintSource`), not just on Forge 1.20.1, where the render path has no world-context tinting hook available.
  - The structure input accepts the picker block, a plain text block, or any String-producing expression, so the structure name can be computed/changed programmatically.
- New **Structure selector** block (`structure_selector`) — double-click picker over the workspace's existing Structures list, returning a `String`.
- New **Utils** toolbox subcategory (under Block Overlays) with dev-time tree capture automation, none of it intended for shipped gameplay logic:
  - **grow tree via bonemeal** — places a sapling/fungus/propagule item and repeatedly applies real vanilla bonemeal growth logic until it becomes a tree; automatically plants dark oak/pale oak as a 2×2 group, since vanilla only grows those from a 2×2 arrangement.
  - **capture tree structure** — saves a region as a `.nbt` structure via the same routine a vanilla Structure Block uses; `height` is a scan ceiling, and the capture is trimmed to the actual topmost non-air block found, so no empty air above the tree is saved.
  - **clear tree area** — resets a capture region back to air between captures.
  - **list all tree sapling items** — scans the item registry for anything that grows into a tree (any `SaplingBlock`, covering vanilla and most modded saplings, plus the vanilla exceptions that aren't: mangrove propagule, azalea, flowering azalea, crimson/warped fungus).
  - **auto-capture all tree structures** — loops the sapling list and grows/captures/clears every tree species in one call; each structure is filed under its own source mod (`generated/<modid>/structure/<sapling_modid>/<sapling_modid>_<sapling_item>.nbt`), so trees from different mods sort into their own folders automatically.

### Fixed

- `StructureTemplate.filterBlocks(pos, settings, block)` is an *inclusive* filter (returns only blocks matching that exact type), not an exclusion — the structure loader was passing `Blocks.STRUCTURE_VOID` expecting "everything except void" and always got zero blocks back. Now discovers the structure's own palette block types first and aggregates `filterBlocks` once per distinct type.
- Structure `.nbt` classpath lookup used a leading `/` with `ClassLoader.getResourceAsStream`, which (unlike `Class.getResourceAsStream`) never strips it, so every lookup silently failed. Paths are now relative (no leading slash).
- `<@addTemplate file="...">` is the actual (and undocumented, outside this repo's own `GEMINI.md` notes) mechanism for pulling a `utils/` file's static methods into a generated Block Overlay class — it was never being called for the tree structure overlay, causing a "cannot find symbol" compile error on regenerate. The dev-tooling Utils blocks route around this entirely by being fully self-contained instead, since the same mechanism doesn't apply to a generic Command element's generated Procedure class.
- Tree hologram was anchoring on the target block's northwest corner instead of its center — the outer render transform was missing the `+0.5` block-center offset that the structure's own local centering math assumed was already applied.

## [2026.2-2026.9.123] - 2026-09-03

### Added

- Initial public release on the standalone repository.
- `Texture` Blockly datatype and workspace image selector.
- Render blocks for item, text, number, texture, and outline overlays.
- 3×3 anchor grid alignment for face-aligned overlays.
- `Direction` → `{front}` / `{back}` / `{left}` / `{right}` resolution helpers.
- Hide / show blocks for per-position overlay visibility.
- Optional SNBT match on held item or looked-at block entity for overlay
  gating.

## 2026.2.174 - 2026-09-09

- Fixed duplicate variable `_a` in screen texture and texture overlay procedures for Forge 1.20.1, NeoForge 1.21.1, NeoForge 26.1.2, NeoForge 26.2
- Built new plugin zip: BlockOverlays-2026.2-2026.9.174.zip

## 2026.2.183 - 2026-09-09

### Added

- New **Biome Tint** value block (`biome [Water/Grass/Foliage] tint`) that returns a hex color string for the current biome's smoothed water, grass, or foliage tint. Reads its target block's `x`/`y`/`z` automatically from the enclosing Block Overlay procedure — no wiring required, just plug it into any `color` input.
- New **Render crop growth** and **Render tree growth** overlay builder blocks for Forge 1.20.1, NeoForge 1.21.1, NeoForge 26.1.2, and NeoForge 26.2.
- Outline overlay: new **width units** dropdown (`1/16 block` or `pixel`) for the line-width input.
- Block Overlay element GUI now requires at least one target block to be selected before saving, and the legacy-block-name migration (for workspaces created with older versions of this plugin) now covers screen texture, precise text, spinning item, and center spinning item blocks in addition to the previous set.

### Fixed

- **Compile error on NeoForge 26.1.2 / 26.2**: `net.minecraft.client.renderer.LightTexture` no longer exists on these targets' Minecraft rendering rewrite (`SubmitCustomGeometryEvent`/pipeline-based rendering). All texture overlay procedures now use the equivalent literal full-bright packed light value (`0xF000F0`) instead.
- **Texture overlays rendering dark depending on placement**: `RenderTypes.entityTranslucent` on NeoForge 26.1.2 / 26.2 applies Minecraft's per-face directional diffuse shading independently of the light value passed to the vertex, which made overlays placed on the top (and bottom) of a block render noticeably dimmer than side-placed overlays. Fixed by correcting the quad's vertex winding order specifically for `UP`/`DOWN` placements and switching to a dedicated render pipeline (registered via NeoForge's `RegisterRenderPipelinesEvent`) that skips per-face lighting entirely, so texture overlays are now uniformly lit regardless of which side of the block they're attached to.
- **Vanilla block outline showing through texture overlays**: a side effect of an earlier attempt at the fix above (using vanilla's `RenderTypes.eyes`) disabled depth-writing, letting the targeted-block selection outline draw through solid overlays. The dedicated render pipeline restores normal depth-write behavior so overlays occlude the outline as before.
- Built new plugin zip: BlockOverlays-2026.2-2026.9.183.zip

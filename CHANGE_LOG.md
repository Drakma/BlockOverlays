# Changelog - Block Overlays

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

# Changelog - Block Overlays

## 2026.2.237 - 2026-09-10

### Added

- New **Render entity overlay** block: renders a live-model hologram of the entity a spawn egg item would spawn (e.g. Zombie Spawn Egg, Pig Spawn Egg). The entity is created but never added to the world, so it stands in its default idle pose with no AI/pathing — a pure client-side preview, same as every other overlay in this plugin. `scale` matches the tree structure overlay's convention: 1 = the entity's longest dimension fits in one block. Optional slow auto-spin.

### Fixed

- **Entity overlay never rendered anything**: the block's JSON definition filename didn't match its `.java.ftl` template filename, so MCreator silently generated no code for it at all — no error, no log output, just nothing. Renamed to match.
- **Entity overlay rendered pitch black**: the preview entity was never positioned anywhere in the world, so its baked-in lighting sampled position `(0,0,0)` instead of the target block. Now positioned at the target block right before extracting its render state each frame.
- **Entity overlay's spin looked stepped/juddery**: it advanced once per 50ms game tick instead of once per render frame, so at any framerate above 20fps the same angle repeated for several frames before jumping. Switched to wall-clock timing.
- **Texture overlay was full-bright regardless of the light value passed in**: the custom render pipeline had an `EMISSIVE` shader define, which (per the shader source) skips lightmap sampling entirely — no light value could ever have worked while that define was present. Removed it and added the required `Sampler2` (lightmap) sampler declaration.
- **Crash: "Missing sampler Sampler2"**: fixed by declaring `Sampler2` on the pipeline above, but a `RenderSetup` also needs `.useLightmap()` to actually bind a texture to that sampler slot — without it, the pipeline expected a sampler nothing ever filled, crashing the game the moment it tried to draw.
- **Severe FPS drop from a single texture/tree/crop overlay instance**: several distinct, stacked causes, all now fixed —
  - The texture overlay's sprite (via `collectParts`/quad scan) and light value were being recomputed from scratch every single render frame; now cached per position/face, refreshed every 2 seconds.
  - Its custom `RenderSetup`/`RenderType` (including an internal texture-binding map) was being rebuilt from scratch on every submission instead of once; now cached per texture.
  - A translucent render pipeline carries real, fixed GPU cost in Minecraft's rendering architecture regardless of how much uses it. Added an opaque/`ALPHA_CUTOUT` fallback pipeline used whenever the overlay's color is fully opaque (the common case), only falling back to translucent when real transparency is requested.
  - The tree and crop overlays were redoing a long item→BlockState resolution chain, a `BlockStateModelSet` lookup, `collectParts()`, and (crop only) a `Stream`-based min/max computation — every frame, for every visible instance, none of which changes moment to moment. Now cached (item resolution and model parts cached indefinitely per JVM session; nothing here is tied to a specific world/atlas instance).
  - The tree structure overlay had no distance cutoff at all, submitting a full block model per structure block (100+) every frame for every nearby matching sapling. Added the same distance-based skip already used elsewhere.
- **Texture overlay occasionally showed a "missing texture" placeholder or wrong tint that self-corrected after a delay**: caused by the new sprite/light caching (above) freezing a transient wrong answer — right after a block is placed or a chunk loads, the model/lighting system can momentarily return an incomplete result. Shortened the cache window (60s → 2s) and made the "missing texture" placeholder specifically never cache with the normal TTL, so it retries every frame until a real texture resolves instead of freezing for up to a minute.
- Cache correctness: a world-position-keyed cache must also be invalidated when the level/world itself changes, or a `TextureAtlasSprite` cached from a previous world's (possibly since-rebuilt) texture atlas can be served as "still fresh" and render as garbage. Also switched cache timestamps from `world.getGameTime()` (resets on a new world, which could make a stale entry look falsely fresh) to `System.currentTimeMillis()`.

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

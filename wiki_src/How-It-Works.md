# How It Works

This page covers the plugin's internals — useful if you're debugging a generated build, extending the plugin, or just curious. Nothing here is required to *use* the plugin; see the [Blockly How-To](Home) pages for that.

## The Block Overlay workspace element

Block Overlays adds a custom MCreator mod element type, **Block Overlay** (`BlockOverlayElement.java`), separate from the built-in Block/Item/Procedure elements. Each instance stores:

- One or more **target blocks** (`targetBlock` / `targetBlocks`) — vanilla or a custom block from the same workspace.
- A **visibility scope**: `LOOKED_AT` (only render for the block the player is currently targeting) or `NEARBY_MATCHING` (render on every matching block currently visible on screen).
- Optional gating: a specific blockstate property/value, `requiresCrouching`, a held-item/tag match, and partial SNBT matches against the held item or a targeted block entity.
- A `maximumDistance` render cutoff.
- The **Overlay logic** procedure itself, stored as `overlayxml` — a normal MCreator/Blockly procedure XML blob, just like any Procedure element.

At generate time, `BlockOverlayElement.getAdditionalTemplateData()` resolves the target block(s) to registry IDs (including `CUSTOM:<name>` references to other elements in the same workspace) and hands the whole thing, plus the compiled procedure data, to a per-generator FreeMarker template.

## One template per generator

Because the rendering APIs changed substantially between Minecraft/Forge/NeoForge versions, there is a **separate, hand-written template tree per generator**:

```
forge-1.20.1/      neoforge-1.21.1/      neoforge-26.1.2/      neoforge-26.2/
├── templates/blockoverlay/block_overlay.java.ftl   ← the element's generated class
├── procedures/*.java.ftl                            ← one per Renderer/Utils/Generation block
├── utils/*.java.ftl                                 ← shared helpers, pulled in via <@addTemplate>
└── triggers/render_block_overlays.java.ftl
```

The Blockly-side block definitions (`procedures/*.json` at the repo root, **not** inside a generator folder) are shared across all four generators — one JSON per block. MCreator matches a Blockly block to its generator-specific `.java.ftl` **by filename**, so `procedures/overlay_builder_entity.json` must be paired with `overlay_builder_entity.java.ftl` in *every* generator folder, kept in sync by hand. A filename mismatch causes MCreator to silently generate no code for that block at all, with no error and no log output — worth checking first if a new block "does nothing."

`<@addTemplate file="some_util.java.ftl"/>` at the top of a procedure template pulls a `utils/*.java.ftl` file's static members into the generated class for that specific procedure. It is how shared caches (e.g. the tree/crop model-parts cache) are reused across multiple blocks — but each new consumer of a shared utils file should be treated cautiously, since MCreator's deduplication behavior for a utils file `<@addTemplate>`-ed by *multiple different blocks in the same generated class* hasn't been independently verified. Where that mattered, blocks were given their own dedicated, separately named cache instead of sharing one.

## The render event pipeline

The generated `${className}` class subscribes to the client render event and, once per frame, decides which block positions to render at:

- **`LOOKED_AT` scope** — uses the player's current block-ray-trace target, if any, and if it matches the configured target block(s).
- **`NEARBY_MATCHING` scope** — scans loaded chunk sections within render distance for matching blocks once per second (`lastVisibleSectionRefresh`, throttled to every 20 ticks) and caches the resulting position set (`VISIBLE_SECTION_POSITIONS`) keyed by section, re-rendering all of them every frame without re-scanning.

For each matching position within `maximumDistance`, the SNBT/blockstate/crouching/held-item gates are checked, and if they pass, every Renderer block placed in the Overlay logic procedure runs for that position.

The actual draw call differs by generator, since this is exactly where the Minecraft rendering API changed:

| Generator | Event | Draw mechanism |
|---|---|---|
| Forge 1.20.1 | `RenderLevelStageEvent` | Classic immediate `PoseStack` + `MultiBufferSource`, e.g. `Minecraft.getInstance().getBlockRenderer().renderSingleBlock(...)` / `EntityRenderDispatcher.render(...)`, ended with `bufferSource.endBatch()`. |
| NeoForge 1.21.1, 26.1.2, 26.2 | `SubmitCustomGeometryEvent` | The newer submit-node pipeline — geometry is *submitted* (`event.getSubmitNodeCollector().submitBlockModel(...)`, `EntityRenderDispatcher.submit(...)`) against `event.getLevelRenderState()` rather than drawn immediately. |

## Custom render pipelines (26.x)

The texture-overlay block needs a render pipeline vanilla doesn't ship (an arbitrarily tinted, lit, textured quad), so on the 26.x generators the plugin registers its own `RenderPipeline`s via `RegisterRenderPipelinesEvent`:

- Built from `core/entity` vertex/fragment shaders with `NO_OVERLAY`/`NO_CARDINAL_LIGHTING` defines, `Sampler0` (the texture) and `Sampler2` (the lightmap).
- **Two variants**: a translucent one (`BlendFunction.TRANSLUCENT`) for overlays with real transparency, and an opaque `ALPHA_CUTOUT` one used whenever the configured color is fully opaque — translucent rendering carries a fixed GPU cost in Minecraft's pipeline (its own sorted draw pass) regardless of how much geometry uses it, so the opaque fallback is preferred whenever real transparency isn't actually needed.
- `RenderSetup.useLightmap()` is required to bind an actual texture to `Sampler2` — declaring the sampler on the pipeline alone isn't sufficient and will crash with "Missing sampler Sampler2" the moment something tries to draw with it.
- An `EMISSIVE` shader define looks tempting for a full-bright overlay but actually breaks *variable* lighting entirely: `core/entity.fsh` wraps `color *= lightMapColor` inside `#ifndef EMISSIVE`, so with that define set no light value can ever have an effect. Don't use it unless you genuinely want full brightness unconditionally.

Both the `RenderSetup` and the `RenderType` built from it are expensive to construct and are cached per-texture rather than rebuilt every submission.

## Caching strategy

Nearly every Renderer block does *some* per-frame, per-instance work that doesn't actually change moment to moment, and early versions of several blocks recomputed all of it from scratch every frame for every visible instance — a real, measured FPS cost that scales with the number of overlays on screen. The general pattern used throughout the plugin:

- **Pure, world-independent lookups** (item → BlockState resolution, a block's `BlockStateModelPart`s) are cached indefinitely per JVM session, keyed by the input alone — safe because `BlockState` instances are canonical/interned and these values are pure functions.
- **World-dependent values** (a texture's resolved sprite, a block's light level, a biome tint) are cached with a short time-to-live (currently 15s) keyed by position, and additionally invalidated on `Level` identity change — a cache keyed only on position would otherwise serve a stale `TextureAtlasSprite` from a *previous* world's texture atlas.
- **Cache timestamps use `System.currentTimeMillis()`, never `world.getGameTime()`** — game time resets when a new world loads, which can make a stale cache entry look falsely fresh (a negative "age" can pass an `age < TTL` check).
- **Transient wrong answers are never cached at their normal TTL.** Right after a block is placed, model/lighting lookups can briefly return an incomplete result (a "missing texture" placeholder, an unresolved tint). If that transient result were cached for the normal TTL, the visible glitch would freeze for that whole window instead of self-correcting within a frame or two. The texture cache specifically detects the missing-texture sentinel and stores it as already-expired, so it retries every frame until a real answer resolves.
- **Distance cutoffs** exist on every Renderer block (`maximumDistance` at the element level, plus a per-block squared-distance check before doing any of the above work) so overlays far outside render-relevant range cost nothing.

## Animation and timing

Two different clocks are used deliberately for different purposes:

- **Wall-clock time** (`System.nanoTime()`) drives spin angles and the entity overlay's look-around motion, so they animate smoothly at whatever framerate the client is actually running, instead of visibly stepping at the 20Hz tick rate.
- **A throttled 20Hz gate** (`System.currentTimeMillis()`, checked against a 50ms interval) drives the entity overlay's walk-cycle animation specifically, because `LivingEntity.walkAnimation` (`WalkAnimationState`) is an accumulator designed to be advanced once per game tick — calling it once per render frame instead would play the cycle far too fast above 20fps.

The entity overlay's "Look around" animation is a sum of several sine waves at incommensurate frequencies (rather than one clean sine wave) so the motion reads as irregular and natural instead of visibly repeating, with a per-entity-type phase offset (derived from `EntityType.hashCode()`) so different mob types don't all glance in lockstep.

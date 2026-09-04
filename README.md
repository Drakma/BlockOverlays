# Block Overlays

MCreator procedure blocks for world-space overlays on NeoForge 26.1.2 and 26.2. Includes a native `Texture` Blockly datatype and workspace image selector.

## Blocks

- Render a tinted texture on a selected block side
- Select workspace block, item, entity, effect, particle, screen, armor, or other textures with an image preview
- Convert between `Texture` and text resource locations
- Get the position Vector of the block the player is looking at
- Resolve `{front}`, `{back}`, `{left}`, and `{right}` from a block-facing Direction
- Render an item graphic at a block position
- Render text at a block position
- Render a number at a block position
- Render an item, text, or number fixed to a selected block face with face lighting
- Render a colored outline around a block
- Hide or restore every overlay on a block
- Place item, text, number, and texture overlays on a reusable 3x3 anchor grid

## Usage

Create a **Block Overlay** workspace element and use its **Overlay logic** Blockly editor. The **Overlay Builder** category contains text, number, item, texture, and outline blocks that automatically render on that element's associated target block; they do not need coordinate inputs. Use normal Blockly logic to control when any number of render blocks run.

Text, number, texture, and outline blocks use MCreator's visual color picker. Selected RGB colors render fully opaque.

Use the **select texture** block to open MCreator's native texture dialog. The selected workspace image becomes a typed `Texture` value. Choose the target face with any `Direction` block. A small expansion such as `0.002` prevents z-fighting with the block model.

The **overlay placement** value provides top-left, top-center, top-right, middle-left, middle-center, middle-right, bottom-left, bottom-center, and bottom-right alignment. Left placements align the content's left edge, center placements center it, and right placements align its right edge. Top, middle, and bottom apply the equivalent vertical alignment. Texture overlays occupy the selected one-third cell on their chosen face.

Relative direction blocks accept the block's facing Direction. `{front}` returns facing, `{back}` returns its opposite, `{left}` rotates facing clockwise by 90 degrees, and `{right}` rotates it counter-clockwise by 90 degrees. Left and right are intended for horizontal facings.

The outline block uses the visual color picker and retains a dynamic line-width input for thickness. Block Overlay workspace elements place their face-aligned item, text, and texture layers against the selected block's shape bounds, so partial blocks such as slabs and inset models use their actual visible dimensions. Their outline layer follows that same shape.

The hide/show blocks maintain visibility by block position in the current render procedure. A hide takes effect no later than the next rendered frame and remains active until the matching show block runs.

The item, text, and number overlays face the camera. Coordinates identify the lower corner of the target block; overlays are centered over that block. Text and number overlays automatically shrink to fit within the target block. Face-aligned item, text, and number overlays remain fixed to their selected face and use the lighting at that face; face-aligned labels render without shadows for clear glyphs.

Block Overlay workspace elements can optionally require a partial SNBT match on the player's held item custom data or the looked-at block entity data. Leave either field empty to ignore it. For example, `{my_flag:1b}` matches a held item whose custom data contains that value. Invalid SNBT makes that overlay stay hidden instead of interrupting rendering.

Block Overlay workspace elements use an embedded MCreator Procedure Blockly editor. Build normal logic statements there to control rendering, and place any number of Block Overlays render blocks inside those statements. The generated renderer provides `world`, `entity`, `x`, `y`, `z`, and the client render `event` to the Blockly code. The target tab chooses whether the program runs for the looked-at target block or every matching block visible on screen; the always-visible mode refreshes visible-section matches every second.

## Building

Run `./build.ps1`. Like BlockDirections, it compiles Java, stages plugin resources, packages with the JDK `jar` tool, and writes:

`build/distribution/BlockOverlays-{mcreatorVersion}-{year}.{month}.{increment}.zip`

The build updates `plugin.json`, then increments `version.properties` for the next build.

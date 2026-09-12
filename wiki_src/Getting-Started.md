# Getting Started

## 1. Create a Block Overlay element

In MCreator, create a new workspace element and choose the **Block Overlay** type.

![Creating a new Block Overlay element](images/setup/new-block-overlay-element.png)

Configure its settings:

- **Target block(s)** — a vanilla block or a block from this workspace. The overlay's logic runs for every instance of this block.
- **Visibility scope** — `Looked at` (only render while the player is aiming at the block) or `Nearby matching` (render on every matching block currently visible on screen).
- Optional gates — a specific blockstate property/value, requires-crouching, a held item/tag match, and SNBT match strings against the held item or a targeted block entity's data (see [Match Conditions](#match-conditions-snbt-gating) below).
- **Maximum distance** — render cutoff, in blocks.

![Block Overlay element settings panel](images/setup/element-settings.png)

## 2. Open Overlay logic

Every Block Overlay element has an embedded **Overlay logic** Blockly procedure editor. This fires every client render frame for every position the element decides to render at (see [How It Works](How-It-Works) for exactly when). It's a normal Blockly canvas — use ordinary logic blocks (`if`, variables, loops) to decide *when* to run a Renderer block, and the plugin's own blocks to decide *what* to render.

![The Overlay logic Blockly editor](images/setup/overlay-logic-editor.png)

You don't need to supply coordinates to any Renderer block — the element already knows its own target block's position and hands it in automatically.

## 3. The toolbox

Every block the plugin adds lives under the **Block Overlays** toolbox category, split into three subcategories:

![Block Overlays toolbox with Renderers, Generation, and Utils expanded](images/setup/toolbox-categories.png)

- **[Renderers](Renderers)** — every block whose name starts with `Render ...`. These are the blocks that actually draw something (text, items, textures, entities, growth stages, outlines, tree structures) on the target block.
- **[Utils](Utils)** — helpers that feed the Renderer blocks: the 3×3 placement grid, direction resolution, texture/structure selectors, biome tint, and the looked-at block's position vector.
- **[Generation](Generation)** — dev-time tools for capturing `.nbt` tree structures used by the tree structure Renderer. Not meant to ship in normal gameplay logic — wire these into a **Command** element instead, since they take explicit `x`/`y`/`z` inputs rather than an implicit target block.

## 4. A minimal example

1. Drag a **Render text** block into Overlay logic.
2. Fill `placement` with an **Overlay placement** block (pick `MIDDLE_CENTER`).
3. Fill `side` with a **{Front}** direction block.
4. Type a literal string into `text`, e.g. `"Hello!"`.
5. Save, regenerate, and look at the target block in-game — the text should float above its front face.

From there, combine any number of Renderer blocks in one procedure, gate them with normal `if` logic on your own variables, and layer multiple anchors from the 3×3 grid for compound HUD-style overlays. See [Renderers](Renderers) for every block's exact inputs, and [Utils](Utils) for the placement/direction/selector blocks that feed them.

## Match Conditions (SNBT Gating)

Each Block Overlay element can optionally require a partial SNBT match on the player's held item or the looked-at block entity's data, e.g.:

```
{tag:{display:{Name:'{"text":"Wrench"}'}}}
```

Leave the field empty to skip that gate entirely. When set, the overlay only renders while the held item or the targeted block entity's serialized NBT *contains* the given pattern — invalid SNBT simply keeps the overlay hidden rather than erroring.

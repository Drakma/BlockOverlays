# Screenshot checklist (not a wiki page — working doc)

This file is **not published to the wiki**. All 27 per-block images now have generated approximate mockups (`wiki_src/images/blocks/*.svg`) — no action needed there unless you want to replace one with a real screenshot later (same filename, swap `.svg` for `.png` and update the one `![...]` reference in the relevant page).

What's still needed: **4 real MCreator UI screenshots** for the [Getting Started](Getting-Started) page — these show application chrome (dialogs, panels) that can't be approximated the same way.

## How to capture

1. Open MCreator with the BlockOverlays plugin installed.
2. Screenshot just the relevant panel/dialog — a tight crop, not the whole window. PNG, any resolution.
3. Save at the exact path below (relative to `wiki_src/`), then let me know — I'll push the wiki update.

| File | What to capture |
|---|---|
| `images/setup/new-block-overlay-element.png` | MCreator's "new element" dialog/screen with the **Block Overlay** element type selected (or just-created, showing it's a distinct type from Block/Item/Procedure). |
| `images/setup/element-settings.png` | A Block Overlay element's settings panel — target block, visibility scope dropdown, maximum distance, etc. |
| `images/setup/overlay-logic-editor.png` | The **Overlay logic** Blockly canvas open, ideally with 2-3 simple blocks already placed (e.g. a Render text setup) so it doesn't look empty. |
| `images/setup/toolbox-categories.png` | The Blockly toolbox with **Block Overlays** expanded showing the **Renderers**, **Generation**, and **Utils** subcategories all visible in the tree. |

Partial batches are fine — send what you have.

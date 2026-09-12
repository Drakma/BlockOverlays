// Generates approximate Blockly-style SVG mockups for BlockOverlays wiki pages.
// Not pixel-perfect Blockly rendering -- a schematic approximation per row of inputs,
// using "external inputs" layout (each input_value gets its own row).
const fs = require("fs");
const path = require("path");

const PROC_DIR = "C:/Users/casey/Desktop/MCreatorPlugins/BlockOverlays/procedures";
const OUT_DIR = "C:/Users/casey/Desktop/MCreatorPlugins/BlockOverlays/wiki_src/images/blocks";
fs.mkdirSync(OUT_DIR, { recursive: true });

// ---- colours ---------------------------------------------------------------
// Sampled from a real MCreator/Blockly screenshot of one of these blocks
// (colour: 20 hue, as rendered by MCreator's actual Blockly theme).
const PLUGIN_FILL = "#72574A";
const PLUGIN_STROKE = "#4A382F";
const PLUGIN_TEXT = "#ffffff";

const TYPE_STYLE = {
  Number: { fill: "#4A5172", stroke: "#2B3252", text: "#ffffff" },
  Boolean: { fill: "#4A5172", stroke: "#2B3252", text: "#ffffff" },
  String: { fill: "#4A5172", stroke: "#2B3252", text: "#ffffff" },
  List: { fill: "#4A5172", stroke: "#2B3252", text: "#ffffff" },
  Vector: { fill: "#4A5172", stroke: "#2B3252", text: "#ffffff" },
  MCItem: { fill: "#5C5340", stroke: "#3A3427", text: "#ffffff" },
  Texture: { fill: PLUGIN_FILL, stroke: PLUGIN_STROKE, text: "#ffffff" },
  OverlayPlacement: { fill: PLUGIN_FILL, stroke: PLUGIN_STROKE, text: "#ffffff" },
  Direction: { fill: PLUGIN_FILL, stroke: PLUGIN_STROKE, text: "#ffffff" },
  Colour: { fill: "#cccccc", stroke: "#888888", text: "#222222" },
  Default: { fill: "#888888", stroke: "#5c5c5c", text: "#ffffff" },
};

function styleFor(check) {
  return TYPE_STYLE[check] || TYPE_STYLE.Default;
}

// ---- text metrics (approximation, no real font available) ---------------
function textWidth(str, fontSize) {
  // Rough average glyph width for a common UI sans font.
  return str.length * fontSize * 0.58;
}

function esc(s) {
  return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}

// ---- toolbox_init parsing -------------------------------------------------
// Extract a rough example value per named input from the block's toolbox_init XML snippets.
function parseToolboxInit(initArr) {
  const map = {};
  if (!initArr) return map;
  for (const snippet of initArr) {
    const nameMatch = snippet.match(/<value name="([^"]+)">/);
    if (!nameMatch) continue;
    const inputName = nameMatch[1];
    const typeMatch = snippet.match(/<block type="([^"]+)">/);
    const blockType = typeMatch ? typeMatch[1] : null;
    const fieldMatch = snippet.match(/<field name="[^"]+">([^<]*)<\/field>/);
    const fieldValue = fieldMatch ? fieldMatch[1] : null;
    map[inputName] = { blockType, fieldValue };
  }
  return map;
}

function titleCaseFromConstant(s) {
  // Items.PIG_SPAWN_EGG -> Pig Spawn Egg
  const raw = s.includes(".") ? s.split(".").pop() : s;
  return raw
    .toLowerCase()
    .split("_")
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(" ");
}

function exampleFor(argName, check, initMap, fallback) {
  const init = initMap[argName];
  if (init) {
    if (init.blockType === "math_number") return { text: init.fieldValue, check: "Number" };
    if (init.blockType === "text") return { text: '"' + init.fieldValue + '"', check: "String" };
    if (init.blockType === "logic_boolean") return { text: init.fieldValue, check: "Boolean" };
    if (init.blockType === "mcitem_all") return { text: titleCaseFromConstant(init.fieldValue), check: "MCItem" };
    if (init.blockType === "overlay_placement") return { text: init.fieldValue, check: "OverlayPlacement" };
    if (init.blockType === "direction_constant") return { text: init.fieldValue || "NORTH", check: "Direction" };
    if (init.fieldValue) return { text: init.fieldValue, check };
  }
  return { text: fallback, check };
}

function fallbackFor(check) {
  switch (check) {
    case "Number": return "0";
    case "Boolean": return "false";
    case "String": return '"text"';
    case "MCItem": return "Item";
    case "Texture": return "texture";
    case "OverlayPlacement": return "MIDDLE_CENTER";
    case "Direction": return "{Front}";
    case "Vector": return "(x, y, z)";
    case "List": return "[ list ]";
    default: return "value";
  }
}

// ---- message0 tokenizer / row builder ------------------------------------
// Splits "Render text %1 at %2 on %3 face color %4" into text/placeholder tokens,
// then groups them into rows using Blockly's external-inputs convention: each
// input_value starts accumulating a NEW row, and any following literal text /
// fields attach to that SAME row until the next input_value.
function buildRows(message0, args0, initMap) {
  const tokens = [];
  const re = /%(\d+)/g;
  let last = 0, m;
  while ((m = re.exec(message0))) {
    if (m.index > last) tokens.push({ text: message0.slice(last, m.index) });
    tokens.push({ arg: args0[parseInt(m[1], 10) - 1] });
    last = re.lastIndex;
  }
  if (last < message0.length) tokens.push({ text: message0.slice(last) });

  // Each row = [label/field pieces that appeared since the previous input] + [this input's socket].
  // Any pieces left over after the last input (or, for blocks with zero inputs, all pieces) become
  // a final label-only row.
  const rows = [];
  let pending = [];

  for (const tok of tokens) {
    if (tok.text !== undefined) {
      const t = tok.text.trim();
      if (!t) continue;
      pending.push({ kind: "text", value: t });
      continue;
    }
    const arg = tok.arg;
    if (arg.type === "input_value") {
      const ex = exampleFor(arg.name, arg.check, initMap, fallbackFor(arg.check));
      rows.push({ pieces: pending, socket: { name: arg.name, check: arg.check, example: ex } });
      pending = [];
    } else if (arg.type === "field_dropdown") {
      const opt = (arg.options && arg.options[0]) ? arg.options[0][0] : "option";
      pending.push({ kind: "dropdown", value: opt });
    } else if (arg.type === "field_color_selector") {
      pending.push({ kind: "swatch", value: arg.color || "#ffffff" });
    } else {
      pending.push({ kind: "text", value: String(arg.name || "") });
    }
  }
  if (pending.length) rows.push({ pieces: pending, socket: null });
  return rows;
}

// ---- SVG rendering ---------------------------------------------------------
// Shape constants approximate Blockly's real "Geras" renderer geometry
// (see google/blockly core/renderers/common/constants.ts): CORNER_RADIUS 8,
// NOTCH_WIDTH 15 (6 + 3 + 6) x NOTCH_HEIGHT 4, PUZZLE_TAB 8w x 15h as a
// smooth double-bezier bump rather than straight/arc segments.
const FONT = "font-family='Segoe UI, Verdana, Helvetica, sans-serif'";
const ROW_H = 32;
const PAD_X = 14;
const CORNER_R = 8;
const NOTCH_H = 4;

// Chevron notch cut into a horizontal edge, travelling left-to-right (top) or
// right-to-left (bottom) -- dips by NOTCH_H then returns to the edge level.
function notchPath(sign) {
  return `l ${6 * sign} ${NOTCH_H} l ${3 * sign} 0 l ${6 * sign} ${-NOTCH_H}`;
}

// Smooth puzzle-tab bump on a vertical edge (output/value connection),
// travelling downward (sign=1) or upward (sign=-1); bulges outward by 6px.
function tabPath(sign) {
  return `c 0,${4 * sign} -6,${2 * sign} -6,${8 * sign} c 0,${5 * sign} 6,${3 * sign} 6,${8 * sign}`;
}

function rowWidth(row) {
  let w = PAD_X;
  for (const p of row.pieces) {
    if (p.kind === "text") w += textWidth(p.value, 14) + 8;
    else if (p.kind === "dropdown") w += textWidth(p.value, 13) + 26;
    else if (p.kind === "swatch") w += 34;
  }
  if (row.socket) {
    w += 8; // connector nub
    w += Math.max(50, textWidth(row.socket.example.text, 13) + 24);
  }
  w += PAD_X;
  return w;
}

function renderRowContent(row, x0, cy, rightEdge) {
  let x = x0;
  let out = "";
  for (const p of row.pieces) {
    if (p.kind === "text") {
      out += `<text x="${x}" y="${cy + 5}" font-size="14" ${FONT} fill="#ffffff">${esc(p.value)}</text>`;
      x += textWidth(p.value, 14) + 8;
    } else if (p.kind === "dropdown") {
      const w = textWidth(p.value, 13) + 26;
      out += `<rect x="${x}" y="${cy - 12}" width="${w}" height="24" rx="4" fill="#3a2b1c" stroke="#20160c"/>`;
      out += `<text x="${x + 8}" y="${cy + 5}" font-size="13" ${FONT} fill="#ffffff">${esc(p.value)}</text>`;
      out += `<text x="${x + w - 16}" y="${cy + 5}" font-size="11" ${FONT} fill="#e5c9a3">\u25BC</text>`;
      x += w + 8;
    } else if (p.kind === "swatch") {
      out += `<rect x="${x}" y="${cy - 10}" width="26" height="20" rx="3" fill="${p.value}" stroke="#20160c"/>`;
      x += 34;
    }
  }
  if (row.socket) {
    // Real MCreator/Blockly external-input rows flush the plugged-in child block
    // to the block's right edge, regardless of how long the row's own label is.
    const st = styleFor(row.socket.check);
    const label = row.socket.example.text;
    const bw = Math.max(50, textWidth(label, 13) + 24);
    const by = cy - 13;
    const bxRight = rightEdge;
    const bxLeft = bxRight - bw;
    const r = 6; // corner radius for the small nested pill
    const pillH = 28; // 2*r corners + 16px puzzle-tab bump, no extra margin
    const by2 = cy - pillH / 2;
    out += `<path d="M ${bxLeft + r} ${by2}
      h ${bw - r}
      a ${r} ${r} 0 0 1 ${r} ${r}
      V ${by2 + pillH - r}
      a ${r} ${r} 0 0 1 ${-r} ${r}
      H ${bxLeft + r}
      a ${r} ${r} 0 0 1 ${-r} ${-r}
      ${tabPath(-1)}
      a ${r} ${r} 0 0 1 ${r} ${-r} Z" fill="${st.fill}" stroke="${st.stroke}" stroke-width="1.5"/>`;
    out += `<text x="${bxLeft + bw / 2}" y="${cy + 5}" font-size="13" ${FONT} fill="${st.text}" text-anchor="middle">${esc(label)}</text>`;
  }
  return { svg: out };
}

function buildBlockSvg(title, rows, shape) {
  let width = 0;
  for (const r of rows) width = Math.max(width, rowWidth(r));
  const bodyHeight = Math.max(rows.length * ROW_H, shape === "value" ? 2 * CORNER_R + 16 : 0);
  const topPad = shape === "statement" ? NOTCH_H + 4 : 6;
  const botPad = shape === "statement" ? NOTCH_H + 4 : 6;
  const leftPad = shape === "value" ? 8 : 0; // room for the output tab bump
  const totalW = width + leftPad + 12;
  const totalH = bodyHeight + topPad + botPad + 12;

  let path;
  const bx = leftPad + 6, by = topPad + 6, bw = width, bh = bodyHeight;
  if (shape === "statement") {
    // rounded rect with a chevron notch cut into the top and a matching bump on the bottom
    const nx = bx + 18;
    path = `M ${bx + CORNER_R} ${by}
      H ${nx}
      ${notchPath(1)}
      H ${bx + bw - CORNER_R}
      a ${CORNER_R} ${CORNER_R} 0 0 1 ${CORNER_R} ${CORNER_R}
      V ${by + bh - CORNER_R}
      a ${CORNER_R} ${CORNER_R} 0 0 1 ${-CORNER_R} ${CORNER_R}
      H ${nx + 15}
      ${notchPath(-1)}
      H ${bx + CORNER_R}
      a ${CORNER_R} ${CORNER_R} 0 0 1 ${-CORNER_R} ${-CORNER_R}
      V ${by + CORNER_R}
      a ${CORNER_R} ${CORNER_R} 0 0 1 ${CORNER_R} ${-CORNER_R} Z`;
  } else {
    // value/reporter block: rounded rect with a smooth puzzle-tab bump on the left edge
    const midY = by + bh / 2;
    path = `M ${bx + CORNER_R} ${by}
      H ${bx + bw - CORNER_R}
      a ${CORNER_R} ${CORNER_R} 0 0 1 ${CORNER_R} ${CORNER_R}
      V ${by + bh - CORNER_R}
      a ${CORNER_R} ${CORNER_R} 0 0 1 ${-CORNER_R} ${CORNER_R}
      H ${bx + CORNER_R}
      a ${CORNER_R} ${CORNER_R} 0 0 1 ${-CORNER_R} ${-CORNER_R}
      V ${midY + 8}
      ${tabPath(-1)}
      V ${by + CORNER_R}
      a ${CORNER_R} ${CORNER_R} 0 0 1 ${CORNER_R} ${-CORNER_R} Z`;
  }

  let inner = "";
  const rightEdge = bx + bw - PAD_X;
  for (let i = 0; i < rows.length; i++) {
    const cy = by + i * ROW_H + ROW_H / 2;
    const { svg } = renderRowContent(rows[i], bx + PAD_X, cy, rightEdge);
    inner += svg;
  }

  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${totalW}" height="${totalH}" viewBox="0 0 ${totalW} ${totalH}">
  <path d="${path}" fill="${PLUGIN_FILL}" stroke="${PLUGIN_STROKE}" stroke-width="1.5"/>
  ${inner}
</svg>`;
  return svg;
}

// ---- main ------------------------------------------------------------------
const dump = JSON.parse(fs.readFileSync(process.env.SCRATCH + "/blocks_dump.json", "utf8"));

const BLOCK_FILES = {
  "render-text.svg": "overlay_builder_text.json",
  "render-number.svg": "overlay_builder_number.json",
  "render-item.svg": "overlay_builder_item.json",
  "render-variable-item.svg": "overlay_builder_variable_item.json",
  "render-spinning-item.svg": "overlay_builder_spinning_item.json",
  "render-center-spinning-item.svg": "overlay_builder_center_spinning_item.json",
  "render-block-texture.svg": "overlay_builder_texture.json",
  "render-screen-texture.svg": "overlay_builder_screen_texture.json",
  "render-precise-text.svg": "overlay_builder_precise_text.json",
  "render-crop-overlay.svg": "overlay_builder_crop.json",
  "render-tree-overlay.svg": "overlay_builder_tree.json",
  "render-tree-structure-overlay.svg": "overlay_builder_tree_structure.json",
  "render-entity-overlay.svg": "overlay_builder_entity.json",
  "render-outline.svg": "overlay_builder_outline.json",
  "grow-tree-via-bonemeal.svg": "grow_sapling_via_bonemeal.json",
  "capture-tree-structure.svg": "capture_tree_structure.json",
  "clear-tree-area.svg": "clear_tree_area.json",
  "list-all-tree-sapling-items.svg": "list_tree_sapling_items.json",
  "auto-capture-all-tree-structures.svg": "auto_capture_all_tree_structures.json",
  "overlay-placement.svg": "overlay_placement.json",
  "texture-selector.svg": "texture_selector.json",
  "screen-texture-selector.svg": "screen_texture_selector.json",
  "structure-selector.svg": "structure_selector.json",
  "biome-tint.svg": "biome_tint.json",
  "looked-at-block-vector.svg": "looked_at_block_vector.json",
};

for (const [outName, jsonFile] of Object.entries(BLOCK_FILES)) {
  const d = dump[jsonFile];
  if (!d) { console.error("missing", jsonFile); continue; }
  const initMap = parseToolboxInit(d.toolbox_init);
  const rows = buildRows(d.message0, d.args0, initMap);
  const shape = d.previousStatement ? "statement" : "value";
  const svg = buildBlockSvg(d.message0, rows, shape);
  fs.writeFileSync(path.join(OUT_DIR, outName), svg, "utf8");
  console.log("wrote", outName, shape);
}

// ---- composite: direction helpers (4 small value blocks stacked) ---------
{
  const files = ["overlay_direction_front.json", "overlay_direction_back.json", "overlay_direction_left.json", "overlay_direction_right.json"];
  const svgs = files.map((f) => {
    const d = dump[f];
    const rows = buildRows(d.message0, d.args0, parseToolboxInit(d.toolbox_init));
    return buildBlockSvg(d.message0, rows, "value");
  });
  // stack them vertically into one file by extracting inner content is complex; instead just
  // write four separate small svgs concatenated inside a single svg via nested <svg> elements.
  let y = 0;
  const parts = [];
  let maxW = 0;
  const parsed = svgs.map((s) => {
    const wm = s.match(/width="(\d+(?:\.\d+)?)"/);
    const hm = s.match(/height="(\d+(?:\.\d+)?)"/);
    return { s, w: parseFloat(wm[1]), h: parseFloat(hm[1]) };
  });
  for (const p of parsed) maxW = Math.max(maxW, p.w);
  const gap = 8;
  const totalH = parsed.reduce((a, p) => a + p.h, 0) + gap * (parsed.length - 1);
  for (const p of parsed) {
    const inner = p.s.replace(/^<svg[^>]*>/, "").replace(/<\/svg>$/, "");
    parts.push(`<svg x="0" y="${y}" width="${p.w}" height="${p.h}">${inner}</svg>`);
    y += p.h + gap;
  }
  const combined = `<svg xmlns="http://www.w3.org/2000/svg" width="${maxW}" height="${totalH}" viewBox="0 0 ${maxW} ${totalH}">${parts.join("\n")}</svg>`;
  fs.writeFileSync(path.join(OUT_DIR, "direction-helpers.svg"), combined, "utf8");
  console.log("wrote direction-helpers.svg (composite)");
}

// ---- composite: texture <-> text conversion (2 value blocks stacked) -----
{
  const files = ["texture_to_text.json", "texture_from_text.json"];
  const svgs = files.map((f) => {
    const d = dump[f];
    const rows = buildRows(d.message0, d.args0, parseToolboxInit(d.toolbox_init));
    return buildBlockSvg(d.message0, rows, "value");
  });
  let y = 0;
  const parts = [];
  let maxW = 0;
  const parsed = svgs.map((s) => {
    const wm = s.match(/width="(\d+(?:\.\d+)?)"/);
    const hm = s.match(/height="(\d+(?:\.\d+)?)"/);
    return { s, w: parseFloat(wm[1]), h: parseFloat(hm[1]) };
  });
  for (const p of parsed) maxW = Math.max(maxW, p.w);
  const gap = 10;
  const totalH = parsed.reduce((a, p) => a + p.h, 0) + gap * (parsed.length - 1);
  for (const p of parsed) {
    const inner = p.s.replace(/^<svg[^>]*>/, "").replace(/<\/svg>$/, "");
    parts.push(`<svg x="0" y="${y}" width="${p.w}" height="${p.h}">${inner}</svg>`);
    y += p.h + gap;
  }
  const combined = `<svg xmlns="http://www.w3.org/2000/svg" width="${maxW}" height="${totalH}" viewBox="0 0 ${maxW} ${totalH}">${parts.join("\n")}</svg>`;
  fs.writeFileSync(path.join(OUT_DIR, "texture-text-conversion.svg"), combined, "utf8");
  console.log("wrote texture-text-conversion.svg (composite)");
}

console.log("done");

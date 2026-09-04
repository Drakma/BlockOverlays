# BlockOverlays Project Knowledge & Rules

## 1. Vertex Colors & BufferBuilder Alpha Encoding

- In Minecraft's `VertexConsumer` / `BufferBuilder`, `setColor(int color)` calls `putRgba(color)` which expects **RGBA** (`0xRRGGBBAA`), NOT ARGB (`0xAARRGGBB`).
- Passing an ARGB integer writes the alpha channel into Red and Blue into Alpha, leaving textures permanently 100% opaque.
- **Rule**: Always call the explicit 4-argument method `setColor(r, g, b, a)` where `a` is an integer `0..255`, or pack strictly as `RGBA` (`(r << 24) | (g << 16) | (b << 8) | a`).

## 2. 2D Isometric Projection & Extrusion

- Non-uniform scaling (`scale(scale, scale, depth)`) combined with model rotations (`XP(-30)`, `YP(45)`) skews axes diagonally and deforms the geometry.
- To produce an isometric decal/sticker extruded perpendicular to the block face:
  1. Flatten the rotated model into 2D in face space (`scale(_scale, _scale, 0.001f)`).
  2. Extrude outward along the face normal (`-Z`) using dense sub-pixel layering ($8 \times \text{thickness}$ slices, up to 64 micro-layers).
  3. This ensures zero gaps and guarantees the extrusion stays strictly perpendicular to the block face regardless of custom angles.

## 3. MCreator Procedure Triggers

- Do NOT use `<@addTemplate>` in procedure trigger templates (`triggers/*.java.ftl`). `<@addTemplate>` is only registered in element generators, not in the `triggers` template generator. Calling it causes a fatal `InvalidReferenceException: addTemplate`.
- Triggers must match MCreator's trigger convention: define the `@EventBusSubscriber` class and event handler method, but do NOT close the class (`}`) or declare `execute(...)` manually. MCreator's `Procedure.java` generator appends the `execute()` method and closing brace automatically.

## 4. Build Script & Versioning

- `build.ps1` tracks `last_year` and `last_month` in `version.properties`.
- When the current month or year changes, `build_increment` automatically resets to `1`.
- When modifying generator templates, run `build/sync_generators.ps1` to keep `neoforge-26.1.2`, `neoforge-26.2`, and `neoforge-1.21.1` in parity with `forge-1.20.1`.

## 5. MCItem Multi-Select GUI Layout

- MCreator's `MCItemListField` (`JItemListField`) embeds a `JScrollPane` defaulted to $200 \times 50$ px.
- To make the block selection box fixed to a single row that expands horizontally as blocks are added:
  - Set `elementsList.setLayoutOrientation(JList.HORIZONTAL_WRAP)` and `elementsList.setVisibleRowCount(1)`.
  - Fix vertical height to 36px and dynamically stretch width up to 650px by modifying the internal `JScrollPane`'s preferred and minimum sizes.

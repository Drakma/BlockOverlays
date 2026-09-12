private record BlockOverlayTreeStructureBlock(net.minecraft.core.BlockPos pos, net.minecraft.world.level.block.state.BlockState state) {
}

private record BlockOverlayTreeStructureData(java.util.List<BlockOverlayTreeStructureBlock> blocks, double centerX, double centerZ, int minY, int maxY, int maxDimension) {
}

private static final BlockOverlayTreeStructureData BLOCK_OVERLAY_EMPTY_TREE_STRUCTURE = new BlockOverlayTreeStructureData(java.util.List.of(), 0.0, 0.0, 0, 0, 1);
private static final java.util.Map<String, BlockOverlayTreeStructureData> BLOCK_OVERLAY_TREE_STRUCTURE_CACHE = new java.util.HashMap<>();

// Biome tint (color) was being recomputed for every block in the structure, every frame - keyed
// by (target position, block state) since the same state can legitimately tint differently at
// different world positions (different biome), but never changes moment to moment.
private record BlockOverlayTreeTintKey(long pos, net.minecraft.world.level.block.state.BlockState state) {
}

private record BlockOverlayTreeTintEntry(long timestampMs, int tint) {
}

private static final long BLOCK_OVERLAY_TREE_TINT_CACHE_INTERVAL_MS = 15_000L;
private static final java.util.Map<BlockOverlayTreeTintKey, BlockOverlayTreeTintEntry> BLOCK_OVERLAY_TREE_TINT_CACHE = new java.util.HashMap<>();

private static int blockOverlayGetCachedTreeTint(long posKey, net.minecraft.world.level.block.state.BlockState state, java.util.function.IntSupplier compute) {
	var key = new BlockOverlayTreeTintKey(posKey, state);
	long now = System.currentTimeMillis();
	var cached = BLOCK_OVERLAY_TREE_TINT_CACHE.get(key);
	if (cached != null && now - cached.timestampMs() < BLOCK_OVERLAY_TREE_TINT_CACHE_INTERVAL_MS)
		return cached.tint();
	int fresh = compute.getAsInt();
	BLOCK_OVERLAY_TREE_TINT_CACHE.put(key, new BlockOverlayTreeTintEntry(now, fresh));
	return fresh;
}

private static BlockOverlayTreeStructureData blockOverlayGetTreeStructure(String name) {
	if (name == null || name.isBlank())
		return BLOCK_OVERLAY_EMPTY_TREE_STRUCTURE;
	return BLOCK_OVERLAY_TREE_STRUCTURE_CACHE.computeIfAbsent(name, structureName -> {
		try {
			String[] candidatePaths = new String[] {
				"data/${modid}/structure/" + structureName + ".nbt",
				"assets/${modid}/structures/" + structureName + ".nbt"
			};
			java.io.InputStream foundStream = null;
			for (String path : candidatePaths) {
				foundStream = Thread.currentThread().getContextClassLoader().getResourceAsStream(path);
				if (foundStream != null) {
					break;
				}
			}
			if (foundStream == null) {
				return BLOCK_OVERLAY_EMPTY_TREE_STRUCTURE;
			}

			net.minecraft.nbt.CompoundTag tag;
			try (java.io.InputStream in = foundStream) {
				tag = net.minecraft.nbt.NbtIo.readCompressed(in, net.minecraft.nbt.NbtAccounter.unlimitedHeap());
			}

			var template = new net.minecraft.world.level.levelgen.structure.templatesystem.StructureTemplate();
			template.load(net.minecraft.core.registries.BuiltInRegistries.BLOCK, tag);

			// StructureTemplate.filterBlocks(pos, settings, block) returns ONLY blocks matching that
			// exact type (Palette.blocks(Block) is an inclusive filter, not an exclusion) and there is
			// no public "get everything" accessor, so discover the structure's own palette block types
			// first, then aggregate filterBlocks(...) once per distinct type.
			java.util.Set<net.minecraft.world.level.block.Block> paletteBlockTypes = new java.util.LinkedHashSet<>();
			net.minecraft.nbt.ListTag paletteListList = tag.getList("palettes", net.minecraft.nbt.Tag.TAG_LIST);
			net.minecraft.nbt.ListTag paletteTag = !paletteListList.isEmpty() ? paletteListList.getList(0) : tag.getList("palette", net.minecraft.nbt.Tag.TAG_COMPOUND);
			for (int i = 0; i < paletteTag.size(); i++) {
				var paletteState = net.minecraft.nbt.NbtUtils.readBlockState(net.minecraft.core.registries.BuiltInRegistries.BLOCK, paletteTag.getCompound(i));
				if (!paletteState.isAir() && paletteState.getBlock() != net.minecraft.world.level.block.Blocks.STRUCTURE_VOID)
					paletteBlockTypes.add(paletteState.getBlock());
			}
			var placeSettings = new net.minecraft.world.level.levelgen.structure.templatesystem.StructurePlaceSettings();
			java.util.List<net.minecraft.world.level.levelgen.structure.templatesystem.StructureTemplate.StructureBlockInfo> infos = new java.util.ArrayList<>();
			for (var blockType : paletteBlockTypes) {
				infos.addAll(template.filterBlocks(net.minecraft.core.BlockPos.ZERO, placeSettings, blockType));
			}

			java.util.List<BlockOverlayTreeStructureBlock> blocks = new java.util.ArrayList<>();
			int minX = Integer.MAX_VALUE;
			int maxX = Integer.MIN_VALUE;
			int minY = Integer.MAX_VALUE;
			int maxY = Integer.MIN_VALUE;
			int minZ = Integer.MAX_VALUE;
			int maxZ = Integer.MIN_VALUE;
			for (var info : infos) {
				if (info.state().isAir())
					continue;
				blocks.add(new BlockOverlayTreeStructureBlock(info.pos(), info.state()));
				minX = Math.min(minX, info.pos().getX());
				maxX = Math.max(maxX, info.pos().getX());
				minY = Math.min(minY, info.pos().getY());
				maxY = Math.max(maxY, info.pos().getY());
				minZ = Math.min(minZ, info.pos().getZ());
				maxZ = Math.max(maxZ, info.pos().getZ());
			}
			if (blocks.isEmpty()) {
				return BLOCK_OVERLAY_EMPTY_TREE_STRUCTURE;
			}
			// Center on the structure's own declared size (the capture region, always a symmetric
			// square around the trunk), NOT the bounding box of actual non-air blocks - a lopsided
			// canopy (random leaf spread) would otherwise pull the center away from the trunk.
			net.minecraft.core.Vec3i declaredSize = template.getSize();
			double centerX = declaredSize.getX() / 2.0;
			double centerZ = declaredSize.getZ() / 2.0;
			int maxDimension = Math.max(maxX - minX + 1, Math.max(maxY - minY + 1, maxZ - minZ + 1));
			return new BlockOverlayTreeStructureData(java.util.List.copyOf(blocks), centerX, centerZ, minY, maxY, maxDimension);
		} catch (Exception exception) {
			return BLOCK_OVERLAY_EMPTY_TREE_STRUCTURE;
		}
	});
}

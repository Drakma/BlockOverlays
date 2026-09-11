private record BlockOverlayTreeStructureBlock(net.minecraft.core.BlockPos pos, net.minecraft.world.level.block.state.BlockState state) {
}

private record BlockOverlayTreeStructureData(java.util.List<BlockOverlayTreeStructureBlock> blocks, double centerX, double centerZ, int minY, int maxY, int maxDimension) {
}

private static final org.slf4j.Logger BLOCK_OVERLAY_TREE_LOG = com.mojang.logging.LogUtils.getLogger();
private static final BlockOverlayTreeStructureData BLOCK_OVERLAY_EMPTY_TREE_STRUCTURE = new BlockOverlayTreeStructureData(java.util.List.of(), 0.0, 0.0, 0, 0, 1);
private static final java.util.Map<String, BlockOverlayTreeStructureData> BLOCK_OVERLAY_TREE_STRUCTURE_CACHE = new java.util.HashMap<>();

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
			String foundPath = null;
			for (String path : candidatePaths) {
				foundStream = Thread.currentThread().getContextClassLoader().getResourceAsStream(path);
				if (foundStream != null) {
					foundPath = path;
					break;
				}
			}
			if (foundStream == null) {
				BLOCK_OVERLAY_TREE_LOG.warn("BlockOverlays: tree structure '{}' not found on classpath, tried: {}", structureName, String.join(", ", candidatePaths));
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
			net.minecraft.nbt.ListTag paletteListList = tag.getListOrEmpty("palettes");
			net.minecraft.nbt.ListTag paletteTag = !paletteListList.isEmpty() ? paletteListList.getListOrEmpty(0) : tag.getListOrEmpty("palette");
			for (int i = 0; i < paletteTag.size(); i++) {
				var paletteState = net.minecraft.nbt.NbtUtils.readBlockState(net.minecraft.core.registries.BuiltInRegistries.BLOCK, paletteTag.getCompoundOrEmpty(i));
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
				BLOCK_OVERLAY_TREE_LOG.warn("BlockOverlays: tree structure '{}' loaded from {} but contained zero non-air blocks (raw block infos: {})", structureName, foundPath, infos.size());
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
			BLOCK_OVERLAY_TREE_LOG.error("BlockOverlays: failed to load tree structure '{}'", structureName, exception);
			return BLOCK_OVERLAY_EMPTY_TREE_STRUCTURE;
		}
	});
}

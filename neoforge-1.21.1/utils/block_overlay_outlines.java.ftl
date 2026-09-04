private record BlockOverlayOutlineStyle(int color, float width, boolean throughWalls) {
}

private record BlockOverlayOutlineEdge(float x1, float y1, float z1, float x2, float y2, float z2) {
}

private record BlockOverlayOutlineBatch(BlockOverlayOutlineStyle style, net.minecraft.core.BlockPos anchor, java.util.List<BlockOverlayOutlineEdge> edges) {
}

private static final java.util.Map<BlockOverlayOutlineStyle, java.util.Set<net.minecraft.core.BlockPos>> BLOCK_OVERLAY_OUTLINES = new java.util.LinkedHashMap<>();
private static java.util.Map<BlockOverlayOutlineStyle, java.util.Set<net.minecraft.core.BlockPos>> BLOCK_OVERLAY_LAST_OUTLINES = java.util.Map.of();
private static java.util.List<BlockOverlayOutlineBatch> BLOCK_OVERLAY_CACHED_OUTLINE_BATCHES = java.util.List.of();

private static void blockOverlayOutlinesBegin() {
	BLOCK_OVERLAY_OUTLINES.clear();
}

private static void blockOverlayOutlineAdd(double x, double y, double z, int color, float width, boolean throughWalls) {
	BlockOverlayOutlineStyle style = new BlockOverlayOutlineStyle(color, Math.max(0, width), throughWalls);
	BLOCK_OVERLAY_OUTLINES.computeIfAbsent(style, _style -> new java.util.LinkedHashSet<>()).add(net.minecraft.core.BlockPos.containing(x, y, z));
}

private static void blockOverlayOutlinesSubmit(SubmitCustomGeometryEvent event) {
	if (!BLOCK_OVERLAY_OUTLINES.equals(BLOCK_OVERLAY_LAST_OUTLINES)) {
		BLOCK_OVERLAY_LAST_OUTLINES = BLOCK_OVERLAY_OUTLINES.entrySet().stream().collect(java.util.stream.Collectors.toUnmodifiableMap(java.util.Map.Entry::getKey, entry -> java.util.Set.copyOf(entry.getValue())));
		java.util.List<BlockOverlayOutlineBatch> batches = new java.util.ArrayList<>();
		for (java.util.Map.Entry<BlockOverlayOutlineStyle, java.util.Set<net.minecraft.core.BlockPos>> entry : BLOCK_OVERLAY_LAST_OUTLINES.entrySet()) {
			net.minecraft.core.BlockPos anchor = entry.getValue().iterator().next();
			net.minecraft.world.phys.shapes.VoxelShape combinedShape = Shapes.empty();
			for (net.minecraft.core.BlockPos position : entry.getValue()) {
				net.minecraft.world.phys.AABB box = new net.minecraft.world.phys.AABB(position.getX() - anchor.getX(), position.getY() - anchor.getY(), position.getZ() - anchor.getZ(), position.getX() - anchor.getX() + 1, position.getY() - anchor.getY() + 1, position.getZ() - anchor.getZ() + 1).inflate(0.005D);
				combinedShape = Shapes.joinUnoptimized(combinedShape, Shapes.create(box), net.minecraft.world.phys.shapes.BooleanOp.OR);
			}
			java.util.List<BlockOverlayOutlineEdge> edges = new java.util.ArrayList<>();
			combinedShape.optimize().forAllEdges((x1, y1, z1, x2, y2, z2) -> edges.add(new BlockOverlayOutlineEdge((float) x1, (float) y1, (float) z1, (float) x2, (float) y2, (float) z2)));
			batches.add(new BlockOverlayOutlineBatch(entry.getKey(), anchor, java.util.List.copyOf(edges)));
		}
		BLOCK_OVERLAY_CACHED_OUTLINE_BATCHES = java.util.List.copyOf(batches);
	}
	Vec3 camera = event.getLevelRenderState().cameraRenderState.pos;
	for (BlockOverlayOutlineBatch batch : BLOCK_OVERLAY_CACHED_OUTLINE_BATCHES) {
		PoseStack poseStack = event.getPoseStack();
		poseStack.pushPose();
		poseStack.translate(batch.anchor().getX() - camera.x, batch.anchor().getY() - camera.y, batch.anchor().getZ() - camera.z);
		event.getSubmitNodeCollector().submitCustomGeometry(poseStack, batch.style().throughWalls() ? RenderTypes.linesTranslucent() : RenderTypes.lines(), (pose, consumer) -> {
			for (BlockOverlayOutlineEdge edge : batch.edges()) {
				consumer.addVertex(pose, edge.x1(), edge.y1(), edge.z1()).setColor(batch.style().color()).setNormal(pose, edge.x2() - edge.x1(), edge.y2() - edge.y1(), edge.z2() - edge.z1()).setLineWidth(batch.style().width());
				consumer.addVertex(pose, edge.x2(), edge.y2(), edge.z2()).setColor(batch.style().color()).setNormal(pose, edge.x2() - edge.x1(), edge.y2() - edge.y1(), edge.z2() - edge.z1()).setLineWidth(batch.style().width());
			}
		});
		poseStack.popPose();
	}
}

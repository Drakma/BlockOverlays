// Item->BlockState resolution (a long chain of comparisons/registry lookups) is a pure function of
// its input - it never needs to be redone every render frame, only when the actual input item
// changes. Redoing it every frame for every visible tree/crop overlay was a real, uncached cost,
// independent of anything else in this plugin. (forge-1.20.1's older rendering API doesn't expose a
// separate "collect model parts" step the way the modern generators do, so only the resolution
// chains are cached here - renderSingleBlock itself still runs live every frame.)
//
// Only the pure item->state resolution chain is cached here (not the world-position fallback used
// when an item isn't recognized at all, since that legitimately depends on the live world block).
private static final java.util.Map<Item, BlockState> BLOCK_OVERLAY_TREE_RESOLUTION_CACHE = new java.util.HashMap<>();

private static BlockState blockOverlayGetCachedTreeResolution(Item item, java.util.function.Supplier<BlockState> resolve) {
	if (BLOCK_OVERLAY_TREE_RESOLUTION_CACHE.containsKey(item))
		return BLOCK_OVERLAY_TREE_RESOLUTION_CACHE.get(item);
	var resolved = resolve.get();
	BLOCK_OVERLAY_TREE_RESOLUTION_CACHE.put(item, resolved);
	return resolved;
}

private static final java.util.Map<Item, BlockState> BLOCK_OVERLAY_CROP_RESOLUTION_CACHE = new java.util.HashMap<>();

private static BlockState blockOverlayGetCachedCropResolution(Item item, java.util.function.Supplier<BlockState> resolve) {
	if (BLOCK_OVERLAY_CROP_RESOLUTION_CACHE.containsKey(item))
		return BLOCK_OVERLAY_CROP_RESOLUTION_CACHE.get(item);
	var resolved = resolve.get();
	BLOCK_OVERLAY_CROP_RESOLUTION_CACHE.put(item, resolved);
	return resolved;
}

// Shape info (double-tall second half, multi-stage age/growth property range) depends only on the
// final resolved BlockState, whether that came from the cached item resolution above or the live
// world-position fallback - so it's cached separately, keyed by state, and works correctly either way.
private record BlockOverlayCropShapeInfo(BlockState secondBaseState, boolean isVisualMultiStage, net.minecraft.world.level.block.state.properties.IntegerProperty ageProp, int minAge, int maxAge, int totalStages) {
}

private static final java.util.Map<BlockState, BlockOverlayCropShapeInfo> BLOCK_OVERLAY_CROP_SHAPE_CACHE = new java.util.HashMap<>();

private static BlockOverlayCropShapeInfo blockOverlayGetCachedCropShapeInfo(BlockState state, java.util.function.Supplier<BlockOverlayCropShapeInfo> compute) {
	return BLOCK_OVERLAY_CROP_SHAPE_CACHE.computeIfAbsent(state, s -> compute.get());
}

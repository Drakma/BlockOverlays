// Item->BlockState resolution (a long chain of comparisons/registry lookups) and block model part
// collection are pure functions of their inputs - they never need to be redone every render frame,
// only when the actual input (item / resolved state) changes. Redoing them every frame for every
// visible tree/crop overlay was a real, uncached cost, independent of anything else in this plugin.
//
// Model parts are cached globally by BlockState (not by position) since a state's model never
// depends on where it's rendered, and BlockState instances are canonical/interned so this is a safe
// map key. Item->state resolution is similarly cached by Item. Neither needs a TTL or level
// invalidation the way the texture overlay's cached TextureAtlasSprite did, since these don't hold
// anything tied to a specific world/atlas instance across reloads - only to static block/model
// registrations for the JVM session.
private static final java.util.Map<net.minecraft.world.level.block.state.BlockState, java.util.List<net.minecraft.client.renderer.block.dispatch.BlockStateModelPart>> BLOCK_OVERLAY_MODEL_PARTS_CACHE = new java.util.HashMap<>();

private static java.util.List<net.minecraft.client.renderer.block.dispatch.BlockStateModelPart> blockOverlayGetModelParts(net.minecraft.world.level.block.state.BlockState state) {
	return BLOCK_OVERLAY_MODEL_PARTS_CACHE.computeIfAbsent(state, s -> {
		var model = Minecraft.getInstance().getModelManager().getBlockStateModelSet().get(s);
		java.util.List<net.minecraft.client.renderer.block.dispatch.BlockStateModelPart> parts = new java.util.ArrayList<>();
		model.collectParts(net.minecraft.util.RandomSource.create(42L), parts);
		return parts;
	});
}

// Only the pure item->state resolution chain is cached here (not the world-position fallback used
// when an item isn't recognized at all, since that legitimately depends on the live world block).
private static final java.util.Map<Item, net.minecraft.world.level.block.state.BlockState> BLOCK_OVERLAY_TREE_RESOLUTION_CACHE = new java.util.HashMap<>();

private static net.minecraft.world.level.block.state.@org.jspecify.annotations.Nullable BlockState blockOverlayGetCachedTreeResolution(Item item, java.util.function.Supplier<net.minecraft.world.level.block.state.@org.jspecify.annotations.Nullable BlockState> resolve) {
	if (BLOCK_OVERLAY_TREE_RESOLUTION_CACHE.containsKey(item))
		return BLOCK_OVERLAY_TREE_RESOLUTION_CACHE.get(item);
	var resolved = resolve.get();
	BLOCK_OVERLAY_TREE_RESOLUTION_CACHE.put(item, resolved);
	return resolved;
}

private static final java.util.Map<Item, net.minecraft.world.level.block.state.BlockState> BLOCK_OVERLAY_CROP_RESOLUTION_CACHE = new java.util.HashMap<>();

private static net.minecraft.world.level.block.state.@org.jspecify.annotations.Nullable BlockState blockOverlayGetCachedCropResolution(Item item, java.util.function.Supplier<net.minecraft.world.level.block.state.@org.jspecify.annotations.Nullable BlockState> resolve) {
	if (BLOCK_OVERLAY_CROP_RESOLUTION_CACHE.containsKey(item))
		return BLOCK_OVERLAY_CROP_RESOLUTION_CACHE.get(item);
	var resolved = resolve.get();
	BLOCK_OVERLAY_CROP_RESOLUTION_CACHE.put(item, resolved);
	return resolved;
}

// Shape info (double-tall second half, multi-stage age/growth property range) depends only on the
// final resolved BlockState, whether that came from the cached item resolution above or the live
// world-position fallback - so it's cached separately, keyed by state, and works correctly either way.
private record BlockOverlayCropShapeInfo(net.minecraft.world.level.block.state.@org.jspecify.annotations.Nullable BlockState secondBaseState, boolean isVisualMultiStage, net.minecraft.world.level.block.state.properties.@org.jspecify.annotations.Nullable IntegerProperty ageProp, int minAge, int maxAge, int totalStages) {
}

private static final java.util.Map<net.minecraft.world.level.block.state.BlockState, BlockOverlayCropShapeInfo> BLOCK_OVERLAY_CROP_SHAPE_CACHE = new java.util.HashMap<>();

private static BlockOverlayCropShapeInfo blockOverlayGetCachedCropShapeInfo(net.minecraft.world.level.block.state.BlockState state, java.util.function.Supplier<BlockOverlayCropShapeInfo> compute) {
	return BLOCK_OVERLAY_CROP_SHAPE_CACHE.computeIfAbsent(state, s -> compute.get());
}

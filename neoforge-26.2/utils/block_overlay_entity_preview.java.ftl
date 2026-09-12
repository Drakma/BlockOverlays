private static final java.util.Map<net.minecraft.world.entity.EntityType<?>, net.minecraft.world.entity.Entity> BLOCK_OVERLAY_ENTITY_PREVIEW_CACHE = new java.util.HashMap<>();
private static final java.util.Set<net.minecraft.world.entity.EntityType<?>> BLOCK_OVERLAY_ENTITY_PREVIEW_FAILED = new java.util.HashSet<>();

private static net.minecraft.world.entity.@org.jspecify.annotations.Nullable Entity blockOverlayGetPreviewEntity(net.minecraft.world.entity.@org.jspecify.annotations.Nullable EntityType<?> type, net.minecraft.world.level.Level level) {
	if (type == null || BLOCK_OVERLAY_ENTITY_PREVIEW_FAILED.contains(type))
		return null;
	var cached = BLOCK_OVERLAY_ENTITY_PREVIEW_CACHE.get(type);
	if (cached != null)
		return cached;
	// Created but never added to the level (no addFreshEntity) and never ticked - same as
	// vanilla's own mob spawner display entity (BaseSpawner#getOrCreateDisplayEntity), which is
	// why it renders in its default idle pose with no AI/pathing/tick-based side effects to worry about.
	net.minecraft.world.entity.Entity entity;
	try {
		entity = type.create(level, net.minecraft.world.entity.EntitySpawnReason.SPAWN_ITEM_USE);
	} catch (Exception exception) {
		BLOCK_OVERLAY_ENTITY_PREVIEW_FAILED.add(type);
		return null;
	}
	if (entity == null) {
		BLOCK_OVERLAY_ENTITY_PREVIEW_FAILED.add(type);
		return null;
	}
	BLOCK_OVERLAY_ENTITY_PREVIEW_CACHE.put(type, entity);
	return entity;
}

// WalkAnimationState.update(...) is designed to be called once per game tick (20/sec) - calling it
// once per render frame instead would advance the walk cycle at framerate instead of tickrate,
// playing it far too fast on anything above 20fps. Throttle to roughly tick rate regardless of how
// often the caller checks; shared globally across all instances since it only gates frequency, not
// which entity's own WalkAnimationState (a per-entity field) actually advances.
private static long BLOCK_OVERLAY_WALK_ANIMATION_LAST_MS = 0L;

private static boolean blockOverlayShouldAdvanceWalkAnimation() {
	long now = System.currentTimeMillis();
	if (now - BLOCK_OVERLAY_WALK_ANIMATION_LAST_MS >= 50L) {
		BLOCK_OVERLAY_WALK_ANIMATION_LAST_MS = now;
		return true;
	}
	return false;
}

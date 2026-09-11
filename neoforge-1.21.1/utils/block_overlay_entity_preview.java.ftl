private static final org.slf4j.Logger BLOCK_OVERLAY_ENTITY_PREVIEW_LOG = com.mojang.logging.LogUtils.getLogger();
private static final java.util.Map<net.minecraft.world.entity.EntityType<?>, net.minecraft.world.entity.Entity> BLOCK_OVERLAY_ENTITY_PREVIEW_CACHE = new java.util.HashMap<>();
private static final java.util.Set<net.minecraft.world.entity.EntityType<?>> BLOCK_OVERLAY_ENTITY_PREVIEW_FAILED = new java.util.HashSet<>();
private static final java.util.Set<Item> BLOCK_OVERLAY_ENTITY_PREVIEW_WARNED_ITEMS = new java.util.HashSet<>();

private static void blockOverlayWarnNotSpawnEgg(Item item) {
	if (BLOCK_OVERLAY_ENTITY_PREVIEW_WARNED_ITEMS.add(item))
		BLOCK_OVERLAY_ENTITY_PREVIEW_LOG.warn("BlockOverlays: item '{}' passed to entity overlay is not a spawn egg (or has no entity data), nothing will render", net.minecraft.core.registries.BuiltInRegistries.ITEM.getKey(item));
}

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
		BLOCK_OVERLAY_ENTITY_PREVIEW_LOG.error("BlockOverlays: exception creating preview entity for type '{}'", net.minecraft.core.registries.BuiltInRegistries.ENTITY_TYPE.getKey(type), exception);
		BLOCK_OVERLAY_ENTITY_PREVIEW_FAILED.add(type);
		return null;
	}
	if (entity == null) {
		BLOCK_OVERLAY_ENTITY_PREVIEW_LOG.warn("BlockOverlays: could not create preview entity for type '{}'", net.minecraft.core.registries.BuiltInRegistries.ENTITY_TYPE.getKey(type));
		BLOCK_OVERLAY_ENTITY_PREVIEW_FAILED.add(type);
		return null;
	}
	BLOCK_OVERLAY_ENTITY_PREVIEW_LOG.info("BlockOverlays: created preview entity for type '{}' ({})", net.minecraft.core.registries.BuiltInRegistries.ENTITY_TYPE.getKey(type), entity.getClass().getName());
	BLOCK_OVERLAY_ENTITY_PREVIEW_CACHE.put(type, entity);
	return entity;
}

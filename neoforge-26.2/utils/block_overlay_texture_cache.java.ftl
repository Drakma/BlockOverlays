// The sprite lookup (collectParts + quad scan) and light lookup are non-trivial CPU work; redoing
// them every render frame for a texture overlay that basically never changes was the actual cause
// of a large FPS hit even with just a single instance. Refresh periodically instead.
//
// Kept short (not the original 60s) because right after a block is placed or a chunk loads, the
// model/lighting system can momentarily return a transient wrong answer (missing-texture sprite
// before the model is ready, or a too-dark/wrong light value before the lighting engine has
// propagated) - a long TTL would freeze that wrong answer for a long time instead of it
// self-correcting within a frame or two like it did before caching existed. A couple of seconds
// still eliminates the vast majority of the original per-frame cost while keeping any transient
// glitch barely noticeable.
//
// Cache is invalidated whenever the level instance changes (new world/dimension/reload) - without
// this, a cached TextureAtlasSprite from a previous world's (possibly since-rebuilt) texture atlas
// could be served as "still fresh" and render as garbage/invisible, and using world.getGameTime()
// (which resets on a new world) as the freshness clock could make an old entry look falsely fresh
// via a negative time delta. System.currentTimeMillis() never goes backward within a session.
private static final long BLOCK_OVERLAY_TEXTURE_CACHE_INTERVAL_MS = 15_000L;

private record BlockOverlayTextureCacheEntry(long timestampMs, net.minecraft.client.renderer.texture.TextureAtlasSprite sprite, int light) {
}

private static final java.util.Map<Long, BlockOverlayTextureCacheEntry> BLOCK_OVERLAY_TEXTURE_CACHE = new java.util.HashMap<>();
private static net.minecraft.world.level.Level BLOCK_OVERLAY_TEXTURE_CACHE_LEVEL = null;

private static BlockOverlayTextureCacheEntry blockOverlayGetTextureCacheEntry(net.minecraft.world.level.Level level, long key, java.util.function.Supplier<BlockOverlayTextureCacheEntry> compute) {
	if (level != BLOCK_OVERLAY_TEXTURE_CACHE_LEVEL) {
		BLOCK_OVERLAY_TEXTURE_CACHE.clear();
		BLOCK_OVERLAY_TEXTURE_CACHE_LEVEL = level;
	}
	long now = System.currentTimeMillis();
	var cached = BLOCK_OVERLAY_TEXTURE_CACHE.get(key);
	if (cached != null && now - cached.timestampMs() < BLOCK_OVERLAY_TEXTURE_CACHE_INTERVAL_MS)
		return cached;
	BlockOverlayTextureCacheEntry fresh = compute.get();
	// The "missing texture" placeholder almost never means the user actually wants that sprite - it
	// means the model system wasn't ready yet (e.g. right after a block was placed). Don't let that
	// transient result get locked in for the normal TTL: store it but with a timestamp of 0 so the
	// very next frame's check sees it as already-expired and retries immediately, until a real
	// texture resolves.
	boolean _isMissing = fresh.sprite().contents().name().equals(net.minecraft.client.renderer.texture.MissingTextureAtlasSprite.getLocation());
	BLOCK_OVERLAY_TEXTURE_CACHE.put(key, _isMissing ? new BlockOverlayTextureCacheEntry(0L, fresh.sprite(), fresh.light()) : fresh);
	return fresh;
}

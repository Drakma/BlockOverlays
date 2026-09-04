private static final java.util.Set<Long> BLOCK_OVERLAYS_HIDDEN = java.util.concurrent.ConcurrentHashMap.newKeySet();

private static boolean blockOverlaysHidden(double x, double y, double z) {
	return BLOCK_OVERLAYS_HIDDEN.contains(net.minecraft.core.BlockPos.containing(x, y, z).asLong());
}

private static void blockOverlaysSetHidden(double x, double y, double z, boolean hidden) {
	long position = net.minecraft.core.BlockPos.containing(x, y, z).asLong();
	if (hidden)
		BLOCK_OVERLAYS_HIDDEN.add(position);
	else
		BLOCK_OVERLAYS_HIDDEN.remove(position);
}
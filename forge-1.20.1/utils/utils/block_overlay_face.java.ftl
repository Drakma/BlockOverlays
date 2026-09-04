private static org.joml.Quaternionf blockOverlayFaceRotation(Direction side) {
	return switch (side) {
		case DOWN -> com.mojang.math.Axis.XP.rotationDegrees(-90.0F);
		case UP -> com.mojang.math.Axis.XP.rotationDegrees(90.0F);
		case NORTH -> new org.joml.Quaternionf();
		case SOUTH -> com.mojang.math.Axis.YP.rotationDegrees(180.0F);
		case WEST -> com.mojang.math.Axis.YP.rotationDegrees(90.0F);
		case EAST -> com.mojang.math.Axis.YP.rotationDegrees(-90.0F);
	};
}

private static void blockOverlayFaceTransform(PoseStack poseStack, Vec3 camera, Direction side, double x, double y, double z, double horizontal, double vertical) {
	poseStack.translate(x - camera.x + 0.5, y - camera.y + 0.5, z - camera.z + 0.5);
	poseStack.mulPose(blockOverlayFaceRotation(side));
	poseStack.translate(horizontal - 0.5, vertical - 0.5, -0.501);
}

private static int blockOverlayFaceLight(double x, double y, double z, Direction side) {
	return net.minecraft.client.renderer.LevelRenderer.getLightColor(Minecraft.getInstance().level, net.minecraft.core.BlockPos.containing(x, y, z).relative(side));
}

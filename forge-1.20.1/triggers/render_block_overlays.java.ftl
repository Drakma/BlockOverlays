<#include "procedures.java.ftl">
import com.mojang.math.Axis;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.state.BlockState;

@OnlyIn(Dist.CLIENT)
@Mod.EventBusSubscriber(bus = Mod.EventBusSubscriber.Bus.FORGE, value = Dist.CLIENT)
public class ${name}Procedure {
	@SubscribeEvent
	public static void renderLevel(RenderLevelStageEvent event) {
		if (event.getStage() == RenderLevelStageEvent.Stage.AFTER_TRANSLUCENT_BLOCKS) {
			Minecraft minecraft = Minecraft.getInstance();
			if (minecraft.level == null || minecraft.player == null)
				return;
			<#assign dependenciesCode>
				<@procedureDependenciesCode dependencies, {
					"world": "minecraft.level",
					"entity": "minecraft.player",
					"x": "minecraft.player.getX()",
					"y": "minecraft.player.getY()",
					"z": "minecraft.player.getZ()"
				}/>
			</#assign>
			execute(event<#if dependenciesCode?has_content>,</#if>${dependenciesCode});
		}
	}

	private static double anchorX(String placement) {
		return placement.endsWith("_LEFT") ? 1.0 : placement.endsWith("_RIGHT") ? 0.0 : 0.5;
	}

	private static double anchorY(String placement) {
		return placement.startsWith("TOP_") ? 1.0 : placement.startsWith("BOTTOM_") ? 0.0 : 0.5;
	}

	private static double itemPlacementX(String placement, double scale) {
		double half = Math.min(0.5, Math.abs(scale) / 2.0);
		return placement.endsWith("_LEFT") ? 0.5 - half : placement.endsWith("_RIGHT") ? -0.5 + half : 0.0;
	}

	private static double itemPlacementY(String placement, double scale) {
		double half = Math.min(0.5, Math.abs(scale) / 2.0);
		return placement.startsWith("TOP_") ? 0.5 - half : placement.startsWith("BOTTOM_") ? -0.5 + half : 0.0;
	}

	private static float localX(String placement, float width) {
		return placement.endsWith("_LEFT") ? 0 : placement.endsWith("_RIGHT") ? -width : -width / 2;
	}

	private static float localY(String placement, float height) {
		return placement.startsWith("TOP_") ? 0 : placement.startsWith("BOTTOM_") ? -height : -height / 2;
	}

	private static double placementOffsetX(String placement, double padding) {
		return placement.endsWith("_LEFT") ? padding : placement.endsWith("_RIGHT") ? -padding : 0.0;
	}

	private static double placementOffsetY(String placement, double padding) {
		return placement.startsWith("TOP_") ? -padding : placement.startsWith("BOTTOM_") ? padding : 0.0;
	}

	private static org.joml.Quaternionf faceRotation(Direction side) {
		return switch (side) {
			case DOWN -> Axis.XP.rotationDegrees(-90.0F);
			case UP -> Axis.XP.rotationDegrees(90.0F);
			case NORTH -> new org.joml.Quaternionf();
			case SOUTH -> Axis.YP.rotationDegrees(180.0F);
			case WEST -> Axis.YP.rotationDegrees(90.0F);
			case EAST -> Axis.YP.rotationDegrees(-90.0F);
		};
	}

	private static Vec3 shapeBoundsPlacement(BlockState state, Level level, BlockPos position, Direction side, String placement) {
		return shapeBoundsPlacement(state, level, position, side, placement, 0.0, 0.0, 0.0);
	}

	private static Vec3 shapeBoundsPlacement(BlockState state, Level level, BlockPos position, Direction side, String placement, double elementWidth, double elementHeight) {
		return shapeBoundsPlacement(state, level, position, side, placement, elementWidth, elementHeight, 0.0);
	}

	private static Vec3 shapeBoundsPlacement(BlockState state, Level level, BlockPos position, Direction side, String placement, double elementWidth, double elementHeight, double padding) {
		net.minecraft.world.phys.shapes.VoxelShape shape = state.getShape(level, position);
		net.minecraft.world.phys.AABB bounds = shape.isEmpty() ? net.minecraft.world.phys.shapes.Shapes.block().bounds() : shape.bounds();
		double horizontalMinimum = 0;
		double horizontalMaximum = 1;
		double verticalMinimum = 0;
		double verticalMaximum = 1;
		double depth = -0.501;
		switch (side) {
			case NORTH -> { horizontalMinimum = bounds.minX; horizontalMaximum = bounds.maxX; verticalMinimum = bounds.minY; verticalMaximum = bounds.maxY; depth = bounds.minZ - 0.501; }
			case SOUTH -> { horizontalMinimum = 1 - bounds.maxX; horizontalMaximum = 1 - bounds.minX; verticalMinimum = bounds.minY; verticalMaximum = bounds.maxY; depth = 0.499 - bounds.maxZ; }
			case WEST -> { horizontalMinimum = 1 - bounds.maxZ; horizontalMaximum = 1 - bounds.minZ; verticalMinimum = bounds.minY; verticalMaximum = bounds.maxY; depth = bounds.minX - 0.501; }
			case EAST -> { horizontalMinimum = bounds.minZ; horizontalMaximum = bounds.maxZ; verticalMinimum = bounds.minY; verticalMaximum = bounds.maxY; depth = 0.499 - bounds.maxX; }
			case UP -> { horizontalMinimum = 1 - bounds.maxX; horizontalMaximum = 1 - bounds.minX; verticalMinimum = 1 - bounds.maxZ; verticalMaximum = 1 - bounds.minZ; depth = 0.499 - bounds.maxY; }
			case DOWN -> { horizontalMinimum = 1 - bounds.maxX; horizontalMaximum = 1 - bounds.minX; verticalMinimum = 1 - bounds.maxZ; verticalMaximum = 1 - bounds.minZ; depth = bounds.minY - 0.501; }
		}
		double hSpan = horizontalMaximum - horizontalMinimum;
		double vSpan = verticalMaximum - verticalMinimum;
		double halfW = Math.min(hSpan / 2.0, Math.abs(elementWidth) / 2.0);
		double halfH = Math.min(vSpan / 2.0, Math.abs(elementHeight) / 2.0);
		double h = placement.endsWith("_LEFT") ? horizontalMaximum - halfW : placement.endsWith("_RIGHT") ? horizontalMinimum + halfW : (horizontalMinimum + horizontalMaximum) / 2.0;
		double v = placement.startsWith("TOP_") ? verticalMaximum - halfH : placement.startsWith("BOTTOM_") ? verticalMinimum + halfH : (verticalMinimum + verticalMaximum) / 2.0;
		double offsetX = placement.endsWith("_LEFT") ? padding : placement.endsWith("_RIGHT") ? -padding : 0.0;
		double offsetY = placement.startsWith("TOP_") ? -padding : placement.startsWith("BOTTOM_") ? padding : 0.0;
		return new Vec3(h - 0.5 + offsetX, v - 0.5 + offsetY, depth);
	}

	private static Vec3 shapeBoundsPrecise(BlockState state, Level level, BlockPos position, Direction side, double coordX, double coordY) {
		return shapeBoundsPrecise(state, level, position, side, coordX, coordY, 0.0);
	}

	private static Vec3 shapeBoundsPrecise(BlockState state, Level level, BlockPos position, Direction side, double coordX, double coordY, double padding) {
		net.minecraft.world.phys.shapes.VoxelShape shape = state.getShape(level, position);
		net.minecraft.world.phys.AABB bounds = shape.isEmpty() ? net.minecraft.world.phys.shapes.Shapes.block().bounds() : shape.bounds();
		double horizontalMinimum = 0;
		double horizontalMaximum = 1;
		double verticalMinimum = 0;
		double verticalMaximum = 1;
		double depth = -0.501;
		switch (side) {
			case NORTH -> { horizontalMinimum = bounds.minX; horizontalMaximum = bounds.maxX; verticalMinimum = bounds.minY; verticalMaximum = bounds.maxY; depth = bounds.minZ - 0.501; }
			case SOUTH -> { horizontalMinimum = 1 - bounds.maxX; horizontalMaximum = 1 - bounds.minX; verticalMinimum = bounds.minY; verticalMaximum = bounds.maxY; depth = 0.499 - bounds.maxZ; }
			case WEST -> { horizontalMinimum = 1 - bounds.maxZ; horizontalMaximum = 1 - bounds.minZ; verticalMinimum = bounds.minY; verticalMaximum = bounds.maxY; depth = bounds.minX - 0.501; }
			case EAST -> { horizontalMinimum = bounds.minZ; horizontalMaximum = bounds.maxZ; verticalMinimum = bounds.minY; verticalMaximum = bounds.maxY; depth = 0.499 - bounds.maxX; }
			case UP -> { horizontalMinimum = 1 - bounds.maxX; horizontalMaximum = 1 - bounds.minX; verticalMinimum = 1 - bounds.maxZ; verticalMaximum = 1 - bounds.minZ; depth = 0.499 - bounds.maxY; }
			case DOWN -> { horizontalMinimum = 1 - bounds.maxX; horizontalMaximum = 1 - bounds.minX; verticalMinimum = 1 - bounds.maxZ; verticalMaximum = 1 - bounds.minZ; depth = bounds.minY - 0.501; }
		}
		double hSpan = horizontalMaximum - horizontalMinimum;
		double vSpan = verticalMaximum - verticalMinimum;
		double h = horizontalMaximum - (coordX / 16.0) * hSpan;
		double v = verticalMinimum + (coordY / 16.0) * vSpan;
		double offsetX = coordX < 8.0 ? -padding : coordX > 8.0 ? padding : 0.0;
		double offsetY = coordY > 8.0 ? -padding : coordY < 8.0 ? padding : 0.0;
		return new Vec3(h - 0.5 + offsetX, v - 0.5 + offsetY, depth);
	}

	private static void blockOverlayOutlineDrawEdgeBand(com.mojang.blaze3d.vertex.VertexConsumer consumer,
			org.joml.Matrix4f pose, org.joml.Matrix3f normal,
			float r, float g, float b, float a, int width, float step,
			double x1, double y1, double z1, double x2, double y2, double z2) {
		double dx = x2 - x1;
		double dy = y2 - y1;
		double dz = z2 - z1;
		int edgeAxis;
		if (Math.abs(dx) >= Math.abs(dy) && Math.abs(dx) >= Math.abs(dz)) edgeAxis = 0;
		else if (Math.abs(dy) >= Math.abs(dx) && Math.abs(dy) >= Math.abs(dz)) edgeAxis = 1;
		else edgeAxis = 2;
		double mx = (x1 + x2) * 0.5;
		double my = (y1 + y2) * 0.5;
		double mz = (z1 + z2) * 0.5;
		float nx = 0, ny = 0, nz = 0;
		switch (edgeAxis) {
			case 0: ny = (my < 0.5) ? -1.0f : 1.0f; nz = (mz < 0.5) ? -1.0f : 1.0f; break;
			case 1: nx = (mx < 0.5) ? -1.0f : 1.0f; nz = (mz < 0.5) ? -1.0f : 1.0f; break;
			case 2: nx = (mx < 0.5) ? -1.0f : 1.0f; ny = (my < 0.5) ? -1.0f : 1.0f; break;
		}
		for (int k = 0; k < width; k++) {
			float o = k * step;
			float ox = nx * o, oy = ny * o, oz = nz * o;
			float ax = (float) x1 + ox, ay = (float) y1 + oy, az = (float) z1 + oz;
			float bx = (float) x2 + ox, by = (float) y2 + oy, bz = (float) z2 + oz;
			consumer.vertex(pose, ax, ay, az).color(r, g, b, a).normal(normal, (float) dx, (float) dy, (float) dz).endVertex();
			consumer.vertex(pose, bx, by, bz).color(r, g, b, a).normal(normal, (float) dx, (float) dy, (float) dz).endVertex();
		}
	}

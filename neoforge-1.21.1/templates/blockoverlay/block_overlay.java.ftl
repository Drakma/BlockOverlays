package ${package};

import com.mojang.blaze3d.vertex.PoseStack;
import com.mojang.math.Axis;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.Font;
import net.minecraft.client.renderer.block.BlockModelResolver;
import net.minecraft.client.renderer.block.BlockModelRenderState;
import net.minecraft.client.renderer.block.model.BlockDisplayContext;
import net.minecraft.client.renderer.rendertype.RenderTypes;
import net.minecraft.client.renderer.item.ItemStackRenderState;
import net.minecraft.client.renderer.texture.OverlayTexture;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.network.chat.Component;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.util.RandomSource;
import net.minecraft.world.item.ItemDisplayContext;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Blocks;
import net.minecraft.world.level.block.SaplingBlock;
import net.minecraft.world.level.block.grower.TreeGrower;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.chunk.ChunkGenerator;
import net.minecraft.world.phys.Vec3;
import net.neoforged.api.distmarker.Dist;
import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.client.event.SubmitCustomGeometryEvent;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

@EventBusSubscriber(value = Dist.CLIENT)
public class ${className} {
	<#if targetBlockIds?? && targetBlockIds?size gt 0>
	private static java.util.Set<net.minecraft.world.level.block.Block> TARGET_BLOCKS = null;

	private static boolean matchesTarget(BlockState state) {
		if (TARGET_BLOCKS == null) {
			java.util.Set<net.minecraft.world.level.block.Block> set = new HashSet<>();
			for (String bid : java.util.List.of(
				<#list targetBlockIds as bid>
				"${bid?j_string}"<#if bid_has_next>,</#if>
				</#list>
			)) {
				var b = BuiltInRegistries.BLOCK.getValue(Identifier.parse(bid));
				if (b != null) set.add(b);
			}
			TARGET_BLOCKS = set;
		}
		return TARGET_BLOCKS.contains(state.getBlock());
	}
	<#else>
	private static net.minecraft.world.level.block.Block TARGET_BLOCK = null;

	private static boolean matchesTarget(BlockState state) {
		if (TARGET_BLOCK == null) {
			TARGET_BLOCK = BuiltInRegistries.BLOCK.getValue(Identifier.parse("${targetBlockId?j_string}"));
		}
		return state.is(TARGET_BLOCK);
	}
	</#if>

	<#if data.visibilityScope == "NEARBY_MATCHING">
	private static final Map<Long, Set<Long>> VISIBLE_SECTION_POSITIONS = new HashMap<>();
	private static long lastVisibleSectionRefresh = -20;

	private static Set<Long> findMatches(Level level, int secX, int secY, int secZ) {
		if (!level.hasChunk(secX, secZ))
			return java.util.Collections.emptySet();
		net.minecraft.world.level.chunk.LevelChunk chunk = level.getChunk(secX, secZ);
		if (chunk == null)
			return java.util.Collections.emptySet();
		int secIndex = chunk.getSectionIndexFromSectionY(secY);
		if (secIndex < 0 || secIndex >= chunk.getSections().length)
			return java.util.Collections.emptySet();
		net.minecraft.world.level.chunk.LevelChunkSection section = chunk.getSection(secIndex);
		if (section == null || section.hasOnlyAir())
			return java.util.Collections.emptySet();
		Set<Long> positions = new HashSet<>();
		BlockPos.MutableBlockPos mut = new BlockPos.MutableBlockPos();
		int originX = secX << 4;
		int originY = secY << 4;
		int originZ = secZ << 4;
		for (int x = 0; x < 16; x++) {
			for (int y = 0; y < 16; y++) {
				for (int z = 0; z < 16; z++) {
					if (matchesTarget(section.getBlockState(x, y, z))) {
						mut.set(originX + x, originY + y, originZ + z);
						positions.add(mut.asLong());
					}
				}
			}
		}
		return positions.isEmpty() ? java.util.Collections.emptySet() : positions;
	}
	</#if>
	<#if data.heldItemNbt?has_content>
	private static final net.minecraft.nbt.CompoundTag HELD_ITEM_NBT = parseNbt("${data.heldItemNbt?j_string}");
	</#if>
	<#if data.blockEntityNbt?has_content>
	private static final net.minecraft.nbt.CompoundTag BLOCK_ENTITY_NBT = parseNbt("${data.blockEntityNbt?j_string}");
	</#if>

	private static net.minecraft.nbt.CompoundTag parseNbt(String snbt) {
		try {
			return net.minecraft.nbt.TagParser.parseCompoundFully(snbt);
		} catch (com.mojang.brigadier.exceptions.CommandSyntaxException exception) {
			return null;
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

	// Helper for overlay_builder_outline: emit N parallel copies of one shape edge, each offset
	// along the face plane(s) the edge sits on. Width=1 -> single edge on the original line.
	// Width>1 -> additional parallel edges extending INTO the faces it touches (not outwards
	// from the block). Caller is responsible for translating the pose stack into shape space.
	private static void blockOverlayOutlineDrawEdgeBand(com.mojang.blaze3d.vertex.VertexConsumer consumer,
			org.joml.Matrix4f pose, org.joml.Matrix3f normal,
			int color, int width, float step,
			double x1, double y1, double z1, double x2, double y2, double z2) {
		double dx = x2 - x1;
		double dy = y2 - y1;
		double dz = z2 - z1;
		// Dominant axis -> which way the edge runs.
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
			consumer.addVertex(pose, ax, ay, az).setColor(color).setNormal((float) dx, (float) dy, (float) dz);
			consumer.addVertex(pose, bx, by, bz).setColor(color).setNormal((float) dx, (float) dy, (float) dz);
		}
	}

	<#if data.overlayxml?has_content>
	${additional_code!""}
	${extra_templates_code!""}
	</#if>

	@SubscribeEvent
	public static void render(SubmitCustomGeometryEvent event) {
		Minecraft minecraft = Minecraft.getInstance();
		if (minecraft.level == null || minecraft.player == null)
			return;
		<#if data.visibilityScope == "LOOKED_AT">
		if (!(minecraft.hitResult instanceof net.minecraft.world.phys.BlockHitResult hitResult))
			return;
		renderAt(event, minecraft, hitResult.getBlockPos());
		<#else>
		Vec3 playerPos = minecraft.player.position();
		double maxDist = ${data.maximumDistance}D;
		double maxDistSq = maxDist * maxDist;
		int minSecX = (int) Math.floor((playerPos.x - maxDist) / 16.0);
		int maxSecX = (int) Math.floor((playerPos.x + maxDist) / 16.0);
		int minSecY = (int) Math.floor((playerPos.y - maxDist) / 16.0);
		int maxSecY = (int) Math.floor((playerPos.y + maxDist) / 16.0);
		int minSecZ = (int) Math.floor((playerPos.z - maxDist) / 16.0);
		int maxSecZ = (int) Math.floor((playerPos.z + maxDist) / 16.0);

		long now = minecraft.level.getGameTime();
		boolean doRefresh = now - lastVisibleSectionRefresh >= 20;
		if (doRefresh) {
			lastVisibleSectionRefresh = now;
		}

		Set<Long> activeSectionKeys = new HashSet<>();
		for (int sx = minSecX; sx <= maxSecX; sx++) {
			for (int sy = minSecY; sy <= maxSecY; sy++) {
				for (int sz = minSecZ; sz <= maxSecZ; sz++) {
					long sectionKey = BlockPos.asLong(sx, sy, sz);
					activeSectionKeys.add(sectionKey);
					if (doRefresh || !VISIBLE_SECTION_POSITIONS.containsKey(sectionKey)) {
						VISIBLE_SECTION_POSITIONS.put(sectionKey, findMatches(minecraft.level, sx, sy, sz));
					}
					Set<Long> positions = VISIBLE_SECTION_POSITIONS.get(sectionKey);
					if (positions != null && !positions.isEmpty()) {
						for (long packedPosition : positions) {
							BlockPos position = BlockPos.of(packedPosition);
							if (minecraft.player.distanceToSqr(Vec3.atCenterOf(position)) <= maxDistSq)
								renderAt(event, minecraft, position);
						}
					}
				}
			}
		}
		if (doRefresh) {
			VISIBLE_SECTION_POSITIONS.keySet().removeIf(k -> !activeSectionKeys.contains(k));
		}
		</#if>
	}

	private static void renderAt(SubmitCustomGeometryEvent event, Minecraft minecraft, BlockPos position) {
		if (!matchesTarget(minecraft.level.getBlockState(position)))
			return;
		<#if data.overlayxml?has_content>
		var world = minecraft.level;
		var entity = minecraft.player;
		double x = position.getX();
		double y = position.getY();
		double z = position.getZ();
		${procedurecode!""}
		<#else>
		<#if data.requiresCrouching>
		if (!minecraft.player.isCrouching())
			return;
		</#if>
		<#if data.heldItemOrTag?has_content>
		<#if data.heldItemOrTag?starts_with("#")>
		if (!minecraft.player.getMainHandItem().is(net.minecraft.tags.TagKey.create(net.minecraft.core.registries.Registries.ITEM, Identifier.parse("${data.heldItemOrTag?substring(1)?j_string}"))))
			return;
		<#else>
		if (!BuiltInRegistries.ITEM.getKey(minecraft.player.getMainHandItem().getItem()).toString().equals("${data.heldItemOrTag?j_string}"))
			return;
		</#if>
		</#if>
		<#if data.heldItemNbt?has_content>
		net.minecraft.world.item.component.CustomData heldItemData = minecraft.player.getMainHandItem().get(net.minecraft.core.component.DataComponents.CUSTOM_DATA);
		if (HELD_ITEM_NBT == null || heldItemData == null || !heldItemData.matchedBy(HELD_ITEM_NBT))
			return;
		</#if>
		if (minecraft.player.distanceToSqr(Vec3.atCenterOf(position)) > ${data.maximumDistance}D * ${data.maximumDistance}D)
			return;
		<#if data.blockStateProperty?has_content>
		if (!minecraft.level.getBlockState(position).getValues().entrySet().stream().anyMatch(entry -> entry.getKey().getName().equals("${data.blockStateProperty?j_string}") && entry.getValue().toString().equals("${data.blockStateValue?j_string}")))
			return;
		</#if>
		<#if data.blockEntityNbt?has_content>
		net.minecraft.world.level.block.entity.BlockEntity blockEntity = minecraft.level.getBlockEntity(position);
		if (BLOCK_ENTITY_NBT == null || blockEntity == null || !net.minecraft.nbt.TagParser.compareNbt(BLOCK_ENTITY_NBT, blockEntity.saveCustomOnly(minecraft.level.registryAccess()), true))
			return;
		</#if>
		<#if data.conditionProcedure?has_content>
		if (!${package}.procedures.${w.getWorkspace().getModElementByName(data.conditionProcedure).getName()}Procedure.execute())
			return;
		</#if>
		Direction side = Direction.${data.face};
		String placement = "${data.placement}";
		net.minecraft.world.phys.shapes.VoxelShape shape = minecraft.level.getBlockState(position).getShape(minecraft.level, position);
		net.minecraft.world.phys.AABB bounds = shape.isEmpty() ? net.minecraft.world.phys.shapes.Shapes.block().bounds() : shape.bounds();
		double horizontalMinimum = 0;
		double horizontalMaximum = 1;
		double verticalMinimum = 0;
		double verticalMaximum = 1;
		double faceDepth = -0.001;
		switch (side) {
			case NORTH -> {
				horizontalMinimum = bounds.minX;
				horizontalMaximum = bounds.maxX;
				verticalMinimum = bounds.minY;
				verticalMaximum = bounds.maxY;
				faceDepth = bounds.minZ - 0.001;
			}
			case SOUTH -> {
				horizontalMinimum = 1 - bounds.maxX;
				horizontalMaximum = 1 - bounds.minX;
				verticalMinimum = bounds.minY;
				verticalMaximum = bounds.maxY;
				faceDepth = 1 - bounds.maxZ - 0.001;
			}
			case WEST -> {
				horizontalMinimum = 1 - bounds.maxZ;
				horizontalMaximum = 1 - bounds.minZ;
				verticalMinimum = bounds.minY;
				verticalMaximum = bounds.maxY;
				faceDepth = bounds.minX - 0.001;
			}
			case EAST -> {
				horizontalMinimum = bounds.minZ;
				horizontalMaximum = bounds.maxZ;
				verticalMinimum = bounds.minY;
				verticalMaximum = bounds.maxY;
				faceDepth = 1 - bounds.maxX - 0.001;
			}
			case UP -> {
				horizontalMinimum = 1 - bounds.maxX;
				horizontalMaximum = 1 - bounds.minX;
				verticalMinimum = 1 - bounds.maxZ;
				verticalMaximum = 1 - bounds.minZ;
				faceDepth = 1 - bounds.maxY - 0.001;
			}
			case DOWN -> {
				horizontalMinimum = 1 - bounds.maxX;
				horizontalMaximum = 1 - bounds.minX;
				verticalMinimum = 1 - bounds.maxZ;
				verticalMaximum = 1 - bounds.minZ;
				faceDepth = bounds.minY - 0.001;
			}
		}
		double hSpan = horizontalMaximum - horizontalMinimum;
		double vSpan = verticalMaximum - verticalMinimum;
		<#if data.layerType == "ITEM">
		double halfW = Math.min(hSpan / 2.0, Math.abs((double) ${data.scale}) / 2.0);
		double halfH = Math.min(vSpan / 2.0, Math.abs((double) ${data.scale}) / 2.0);
		<#elseif data.layerType == "TEXTURE">
		double halfW = Math.min(hSpan / 2.0, (hSpan / 3.0) / 2.0);
		double halfH = Math.min(vSpan / 2.0, (vSpan / 3.0) / 2.0);
		<#else>
		double halfW = 0.0;
		double halfH = 0.0;
		</#if>
		double horizontal = placement.endsWith("_LEFT") ? horizontalMaximum - halfW : placement.endsWith("_RIGHT") ? horizontalMinimum + halfW : (horizontalMinimum + horizontalMaximum) / 2.0;
		double vertical = placement.startsWith("TOP_") ? verticalMaximum - halfH : placement.startsWith("BOTTOM_") ? verticalMinimum + halfH : (verticalMinimum + verticalMaximum) / 2.0;
		Vec3 camera = event.getLevelRenderState().cameraRenderState.pos;
		PoseStack poseStack = event.getPoseStack();
		int light = net.minecraft.client.renderer.LevelRenderer.getLightCoords(minecraft.level, position.relative(side));
		poseStack.pushPose();
		poseStack.translate(position.getX() - camera.x + 0.5, position.getY() - camera.y + 0.5, position.getZ() - camera.z + 0.5);
		<#if data.layerType == "OUTLINE">
		poseStack.translate(-0.5, -0.5, -0.5);
		<#else>
		poseStack.mulPose(faceRotation(side));
		poseStack.translate(-0.5, -0.5, -0.5);
		</#if>
		<#if data.layerType == "ITEM">
		poseStack.translate(horizontal, vertical, faceDepth);
		poseStack.scale((float) ${data.scale}, (float) ${data.scale}, 0.001f);
		ItemStack itemStack = new ItemStack(BuiltInRegistries.ITEM.get(Identifier.parse("${data.layerValue?j_string}")));
		if (itemStack.getItem() instanceof net.minecraft.world.item.BlockItem) {
			poseStack.mulPose(Axis.XP.rotationDegrees(-30.0F));
			poseStack.mulPose(Axis.YP.rotationDegrees(45.0F));
			poseStack.scale(0.625f, 0.625f, 0.625f);
		}
		ItemStackRenderState itemState = new ItemStackRenderState();
		minecraft.getItemModelResolver().updateForTopItem(itemState, itemStack, ItemDisplayContext.FIXED, minecraft.level, null, 0);
		itemState.submit(poseStack, event.getSubmitNodeCollector(), light, OverlayTexture.NO_OVERLAY, 0);
		<#elseif data.layerType == "TEXT" || data.layerType == "NUMBER">
		String text = "${data.layerValue?j_string}";
		Font font = minecraft.font;
		float textScale = Math.copySign(Math.min(0.025f * Math.abs((float) ${data.scale}), Math.min((float) ((horizontalMaximum - horizontalMinimum) * 0.95 / Math.max(1, font.width(text))), (float) ((verticalMaximum - verticalMinimum) * 0.95 / Math.max(1, font.lineHeight)))), (float) ${data.scale});
		poseStack.translate(horizontal, vertical, faceDepth);
		poseStack.scale(-textScale, -textScale, textScale);
		event.getSubmitNodeCollector().submitText(poseStack, localX(placement, font.width(text)), localY(placement, font.lineHeight), Component.literal(text).getVisualOrderText(), false, Font.DisplayMode.NORMAL, light, 0xFF${data.color?substring(1)}, 0, 0);
		<#elseif data.layerType == "TEXTURE">
		Identifier texture = Identifier.parse("${data.layerValue?j_string}");
		poseStack.translate(horizontal, vertical, faceDepth);
		poseStack.scale((float) ((horizontalMaximum - horizontalMinimum) / 3), (float) ((verticalMaximum - verticalMinimum) / 3), 1.0f);
		event.getSubmitNodeCollector().submitCustomGeometry(poseStack, RenderTypes.entityTranslucent(texture), (pose, consumer) -> {
			consumer.addVertex(pose, 0.5f, -0.5f, 0).setColor(0xFFFFFFFF).setUv(0, 1).setOverlay(OverlayTexture.NO_OVERLAY).setLight(light).setNormal(pose, 0, 0, -1);
			consumer.addVertex(pose, 0.5f, 0.5f, 0).setColor(0xFFFFFFFF).setUv(0, 0).setOverlay(OverlayTexture.NO_OVERLAY).setLight(light).setNormal(pose, 0, 0, -1);
			consumer.addVertex(pose, -0.5f, 0.5f, 0).setColor(0xFFFFFFFF).setUv(1, 0).setOverlay(OverlayTexture.NO_OVERLAY).setLight(light).setNormal(pose, 0, 0, -1);
			consumer.addVertex(pose, -0.5f, -0.5f, 0).setColor(0xFFFFFFFF).setUv(1, 1).setOverlay(OverlayTexture.NO_OVERLAY).setLight(light).setNormal(pose, 0, 0, -1);
		});
		<#elseif data.layerType == "OUTLINE">
		event.getSubmitNodeCollector().submitCustomGeometry(poseStack, ${data.throughWalls?c} ? RenderTypes.linesTranslucent() : RenderTypes.lines(), (pose, consumer) -> shape.forAllEdges((x1, y1, z1, x2, y2, z2) -> {
			consumer.addVertex(pose, (float) x1, (float) y1, (float) z1).setColor(0xFF${data.color?substring(1)}).setNormal(pose, (float) (x2 - x1), (float) (y2 - y1), (float) (z2 - z1)).setLineWidth((float) ${data.lineWidth});
			consumer.addVertex(pose, (float) x2, (float) y2, (float) z2).setColor(0xFF${data.color?substring(1)}).setNormal(pose, (float) (x2 - x1), (float) (y2 - y1), (float) (z2 - z1)).setLineWidth((float) ${data.lineWidth});
		}));
		</#if>
		poseStack.popPose();
		</#if>
	}
}

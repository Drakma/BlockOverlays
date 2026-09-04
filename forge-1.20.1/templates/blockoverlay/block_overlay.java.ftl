package ${package};

import com.mojang.blaze3d.vertex.PoseStack;
import com.mojang.blaze3d.vertex.VertexConsumer;
import com.mojang.math.Axis;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.Font;
import net.minecraft.client.renderer.LevelRenderer;
import net.minecraft.client.renderer.MultiBufferSource;
import net.minecraft.client.renderer.RenderType;
import net.minecraft.client.renderer.texture.OverlayTexture;
import net.minecraft.client.renderer.texture.TextureAtlas;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.network.chat.Component;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.item.ItemDisplayContext;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.phys.Vec3;
import net.minecraftforge.api.distmarker.Dist;
import net.minecraftforge.api.distmarker.OnlyIn;
import net.minecraftforge.client.event.RenderLevelStageEvent;
import net.minecraftforge.eventbus.api.SubscribeEvent;
import net.minecraftforge.fml.common.Mod;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

@OnlyIn(Dist.CLIENT)
@Mod.EventBusSubscriber(bus = Mod.EventBusSubscriber.Bus.FORGE, value = Dist.CLIENT)
public class ${name} {
	<#if data.visibilityScope == "NEARBY_MATCHING">
	private static final Map<Long, Set<Long>> VISIBLE_SECTION_POSITIONS = new HashMap<>();
	private static long lastVisibleSectionRefresh = -20;

	<#if targetBlockIds?? && targetBlockIds?size gt 0>
	private static final java.util.Set<ResourceLocation> TARGET_BLOCKS = java.util.Set.of(
		<#list targetBlockIds as bid>
		new ResourceLocation("${bid?j_string}")<#if bid_has_next>,</#if>
		</#list>
	);

	private static boolean matchesTarget(BlockState state) {
		return TARGET_BLOCKS.contains(BuiltInRegistries.BLOCK.getKey(state.getBlock()));
	}
	<#else>
	private static boolean matchesTarget(BlockState state) {
		return BuiltInRegistries.BLOCK.getKey(state.getBlock()).toString().equals("${targetBlockId?j_string}");
	}
	</#if>

	private static Set<Long> findMatches(Level level, BlockPos origin) {
		Set<Long> positions = new HashSet<>();
		for (int x = origin.getX(); x < origin.getX() + 16; x++)
			for (int y = origin.getY(); y < origin.getY() + 16; y++)
				for (int z = origin.getZ(); z < origin.getZ() + 16; z++) {
					BlockPos position = new BlockPos(x, y, z);
					if (matchesTarget(level.getBlockState(position)))
						positions.add(position.asLong());
				}
		return positions;
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

	@SubscribeEvent
	public static void render(RenderLevelStageEvent event) {
		if (event.getStage() != RenderLevelStageEvent.Stage.AFTER_TRANSLUCENT_BLOCKS)
			return;
		Minecraft minecraft = Minecraft.getInstance();
		if (minecraft.player == null || minecraft.level == null)
			return;
		<#if data.heldItem?has_content>
		ItemStack held = minecraft.player.getMainHandItem();
		if (!BuiltInRegistries.ITEM.getKey(held.getItem()).toString().equals("${data.heldItem?j_string}"))
			return;
		</#if>
		<#if data.heldItemNbt?has_content>
		ItemStack heldNbt = minecraft.player.getMainHandItem();
		if (HELD_ITEM_NBT == null || !heldNbt.hasTag() || !net.minecraft.nbt.NbtUtils.compareNbt(HELD_ITEM_NBT, heldNbt.getTag(), true))
			return;
		</#if>
		<#if data.visibilityScope == "TARGETED_ONLY">
		net.minecraft.world.phys.HitResult hitResult = minecraft.hitResult;
		if (!(hitResult instanceof net.minecraft.world.phys.BlockHitResult blockHitResult))
			return;
		BlockPos position = blockHitResult.getBlockPos();
		if (!matchesTarget(minecraft.level.getBlockState(position)))
			return;
		renderAt(event, minecraft, position);
		<#elseif data.visibilityScope == "ALL_VISIBLE_BLOCKS">
		net.minecraft.world.phys.HitResult hitResult = minecraft.hitResult;
		if (hitResult instanceof net.minecraft.world.phys.BlockHitResult blockHitResult) {
			BlockPos position = blockHitResult.getBlockPos();
			renderAt(event, minecraft, position);
		}
		<#else>
		BlockPos playerBlockPos = minecraft.player.blockPosition();
		int playerSectionX = playerBlockPos.getX() >> 4;
		int playerSectionY = playerBlockPos.getY() >> 4;
		int playerSectionZ = playerBlockPos.getZ() >> 4;
		long currentGameTime = minecraft.level.getGameTime();
		if (currentGameTime - lastVisibleSectionRefresh >= 20) {
			VISIBLE_SECTION_POSITIONS.clear();
			lastVisibleSectionRefresh = currentGameTime;
		}
		for (int x = -1; x <= 1; x++) {
			for (int y = -1; y <= 1; y++) {
				for (int z = -1; z <= 1; z++) {
					long key = BlockPos.asLong(playerSectionX + x, playerSectionY + y, playerSectionZ + z);
					Set<Long> positions = VISIBLE_SECTION_POSITIONS.computeIfAbsent(key, ignored -> findMatches(minecraft.level, new BlockPos((playerSectionX + x) << 4, (playerSectionY + y) << 4, (playerSectionZ + z) << 4)));
					for (Long encoded : positions) {
						BlockPos position = BlockPos.of(encoded);
						renderAt(event, minecraft, position);
					}
				}
			}
		}
		</#if>
	}

	private static void renderAt(RenderLevelStageEvent event, Minecraft minecraft, BlockPos position) {
		<#if data.layerType == "NONE">
		return;
		<#else>
		if (minecraft.player == null || minecraft.level == null)
			return;
		if (minecraft.player.position().distanceTo(Vec3.atCenterOf(position)) > ${data.renderDistance})
			return;
		<#if data.onlyIfAirAbove>
		if (!minecraft.level.getBlockState(position.above()).isAir())
			return;
		</#if>
		<#if data.requiresLookingAt>
		net.minecraft.world.phys.HitResult hit = minecraft.hitResult;
		if (!(hit instanceof net.minecraft.world.phys.BlockHitResult bhr) || !bhr.getBlockPos().equals(position) || bhr.getDirection() != Direction.${data.face})
			return;
		</#if>
		<#if data.checkRaycast>
		net.minecraft.world.level.ClipContext ctx = new net.minecraft.world.level.ClipContext(minecraft.player.getEyePosition(), Vec3.atCenterOf(position), net.minecraft.world.level.ClipContext.Block.COLLIDER, net.minecraft.world.level.ClipContext.Fluid.NONE, minecraft.player);
		net.minecraft.world.phys.BlockHitResult ray = minecraft.level.clip(ctx);
		if (ray.getType() == net.minecraft.world.phys.HitResult.Type.BLOCK && !ray.getBlockPos().equals(position))
			return;
		</#if>
		<#if data.blockEntityNbt?has_content>
		net.minecraft.world.level.block.entity.BlockEntity blockEntity = minecraft.level.getBlockEntity(position);
		if (BLOCK_ENTITY_NBT == null || blockEntity == null || !net.minecraft.nbt.NbtUtils.compareNbt(BLOCK_ENTITY_NBT, blockEntity.saveWithFullMetadata(), true))
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
		Vec3 camera = event.getCamera().getPosition();
		PoseStack poseStack = event.getPoseStack();
		int light = LevelRenderer.getLightCoords(minecraft.level, position.relative(side));
		MultiBufferSource.BufferSource bufferSource = minecraft.renderBuffers().bufferSource();
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
		ItemStack itemStack = new ItemStack(BuiltInRegistries.ITEM.get(new ResourceLocation("${data.layerValue?j_string}")));
		if (itemStack.getItem() instanceof net.minecraft.world.item.BlockItem) {
			poseStack.mulPose(Axis.XP.rotationDegrees(-30.0F));
			poseStack.mulPose(Axis.YP.rotationDegrees(45.0F));
			poseStack.scale(0.625f, 0.625f, 0.625f);
		}
		minecraft.getItemRenderer().renderStatic(itemStack, ItemDisplayContext.FIXED, light, OverlayTexture.NO_OVERLAY, poseStack, bufferSource, minecraft.level, 0);
		bufferSource.endBatch();
		<#elseif data.layerType == "TEXT" || data.layerType == "NUMBER">
		String text = "${data.layerValue?j_string}";
		Font font = minecraft.font;
		float textScale = Math.copySign(Math.min(0.025f * Math.abs((float) ${data.scale}), Math.min((float) ((horizontalMaximum - horizontalMinimum) * 0.95 / Math.max(1, font.width(text))), (float) ((verticalMaximum - verticalMinimum) * 0.95 / Math.max(1, font.lineHeight)))), (float) ${data.scale});
		poseStack.translate(horizontal, vertical, faceDepth);
		poseStack.scale(-textScale, -textScale, textScale);
		font.drawInBatch(text, localX(placement, font.width(text)), localY(placement, font.lineHeight), 0xFF${data.color?substring(1)}, false, poseStack.last().pose(), bufferSource, Font.DisplayMode.NORMAL, 0, light);
		bufferSource.endBatch();
		<#elseif data.layerType == "TEXTURE">
		ResourceLocation texture = new ResourceLocation("${data.layerValue?j_string}");
		poseStack.translate(horizontal, vertical, faceDepth);
		poseStack.scale((float) ((horizontalMaximum - horizontalMinimum) / 3), (float) ((verticalMaximum - verticalMinimum) / 3), 1.0f);
		var consumer = bufferSource.getBuffer(RenderType.entityTranslucent(texture));
		var pose = poseStack.last().pose();
		var normal = poseStack.last().normal();
		int color = 0xFF${data.color?substring(1)};
		int a = (color >> 24) & 0xFF, r = (color >> 16) & 0xFF, g = (color >> 8) & 0xFF, b = color & 0xFF;
		consumer.vertex(pose, 0.5f, -0.5f, 0).color(r, g, b, a).uv(0, 1).overlayCoords(OverlayTexture.NO_OVERLAY).uv2(light).normal(normal, 0, 0, -1).endVertex();
		consumer.vertex(pose, 0.5f, 0.5f, 0).color(r, g, b, a).uv(0, 0).overlayCoords(OverlayTexture.NO_OVERLAY).uv2(light).normal(normal, 0, 0, -1).endVertex();
		consumer.vertex(pose, -0.5f, 0.5f, 0).color(r, g, b, a).uv(1, 0).overlayCoords(OverlayTexture.NO_OVERLAY).uv2(light).normal(normal, 0, 0, -1).endVertex();
		consumer.vertex(pose, -0.5f, -0.5f, 0).color(r, g, b, a).uv(1, 1).overlayCoords(OverlayTexture.NO_OVERLAY).uv2(light).normal(normal, 0, 0, -1).endVertex();
		bufferSource.endBatch(RenderType.entityTranslucent(texture));
		<#elseif data.layerType == "OUTLINE">
		var consumer = bufferSource.getBuffer(${data.throughWalls?c} ? RenderType.lines() : RenderType.lines());
		int color = 0xFF${data.color?substring(1)};
		float a = ((color >> 24) & 0xFF) / 255.0f, r = ((color >> 16) & 0xFF) / 255.0f, g = ((color >> 8) & 0xFF) / 255.0f, b = (color & 0xFF) / 255.0f;
		LevelRenderer.renderShape(poseStack, consumer, shape, 0, 0, 0, r, g, b, a);
		bufferSource.endBatch(RenderType.lines());
		</#if>
		poseStack.popPose();
		</#if>
	}
}

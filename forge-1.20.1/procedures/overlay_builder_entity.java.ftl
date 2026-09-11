<#include "mcitems.ftl">
<@addTemplate file="block_overlay_entity_preview.java.ftl"/>
if (event instanceof RenderLevelStageEvent) {
	float _growth = Math.max(0.0f, Math.min(1.0f, (float) ((Number) ${(input$percentage!"1.0")}).doubleValue()));
	double _offsetY = ((Number) ${(input$offset_y!"0")}).doubleValue() / 16.0;
	float _baseScale = (float) ((Number) ${(input$scale!"1.0")}).doubleValue();
	boolean _spin = ${(input$spin!"false")};
	ItemStack _eggStack = ${mappedMCItemToItemStackCode(input$spawn_egg, 1)};
	net.minecraft.world.entity.EntityType<?> _entityType = null;
	if (_eggStack.getItem() instanceof net.minecraft.world.item.SpawnEggItem _eggItem) {
		_entityType = _eggItem.getType(_eggStack.getTag());
	} else {
		blockOverlayWarnNotSpawnEgg(_eggStack.getItem());
	}
	var _entity = blockOverlayGetPreviewEntity(_entityType, world);

	if (_entity != null && event.getCamera().getPosition().distanceToSqr(x + 0.5, y + 0.5, z + 0.5) <= 2304.0) {
		// Match the tree structure overlay's scale semantics: scale 1 = the entity's longest
		// dimension (width or height) fits in exactly one block, not its real-world size.
		float _maxDimension = Math.max(0.001f, Math.max(_entityType.getDimensions().width(), _entityType.getDimensions().height()));
		float _scale = (_baseScale * Math.max(0.001f, _growth)) / _maxDimension;
		// Driven by wall-clock time (not world.getGameTime()) so it updates every render frame
		// instead of only once per 50ms game tick, which looked stepped/juddery at high framerate.
		float _spinAngle = _spin ? (float) ((System.nanoTime() / 1_000_000L % 4500L) / 4500.0 * 360.0) : 0.0f;

		PoseStack _poseStack = event.getPoseStack();
		Vec3 _camera = event.getCamera().getPosition();
		int _light = net.minecraft.client.renderer.LightTexture.pack(
			Minecraft.getInstance().level.getBrightness(net.minecraft.world.level.LightLayer.SKY, BlockPos.containing(x, y + 1, z)),
			Minecraft.getInstance().level.getBrightness(net.minecraft.world.level.LightLayer.BLOCK, BlockPos.containing(x, y + 1, z))
		);
		var _bufferSource = Minecraft.getInstance().renderBuffers().bufferSource();

		_poseStack.pushPose();
		_poseStack.translate(x - _camera.x + 0.5, y - _camera.y + _offsetY, z - _camera.z + 0.5);
		_poseStack.mulPose(com.mojang.math.Axis.YP.rotationDegrees(_spinAngle));
		_poseStack.scale(_scale, _scale, _scale);

		try {
			Minecraft.getInstance().getEntityRenderDispatcher().render(_entity, 0.0, 0.0, 0.0, 0.0f, 1.0f, _poseStack, _bufferSource, _light);
			_bufferSource.endBatch();
		} catch (Exception _renderException) {
			BLOCK_OVERLAY_ENTITY_PREVIEW_LOG.error("BlockOverlays: exception rendering preview entity for type '{}'", net.minecraftforge.registries.ForgeRegistries.ENTITY_TYPES.getKey(_entityType), _renderException);
		}

		_poseStack.popPose();
	}
}

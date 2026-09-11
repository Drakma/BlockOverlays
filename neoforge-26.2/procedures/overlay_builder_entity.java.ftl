<#include "mcitems.ftl">
<@addTemplate file="block_overlay_entity_preview.java.ftl"/>
if (event instanceof SubmitCustomGeometryEvent _overlayEvent) {
	float _growth = Math.max(0.0f, Math.min(1.0f, (float) ((Number) ${(input$percentage!"1.0")}).doubleValue()));
	double _offsetY = ((Number) ${(input$offset_y!"0")}).doubleValue() / 16.0;
	float _baseScale = (float) ((Number) ${(input$scale!"1.0")}).doubleValue();
	boolean _spin = ${(input$spin!"false")};
	Vec3 _camera = _overlayEvent.getLevelRenderState().cameraRenderState.pos;
	if (_camera.distanceToSqr(x + 0.5, y + 0.5, z + 0.5) <= 2304.0) {
		ItemStack _eggStack = ${mappedMCItemToItemStackCode(input$spawn_egg, 1)};
		var _entityType = net.minecraft.world.item.SpawnEggItem.getType(_eggStack);
		if (_entityType == null) {
			blockOverlayWarnNotSpawnEgg(_eggStack.getItem());
		}
		var _entity = blockOverlayGetPreviewEntity(_entityType, world);

		if (_entity != null) {
			// Match the tree structure overlay's scale semantics: scale 1 = the entity's longest
			// dimension (width or height) fits in exactly one block, not its real-world size.
			float _maxDimension = Math.max(0.001f, Math.max(_entityType.getDimensions().width(), _entityType.getDimensions().height()));
			float _scale = (_baseScale * Math.max(0.001f, _growth)) / _maxDimension;
			// Driven by wall-clock time (not world.getGameTime()) so it updates every render frame
			// instead of only once per 50ms game tick, which looked stepped/juddery at high framerate.
			float _spinAngle = _spin ? (float) ((System.nanoTime() / 1_000_000L % 4500L) / 4500.0 * 360.0) : 0.0f;
			// Light is baked into the render state from the entity's OWN world position (never set since
			// this entity is never added to a level), so without this it always samples (0,0,0) and looks
			// dark/wrong. partialTicks is fixed at 1.0 below, so old-position interpolation fields don't matter.
			_entity.setPos(x + 0.5, y + _offsetY, z + 0.5);

			PoseStack _poseStack = _overlayEvent.getPoseStack();

			_poseStack.pushPose();
			_poseStack.translate(x - _camera.x + 0.5, y - _camera.y + _offsetY, z - _camera.z + 0.5);
			_poseStack.mulPose(com.mojang.math.Axis.YP.rotationDegrees(_spinAngle));
			_poseStack.scale(_scale, _scale, _scale);

			try {
				var _renderState = Minecraft.getInstance().getEntityRenderDispatcher().extractEntity(_entity, 1.0f);
				Minecraft.getInstance().getEntityRenderDispatcher().submit(_renderState, _overlayEvent.getLevelRenderState().cameraRenderState, 0.0, 0.0, 0.0, _poseStack, _overlayEvent.getSubmitNodeCollector());
			} catch (Exception _renderException) {
				BLOCK_OVERLAY_ENTITY_PREVIEW_LOG.error("BlockOverlays: exception rendering preview entity for type '{}'", net.minecraft.core.registries.BuiltInRegistries.ENTITY_TYPE.getKey(_entityType), _renderException);
			}

			_poseStack.popPose();
		}
	}
}

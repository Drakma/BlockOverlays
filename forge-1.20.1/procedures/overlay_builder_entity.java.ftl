<#include "mcitems.ftl">
<@addTemplate file="block_overlay_entity_preview.java.ftl"/>
if (event instanceof RenderLevelStageEvent) {
	float _growth = Math.max(0.0f, Math.min(1.0f, (float) ((Number) ${(input$percentage!"1.0")}).doubleValue()));
	double _offsetY = ((Number) ${(input$offset_y!"0")}).doubleValue() / 16.0;
	float _baseScale = (float) ((Number) ${(input$scale!"1.0")}).doubleValue();
	float _spinSpeed = (float) ((Number) ${(input$spin_speed!"0")}).doubleValue();
	String _animation = "${field$animation!"NONE"}";
	ItemStack _eggStack = ${mappedMCItemToItemStackCode(input$spawn_egg, 1)};
	net.minecraft.world.entity.EntityType<?> _entityType = null;
	if (_eggStack.getItem() instanceof net.minecraft.world.item.SpawnEggItem _eggItem) {
		_entityType = _eggItem.getType(_eggStack.getTag());
	}
	var _entity = blockOverlayGetPreviewEntity(_entityType, world);

	if (_entity != null && event.getCamera().getPosition().distanceToSqr(x + 0.5, y + 0.5, z + 0.5) <= 2304.0) {
		// Match the tree structure overlay's scale semantics: scale 1 = the entity's longest
		// dimension (width or height) fits in exactly one block, not its real-world size.
		float _maxDimension = Math.max(0.001f, Math.max(_entityType.getDimensions().width(), _entityType.getDimensions().height()));
		float _scale = (_baseScale * Math.max(0.001f, _growth)) / _maxDimension;
		// Driven by wall-clock time (not world.getGameTime()) so it updates every render frame
		// instead of only once per 50ms game tick, which looked stepped/juddery at high framerate.
		float _spinAngle = _spinSpeed != 0.0f ? (float) ((System.nanoTime() / 1_000_000_000.0 * _spinSpeed) % 360.0) : 0.0f;

		// Shape bounds calculation
		double _shapeTop = 0.0;
		if (${(input$bounds!"false")}) {
			var _shape = world.getBlockState(BlockPos.containing(x, y, z)).getShape(world, BlockPos.containing(x, y, z));
			if (!_shape.isEmpty()) {
				_shapeTop = _shape.bounds().maxY;
			}
		}

		// Cosmetic only, independent of spin: driven purely client-side since this entity is
		// never ticked (no AI to drive these fields normally).
		if (_entity instanceof net.minecraft.world.entity.LivingEntity _livingEntity) {
			if ("LOOK_AROUND".equals(_animation)) {
				double _t = System.nanoTime() / 1_000_000_000.0;
				// Per-entity-type phase offset so different mobs don't all glance around in lockstep.
				double _phase = (_entityType.hashCode() & 0xFFFF) / 65536.0 * Math.PI * 2.0;
				// Sum of a few incommensurate sine waves reads as irregular, wandering motion instead
				// of one perfectly periodic sweep - no stored per-entity state needed.
				float _lookYaw = (float) (Math.sin(_t * 0.9 + _phase) * 25.0
					+ Math.sin(_t * 0.37 + _phase * 1.7 + 1.3) * 15.0
					+ Math.sin(_t * 1.7 + _phase * 2.3 + 0.6) * 6.0);
				float _lookPitch = (float) (Math.sin(_t * 0.53 + _phase * 1.3 + 2.1) * 8.0
					+ Math.sin(_t * 1.1 + _phase * 0.7 + 0.4) * 4.0);
				_livingEntity.yBodyRot = 0.0f;
				_livingEntity.yHeadRot = _lookYaw;
				_livingEntity.setXRot(_lookPitch);
			} else if ("WALK".equals(_animation) && blockOverlayShouldAdvanceWalkAnimation()) {
				_livingEntity.walkAnimation.update(1.0f, 0.4f, _livingEntity.isBaby() ? 3.0f : 1.0f);
			}
		}

		PoseStack _poseStack = event.getPoseStack();
		Vec3 _camera = event.getCamera().getPosition();
		int _light = net.minecraft.client.renderer.LightTexture.pack(
			Minecraft.getInstance().level.getBrightness(net.minecraft.world.level.LightLayer.SKY, BlockPos.containing(x, y + 1, z)),
			Minecraft.getInstance().level.getBrightness(net.minecraft.world.level.LightLayer.BLOCK, BlockPos.containing(x, y + 1, z))
		);
		var _bufferSource = Minecraft.getInstance().renderBuffers().bufferSource();
		var _dispatcher = Minecraft.getInstance().getEntityRenderDispatcher();

		_poseStack.pushPose();
		_poseStack.translate(x - _camera.x + 0.5, y - _camera.y + _offsetY + _shapeTop, z - _camera.z + 0.5);
		_poseStack.mulPose(com.mojang.math.Axis.YP.rotationDegrees(_spinAngle));
		_poseStack.scale(_scale, _scale, _scale);

		// render(...) draws its own ground-shadow decal by raycasting the real level at the entity's
		// set position, ignoring our pose stack - suppress it for this call, then restore the flag.
		boolean _prevShouldRenderShadow = _dispatcher.shouldRenderShadow;
		_dispatcher.shouldRenderShadow = false;
		try {
			_dispatcher.render(_entity, 0.0, 0.0, 0.0, 0.0f, 1.0f, _poseStack, _bufferSource, _light);
			_bufferSource.endBatch();
		} catch (Exception _renderException) {
			// Ignore - a single bad render shouldn't take down the rest of the frame.
		} finally {
			_dispatcher.shouldRenderShadow = _prevShouldRenderShadow;
		}

		_poseStack.popPose();
	}
}

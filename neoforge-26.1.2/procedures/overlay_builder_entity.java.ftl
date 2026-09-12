<#include "mcitems.ftl">
<@addTemplate file="block_overlay_entity_preview.java.ftl"/>
if (event instanceof SubmitCustomGeometryEvent _overlayEvent) {
	float _growth = Math.max(0.0f, Math.min(1.0f, (float) ((Number) ${(input$percentage!"1.0")}).doubleValue()));
	double _offsetY = ((Number) ${(input$offset_y!"0")}).doubleValue() / 16.0;
	float _baseScale = (float) ((Number) ${(input$scale!"1.0")}).doubleValue();
	float _spinSpeed = (float) ((Number) ${(input$spin_speed!"0")}).doubleValue();
	String _animation = "${field$animation!"NONE"}";
	Vec3 _camera = _overlayEvent.getLevelRenderState().cameraRenderState.pos;
	if (_camera.distanceToSqr(x + 0.5, y + 0.5, z + 0.5) <= 2304.0) {
		ItemStack _eggStack = ${mappedMCItemToItemStackCode(input$spawn_egg, 1)};
		var _entityType = net.minecraft.world.item.SpawnEggItem.getType(_eggStack);
		var _entity = blockOverlayGetPreviewEntity(_entityType, world);

		if (_entity != null) {
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

			// Light is baked into the render state from the entity's OWN world position (never set since
			// this entity is never added to a level), so without this it always samples (0,0,0) and looks
			// dark/wrong. partialTicks is fixed at 1.0 below, so old-position interpolation fields don't matter.
			_entity.setPos(x + 0.5, y + _offsetY + _shapeTop, z + 0.5);

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

			PoseStack _poseStack = _overlayEvent.getPoseStack();

			_poseStack.pushPose();
			_poseStack.translate(x - _camera.x + 0.5, y - _camera.y + _offsetY + _shapeTop, z - _camera.z + 0.5);
			_poseStack.mulPose(com.mojang.math.Axis.YP.rotationDegrees(_spinAngle));
			_poseStack.scale(_scale, _scale, _scale);

			try {
				var _renderState = Minecraft.getInstance().getEntityRenderDispatcher().extractEntity(_entity, 1.0f);
				// Suppress the vanilla ground-shadow decal, which would otherwise raycast against the
				// real level at the entity's set position instead of following the overlay's pose stack.
				_renderState.shadowRadius = 0.0f;
				_renderState.shadowPieces.clear();
				Minecraft.getInstance().getEntityRenderDispatcher().submit(_renderState, _overlayEvent.getLevelRenderState().cameraRenderState, 0.0, 0.0, 0.0, _poseStack, _overlayEvent.getSubmitNodeCollector());
			} catch (Exception _renderException) {
				// Ignore - a single bad render shouldn't take down the rest of the frame.
			}

			_poseStack.popPose();
		}
	}
}

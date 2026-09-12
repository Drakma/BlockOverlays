<@addTemplate file="block_overlay_tree_structures.java.ftl"/>
if (event instanceof SubmitCustomGeometryEvent _overlayEvent) {
	float _growth = Math.max(0.0f, Math.min(1.0f, (float) ((Number) ${(input$percentage!"0.5")}).doubleValue()));
	double _offsetY = ((Number) ${(input$offset_y!"0")}).doubleValue() / 16.0;
	float _baseScale = (float) ((Number) ${(input$scale!"1.0")}).doubleValue();
	float _spinSpeed = (float) ((Number) ${(input$spin_speed!"0")}).doubleValue();
	String _growthMode = "${field$growth_mode!"UNIFORM_SCALE"}";
	String _structureName = <#if input$structure??>${input$structure}<#else>""</#if>;

	Vec3 _camera = _overlayEvent.getLevelRenderState().cameraRenderState.pos;
	var _structureData = blockOverlayGetTreeStructure(_structureName);
	// A structure can be 100+ blocks, each submitted individually every frame - skip the whole
	// thing beyond a reasonable view distance so multiple nearby trees don't tank framerate.
	if (!_structureData.blocks().isEmpty() && _camera.distanceToSqr(x + 0.5, y + 0.5, z + 0.5) <= 4096.0) {
		// Shape bounds calculation
		double _shapeTop = 0.0;
		if (${(input$bounds!"false")}) {
			var _shape = world.getBlockState(BlockPos.containing(x, y, z)).getShape(world, BlockPos.containing(x, y, z));
			if (!_shape.isEmpty()) {
				_shapeTop = _shape.bounds().maxY;
			}
		}

		PoseStack _poseStack = _overlayEvent.getPoseStack();
		int _light = net.minecraft.client.renderer.LevelRenderer.getLightCoords(Minecraft.getInstance().level, net.minecraft.core.BlockPos.containing(x, y + 1, z));
		var _blockColors = Minecraft.getInstance().getBlockColors();
		net.minecraft.core.BlockPos _tintPos = net.minecraft.core.BlockPos.containing(x, y + 1, z);

		boolean _bottomUpReveal = "BOTTOM_UP_REVEAL".equals(_growthMode);
		float _growthScale = _bottomUpReveal ? 1.0f : Math.max(0.001f, _growth);
		// scale=1 means the whole structure (its longest axis) fits within one block, matching
		// how scale=1 means "normal block size" on the single-block tree overlay.
		float _scale = (_baseScale * _growthScale) / _structureData.maxDimension();
		int _structureHeight = _structureData.maxY() - _structureData.minY() + 1;
		int _revealedMaxY = _structureData.minY() + Math.max(0, Math.round(_growth * _structureHeight) - 1);

		// Wall-clock driven (not world.getGameTime()) so it updates every render frame instead of
		// only once per 50ms game tick, matching the entity overlay's spin.
		float _spinAngle = _spinSpeed != 0.0f ? (float) ((System.nanoTime() / 1_000_000_000.0 * _spinSpeed) % 360.0) : 0.0f;

		_poseStack.pushPose();
		_poseStack.translate(x - _camera.x + 0.5, y - _camera.y + _offsetY + _shapeTop, z - _camera.z + 0.5);
		// Rotate before scaling/recentering so the structure spins around its own vertical axis
		// through the target block's center, regardless of scale.
		if (_spinAngle != 0.0f) {
			_poseStack.mulPose(com.mojang.math.Axis.YP.rotationDegrees(_spinAngle));
		}
		_poseStack.scale(_scale, _scale, _scale);
		_poseStack.translate(-_structureData.centerX(), -_structureData.minY(), -_structureData.centerZ());

		long _tintPosKey = _tintPos.asLong();
		for (var _block : _structureData.blocks()) {
			if (_bottomUpReveal && _block.pos().getY() > _revealedMaxY)
				continue;
			_poseStack.pushPose();
			_poseStack.translate(_block.pos().getX(), _block.pos().getY(), _block.pos().getZ());
			var _parts = blockOverlayGetTreeStructureModelParts(_block.state());
			int[] _tints = new int[] { blockOverlayGetCachedTreeTint(_tintPosKey, _block.state(), () -> _blockColors.getColor(_block.state(), world, _tintPos, 0)) };
			_overlayEvent.getSubmitNodeCollector().submitBlockModel(_poseStack, net.minecraft.client.renderer.rendertype.RenderTypes.cutoutMovingBlock(), _parts, _tints, _light, OverlayTexture.NO_OVERLAY, 0);
			_poseStack.popPose();
		}
		_poseStack.popPose();
	}
}
<@addTemplate file="block_overlay_tree_structures.java.ftl"/>
if (event instanceof RenderLevelStageEvent) {
	float _growth = Math.max(0.0f, Math.min(1.0f, (float) ((Number) ${(input$percentage!"0.5")}).doubleValue()));
	double _offsetY = ((Number) ${(input$offset_y!"0")}).doubleValue() / 16.0;
	float _baseScale = (float) ((Number) ${(input$scale!"1.0")}).doubleValue();
	String _growthMode = "${field$growth_mode!"UNIFORM_SCALE"}";
	String _structureName = <#if input$structure??>${input$structure}<#else>""</#if>;

	Vec3 _camera = event.getCamera().getPosition();
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

		PoseStack _poseStack = event.getPoseStack();
		int _light = net.minecraft.client.renderer.LightTexture.pack(
			Minecraft.getInstance().level.getBrightness(net.minecraft.world.level.LightLayer.SKY, BlockPos.containing(x, y + 1, z)),
			Minecraft.getInstance().level.getBrightness(net.minecraft.world.level.LightLayer.BLOCK, BlockPos.containing(x, y + 1, z))
		);
		var _bufferSource = Minecraft.getInstance().renderBuffers().bufferSource();

		boolean _bottomUpReveal = "BOTTOM_UP_REVEAL".equals(_growthMode);
		float _growthScale = _bottomUpReveal ? 1.0f : Math.max(0.001f, _growth);
		// scale=1 means the whole structure (its longest axis) fits within one block, matching
		// how scale=1 means "normal block size" on the single-block tree overlay.
		float _scale = (_baseScale * _growthScale) / _structureData.maxDimension();
		int _structureHeight = _structureData.maxY() - _structureData.minY() + 1;
		int _revealedMaxY = _structureData.minY() + Math.max(0, Math.round(_growth * _structureHeight) - 1);

		_poseStack.pushPose();
		_poseStack.translate(x - _camera.x + 0.5, y - _camera.y + _offsetY + _shapeTop, z - _camera.z + 0.5);
		_poseStack.scale(_scale, _scale, _scale);
		_poseStack.translate(-_structureData.centerX(), -_structureData.minY(), -_structureData.centerZ());

		for (var _block : _structureData.blocks()) {
			if (_bottomUpReveal && _block.pos().getY() > _revealedMaxY)
				continue;
			_poseStack.pushPose();
			_poseStack.translate(_block.pos().getX(), _block.pos().getY(), _block.pos().getZ());
			Minecraft.getInstance().getBlockRenderer().renderSingleBlock(_block.state(), _poseStack, _bufferSource, _light, OverlayTexture.NO_OVERLAY);
			_poseStack.popPose();
		}
		_bufferSource.endBatch();
		_poseStack.popPose();
	}
}

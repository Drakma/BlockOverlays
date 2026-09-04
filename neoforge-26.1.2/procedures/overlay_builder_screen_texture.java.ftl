if (event instanceof SubmitCustomGeometryEvent _overlayEvent) {
	String _placement = ${input$placement};
	Direction _side = ${input$side};
	float _scale = (float) ${input$scale};
	Identifier _texture = ${input$texture};
	int _color = 0xFF${(field$color!"#ffffff")?substring(1)};
	int _r = (_color >> 16) & 0xFF, _g = (_color >> 8) & 0xFF, _b = _color & 0xFF;
	int _a = (int) (Math.max(0.0f, Math.min(1.0f, (float) ${(input$transparency!"1.0")})) * 255.0f);
	PoseStack _poseStack = _overlayEvent.getPoseStack();
	Vec3 _camera = _overlayEvent.getLevelRenderState().cameraRenderState.pos;
	double _padding = ((Number) ${(input$padding!"0")}).doubleValue() / 16.0;
	Vec3 _position = ${(input$bounds!"false")} ? shapeBoundsPlacement(world.getBlockState(BlockPos.containing(x, y, z)), world, BlockPos.containing(x, y, z), _side, _placement, _scale, _scale, _padding) : new Vec3(itemPlacementX(_placement, _scale) + placementOffsetX(_placement, _padding), itemPlacementY(_placement, _scale) + placementOffsetY(_placement, _padding), -0.501);
	_poseStack.pushPose();
	_poseStack.translate(x - _camera.x + 0.5, y - _camera.y + 0.5, z - _camera.z + 0.5);
	_poseStack.mulPose(faceRotation(_side));
	_poseStack.translate(_position.x, _position.y, _position.z);
	_poseStack.scale(_scale, _scale, 1.0f);
	_overlayEvent.getSubmitNodeCollector().submitCustomGeometry(_poseStack, RenderTypes.entityTranslucent(_texture), (_pose, _consumer) -> {
		_consumer.addVertex(_pose, 0.5f, -0.5f, 0).setColor(_r, _g, _b, _a).setUv(0, 1).setOverlay(OverlayTexture.NO_OVERLAY).setLight(net.minecraft.client.renderer.LevelRenderer.getLightCoords(Minecraft.getInstance().level, net.minecraft.core.BlockPos.containing(x, y, z).relative(_side))).setNormal(_pose, 0, 0, -1);
		_consumer.addVertex(_pose, 0.5f, 0.5f, 0).setColor(_r, _g, _b, _a).setUv(0, 0).setOverlay(OverlayTexture.NO_OVERLAY).setLight(net.minecraft.client.renderer.LevelRenderer.getLightCoords(Minecraft.getInstance().level, net.minecraft.core.BlockPos.containing(x, y, z).relative(_side))).setNormal(_pose, 0, 0, -1);
		_consumer.addVertex(_pose, -0.5f, 0.5f, 0).setColor(_r, _g, _b, _a).setUv(1, 0).setOverlay(OverlayTexture.NO_OVERLAY).setLight(net.minecraft.client.renderer.LevelRenderer.getLightCoords(Minecraft.getInstance().level, net.minecraft.core.BlockPos.containing(x, y, z).relative(_side))).setNormal(_pose, 0, 0, -1);
		_consumer.addVertex(_pose, -0.5f, -0.5f, 0).setColor(_r, _g, _b, _a).setUv(1, 1).setOverlay(OverlayTexture.NO_OVERLAY).setLight(net.minecraft.client.renderer.LevelRenderer.getLightCoords(Minecraft.getInstance().level, net.minecraft.core.BlockPos.containing(x, y, z).relative(_side))).setNormal(_pose, 0, 0, -1);
	});
	_poseStack.popPose();
}

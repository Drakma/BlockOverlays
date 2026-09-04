if (event instanceof SubmitCustomGeometryEvent _overlayEvent) {
	float _transparency = Math.max(0.0f, Math.min(1.0f, (float) ${input$transparency}));
	if (_transparency > 0.0f) {
		net.minecraft.resources.Identifier _texture = ${input$texture};
		float _height = (float) ${input$height};
		float _width = (float) ${input$width};
		float _spinSpeed = (float) ${input$spin_speed};
		float _animTime = (float) (System.nanoTime() / 1_000_000L % 36000000L) / 50.0f;
		float _spinDeg = _animTime * _spinSpeed;
		int _a = (int) (_transparency * 255.0f);
		PoseStack _poseStack = _overlayEvent.getPoseStack();
		Vec3 _camera = _overlayEvent.getLevelRenderState().cameraRenderState.pos;
		_poseStack.pushPose();
		_poseStack.translate(x - _camera.x + 0.5, y - _camera.y + _height * 0.5, z - _camera.z + 0.5);
		_poseStack.mulPose(com.mojang.math.Axis.YP.rotationDegrees(-_spinDeg));
		_poseStack.mulPose(_overlayEvent.getLevelRenderState().cameraRenderState.orientation);
		_poseStack.scale(_width, _height, 1.0f);
		_overlayEvent.getSubmitNodeCollector().submitCustomGeometry(_poseStack, RenderTypes.entityTranslucent(_texture), (_pose, _consumer) -> {
			_consumer.addVertex(_pose, 0.5f, -0.5f, 0).setColor(0xFF, 0xFF, 0xFF, _a).setUv(0, 1).setOverlay(OverlayTexture.NO_OVERLAY).setLight(0xF000F0).setNormal(_pose, 0, 0, 1);
			_consumer.addVertex(_pose, 0.5f, 0.5f, 0).setColor(0xFF, 0xFF, 0xFF, _a).setUv(0, 0).setOverlay(OverlayTexture.NO_OVERLAY).setLight(0xF000F0).setNormal(_pose, 0, 0, 1);
			_consumer.addVertex(_pose, -0.5f, 0.5f, 0).setColor(0xFF, 0xFF, 0xFF, _a).setUv(1, 0).setOverlay(OverlayTexture.NO_OVERLAY).setLight(0xF000F0).setNormal(_pose, 0, 0, 1);
			_consumer.addVertex(_pose, -0.5f, -0.5f, 0).setColor(0xFF, 0xFF, 0xFF, _a).setUv(1, 1).setOverlay(OverlayTexture.NO_OVERLAY).setLight(0xF000F0).setNormal(_pose, 0, 0, 1);
		});
		_poseStack.popPose();
	}
}

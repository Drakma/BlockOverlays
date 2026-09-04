if (event instanceof RenderLevelStageEvent) {
	String _placement = ${input$placement};
	Direction _side = ${input$side};
	float _scale = (float) ${input$scale};
	ResourceLocation _texture = ${input$texture};
	PoseStack _poseStack = event.getPoseStack();
	Vec3 _camera = event.getCamera().getPosition();
	double _padding = ((Number) ${(input$padding!"0")}).doubleValue() / 16.0;
	Vec3 _position = ${(input$bounds!"false")} ? shapeBoundsPlacement(world.getBlockState(BlockPos.containing(x, y, z)), world, BlockPos.containing(x, y, z), _side, _placement, _scale, _scale, _padding) : new Vec3(itemPlacementX(_placement, _scale) + placementOffsetX(_placement, _padding), itemPlacementY(_placement, _scale) + placementOffsetY(_placement, _padding), -0.501);
	_poseStack.pushPose();
	_poseStack.translate(x - _camera.x + 0.5, y - _camera.y + 0.5, z - _camera.z + 0.5);
	_poseStack.mulPose(faceRotation(_side));
	_poseStack.translate(_position.x, _position.y, _position.z);
	_poseStack.scale(_scale, _scale, 1.0f);
	int _light = net.minecraft.client.renderer.LightTexture.pack(
		Minecraft.getInstance().level.getBrightness(net.minecraft.world.level.LightLayer.SKY, BlockPos.containing(x, y, z).relative(_side)),
		Minecraft.getInstance().level.getBrightness(net.minecraft.world.level.LightLayer.BLOCK, BlockPos.containing(x, y, z).relative(_side))
	);
	var _bufferSource = Minecraft.getInstance().renderBuffers().bufferSource();
	var _consumer = _bufferSource.getBuffer(RenderType.entityTranslucent(_texture));
	var _pose = _poseStack.last().pose();
	var _normal = _poseStack.last().normal();
	int _color = 0xFF${(field$color!"#ffffff")?substring(1)};
	int _a = (int) (Math.max(0.0f, Math.min(1.0f, (float) ${(input$transparency!"1.0")})) * 255.0f);
	int _r = (_color >> 16) & 0xFF, _g = (_color >> 8) & 0xFF, _b = _color & 0xFF;
	_consumer.vertex(_pose, 0.5f, -0.5f, 0).color(_r, _g, _b, _a).uv(0, 1).overlayCoords(OverlayTexture.NO_OVERLAY).uv2(_light).normal(_normal, 0, 0, -1).endVertex();
	_consumer.vertex(_pose, 0.5f, 0.5f, 0).color(_r, _g, _b, _a).uv(0, 0).overlayCoords(OverlayTexture.NO_OVERLAY).uv2(_light).normal(_normal, 0, 0, -1).endVertex();
	_consumer.vertex(_pose, -0.5f, 0.5f, 0).color(_r, _g, _b, _a).uv(1, 0).overlayCoords(OverlayTexture.NO_OVERLAY).uv2(_light).normal(_normal, 0, 0, -1).endVertex();
	_consumer.vertex(_pose, -0.5f, -0.5f, 0).color(_r, _g, _b, _a).uv(1, 1).overlayCoords(OverlayTexture.NO_OVERLAY).uv2(_light).normal(_normal, 0, 0, -1).endVertex();
	_bufferSource.endBatch(RenderType.entityTranslucent(_texture));
	_poseStack.popPose();
}

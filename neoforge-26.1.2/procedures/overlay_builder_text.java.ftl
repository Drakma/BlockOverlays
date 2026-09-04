if (event instanceof SubmitCustomGeometryEvent _overlayEvent) {
	String _placement = ${input$placement};
	String _text = ${input$text};
	Direction _side = ${input$side};
	Font _font = Minecraft.getInstance().font;
	float _scale = Math.copySign(Math.min(0.025f * Math.abs((float) ${input$scale}), Math.min(0.95f / Math.max(1, _font.width(_text)), 0.95f / Math.max(1, _font.lineHeight))), (float) ${input$scale});
	int _alphaInt = (int) (Math.max(0.0f, Math.min(1.0f, (float) ${(input$transparency!"1.0")})) * 255.0f);
	int _textColor = (_alphaInt << 24) | (0x00FFFFFF & 0xFF${(field$color!"#ffffff")?substring(1)});
	PoseStack _poseStack = _overlayEvent.getPoseStack();
	Vec3 _camera = _overlayEvent.getLevelRenderState().cameraRenderState.pos;
	double _padding = ((Number) ${(input$padding!"0")}).doubleValue() / 16.0;
	Vec3 _position = ${(input$bounds!"false")} ? shapeBoundsPlacement(world.getBlockState(BlockPos.containing(x, y, z)), world, BlockPos.containing(x, y, z), _side, _placement, 0.0, 0.0, _padding) : new Vec3(anchorX(_placement) - 0.5 + placementOffsetX(_placement, _padding), anchorY(_placement) - 0.5 + placementOffsetY(_placement, _padding), -0.501);
	_poseStack.pushPose();
	_poseStack.translate(x - _camera.x + 0.5, y - _camera.y + 0.5, z - _camera.z + 0.5);
	_poseStack.mulPose(faceRotation(_side));
	_poseStack.translate(_position.x, _position.y, _position.z);
	_poseStack.scale(-_scale, -_scale, _scale);
	_overlayEvent.getSubmitNodeCollector().submitText(_poseStack, localX(_placement, _font.width(_text)), localY(_placement, _font.lineHeight), Component.literal(_text).getVisualOrderText(), false, Font.DisplayMode.NORMAL, net.minecraft.client.renderer.LevelRenderer.getLightCoords(Minecraft.getInstance().level, net.minecraft.core.BlockPos.containing(x, y, z).relative(_side)), _textColor, 0, 0);
	_poseStack.popPose();
}
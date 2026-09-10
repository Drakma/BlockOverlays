if (event instanceof RenderLevelStageEvent) {
	String _placement = ${input$placement};
	Direction _side = ${input$side};
	String _text = "" + ${input$text};
	float _scale = (float) ${input$scale};
	String _rawColor = "${(field$color!"#ffffff")?trim?replace("#", "")}";
	long _parsedColor = Long.parseLong(_rawColor, 16);
	int _colorAlpha = (_rawColor.length() == 8) ? (int) ((_parsedColor >> 24) & 0xFF) : 255;
	int _alphaInt = (int) (Math.max(0.0f, Math.min(1.0f, (float) ${(input$transparency!"1.0")})) * (float) _colorAlpha);
	int _textColor = (_alphaInt << 24) | (int) (_parsedColor & 0x00FFFFFF);
	PoseStack _poseStack = event.getPoseStack();
	Vec3 _camera = event.getCamera().getPosition();
	Font _font = Minecraft.getInstance().font;
	float _textScale = (float) (0.025f * _scale);
	float _w = (float) (_font.width(_text) * _textScale);
	float _h = (float) (_font.lineHeight * _textScale);
	double _padding = ((Number) ${(input$padding!"0")}).doubleValue() / 16.0;
	Vec3 _position = ${(input$bounds!"false")} ? shapeBoundsPlacement(world.getBlockState(BlockPos.containing(x, y, z)), world, BlockPos.containing(x, y, z), _side, _placement, _w, _h, _padding) : new Vec3(itemPlacementX(_placement, _w) + placementOffsetX(_placement, _padding), itemPlacementY(_placement, _h) + placementOffsetY(_placement, _padding), -0.501);
	_poseStack.pushPose();
	_poseStack.translate(x - _camera.x + 0.5, y - _camera.y + 0.5, z - _camera.z + 0.5);
	_poseStack.mulPose(faceRotation(_side));
	_poseStack.translate(_position.x, _position.y, _position.z);
	_poseStack.scale(-_textScale, -_textScale, _textScale);
	int _light = net.minecraft.client.renderer.LightTexture.pack(
		Minecraft.getInstance().level.getBrightness(net.minecraft.world.level.LightLayer.SKY, BlockPos.containing(x, y, z).relative(_side)),
		Minecraft.getInstance().level.getBrightness(net.minecraft.world.level.LightLayer.BLOCK, BlockPos.containing(x, y, z).relative(_side))
	);
	var _bufferSource = Minecraft.getInstance().renderBuffers().bufferSource();
	_font.drawInBatch(_text, localX(_placement, _font.width(_text)), localY(_placement, _font.lineHeight), _textColor, false, _poseStack.last().pose(), _bufferSource, Font.DisplayMode.NORMAL, 0, _light);
	_bufferSource.endBatch();
	_poseStack.popPose();
}

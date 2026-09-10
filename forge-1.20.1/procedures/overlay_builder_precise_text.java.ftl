if (event instanceof RenderLevelStageEvent) {
	String _text = "" + ${input$text};
	Direction _side = ${input$side};
	double _coordX = ((Number) ${input$coord_x}).doubleValue();
	double _coordY = ((Number) ${input$coord_y}).doubleValue();
	Font _font = Minecraft.getInstance().font;
	float _scale = (float) ${input$scale} * 0.02f;
	String _rawColor = "${(field$color!"#ffffff")?trim?replace("#", "")}";
	long _parsedColor = Long.parseLong(_rawColor, 16);
	int _colorAlpha = (_rawColor.length() == 8) ? (int) ((_parsedColor >> 24) & 0xFF) : 255;
	int _alphaInt = (int) (Math.max(0.0f, Math.min(1.0f, (float) ${(input$transparency!"1.0")})) * (float) _colorAlpha);
	int _textColor = (_alphaInt << 24) | (int) (_parsedColor & 0x00FFFFFF);
	PoseStack _poseStack = event.getPoseStack();
	Vec3 _camera = event.getCamera().getPosition();
	double _padding = ((Number) ${(input$padding!"0")}).doubleValue() / 16.0;
	Vec3 _position = ${(input$bounds!"false")} ? shapeBoundsPrecise(world.getBlockState(BlockPos.containing(x, y, z)), world, BlockPos.containing(x, y, z), _side, _coordX, _coordY, _padding) : new Vec3(0.5 - (_coordX / 16.0) + (_coordX < 8.0 ? -_padding : _coordX > 8.0 ? _padding : 0.0), -0.5 + (_coordY / 16.0) + (_coordY > 8.0 ? -_padding : _coordY < 8.0 ? _padding : 0.0), -0.501);
	float _alignOffset = switch ("${field$alignment!"LEFT"}") {
		case "CENTER" -> -_font.width(_text) / 2.0f;
		case "RIGHT" -> -_font.width(_text);
		default -> 0.0f;
	};
	float _verticalOffset = -_font.lineHeight;
	_poseStack.pushPose();
	_poseStack.translate(x - _camera.x + 0.5, y - _camera.y + 0.5, z - _camera.z + 0.5);
	_poseStack.mulPose(faceRotation(_side));
	_poseStack.translate(_position.x, _position.y, _position.z);
	_poseStack.scale(-_scale, -_scale, _scale);
	int _light = net.minecraft.client.renderer.LightTexture.pack(
		Minecraft.getInstance().level.getBrightness(net.minecraft.world.level.LightLayer.SKY, BlockPos.containing(x, y, z).relative(_side)),
		Minecraft.getInstance().level.getBrightness(net.minecraft.world.level.LightLayer.BLOCK, BlockPos.containing(x, y, z).relative(_side))
	);
	var _bufferSource = Minecraft.getInstance().renderBuffers().bufferSource();
	_font.drawInBatch(_text, _alignOffset, _verticalOffset, _textColor, false, _poseStack.last().pose(), _bufferSource, Font.DisplayMode.NORMAL, 0, _light);
	_bufferSource.endBatch();
	_poseStack.popPose();
}

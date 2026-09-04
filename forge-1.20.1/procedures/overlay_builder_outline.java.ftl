if (event instanceof RenderLevelStageEvent _overlayEvent) {
	PoseStack _poseStack = _overlayEvent.getPoseStack();
	Vec3 _camera = _overlayEvent.getCamera().getPosition();
	int _color = 0xFF${(field$color!"#ffffff")?substring(1)};
	float _a = Math.max(0.0f, Math.min(1.0f, (float) ${(input$transparency!"1.0")}));
	float _r = ((_color >> 16) & 0xFF) / 255.0f, _g = ((_color >> 8) & 0xFF) / 255.0f, _b = (_color & 0xFF) / 255.0f;
	_poseStack.pushPose();
	_poseStack.translate(x - _camera.x, y - _camera.y, z - _camera.z);
	var _bufferSource = Minecraft.getInstance().renderBuffers().bufferSource();
	var _consumer = _bufferSource.getBuffer(RenderType.lines());
	var _shape = ${(input$bounds!"false")} ? world.getBlockState(BlockPos.containing(x, y, z)).getShape(world, BlockPos.containing(x, y, z)) : net.minecraft.world.phys.shapes.Shapes.block();
	LevelRenderer.renderShape(_poseStack, _consumer, _shape, 0, 0, 0, _r, _g, _b, _a);
	_bufferSource.endBatch(RenderType.lines());
	_poseStack.popPose();
}

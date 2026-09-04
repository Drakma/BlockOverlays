if (event instanceof SubmitCustomGeometryEvent _overlayEvent) {
	PoseStack _poseStack = _overlayEvent.getPoseStack();
	Vec3 _camera = _overlayEvent.getLevelRenderState().cameraRenderState.pos;
	net.minecraft.world.phys.shapes.VoxelShape _shape = ${(input$bounds!"false")} ? world.getBlockState(BlockPos.containing(x, y, z)).getShape(world, BlockPos.containing(x, y, z)) : Shapes.block();
	int _alphaInt = (int) (Math.max(0.0f, Math.min(1.0f, (float) ${(input$transparency!"1.0")})) * 255.0f);
	int _outlineColor = (_alphaInt << 24) | (0x00FFFFFF & 0xFF${(field$color!"#ff0000")?substring(1)});
	_poseStack.pushPose();
	_poseStack.translate(x - _camera.x, y - _camera.y, z - _camera.z);
	VertexConsumer _consumer = Minecraft.getInstance().renderBuffers().bufferSource().getBuffer(${input$through_walls} ? RenderTypes.linesTranslucent() : RenderTypes.lines());
	ShapeRenderer.renderShape(_poseStack, _consumer, _shape, 0, 0, 0, _outlineColor, (float) ${input$width});
	_poseStack.popPose();
}
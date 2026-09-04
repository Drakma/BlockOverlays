<#include "mcitems.ftl">
if (event instanceof RenderLevelStageEvent _overlayEvent) {
	String _placement = ${input$placement};
	Direction _side = ${input$side};
	TextureAtlasSprite _sprite = Minecraft.getInstance().getBlockRenderer().getBlockModelShaper().getParticleIcon(${mappedBlockToBlockStateCode(input$block)});
	PoseStack _poseStack = _overlayEvent.getPoseStack();
	Vec3 _camera = _overlayEvent.getCamera().getPosition();
	double _padding = ((Number) ${(input$padding!"0")}).doubleValue() / 16.0;
	Vec3 _position = ${(input$bounds!"false")} ? shapeBoundsPlacement(world.getBlockState(BlockPos.containing(x, y, z)), world, BlockPos.containing(x, y, z), _side, _placement, 1.0 / 3.0, 1.0 / 3.0, _padding) : new Vec3(itemPlacementX(_placement, 1.0 / 3.0) + placementOffsetX(_placement, _padding), itemPlacementY(_placement, 1.0 / 3.0) + placementOffsetY(_placement, _padding), -0.501);
	_poseStack.pushPose();
	_poseStack.translate(x - _camera.x + 0.5, y - _camera.y + 0.5, z - _camera.z + 0.5);
	_poseStack.mulPose(faceRotation(_side));
	_poseStack.translate(_position.x, _position.y, _position.z);
	_poseStack.scale(1.0f / 3.0f, 1.0f / 3.0f, 1.0f);
	int _light = LevelRenderer.getLightCoords(Minecraft.getInstance().level, BlockPos.containing(x, y, z).relative(_side));
	var _bufferSource = Minecraft.getInstance().renderBuffers().bufferSource();
	var _consumer = _bufferSource.getBuffer(RenderType.entityTranslucent(TextureAtlas.LOCATION_BLOCKS));
	var _pose = _poseStack.last().pose();
	var _normal = _poseStack.last().normal();
	int _color = 0xFF${(field$color!"#ffffff")?substring(1)};
	int _a = (int) (Math.max(0.0f, Math.min(1.0f, (float) ${(input$transparency!"1.0")})) * 255.0f);
	int _r = (_color >> 16) & 0xFF, _g = (_color >> 8) & 0xFF, _b = _color & 0xFF;
	_consumer.vertex(_pose, 0.5f, -0.5f, 0).color(_r, _g, _b, _a).uv(_sprite.getU0(), _sprite.getV1()).overlayCoords(OverlayTexture.NO_OVERLAY).uv2(_light).normal(_normal, 0, 0, -1).endVertex();
	_consumer.vertex(_pose, 0.5f, 0.5f, 0).color(_r, _g, _b, _a).uv(_sprite.getU0(), _sprite.getV0()).overlayCoords(OverlayTexture.NO_OVERLAY).uv2(_light).normal(_normal, 0, 0, -1).endVertex();
	_consumer.vertex(_pose, -0.5f, 0.5f, 0).color(_r, _g, _b, _a).uv(_sprite.getU1(), _sprite.getV0()).overlayCoords(OverlayTexture.NO_OVERLAY).uv2(_light).normal(_normal, 0, 0, -1).endVertex();
	_consumer.vertex(_pose, -0.5f, -0.5f, 0).color(_r, _g, _b, _a).uv(_sprite.getU1(), _sprite.getV1()).overlayCoords(OverlayTexture.NO_OVERLAY).uv2(_light).normal(_normal, 0, 0, -1).endVertex();
	_bufferSource.endBatch(RenderType.entityTranslucent(TextureAtlas.LOCATION_BLOCKS));
	_poseStack.popPose();
}

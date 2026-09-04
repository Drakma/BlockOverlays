<#include "mcitems.ftl">
if (event instanceof SubmitCustomGeometryEvent _overlayEvent) {
	String _placement = ${input$placement};
	Direction _side = ${input$side};
	int _color = 0xFF${(field$color!"#ffffff")?substring(1)};
	int _r = (_color >> 16) & 0xFF, _g = (_color >> 8) & 0xFF, _b = _color & 0xFF;
	int _a = (int) (Math.max(0.0f, Math.min(1.0f, (float) ${(input$transparency!"1.0")})) * 255.0f);
	net.minecraft.client.renderer.texture.TextureAtlasSprite _sprite = Minecraft.getInstance().getModelManager().getBlockStateModelSet().get(${mappedBlockToBlockStateCode(input$block)}).particleMaterial().sprite();
	PoseStack _poseStack = _overlayEvent.getPoseStack();
	Vec3 _camera = _overlayEvent.getLevelRenderState().cameraRenderState.pos;
	double _padding = ((Number) ${(input$padding!"0")}).doubleValue() / 16.0;
	Vec3 _position = ${(input$bounds!"false")} ? shapeBoundsPlacement(world.getBlockState(BlockPos.containing(x, y, z)), world, BlockPos.containing(x, y, z), _side, _placement, 1.0 / 3.0, 1.0 / 3.0, _padding) : new Vec3(itemPlacementX(_placement, 1.0 / 3.0) + placementOffsetX(_placement, _padding), itemPlacementY(_placement, 1.0 / 3.0) + placementOffsetY(_placement, _padding), -0.501);
	_poseStack.pushPose();
	_poseStack.translate(x - _camera.x + 0.5, y - _camera.y + 0.5, z - _camera.z + 0.5);
	_poseStack.mulPose(faceRotation(_side));
	_poseStack.translate(_position.x, _position.y, _position.z);
	_poseStack.scale(1.0f / 3.0f, 1.0f / 3.0f, 1.0f);
	_overlayEvent.getSubmitNodeCollector().submitCustomGeometry(_poseStack, RenderTypes.entityTranslucent(net.minecraft.client.renderer.texture.TextureAtlas.LOCATION_BLOCKS), (_pose, _consumer) -> {
		_consumer.addVertex(_pose, 0.5f, -0.5f, 0).setColor(_r, _g, _b, _a).setUv(_sprite.getU0(), _sprite.getV1()).setOverlay(OverlayTexture.NO_OVERLAY).setLight(net.minecraft.client.renderer.LevelRenderer.getLightCoords(Minecraft.getInstance().level, net.minecraft.core.BlockPos.containing(x, y, z).relative(_side))).setNormal(_pose, 0, 0, -1);
		_consumer.addVertex(_pose, 0.5f, 0.5f, 0).setColor(_r, _g, _b, _a).setUv(_sprite.getU0(), _sprite.getV0()).setOverlay(OverlayTexture.NO_OVERLAY).setLight(net.minecraft.client.renderer.LevelRenderer.getLightCoords(Minecraft.getInstance().level, net.minecraft.core.BlockPos.containing(x, y, z).relative(_side))).setNormal(_pose, 0, 0, -1);
		_consumer.addVertex(_pose, -0.5f, 0.5f, 0).setColor(_r, _g, _b, _a).setUv(_sprite.getU1(), _sprite.getV0()).setOverlay(OverlayTexture.NO_OVERLAY).setLight(net.minecraft.client.renderer.LevelRenderer.getLightCoords(Minecraft.getInstance().level, net.minecraft.core.BlockPos.containing(x, y, z).relative(_side))).setNormal(_pose, 0, 0, -1);
		_consumer.addVertex(_pose, -0.5f, -0.5f, 0).setColor(_r, _g, _b, _a).setUv(_sprite.getU1(), _sprite.getV1()).setOverlay(OverlayTexture.NO_OVERLAY).setLight(net.minecraft.client.renderer.LevelRenderer.getLightCoords(Minecraft.getInstance().level, net.minecraft.core.BlockPos.containing(x, y, z).relative(_side))).setNormal(_pose, 0, 0, -1);
	});
	_poseStack.popPose();
}
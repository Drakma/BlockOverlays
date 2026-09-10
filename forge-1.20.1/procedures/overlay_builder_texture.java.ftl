<#include "mcitems.ftl">
if (event instanceof RenderLevelStageEvent) {
	String _placement = ${input$placement};
	Direction _side = ${input$side};
	double _scale = ((Number) ${(input$scale!"(1.0 / 3.0)")}).doubleValue();
	BlockState _targetState = ${mappedBlockToBlockStateCode(input$block)};
	TextureAtlasSprite _sprite = null;
	net.minecraft.client.resources.model.BakedModel _model = Minecraft.getInstance().getBlockRenderer().getBlockModel(_targetState);
	String _blockSideStr = "${field$block_side!"PARTICLE"}";
	if (!"PARTICLE".equals(_blockSideStr)) {
		Direction _dir = Direction.byName(_blockSideStr.toLowerCase());
		java.util.List<net.minecraft.client.renderer.block.model.BakedQuad> _quads = _model.getQuads(_targetState, _dir, net.minecraft.util.RandomSource.create(42L));
		if (_quads != null && !_quads.isEmpty()) {
			_sprite = _quads.get(0).getSprite();
		}
		if (_sprite == null) {
			_quads = _model.getQuads(_targetState, null, net.minecraft.util.RandomSource.create(42L));
			if (_quads != null && !_quads.isEmpty()) {
				_sprite = _quads.get(0).getSprite();
			}
		}
	}
	if (_sprite == null) {
		_sprite = Minecraft.getInstance().getBlockRenderer().getBlockModelShaper().getParticleIcon(_targetState);
	}
	PoseStack _poseStack = event.getPoseStack();
	Vec3 _camera = event.getCamera().getPosition();
	double _padding = ((Number) ${(input$padding!"0")}).doubleValue() / 16.0;
	double _offsetY = ((Number) ${(input$offset_y!"0")}).doubleValue() / 16.0;
	Vec3 _position = ${(input$bounds!"false")} ? shapeBoundsPlacement(world.getBlockState(BlockPos.containing(x, y, z)), world, BlockPos.containing(x, y, z), _side, _placement, _scale, _scale, _padding) : new Vec3(itemPlacementX(_placement, _scale) + placementOffsetX(_placement, _padding), itemPlacementY(_placement, _scale) + placementOffsetY(_placement, _padding), -0.501);
	_poseStack.pushPose();
	_poseStack.translate(x - _camera.x + 0.5, y - _camera.y + 0.5 + _offsetY, z - _camera.z + 0.5);
	_poseStack.mulPose(faceRotation(_side));
	_poseStack.translate(_position.x, _position.y, _position.z);
	_poseStack.scale((float) _scale, (float) _scale, 1.0f);
	int _light = net.minecraft.client.renderer.LightTexture.FULL_BRIGHT;
	var _bufferSource = Minecraft.getInstance().renderBuffers().bufferSource();
	var _consumer = _bufferSource.getBuffer(RenderType.entityTranslucent(TextureAtlas.LOCATION_BLOCKS));
	var _pose = _poseStack.last().pose();
	var _normal = _poseStack.last().normal();
	String _rawColor = "" + <#if input$color??>${input$color}<#elseif field$color??>"${field$color}"<#else>"#ffffffff"</#if>;
	_rawColor = _rawColor.trim().replace("#", "").replace("0x", "").replace("0X", "").replace("\"", "");
	long _parsedColor = 0xFFFFFFFFL;
	try {
		_parsedColor = Long.parseLong(_rawColor, 16);
	} catch (Exception _e) {
		_parsedColor = 0xFFFFFFFFL;
	}
	int _rTint, _gTint, _bTint, _aTint;
	if (_rawColor.length() == 8) {
		_rTint = (int) ((_parsedColor >> 24) & 0xFF);
		_gTint = (int) ((_parsedColor >> 16) & 0xFF);
		_bTint = (int) ((_parsedColor >> 8) & 0xFF);
		_aTint = (int) (_parsedColor & 0xFF);
	} else {
		_rTint = (int) ((_parsedColor >> 16) & 0xFF);
		_gTint = (int) ((_parsedColor >> 8) & 0xFF);
		_bTint = (int) (_parsedColor & 0xFF);
		_aTint = 255;
	}
	boolean _useColor = ${(input$use_color!"true")};
	float _tintAlpha = _useColor ? Math.max(0.0f, Math.min(1.0f, (float) _aTint / 255.0f)) : 0.0f;
	int _r = Math.max(0, Math.min(255, Math.round(255.0f * (1.0f - _tintAlpha) + (float) _rTint * _tintAlpha)));
	int _g = Math.max(0, Math.min(255, Math.round(255.0f * (1.0f - _tintAlpha) + (float) _gTint * _tintAlpha)));
	int _b = Math.max(0, Math.min(255, Math.round(255.0f * (1.0f - _tintAlpha) + (float) _bTint * _tintAlpha)));
	int _a = (int) (Math.max(0.0f, Math.min(1.0f, (float) ${(input$transparency!"1.0")})) * 255.0f);
	_consumer.vertex(_pose, 0.5f, -0.5f, 0).color(_r, _g, _b, _a).uv(_sprite.getU0(), _sprite.getV1()).overlayCoords(OverlayTexture.NO_OVERLAY).uv2(_light).normal(_normal, 0, 0, -1).endVertex();
	_consumer.vertex(_pose, 0.5f, 0.5f, 0).color(_r, _g, _b, _a).uv(_sprite.getU0(), _sprite.getV0()).overlayCoords(OverlayTexture.NO_OVERLAY).uv2(_light).normal(_normal, 0, 0, -1).endVertex();
	_consumer.vertex(_pose, -0.5f, 0.5f, 0).color(_r, _g, _b, _a).uv(_sprite.getU1(), _sprite.getV0()).overlayCoords(OverlayTexture.NO_OVERLAY).uv2(_light).normal(_normal, 0, 0, -1).endVertex();
	_consumer.vertex(_pose, -0.5f, -0.5f, 0).color(_r, _g, _b, _a).uv(_sprite.getU1(), _sprite.getV1()).overlayCoords(OverlayTexture.NO_OVERLAY).uv2(_light).normal(_normal, 0, 0, -1).endVertex();
	_bufferSource.endBatch(RenderType.entityTranslucent(TextureAtlas.LOCATION_BLOCKS));
	_poseStack.popPose();
}

<#include "mcitems.ftl">
if (event instanceof SubmitCustomGeometryEvent _overlayEvent) {
	String _placement = ${input$placement};
	Direction _side = ${input$side};
	double _scale = ((Number) ${(input$scale!"(1.0 / 3.0)")}).doubleValue();
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
	net.minecraft.client.renderer.texture.TextureAtlasSprite _sprite = null;
	var _targetState = ${mappedBlockToBlockStateCode(input$block)};
	var _model = Minecraft.getInstance().getModelManager().getBlockStateModelSet().get(_targetState);
	String _blockSideStr = "${field$block_side!"PARTICLE"}";
	if (!"PARTICLE".equals(_blockSideStr)) {
		Direction _dir = Direction.byName(_blockSideStr.toLowerCase());
		java.util.List<net.minecraft.client.renderer.block.dispatch.BlockStateModelPart> _parts = new java.util.ArrayList<>();
		_model.collectParts(net.minecraft.util.RandomSource.create(42L), _parts);
		for (var _part : _parts) {
			var _quads = _part.getQuads(_dir);
			if (_quads != null && !_quads.isEmpty()) {
				_sprite = _quads.get(0).materialInfo().sprite();
				break;
			}
		}
		if (_sprite == null) {
			for (var _part : _parts) {
				var _quads = _part.getQuads(null);
				if (_quads != null && !_quads.isEmpty()) {
					_sprite = _quads.get(0).materialInfo().sprite();
					break;
				}
			}
		}
	}
	if (_sprite == null) {
		_sprite = _model.particleMaterial().sprite();
	}
	final net.minecraft.client.renderer.texture.TextureAtlasSprite _finalSprite = _sprite;
	PoseStack _poseStack = _overlayEvent.getPoseStack();
	Vec3 _camera = _overlayEvent.getLevelRenderState().cameraRenderState.pos;
	double _padding = ((Number) ${(input$padding!"0")}).doubleValue() / 16.0;
	double _offsetY = ((Number) ${(input$offset_y!"0")}).doubleValue() / 16.0;
	Vec3 _position = ${(input$bounds!"false")} ? shapeBoundsPlacement(world.getBlockState(BlockPos.containing(x, y, z)), world, BlockPos.containing(x, y, z), _side, _placement, _scale, _scale, _padding) : new Vec3(itemPlacementX(_placement, _scale) + placementOffsetX(_placement, _padding), itemPlacementY(_placement, _scale) + placementOffsetY(_placement, _padding), -0.501);
	_poseStack.pushPose();
	_poseStack.translate(x - _camera.x + 0.5, y - _camera.y + 0.5 + _offsetY, z - _camera.z + 0.5);
	_poseStack.mulPose(faceRotation(_side));
	_poseStack.translate(_position.x, _position.y, _position.z);
	_poseStack.scale((float) _scale, (float) _scale, 1.0f);
	_overlayEvent.getSubmitNodeCollector().submitCustomGeometry(_poseStack, RenderTypes.entityTranslucent(net.minecraft.client.renderer.texture.TextureAtlas.LOCATION_BLOCKS), (_pose, _consumer) -> {
		_consumer.addVertex(_pose, 0.5f, -0.5f, 0).setColor(_r, _g, _b, _a).setUv(_finalSprite.getU0(), _finalSprite.getV1()).setOverlay(OverlayTexture.NO_OVERLAY).setLight(net.minecraft.client.renderer.LightTexture.FULL_BRIGHT).setNormal(_pose, 0, 0, -1);
		_consumer.addVertex(_pose, 0.5f, 0.5f, 0).setColor(_r, _g, _b, _a).setUv(_finalSprite.getU0(), _finalSprite.getV0()).setOverlay(OverlayTexture.NO_OVERLAY).setLight(net.minecraft.client.renderer.LightTexture.FULL_BRIGHT).setNormal(_pose, 0, 0, -1);
		_consumer.addVertex(_pose, -0.5f, 0.5f, 0).setColor(_r, _g, _b, _a).setUv(_finalSprite.getU1(), _finalSprite.getV0()).setOverlay(OverlayTexture.NO_OVERLAY).setLight(net.minecraft.client.renderer.LightTexture.FULL_BRIGHT).setNormal(_pose, 0, 0, -1);
		_consumer.addVertex(_pose, -0.5f, -0.5f, 0).setColor(_r, _g, _b, _a).setUv(_finalSprite.getU1(), _finalSprite.getV1()).setOverlay(OverlayTexture.NO_OVERLAY).setLight(net.minecraft.client.renderer.LightTexture.FULL_BRIGHT).setNormal(_pose, 0, 0, -1);
	});
	_poseStack.popPose();
}
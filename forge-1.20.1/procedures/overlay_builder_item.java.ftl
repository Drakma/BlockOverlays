<#include "mcitems.ftl">
if (event instanceof RenderLevelStageEvent) {
	float _transparency = Math.max(0.0f, Math.min(1.0f, (float) ${(input$transparency!"1.0")}));
	if (_transparency > 0.0f) {
		String _placement = ${input$placement};
		Direction _side = ${input$side};
		float _scale = (float) ${input$scale};
		float _rotX = (float) ${input$angle_x};
		float _rotY = (float) ${input$angle_y};
		float _rotZ = (float) ${input$angle_z};
		float _thickness = (float) ${(input$thickness!input$extrude!"5")};
		PoseStack _poseStack = event.getPoseStack();
		Vec3 _camera = event.getCamera().getPosition();
		double _padding = ((Number) ${(input$padding!"0")}).doubleValue() / 16.0;
		Vec3 _position = ${(input$bounds!"false")} ? shapeBoundsPlacement(world.getBlockState(BlockPos.containing(x, y, z)), world, BlockPos.containing(x, y, z), _side, _placement, _scale, _scale, _padding) : new Vec3(itemPlacementX(_placement, _scale) + placementOffsetX(_placement, _padding), itemPlacementY(_placement, _scale) + placementOffsetY(_placement, _padding), -0.501);
		ItemStack _itemStack = ${mappedMCItemToItemStackCode(input$item, 1)};
		int _light = net.minecraft.client.renderer.LightTexture.pack(
			Minecraft.getInstance().level.getBrightness(net.minecraft.world.level.LightLayer.SKY, BlockPos.containing(x, y, z).relative(_side)),
			Minecraft.getInstance().level.getBrightness(net.minecraft.world.level.LightLayer.BLOCK, BlockPos.containing(x, y, z).relative(_side))
		);
		var _bufferSource = Minecraft.getInstance().renderBuffers().bufferSource();
		int _layers = _thickness <= 0 ? 1 : Math.max(1, Math.min(64, Math.round(_thickness * 8.0f)));
		double _totalExtrusion = _thickness <= 0 ? 0.0 : (_thickness / 16.0) * _scale;
		double _step = _layers > 1 ? _totalExtrusion / (_layers - 1) : 0.0;
		for (int _i = 0; _i < _layers; _i++) {
			_poseStack.pushPose();
			_poseStack.translate(x - _camera.x + 0.5, y - _camera.y + 0.5, z - _camera.z + 0.5);
			_poseStack.mulPose(faceRotation(_side));
			_poseStack.translate(_position.x, _position.y, _position.z - (_i * _step));
			_poseStack.scale(_scale, _scale, 0.001f);
			if (_rotX != 0.0F) _poseStack.mulPose(com.mojang.math.Axis.XP.rotationDegrees(_rotX));
			if (_rotY != 0.0F) _poseStack.mulPose(com.mojang.math.Axis.YP.rotationDegrees(_rotY));
			if (_rotZ != 0.0F) _poseStack.mulPose(com.mojang.math.Axis.ZP.rotationDegrees(_rotZ));
			if (_itemStack.getItem() instanceof BlockItem) {
				_poseStack.scale(0.625f, 0.625f, 0.625f);
			}
			Minecraft.getInstance().getItemRenderer().renderStatic(_itemStack, ItemDisplayContext.FIXED, _light, OverlayTexture.NO_OVERLAY, _poseStack, _bufferSource, Minecraft.getInstance().level, 0);
			_poseStack.popPose();
		}
		_bufferSource.endBatch();
	}
}

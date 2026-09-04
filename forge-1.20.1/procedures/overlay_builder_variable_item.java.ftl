<#include "mcitems.ftl">
if (event instanceof RenderLevelStageEvent) {
	String _placement = ${input$placement};
	Direction _side = ${input$side};
	float _scale = Math.max(0.0f, Math.min(1.0f, (float) ${input$value}));
	float _distance = (float) ${(input$distance!"0")};
	float _bobHeight = Math.max(0, (float) ${input$bob_height});
	float _animTime = (float) (System.nanoTime() / 1_000_000L % 36000000L) / 50.0f;
	float _spinDegrees = _animTime * (float) ${input$spin_speed};
	float _bob = (float) Math.sin(_animTime * 0.075f) * _bobHeight;
	if (_scale > 0.0f) {
		double _padding = ((Number) ${(input$padding!"0")}).doubleValue() / 16.0;
		PoseStack _poseStack = event.getPoseStack();
		Vec3 _camera = event.getCamera().getPosition();
		_poseStack.pushPose();
		_poseStack.translate(x - _camera.x + 0.5, y - _camera.y + 0.5, z - _camera.z + 0.5);
		_poseStack.mulPose(faceRotation(_side));
		_poseStack.translate(itemPlacementX(_placement, _scale) + placementOffsetX(_placement, _padding), itemPlacementY(_placement, _scale) + placementOffsetY(_placement, _padding), -(0.5f + _scale * 0.5f) - _bob - _distance);
		_poseStack.mulPose(com.mojang.math.Axis.XP.rotationDegrees(-90.0F));
		_poseStack.mulPose(com.mojang.math.Axis.YP.rotationDegrees(_spinDegrees));
		_poseStack.scale(_scale, _scale, _scale);
		int _light = net.minecraft.client.renderer.LightTexture.pack(
			Minecraft.getInstance().level.getBrightness(net.minecraft.world.level.LightLayer.SKY, BlockPos.containing(x, y, z).relative(_side)),
			Minecraft.getInstance().level.getBrightness(net.minecraft.world.level.LightLayer.BLOCK, BlockPos.containing(x, y, z).relative(_side))
		);
		var _bufferSource = Minecraft.getInstance().renderBuffers().bufferSource();
		Minecraft.getInstance().getItemRenderer().renderStatic(${mappedMCItemToItemStackCode(input$item, 1)}, ItemDisplayContext.FIXED, _light, OverlayTexture.NO_OVERLAY, _poseStack, _bufferSource, Minecraft.getInstance().level, 0);
		_bufferSource.endBatch();
		_poseStack.popPose();
	}
}

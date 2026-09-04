<#include "mcitems.ftl">
if (event instanceof RenderLevelStageEvent _overlayEvent) {
	float _scale = (float) ${input$scale};
	float _rotX = (float) ${(input$angle_x!"0")};
	float _rotY = (float) ${(input$angle_y!"0")};
	float _rotZ = (float) ${(input$angle_z!"0")};
	float _bobHeight = Math.max(0, (float) ${input$bob_height});
	float _animTime = (float) (System.nanoTime() / 1_000_000L % 36000000L) / 50.0f;
	float _spinDegrees = _animTime * (float) ${input$spin_speed};
	float _bob = (float) Math.sin(_animTime * 0.075f) * _bobHeight;
	PoseStack _poseStack = _overlayEvent.getPoseStack();
	Vec3 _camera = _overlayEvent.getCamera().getPosition();
	_poseStack.pushPose();
	_poseStack.translate(x - _camera.x + 0.5, y - _camera.y + 0.5 + _bob, z - _camera.z + 0.5);
	_poseStack.mulPose(com.mojang.math.Axis.YP.rotationDegrees(_spinDegrees));
	if (_rotX != 0.0F) _poseStack.mulPose(com.mojang.math.Axis.XP.rotationDegrees(_rotX));
	if (_rotY != 0.0F) _poseStack.mulPose(com.mojang.math.Axis.YP.rotationDegrees(_rotY));
	if (_rotZ != 0.0F) _poseStack.mulPose(com.mojang.math.Axis.ZP.rotationDegrees(_rotZ));
	_poseStack.scale(_scale, _scale, _scale);
	int _light = LevelRenderer.getLightCoords(Minecraft.getInstance().level, BlockPos.containing(x, y, z));
	var _bufferSource = Minecraft.getInstance().renderBuffers().bufferSource();
	Minecraft.getInstance().getItemRenderer().renderStatic(${mappedMCItemToItemStackCode(input$item, 1)}, ItemDisplayContext.FIXED, _light, OverlayTexture.NO_OVERLAY, _poseStack, _bufferSource, Minecraft.getInstance().level, 0);
	_bufferSource.endBatch();
	_poseStack.popPose();
}

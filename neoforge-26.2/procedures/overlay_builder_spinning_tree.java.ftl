<#include "mcitems.ftl">
if (event instanceof SubmitCustomGeometryEvent _overlayEvent) {
	net.minecraft.world.item.ItemStack _saplingStack = ${mappedMCItemToItemStackCode(input$sapling, 1)};
	net.minecraft.world.level.block.state.BlockState _fallbackLogState = ${mappedBlockToBlockStateCode(input$fallback_log)};
	net.minecraft.world.level.block.state.BlockState _fallbackLeavesState = ${mappedBlockToBlockStateCode(input$fallback_leaves)};
	net.minecraft.world.level.block.state.BlockState _logStateBc = _fallbackLogState;
	net.minecraft.world.level.block.state.BlockState _leavesStateBc = _fallbackLeavesState;
	net.minecraft.resources.Identifier _saplingId = BuiltInRegistries.ITEM.getKey(_saplingStack.getItem());
	if (_saplingId != null) {
		String _saplingPath = _saplingId.getPath();
		String _species = null;
		if (_saplingPath.endsWith("_sapling")) {
			_species = _saplingPath.substring(0, _saplingPath.length() - "_sapling".length());
		} else if (_saplingPath.endsWith("_propagule")) {
			_species = _saplingPath.substring(0, _saplingPath.length() - "_propagule".length());
		}
		if (_species != null && !_species.isEmpty()) {
			net.minecraft.resources.Identifier _logId = net.minecraft.resources.Identifier.fromNamespaceAndPath(_saplingId.getNamespace(), _species + "_log");
			net.minecraft.resources.Identifier _leavesId = net.minecraft.resources.Identifier.fromNamespaceAndPath(_saplingId.getNamespace(), _species + "_leaves");
			java.util.Optional<net.minecraft.world.level.block.Block> _logBlock = BuiltInRegistries.BLOCK.getOptional(_logId);
			java.util.Optional<net.minecraft.world.level.block.Block> _leavesBlock = BuiltInRegistries.BLOCK.getOptional(_leavesId);
			if (_logBlock.isPresent() && _leavesBlock.isPresent()) {
				_logStateBc = _logBlock.get().defaultBlockState();
				_leavesStateBc = _leavesBlock.get().defaultBlockState();
			}
		}
	}
	int _trunkHeight = Math.max(1, Math.min(16, (int) Math.round((float) ${input$trunk_height})));
	int _leafRadius = Math.max(0, Math.min(4, (int) Math.round((float) ${input$leaf_radius})));
	float _scale = Math.max(0.0f, Math.min(1.0f, (float) ${input$scale}));
	if (_scale > 0.0f) {
		net.minecraft.client.renderer.block.BlockModelResolver _resolver = new net.minecraft.client.renderer.block.BlockModelResolver(Minecraft.getInstance().getModelManager());
		net.minecraft.client.renderer.block.model.BlockDisplayContext _displayCtx = net.minecraft.client.renderer.block.model.BlockDisplayContext.create();
		net.minecraft.client.renderer.block.BlockModelRenderState _logRState = new net.minecraft.client.renderer.block.BlockModelRenderState();
		net.minecraft.client.renderer.block.BlockModelRenderState _leavesRState = new net.minecraft.client.renderer.block.BlockModelRenderState();
		_resolver.update(_logRState, _logStateBc, _displayCtx);
		_resolver.update(_leavesRState, _leavesStateBc, _displayCtx);
		float _animTime = (float) (System.nanoTime() / 1_000_000L % 36000000L) / 50.0f;
		float _spinDeg = _animTime * (float) ${input$spin_speed};
		PoseStack _poseStack = _overlayEvent.getPoseStack();
		Vec3 _camera = _overlayEvent.getLevelRenderState().cameraRenderState.pos;
		int _light = net.minecraft.client.renderer.LevelRenderer.getLightCoords(Minecraft.getInstance().level, net.minecraft.core.BlockPos.containing(x, y, z));
		_poseStack.pushPose();
		_poseStack.translate(x - _camera.x + 0.5, y - _camera.y, z - _camera.z + 0.5);
		_poseStack.mulPose(com.mojang.math.Axis.YP.rotationDegrees(_spinDeg));
		_poseStack.scale(_scale, _scale, _scale);
		_poseStack.pushPose();
		_logRState.submit(_poseStack, _overlayEvent.getSubmitNodeCollector(), _light, OverlayTexture.NO_OVERLAY, 0);
		for (int _i = 1; _i < _trunkHeight; _i++) {
			_poseStack.pushPose();
			_poseStack.translate(0.0f, _i, 0.0f);
			_logRState.submit(_poseStack, _overlayEvent.getSubmitNodeCollector(), _light, OverlayTexture.NO_OVERLAY, 0);
			_poseStack.popPose();
		}
		_poseStack.popPose();
		_poseStack.pushPose();
		_poseStack.translate(0.0f, _trunkHeight, 0.0f);
		for (int _dy = -_leafRadius; _dy <= _leafRadius; _dy++) {
			float _r = _leafRadius + 0.5f;
			int _extent = Math.max(0, (int) Math.round(Math.sqrt(Math.max(0.0f, _r * _r - _dy * _dy))));
			for (int _dx = -_extent; _dx <= _extent; _dx++) {
				for (int _dz = -_extent; _dz <= _extent; _dz++) {
					if (_dx == 0 && _dz == 0 && _dy < 0)
						continue;
					if (Math.abs(_dy) == _leafRadius && (Math.abs(_dx) > _extent - 1 || Math.abs(_dz) > _extent - 1))
						continue;
					_poseStack.pushPose();
					_poseStack.translate(_dx, _dy, _dz);
					_leavesRState.submit(_poseStack, _overlayEvent.getSubmitNodeCollector(), _light, OverlayTexture.NO_OVERLAY, 0);
					_poseStack.popPose();
				}
			}
		}
		_poseStack.popPose();
		_poseStack.popPose();
	}
}

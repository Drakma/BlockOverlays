<#include "mcitems.ftl">
if (event instanceof RenderLevelStageEvent) {
	float _growth = Math.max(0.0f, Math.min(1.0f, (float) ((Number) ${(input$percentage!input$growth!"0.5")}).doubleValue()));
	double _offsetY = ((Number) ${(input$offset_y!"0")}).doubleValue() / 16.0;
	float _baseScale = (float) ((Number) ${(input$scale!"1.0")}).doubleValue();
	ItemStack _cropStack = ${mappedMCItemToItemStackCode(input$crop, 1)};
	Item _cropItem = _cropStack.getItem();
	BlockState _cropState = null;

	if (_cropItem == net.minecraft.world.item.Items.WHEAT_SEEDS || _cropItem == net.minecraft.world.item.Items.WHEAT) {
		_cropState = net.minecraft.world.level.block.Blocks.WHEAT.defaultBlockState();
	} else if (_cropItem == net.minecraft.world.item.Items.CARROT) {
		_cropState = net.minecraft.world.level.block.Blocks.CARROTS.defaultBlockState();
	} else if (_cropItem == net.minecraft.world.item.Items.POTATO) {
		_cropState = net.minecraft.world.level.block.Blocks.POTATOES.defaultBlockState();
	} else if (_cropItem == net.minecraft.world.item.Items.BEETROOT_SEEDS || _cropItem == net.minecraft.world.item.Items.BEETROOT) {
		_cropState = net.minecraft.world.level.block.Blocks.BEETROOTS.defaultBlockState();
	} else if (_cropItem == net.minecraft.world.item.Items.PUMPKIN_SEEDS || _cropItem == net.minecraft.world.item.Items.PUMPKIN || _cropItem == net.minecraft.world.item.Items.CARVED_PUMPKIN) {
		_cropState = net.minecraft.world.level.block.Blocks.PUMPKIN.defaultBlockState();
	} else if (_cropItem == net.minecraft.world.item.Items.MELON_SEEDS || _cropItem == net.minecraft.world.item.Items.MELON || _cropItem == net.minecraft.world.item.Items.MELON_SLICE) {
		_cropState = net.minecraft.world.level.block.Blocks.MELON.defaultBlockState();
	} else if (_cropItem == net.minecraft.world.item.Items.NETHER_WART) {
		_cropState = net.minecraft.world.level.block.Blocks.NETHER_WART.defaultBlockState();
	} else if (_cropItem == net.minecraft.world.item.Items.COCOA_BEANS) {
		_cropState = net.minecraft.world.level.block.Blocks.COCOA.defaultBlockState().setValue(net.minecraft.world.level.block.CocoaBlock.AGE, 2);
	} else if (_cropItem == net.minecraft.world.item.Items.SWEET_BERRIES) {
		_cropState = net.minecraft.world.level.block.Blocks.SWEET_BERRY_BUSH.defaultBlockState();
	} else if (_cropItem == net.minecraft.world.item.Items.GLOW_BERRIES) {
		_cropState = net.minecraft.world.level.block.Blocks.CAVE_VINES.defaultBlockState();
	} else if (_cropItem == net.minecraft.world.item.Items.TORCHFLOWER_SEEDS) {
		_cropState = net.minecraft.world.level.block.Blocks.TORCHFLOWER_CROP.defaultBlockState();
	} else if (_cropItem == net.minecraft.world.item.Items.PITCHER_POD) {
		_cropState = net.minecraft.world.level.block.Blocks.PITCHER_CROP.defaultBlockState();
	} else if (_cropItem instanceof net.minecraft.world.item.BlockItem _bi) {
		_cropState = _bi.getBlock().defaultBlockState();
	} else {
		var _itemLoc = BuiltInRegistries.ITEM.getKey(_cropItem);
		if (_itemLoc != null) {
			String _path = _itemLoc.getPath();
			String _basePath = _path.endsWith("_seeds") ? _path.substring(0, _path.length() - 6) : _path.endsWith("_seed") ? _path.substring(0, _path.length() - 5) : _path;
			var _block = BuiltInRegistries.BLOCK.get(new net.minecraft.resources.ResourceLocation(_itemLoc.getNamespace(), _basePath));
			if (_block == null || _block == net.minecraft.world.level.block.Blocks.AIR) {
				_block = BuiltInRegistries.BLOCK.get(new net.minecraft.resources.ResourceLocation(_itemLoc.getNamespace(), _basePath + "_crop"));
			}
			if (_block == null || _block == net.minecraft.world.level.block.Blocks.AIR) {
				_block = BuiltInRegistries.BLOCK.get(new net.minecraft.resources.ResourceLocation(_itemLoc.getNamespace(), _basePath + "_plant"));
			}
			if (_block != null && _block != net.minecraft.world.level.block.Blocks.AIR) {
				_cropState = _block.defaultBlockState();
			}
		}
	}

	if (_cropState == null || _cropState.isAir()) {
		_cropState = world.getBlockState(BlockPos.containing(x, y, z));
		if (_cropState.isAir()) _cropState = world.getBlockState(BlockPos.containing(x, y + 1, z));
		if (_cropState.isAir()) _cropState = net.minecraft.world.level.block.Blocks.WHEAT.defaultBlockState();
	}

	if (_cropState.is(net.minecraft.world.level.block.Blocks.COCOA)) {
		_cropState = _cropState.setValue(net.minecraft.world.level.block.CocoaBlock.AGE, 2);
	}

	float _scaleX = _baseScale;
	float _scaleY = _baseScale;
	float _scaleZ = _baseScale;
	BlockState _secondState = null;
	double _secondOffsetY = 0.0;
	float _secondScaleY = _baseScale;

	// Special Case: Double-tall plants (Rose Bush, Sunflower, Peony, Pitcher Crop, etc.)
	if (_cropState.hasProperty(net.minecraft.world.level.block.state.properties.BlockStateProperties.DOUBLE_BLOCK_HALF)) {
		float _growthScale = Math.max(0.001f, _growth);
		_scaleX = _baseScale * _growthScale;
		_scaleY = _baseScale * _growthScale;
		_scaleZ = _baseScale * _growthScale;
		_cropState = _cropState.setValue(net.minecraft.world.level.block.state.properties.BlockStateProperties.DOUBLE_BLOCK_HALF, net.minecraft.world.level.block.state.properties.DoubleBlockHalf.LOWER);
		_secondState = _cropState.setValue(net.minecraft.world.level.block.state.properties.BlockStateProperties.DOUBLE_BLOCK_HALF, net.minecraft.world.level.block.state.properties.DoubleBlockHalf.UPPER);
		_secondOffsetY = (double) _scaleY;
		_secondScaleY = _scaleY;
	}

	boolean _isVisualMultiStage = false;
	net.minecraft.world.level.block.state.properties.IntegerProperty _ageProp = null;

	// Only true multi-stage visual crops extrapolate discrete growth stages from percentage
	if (_cropState.getBlock() instanceof net.minecraft.world.level.block.CropBlock
		|| _cropState.getBlock() instanceof net.minecraft.world.level.block.NetherWartBlock
		|| _cropState.getBlock() instanceof net.minecraft.world.level.block.SweetBerryBushBlock
		|| _cropState.is(net.minecraft.world.level.block.Blocks.TORCHFLOWER_CROP)
		|| _cropState.is(net.minecraft.world.level.block.Blocks.PITCHER_CROP)
		|| _cropState.is(net.minecraft.world.level.block.Blocks.PUMPKIN_STEM)
		|| _cropState.is(net.minecraft.world.level.block.Blocks.MELON_STEM)) {

		for (net.minecraft.world.level.block.state.properties.Property<?> _p : _cropState.getProperties()) {
			if (_p instanceof net.minecraft.world.level.block.state.properties.IntegerProperty _ip && (_ip.getName().equals("age") || _ip.getName().equals("stage") || _ip.getName().equals("growth"))) {
				_ageProp = _ip;
				_isVisualMultiStage = true;
				break;
			}
		}
	}

	if (_isVisualMultiStage && _ageProp != null) {
		int _minAge = _ageProp.getPossibleValues().stream().mapToInt(Integer::intValue).min().orElse(0);
		int _maxAge = _ageProp.getPossibleValues().stream().mapToInt(Integer::intValue).max().orElse(7);
		int _totalStages = _maxAge - _minAge + 1;
		int _calculatedStage = (int) Math.floor(_growth * _totalStages);
		if (_calculatedStage >= _totalStages) _calculatedStage = _totalStages - 1;
		int _targetAge = _minAge + _calculatedStage;
		_cropState = _cropState.setValue(_ageProp, _targetAge);
	} else if (!_cropState.hasProperty(net.minecraft.world.level.block.state.properties.BlockStateProperties.DOUBLE_BLOCK_HALF)) {
		// Single-stage crops (Cactus, Sugar Cane, Bamboo, Kelp, Gourds like Pumpkin/Melon, Flowers, Saplings, etc.):
		// Percentage complete directly scales the block from 0 to 1 of maximum size (scale)
		float _growthScale = Math.max(0.001f, _growth);
		_scaleX *= _growthScale;
		_scaleY *= _growthScale;
		_scaleZ *= _growthScale;
	}

	// Shape bounds calculation
	double _shapeTop = 0.0;
	if (${(input$bounds!"false")}) {
		var _shape = world.getBlockState(BlockPos.containing(x, y, z)).getShape(world, BlockPos.containing(x, y, z));
		if (!_shape.isEmpty()) {
			_shapeTop = _shape.bounds().maxY;
		}
	}

	PoseStack _poseStack = event.getPoseStack();
	Vec3 _camera = event.getCamera().getPosition();
	int _light = net.minecraft.client.renderer.LightTexture.pack(
		Minecraft.getInstance().level.getBrightness(net.minecraft.world.level.LightLayer.SKY, BlockPos.containing(x, y + 1, z)),
		Minecraft.getInstance().level.getBrightness(net.minecraft.world.level.LightLayer.BLOCK, BlockPos.containing(x, y + 1, z))
	);
	var _bufferSource = Minecraft.getInstance().renderBuffers().bufferSource();

	_poseStack.pushPose();
	_poseStack.translate(x - _camera.x + 0.5, y - _camera.y + _offsetY + _shapeTop, z - _camera.z + 0.5);
	_poseStack.scale(_scaleX, _scaleY, _scaleZ);
	_poseStack.translate(-0.5, 0.0, -0.5);
	Minecraft.getInstance().getBlockRenderer().renderSingleBlock(_cropState, _poseStack, _bufferSource, _light, OverlayTexture.NO_OVERLAY);
	_bufferSource.endBatch();
	_poseStack.popPose();

	if (_secondState != null) {
		_poseStack.pushPose();
		_poseStack.translate(x - _camera.x + 0.5, y - _camera.y + _offsetY + _shapeTop + _secondOffsetY, z - _camera.z + 0.5);
		_poseStack.scale(_scaleX, _secondScaleY, _scaleZ);
		_poseStack.translate(-0.5, 0.0, -0.5);
		Minecraft.getInstance().getBlockRenderer().renderSingleBlock(_secondState, _poseStack, _bufferSource, _light, OverlayTexture.NO_OVERLAY);
		_bufferSource.endBatch();
		_poseStack.popPose();
	}
}

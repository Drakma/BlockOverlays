<#include "mcitems.ftl">
<@addTemplate file="block_overlay_growth_cache.java.ftl"/>
if (event instanceof RenderLevelStageEvent) {
	float _growth = Math.max(0.0f, Math.min(1.0f, (float) ((Number) ${(input$percentage!"0.5")}).doubleValue()));
	double _offsetY = ((Number) ${(input$offset_y!"0")}).doubleValue() / 16.0;
	float _baseScale = (float) ((Number) ${(input$scale!"1.0")}).doubleValue();
	ItemStack _treeStack = ${mappedMCItemToItemStackCode(input$tree, 1)};
	Item _treeItem = _treeStack.getItem();
	BlockState _treeState = blockOverlayGetCachedTreeResolution(_treeItem, () -> {
		BlockState _resolved = null;
		if (_treeItem == net.minecraft.world.item.Items.OAK_SAPLING) {
			_resolved = net.minecraft.world.level.block.Blocks.OAK_SAPLING.defaultBlockState();
		} else if (_treeItem == net.minecraft.world.item.Items.SPRUCE_SAPLING) {
			_resolved = net.minecraft.world.level.block.Blocks.SPRUCE_SAPLING.defaultBlockState();
		} else if (_treeItem == net.minecraft.world.item.Items.BIRCH_SAPLING) {
			_resolved = net.minecraft.world.level.block.Blocks.BIRCH_SAPLING.defaultBlockState();
		} else if (_treeItem == net.minecraft.world.item.Items.JUNGLE_SAPLING) {
			_resolved = net.minecraft.world.level.block.Blocks.JUNGLE_SAPLING.defaultBlockState();
		} else if (_treeItem == net.minecraft.world.item.Items.ACACIA_SAPLING) {
			_resolved = net.minecraft.world.level.block.Blocks.ACACIA_SAPLING.defaultBlockState();
		} else if (_treeItem == net.minecraft.world.item.Items.DARK_OAK_SAPLING) {
			_resolved = net.minecraft.world.level.block.Blocks.DARK_OAK_SAPLING.defaultBlockState();
		} else if (_treeItem == net.minecraft.world.item.Items.MANGROVE_PROPAGULE) {
			_resolved = net.minecraft.world.level.block.Blocks.MANGROVE_PROPAGULE.defaultBlockState();
		} else if (_treeItem == net.minecraft.world.item.Items.CHERRY_SAPLING) {
			_resolved = net.minecraft.world.level.block.Blocks.CHERRY_SAPLING.defaultBlockState();
		} else if (_treeItem == net.minecraft.world.item.Items.BAMBOO) {
			_resolved = net.minecraft.world.level.block.Blocks.BAMBOO_SAPLING.defaultBlockState();
		} else if (_treeItem == net.minecraft.world.item.Items.CRIMSON_FUNGUS) {
			_resolved = net.minecraft.world.level.block.Blocks.CRIMSON_FUNGUS.defaultBlockState();
		} else if (_treeItem == net.minecraft.world.item.Items.WARPED_FUNGUS) {
			_resolved = net.minecraft.world.level.block.Blocks.WARPED_FUNGUS.defaultBlockState();
		} else if (_treeItem == net.minecraft.world.item.Items.AZALEA) {
			_resolved = net.minecraft.world.level.block.Blocks.AZALEA.defaultBlockState();
		} else if (_treeItem == net.minecraft.world.item.Items.FLOWERING_AZALEA) {
			_resolved = net.minecraft.world.level.block.Blocks.FLOWERING_AZALEA.defaultBlockState();
		} else if (_treeItem instanceof net.minecraft.world.item.BlockItem _bi) {
			_resolved = _bi.getBlock().defaultBlockState();
		} else {
			var _itemLoc = BuiltInRegistries.ITEM.getKey(_treeItem);
			if (_itemLoc != null) {
				String _path = _itemLoc.getPath();
				var _block = BuiltInRegistries.BLOCK.get(new net.minecraft.resources.ResourceLocation(_itemLoc.getNamespace(), _path));
				if (_block == null || _block == net.minecraft.world.level.block.Blocks.AIR) {
					_block = BuiltInRegistries.BLOCK.get(new net.minecraft.resources.ResourceLocation(_itemLoc.getNamespace(), _path + "_sapling"));
				}
				if (_block != null && _block != net.minecraft.world.level.block.Blocks.AIR) {
					_resolved = _block.defaultBlockState();
				}
			}
		}
		return _resolved;
	});

	if (_treeState == null || _treeState.isAir()) {
		_treeState = world.getBlockState(BlockPos.containing(x, y, z));
		if (_treeState.isAir()) _treeState = world.getBlockState(BlockPos.containing(x, y + 1, z));
		if (_treeState.isAir()) _treeState = net.minecraft.world.level.block.Blocks.OAK_SAPLING.defaultBlockState();
	}

	float _growthScale = Math.max(0.001f, _growth);
	float _scaleX = _baseScale * _growthScale;
	float _scaleY = _baseScale * _growthScale;
	float _scaleZ = _baseScale * _growthScale;

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
	Minecraft.getInstance().getBlockRenderer().renderSingleBlock(_treeState, _poseStack, _bufferSource, _light, OverlayTexture.NO_OVERLAY);
	_bufferSource.endBatch();
	_poseStack.popPose();
}

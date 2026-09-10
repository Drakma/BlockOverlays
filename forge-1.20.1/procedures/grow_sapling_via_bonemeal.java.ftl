((java.util.function.Supplier<Boolean>) () -> {
	ItemStack _treeStack = ${mappedMCItemToItemStackCode(input$tree, 1)};
	BlockPos _pos = net.minecraft.core.BlockPos.containing(
		((Number) (${input$pos_x!"0"})).doubleValue(),
		((Number) (${input$pos_y!"0"})).doubleValue(),
		((Number) (${input$pos_z!"0"})).doubleValue()
	);
	int _maxAttempts = (int) Math.round(((Number) (${input$max_attempts!"200"})).doubleValue());
	if (!(world instanceof net.minecraft.server.level.ServerLevel _serverLevel))
		return false;

	Item _treeItem = _treeStack.getItem();
	BlockState _treeState = null;
	if (_treeItem == net.minecraft.world.item.Items.OAK_SAPLING) {
		_treeState = net.minecraft.world.level.block.Blocks.OAK_SAPLING.defaultBlockState();
	} else if (_treeItem == net.minecraft.world.item.Items.SPRUCE_SAPLING) {
		_treeState = net.minecraft.world.level.block.Blocks.SPRUCE_SAPLING.defaultBlockState();
	} else if (_treeItem == net.minecraft.world.item.Items.BIRCH_SAPLING) {
		_treeState = net.minecraft.world.level.block.Blocks.BIRCH_SAPLING.defaultBlockState();
	} else if (_treeItem == net.minecraft.world.item.Items.JUNGLE_SAPLING) {
		_treeState = net.minecraft.world.level.block.Blocks.JUNGLE_SAPLING.defaultBlockState();
	} else if (_treeItem == net.minecraft.world.item.Items.ACACIA_SAPLING) {
		_treeState = net.minecraft.world.level.block.Blocks.ACACIA_SAPLING.defaultBlockState();
	} else if (_treeItem == net.minecraft.world.item.Items.DARK_OAK_SAPLING) {
		_treeState = net.minecraft.world.level.block.Blocks.DARK_OAK_SAPLING.defaultBlockState();
	} else if (_treeItem == net.minecraft.world.item.Items.BAMBOO) {
		_treeState = net.minecraft.world.level.block.Blocks.BAMBOO_SAPLING.defaultBlockState();
	} else if (_treeItem == net.minecraft.world.item.Items.CRIMSON_FUNGUS) {
		_treeState = net.minecraft.world.level.block.Blocks.CRIMSON_FUNGUS.defaultBlockState();
	} else if (_treeItem == net.minecraft.world.item.Items.WARPED_FUNGUS) {
		_treeState = net.minecraft.world.level.block.Blocks.WARPED_FUNGUS.defaultBlockState();
	} else if (_treeItem == net.minecraft.world.item.Items.AZALEA) {
		_treeState = net.minecraft.world.level.block.Blocks.AZALEA.defaultBlockState();
	} else if (_treeItem == net.minecraft.world.item.Items.FLOWERING_AZALEA) {
		_treeState = net.minecraft.world.level.block.Blocks.FLOWERING_AZALEA.defaultBlockState();
	} else if (_treeItem instanceof net.minecraft.world.item.BlockItem _bi) {
		_treeState = _bi.getBlock().defaultBlockState();
	} else {
		var _itemLoc = BuiltInRegistries.ITEM.getKey(_treeItem);
		if (_itemLoc != null) {
			String _path = _itemLoc.getPath();
			var _block = BuiltInRegistries.BLOCK.get(new net.minecraft.resources.ResourceLocation(_itemLoc.getNamespace(), _path));
			if (_block == null || _block == net.minecraft.world.level.block.Blocks.AIR) {
				_block = BuiltInRegistries.BLOCK.get(new net.minecraft.resources.ResourceLocation(_itemLoc.getNamespace(), _path + "_sapling"));
			}
			if (_block != null && _block != net.minecraft.world.level.block.Blocks.AIR) {
				_treeState = _block.defaultBlockState();
			}
		}
	}
	if (_treeState == null || _treeState.isAir()) {
		_treeState = net.minecraft.world.level.block.Blocks.OAK_SAPLING.defaultBlockState();
	}

	boolean _needs2x2 = _treeItem == net.minecraft.world.item.Items.DARK_OAK_SAPLING;
	_serverLevel.setBlock(_pos, _treeState, 3);
	if (_needs2x2) {
		_serverLevel.setBlock(_pos.east(), _treeState, 3);
		_serverLevel.setBlock(_pos.south(), _treeState, 3);
		_serverLevel.setBlock(_pos.east().south(), _treeState, 3);
	}
	for (int _attempt = 0; _attempt < _maxAttempts; _attempt++) {
		BlockState _current = _serverLevel.getBlockState(_pos);
		if (_current.getBlock() != _treeState.getBlock())
			return true;
		if (_current.getBlock() instanceof net.minecraft.world.level.block.BonemealableBlock _bonemealable) {
			if (_bonemealable.isValidBonemealTarget(_serverLevel, _pos, _current)
					&& _bonemealable.isBonemealSuccess(_serverLevel, _serverLevel.getRandom(), _pos, _current)) {
				_bonemealable.performBonemeal(_serverLevel, _serverLevel.getRandom(), _pos, _current);
			}
		} else {
			return false;
		}
	}
	return _serverLevel.getBlockState(_pos).getBlock() != _treeState.getBlock();
}).get()
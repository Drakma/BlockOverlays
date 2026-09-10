{
	BlockPos _center = net.minecraft.core.BlockPos.containing(
		((Number) (${input$pos_x!"0"})).doubleValue(),
		((Number) (${input$pos_y!"0"})).doubleValue(),
		((Number) (${input$pos_z!"0"})).doubleValue()
	);
	int _radius = (int) Math.round(((Number) (${input$radius!"4"})).doubleValue());
	int _maxHeight = (int) Math.round(((Number) (${input$height!"10"})).doubleValue());
	int _maxAttempts = (int) Math.round(((Number) (${input$max_attempts!"200"})).doubleValue());

	if (world instanceof net.minecraft.server.level.ServerLevel _serverLevel) {
		Runnable _clear = () -> {
			BlockPos _origin = _center.offset(-_radius, 0, -_radius);
			BlockPos.MutableBlockPos _mutable = new BlockPos.MutableBlockPos();
			for (int _dx = 0; _dx <= _radius * 2; _dx++) {
				for (int _dy = 0; _dy <= _maxHeight; _dy++) {
					for (int _dz = 0; _dz <= _radius * 2; _dz++) {
						_mutable.setWithOffset(_origin, _dx, _dy, _dz);
						_serverLevel.setBlock(_mutable, net.minecraft.world.level.block.Blocks.AIR.defaultBlockState(), 3);
					}
				}
			}
		};

		java.util.function.Function<ItemStack, Boolean> _grow = _treeStack -> {
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
			}
			if (_treeState == null || _treeState.isAir()) {
				_treeState = net.minecraft.world.level.block.Blocks.OAK_SAPLING.defaultBlockState();
			}
			final BlockState _finalTreeState = _treeState;
			boolean _needs2x2 = _treeItem == net.minecraft.world.item.Items.DARK_OAK_SAPLING;
			_serverLevel.setBlock(_center, _finalTreeState, 3);
			if (_needs2x2) {
				_serverLevel.setBlock(_center.east(), _finalTreeState, 3);
				_serverLevel.setBlock(_center.south(), _finalTreeState, 3);
				_serverLevel.setBlock(_center.east().south(), _finalTreeState, 3);
			}
			for (int _attempt = 0; _attempt < _maxAttempts; _attempt++) {
				BlockState _current = _serverLevel.getBlockState(_center);
				if (_current.getBlock() != _finalTreeState.getBlock())
					return true;
				if (_current.getBlock() instanceof net.minecraft.world.level.block.BonemealableBlock _bonemealable) {
					if (_bonemealable.isValidBonemealTarget(_serverLevel, _center, _current)
							&& _bonemealable.isBonemealSuccess(_serverLevel, _serverLevel.getRandom(), _center, _current)) {
						_bonemealable.performBonemeal(_serverLevel, _serverLevel.getRandom(), _center, _current);
					}
				} else {
					return false;
				}
			}
			return _serverLevel.getBlockState(_center).getBlock() != _finalTreeState.getBlock();
		};

		java.util.function.Function<String, Boolean> _capture = _structureName -> {
			try {
				BlockPos _origin = _center.offset(-_radius, 0, -_radius);
				int _actualTop = 0;
				BlockPos.MutableBlockPos _scan = new BlockPos.MutableBlockPos();
				for (int _dx = 0; _dx <= _radius * 2; _dx++) {
					for (int _dz = 0; _dz <= _radius * 2; _dz++) {
						for (int _dy = _maxHeight; _dy > _actualTop; _dy--) {
							_scan.setWithOffset(_origin, _dx, _dy, _dz);
							if (!_serverLevel.getBlockState(_scan).isAir()) {
								_actualTop = _dy;
								break;
							}
						}
					}
				}
				net.minecraft.resources.ResourceLocation _id = new net.minecraft.resources.ResourceLocation("${modid}", _structureName);
				net.minecraft.core.Vec3i _size = new net.minecraft.core.Vec3i(_radius * 2 + 1, _actualTop + 1, _radius * 2 + 1);
				return net.minecraft.world.level.block.entity.StructureBlockEntity.saveStructure(_serverLevel, _id, _origin, _size, true, "BlockOverlays", true, java.util.List.of());
			} catch (Exception _exception) {
				return false;
			}
		};

		java.util.List<ItemStack> _saplings = new java.util.ArrayList<>();
		for (var _item : BuiltInRegistries.ITEM) {
			boolean _isTreeSapling = false;
			if (_item instanceof net.minecraft.world.item.BlockItem _blockItem
					&& _blockItem.getBlock() instanceof net.minecraft.world.level.block.SaplingBlock) {
				_isTreeSapling = true;
			} else if (_item == net.minecraft.world.item.Items.MANGROVE_PROPAGULE
					|| _item == net.minecraft.world.item.Items.AZALEA
					|| _item == net.minecraft.world.item.Items.FLOWERING_AZALEA
					|| _item == net.minecraft.world.item.Items.CRIMSON_FUNGUS
					|| _item == net.minecraft.world.item.Items.WARPED_FUNGUS) {
				_isTreeSapling = true;
			}
			if (_isTreeSapling) {
				_saplings.add(new ItemStack(_item));
			}
		}

		for (ItemStack _treeStack : _saplings) {
			_clear.run();
			if (_grow.apply(_treeStack)) {
				var _itemLoc = BuiltInRegistries.ITEM.getKey(_treeStack.getItem());
				String _saplingNamespace = _itemLoc != null ? _itemLoc.getNamespace() : "minecraft";
				String _saplingPath = _itemLoc != null ? _itemLoc.getPath() : "tree";
				String _structureName = _saplingNamespace + "/" + _saplingNamespace + "_" + _saplingPath;
				_capture.apply(_structureName);
			}
			_clear.run();
		}
	}
}
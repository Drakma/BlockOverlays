((java.util.function.Supplier<java.util.List<ItemStack>>) () -> {
	java.util.List<ItemStack> _result = new java.util.ArrayList<>();
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
			_result.add(new ItemStack(_item));
		}
	}
	return _result;
}).get()
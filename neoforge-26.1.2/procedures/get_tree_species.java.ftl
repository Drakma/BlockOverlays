(java.util.function.Function<net.minecraft.world.item.ItemStack, String>)(_saplingStack -> {
	String _species = "";
	net.minecraft.world.item.Item _item = _saplingStack.getItem();
	if (_item instanceof net.minecraft.world.item.BlockItem _bi) {
		net.minecraft.world.level.block.Block _block = _bi.getBlock();
		if (_block instanceof net.minecraft.world.level.block.SaplingBlock _sapling) {
			try {
				java.lang.reflect.Field _f = net.minecraft.world.level.block.SaplingBlock.class.getDeclaredField("treeGrower");
				_f.setAccessible(true);
				net.minecraft.world.level.block.grower.TreeGrower _g = (net.minecraft.world.level.block.grower.TreeGrower) _f.get(_sapling);
				if (_g == net.minecraft.world.level.block.grower.TreeGrower.OAK)      _species = "oak";
				else if (_g == net.minecraft.world.level.block.grower.TreeGrower.SPRUCE)   _species = "spruce";
				else if (_g == net.minecraft.world.level.block.grower.TreeGrower.BIRCH)    _species = "birch";
				else if (_g == net.minecraft.world.level.block.grower.TreeGrower.JUNGLE)   _species = "jungle";
				else if (_g == net.minecraft.world.level.block.grower.TreeGrower.ACACIA)   _species = "acacia";
				else if (_g == net.minecraft.world.level.block.grower.TreeGrower.CHERRY)   _species = "cherry";
				else if (_g == net.minecraft.world.level.block.grower.TreeGrower.DARK_OAK) _species = "dark_oak";
				else if (_g == net.minecraft.world.level.block.grower.TreeGrower.PALE_OAK) _species = "pale_oak";
				else if (_g == net.minecraft.world.level.block.grower.TreeGrower.MANGROVE) _species = "mangrove";
				else if (_g == net.minecraft.world.level.block.grower.TreeGrower.AZALEA)   _species = "azalea";
			} catch (java.lang.Throwable _t) {
				_species = "";
			}
		}
	}
	return _species;
}).apply(${mappedMCItemToItemStackCode(input$sapling, 1)})

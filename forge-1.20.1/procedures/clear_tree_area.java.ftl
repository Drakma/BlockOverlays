((java.util.function.Supplier<Boolean>) () -> {
	BlockPos _center = net.minecraft.core.BlockPos.containing(
		((Number) (${input$pos_x!"0"})).doubleValue(),
		((Number) (${input$pos_y!"0"})).doubleValue(),
		((Number) (${input$pos_z!"0"})).doubleValue()
	);
	int _radius = (int) Math.round(((Number) (${input$radius!"4"})).doubleValue());
	int _height = (int) Math.round(((Number) (${input$height!"10"})).doubleValue());
	if (!(world instanceof net.minecraft.server.level.ServerLevel _serverLevel))
		return false;
	BlockPos _origin = _center.offset(-_radius, 0, -_radius);
	BlockPos.MutableBlockPos _mutable = new BlockPos.MutableBlockPos();
	for (int _dx = 0; _dx <= _radius * 2; _dx++) {
		for (int _dy = 0; _dy <= _height; _dy++) {
			for (int _dz = 0; _dz <= _radius * 2; _dz++) {
				_mutable.setWithOffset(_origin, _dx, _dy, _dz);
				_serverLevel.setBlock(_mutable, net.minecraft.world.level.block.Blocks.AIR.defaultBlockState(), 3);
			}
		}
	}
	return true;
}).get()
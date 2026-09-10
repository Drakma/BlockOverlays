((java.util.function.Supplier<Boolean>) () -> {
	BlockPos _center = net.minecraft.core.BlockPos.containing(
		((Number) (${input$pos_x!"0"})).doubleValue(),
		((Number) (${input$pos_y!"0"})).doubleValue(),
		((Number) (${input$pos_z!"0"})).doubleValue()
	);
	int _radius = (int) Math.round(((Number) (${input$radius!"4"})).doubleValue());
	int _maxHeight = (int) Math.round(((Number) (${input$height!"10"})).doubleValue());
	String _structureName = ${(input$structure_name!"\"tree\"")};
	if (!(world instanceof net.minecraft.server.level.ServerLevel _serverLevel))
		return false;
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
}).get()
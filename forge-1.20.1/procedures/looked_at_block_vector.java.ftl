(entity.pick(${input$distance}, 1.0F, false) instanceof BlockHitResult _bhr ? Vec3.atCenterOf(_bhr.getBlockPos()) : new Vec3(0, 0, 0))

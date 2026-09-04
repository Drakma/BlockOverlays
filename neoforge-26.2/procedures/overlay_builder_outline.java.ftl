if (event instanceof SubmitCustomGeometryEvent _overlayEvent) {
	PoseStack _poseStack = _overlayEvent.getPoseStack();
	Vec3 _camera = _overlayEvent.getLevelRenderState().cameraRenderState.pos;
	net.minecraft.world.phys.shapes.VoxelShape _shape = ${(input$bounds!"false")} ? world.getBlockState(BlockPos.containing(x, y, z)).getShape(world, BlockPos.containing(x, y, z)) : Shapes.block();

	// --- Effect toggles ---
	boolean _pulseOn = ${(input$pulse!"false")};
	boolean _rainbowOn = ${(input$rainbow!"false")};
	boolean _glowOn = ${(input$glow!"false")};
	boolean _waveOn = ${(input$wave!"false")};
	boolean _marqueeOn = ${(input$marquee!"false")};

	// --- Effect knobs ---
	float _speed = (float) ${(input$speed!"1.0")};
	float _intensity = Math.max(0.0f, Math.min(1.0f, (float) ${(input$intensity!"0.5")}));
	int _glowLayers = (int) Math.max(0.0f, Math.min(4.0f, (float) ${(input$glow_layers!"0")}));
	float _wavePhase = (float) ${(input$wave_phase!"0.0")};
	float _marqueeSpeed = (float) ${(input$marquee_speed!"1.0")};
	int _width = Math.max(1, (int) ${input$width});
	String _glowFalloff = "${(field$glow_falloff!"linear")}";

	// --- Time ---
	float _tScaled = (float) (world.getGameTime() * (double) _speed);
	float _tMarquee = (float) (world.getGameTime() * (double) _marqueeSpeed);

	// --- Base color + alpha (packed ARGB int for VertexConsumer.setColor) ---
	int _baseColor = 0xFF${(field$color!"#ff0000")?substring(1)};
	int _baseR = (_baseColor >> 16) & 0xFF;
	int _baseG = (_baseColor >> 8) & 0xFF;
	int _baseB = _baseColor & 0xFF;
	float _baseAlpha = Math.max(0.0f, Math.min(1.0f, (float) ${(input$transparency!"1.0")}));

	// --- Glow color (separate, default white) ---
	int _glowColorRaw = 0xFF${(field$glow_color!"#ffffff")?substring(1)};
	int _glowR = (_glowColorRaw >> 16) & 0xFF;
	int _glowG = (_glowColorRaw >> 8) & 0xFF;
	int _glowB = _glowColorRaw & 0xFF;

	// --- Wave color (separate, default white) ---
	int _waveColorRaw = 0xFF${(field$wave_color!"#ffffff")?substring(1)};
	int _waveR = (_waveColorRaw >> 16) & 0xFF;
	int _waveG = (_waveColorRaw >> 8) & 0xFF;
	int _waveB = _waveColorRaw & 0xFF;

	// --- Pulse (applies to base + glow alphas) ---
	float _pulse = _pulseOn ? (1.0f + _intensity * 0.5f * (float) Math.sin(_tScaled * 2.0)) : 1.0f;

	// --- Rainbow (HSV cycling, blends into base color only; glow + wave use their own colors) ---
	float _hueRad = (float) Math.toRadians((_tScaled * 60.0f) % 360.0);
	float _hueR = (float) (0.5 + 0.5 * Math.cos(_hueRad));
	float _hueG = (float) (0.5 + 0.5 * Math.cos(_hueRad - 2.0943951023931953));
	float _hueB = (float) (0.5 + 0.5 * Math.cos(_hueRad - 4.1887902047863905));
	float _rainbowBlend = _rainbowOn ? _intensity : 0.0f;
	float _finalR = (_baseR / 255.0f) * (1.0f - _rainbowBlend) + _hueR * _rainbowBlend;
	float _finalG = (_baseG / 255.0f) * (1.0f - _rainbowBlend) + _hueG * _rainbowBlend;
	float _finalB = (_baseB / 255.0f) * (1.0f - _rainbowBlend) + _hueB * _rainbowBlend;

	// --- Wave ---
	int _wavePasses = _waveOn ? (int) Math.max(0.0f, Math.min(8.0f, _wavePhase / 0.7853982f)) : 0;

	// Step size for face extension: 1/16 of a block.
	float _step = 1.0f / 16.0f;
	float _phaseShift = (float) Math.toRadians(_tMarquee * 90.0f);

	// --- Push the pose stack into shape-local space ---
	_poseStack.pushPose();
	_poseStack.translate(x - _camera.x, y - _camera.y, z - _camera.z);
	var _renderType = ${input$through_walls} ? RenderTypes.linesTranslucent() : RenderTypes.lines();

	// Single submission wrapper; the lambda below accumulates glow + main + wave passes
	// via blockOverlayOutlineDrawEdgeBand, which emits parallel edges offset into the faces.
	_overlayEvent.getSubmitNodeCollector().submitCustomGeometry(_poseStack, _renderType, (pose, consumer) -> {
		// --- Glow passes (uses glow_color, not base color) ---
		for (int _g = _glowLayers; _g >= 1 && _glowOn; _g--) {
			float _gF = (float) _g / (float) Math.max(1, _glowLayers);
			float _gFalloffAlpha;
			if ("steep".equals(_glowFalloff)) {
				_gFalloffAlpha = (float) Math.pow(1.0 - _intensity * 0.7f, _gF * 3.0);
			} else if ("exponential".equals(_glowFalloff)) {
				_gFalloffAlpha = (float) Math.pow(1.0 - _intensity * 0.7f, _g);
			} else {
				_gFalloffAlpha = 1.0f - _intensity * 0.7f * _gF;
			}
			float _gAlpha = _baseAlpha * _pulse * _gFalloffAlpha;
			int _gRByte = Math.max(0, Math.min(255, _glowR));
			int _gGByte = Math.max(0, Math.min(255, _glowG));
			int _gBByte = Math.max(0, Math.min(255, _glowB));
			int _gAByte = Math.max(0, Math.min(255, (int) (_gAlpha * 255.0f)));
			int _gColor = (_gAByte << 24) | (_gRByte << 16) | (_gGByte << 8) | _gBByte;
			int _gWidth = _width + _g;
			float _gStep = _step;
			_shape.forAllEdges((x1, y1, z1, x2, y2, z2) ->
				blockOverlayOutlineDrawEdgeBand(consumer, pose, null, _gColor, _gWidth, _gStep,
					x1, y1, z1, x2, y2, z2));
		}

		// --- Main pass (uses base color with rainbow blend + pulse) ---
		int _mRByte = Math.max(0, Math.min(255, (int) (_finalR * 255.0f)));
		int _mGByte = Math.max(0, Math.min(255, (int) (_finalG * 255.0f)));
		int _mBByte = Math.max(0, Math.min(255, (int) (_finalB * 255.0f)));
		int _mAByte = Math.max(0, Math.min(255, (int) (_baseAlpha * _pulse * 255.0f)));
		int _mColor = (_mAByte << 24) | (_mRByte << 16) | (_mGByte << 8) | _mBByte;
		int _mWidth = _width;
		float _mStep = _step;
		_shape.forAllEdges((x1, y1, z1, x2, y2, z2) ->
			blockOverlayOutlineDrawEdgeBand(consumer, pose, null, _mColor, _mWidth, _mStep,
				x1, y1, z1, x2, y2, z2));

		// --- Wave passes (uses wave_color, marquee phase shift uses _tMarquee) ---
		for (int _w = 1; _w <= _wavePasses; _w++) {
			float _wF = (float) _w / (float) Math.max(1, _wavePasses);
			float _wBaseR = (_waveR / 255.0f) * (1.0f - _rainbowBlend) + _hueR * _rainbowBlend;
			float _wBaseG = (_waveG / 255.0f) * (1.0f - _rainbowBlend) + _hueG * _rainbowBlend;
			float _wBaseB = (_waveB / 255.0f) * (1.0f - _rainbowBlend) + _hueB * _rainbowBlend;
			float _wA = _baseAlpha * _intensity * (1.0f - _wF) * 0.5f;
			int _wRByte = Math.max(0, Math.min(255, (int) (_wBaseR * 255.0f)));
			int _wGByte = Math.max(0, Math.min(255, (int) (_wBaseG * 255.0f)));
			int _wBByte = Math.max(0, Math.min(255, (int) (_wBaseB * 255.0f)));
			int _wAByte = Math.max(0, Math.min(255, (int) (_wA * 255.0f)));
			int _wColor = (_wAByte << 24) | (_wRByte << 16) | (_wGByte << 8) | _wBByte;
			int _wWidth = Math.max(1, _width - (_w - 1));
			float _wStep = _step;
			float _wPhaseShift = _phaseShift;
			boolean _wMarquee = _marqueeOn;
			float _wIntensityPulse = _baseAlpha * _pulse;
			float _wFR = _finalR;
			float _wFG = _finalG;
			float _wFB = _finalB;
			_shape.forAllEdges((x1, y1, z1, x2, y2, z2) -> {
				int _useColor = _wColor;
				if (_wMarquee) {
					double _mx = (x1 + x2) * 0.5;
					double _mz = (z1 + z2) * 0.5;
					double _theta = Math.atan2(_mz, _mx);
					float _band = (float) Math.max(0.0, Math.cos(_theta - _wPhaseShift - _wF * 6.2831853));
					int _mR = Math.max(0, Math.min(255, (int) ((_wBaseR * _band + _wFR * (1.0f - _band)) * 255.0f)));
					int _mG = Math.max(0, Math.min(255, (int) ((_wBaseG * _band + _wFG * (1.0f - _band)) * 255.0f)));
					int _mB = Math.max(0, Math.min(255, (int) ((_wBaseB * _band + _wFB * (1.0f - _band)) * 255.0f)));
					int _mA = Math.max(0, Math.min(255, (int) ((_wA * _band + _wIntensityPulse * (1.0f - _band)) * 255.0f)));
					_useColor = (_mA << 24) | (_mR << 16) | (_mG << 8) | _mB;
				}
				blockOverlayOutlineDrawEdgeBand(consumer, pose, null, _useColor, _wWidth, _wStep,
					x1, y1, z1, x2, y2, z2);
			});
		}
	});

	_poseStack.popPose();
}
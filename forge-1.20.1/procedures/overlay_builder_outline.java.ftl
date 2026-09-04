{
	PoseStack _poseStack = event.getPoseStack();
	Vec3 _camera = event.getCamera().getPosition();

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

	// --- Base color + alpha ---
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

	// --- Pulse ---
	float _pulse = _pulseOn ? (1.0f + _intensity * 0.5f * (float) Math.sin(_tScaled * 2.0)) : 1.0f;

	// --- Rainbow ---
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

	_poseStack.pushPose();
	_poseStack.translate(x - _camera.x, y - _camera.y, z - _camera.z);
	var _bufferSource = Minecraft.getInstance().renderBuffers().bufferSource();
	var _consumer = _bufferSource.getBuffer(RenderType.lines());
	var _shape = ${(input$bounds!"false")} ? world.getBlockState(BlockPos.containing(x, y, z)).getShape(world, BlockPos.containing(x, y, z)) : net.minecraft.world.phys.shapes.Shapes.block();
	var _pose = _poseStack.last().pose();
	var _normal = _poseStack.last().normal();

	// Step size for face extension: 1/16 of a block, matching one face-texture pixel.
	float _step = 1.0f / 16.0f;
	float _phaseShift = (float) Math.toRadians(_tMarquee * 90.0f);

	// --- Glow passes (uses glow_color, only when glow toggle is on) ---
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
		int _gWidth = _width + _g;
		var _poseG = _pose;
		var _normalG = _normal;
		var _consumerG = _consumer;
		float _gR = _glowR / 255.0f;
		float _gG = _glowG / 255.0f;
		float _gB = _glowB / 255.0f;
		float _gA = _gAlpha;
		float _gStep = _step;
		_shape.forAllEdges((x1, y1, z1, x2, y2, z2) ->
			blockOverlayOutlineDrawEdgeBand(_consumerG, _poseG, _normalG, _gR, _gG, _gB, _gA, _gWidth, _gStep,
				x1, y1, z1, x2, y2, z2));
	}

	// --- Main pass (uses base color, pulse applied to alpha) ---
	{
		var _poseM = _pose;
		var _normalM = _normal;
		var _consumerM = _consumer;
		float _mR = _finalR;
		float _mG = _finalG;
		float _mB = _finalB;
		float _mA = _baseAlpha * _pulse;
		int _mWidth = _width;
		float _mStep = _step;
		_shape.forAllEdges((x1, y1, z1, x2, y2, z2) ->
			blockOverlayOutlineDrawEdgeBand(_consumerM, _poseM, _normalM, _mR, _mG, _mB, _mA, _mWidth, _mStep,
				x1, y1, z1, x2, y2, z2));
	}

	// --- Wave passes (uses wave_color; marquee phase uses _tMarquee) ---
	for (int _w = 1; _w <= _wavePasses; _w++) {
		float _wF = (float) _w / (float) Math.max(1, _wavePasses);
		float _wBaseR = (_waveR / 255.0f) * (1.0f - _rainbowBlend) + _hueR * _rainbowBlend;
		float _wBaseG = (_waveG / 255.0f) * (1.0f - _rainbowBlend) + _hueG * _rainbowBlend;
		float _wBaseB = (_waveB / 255.0f) * (1.0f - _rainbowBlend) + _hueB * _rainbowBlend;
		float _wA = _baseAlpha * _intensity * (1.0f - _wF) * 0.5f;
		int _wWidth = Math.max(1, _width - (_w - 1));
		var _poseW = _pose;
		var _normalW = _normal;
		var _consumerW = _consumer;
		float _wRf = _wBaseR;
		float _wGf = _wBaseG;
		float _wBf = _wBaseB;
		float _wAf = _wA;
		int _wW = _wWidth;
		float _wStep = _step;
		_shape.forAllEdges((x1, y1, z1, x2, y2, z2) -> {
			if (_marqueeOn) {
				double _mx = (x1 + x2) * 0.5;
				double _mz = (z1 + z2) * 0.5;
				double _theta = Math.atan2(_mz, _mx);
				float _band = (float) Math.max(0.0, Math.cos(_theta - _phaseShift - _wF * 6.2831853));
				float _mr = _wRf * _band + _finalR * (1.0f - _band);
				float _mg = _wGf * _band + _finalG * (1.0f - _band);
				float _mb = _wBf * _band + _finalB * (1.0f - _band);
				float _ma = _wAf * _band + _baseAlpha * _pulse * (1.0f - _band);
				blockOverlayOutlineDrawEdgeBand(_consumerW, _poseW, _normalW, _mr, _mg, _mb, _ma, _wW, _wStep,
					x1, y1, z1, x2, y2, z2);
			} else {
				blockOverlayOutlineDrawEdgeBand(_consumerW, _poseW, _normalW, _wRf, _wGf, _wBf, _wAf, _wW, _wStep,
					x1, y1, z1, x2, y2, z2);
			}
		});
	}

	_bufferSource.endBatch(RenderType.lines());
	_poseStack.popPose();
}
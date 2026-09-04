class FieldTextureSelector extends Blockly.FieldImage {
	EDITABLE = true;
	SERIALIZABLE = true;
	CURSOR = 'default';

	constructor(opt_validator, textureType) {
		super('', 36, 36, '');
		if (opt_validator) this.setValidator(opt_validator);
		this.fixedTextureType = textureType || null;
		this.setTooltip(
			() => this.getValue() || 'Double-click to select a texture'
		);
	}

	static fromJson(options) {
		const textureType = options
			? options.texture_type || options.textureType || null
			: null;
		return new this(undefined, textureType);
	}

	getEffectiveTextureType() {
		if (this.fixedTextureType) return this.fixedTextureType;
		if (this.sourceBlock_) {
			const fieldVal = this.sourceBlock_.getFieldValue('texture_type');
			if (fieldVal) return fieldVal;
		}
		return 'SCREEN';
	}

	static PLACEHOLDER =
		"data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='36' height='36' viewBox='0 0 36 36'><rect width='36' height='36' rx='4' fill='%232b2b2b' stroke='%23555555' stroke-width='2'/><path d='M8 26l6-8 4 5 5-7 5 10H8z' fill='%23888888'/><circle cx='13' cy='12' r='2.5' fill='%23888888'/></svg>";

	initView() {
		this.imageElement = Blockly.utils.dom.createSvgElement(
			'image',
			{
				height: this.size_.height + 'px',
				width: this.size_.width + 'px',
				style: 'cursor: pointer; image-rendering: pixelated;'
			},
			this.fieldGroup_
		);
		this.sourceBlock_.getSvgRoot().appendChild(this.fieldGroup_);
		this.lastClickTime = -1;
		this.refreshPreview();
	}

	onMouseDown_(event) {
		if (this.sourceBlock_ && !this.sourceBlock_.isInFlyout) {
			if (
				this.lastClickTime !== -1 &&
				new Date().getTime() - this.lastClickTime < 500
			) {
				event.stopPropagation();
				const thisField = this;
				const textureType = this.getEffectiveTextureType();
				texturebridge.openTextureSelector(textureType, {
					callback: function (selected) {
						if (!selected) return;
						const group = Blockly.Events.getGroup();
						Blockly.Events.setGroup(true);
						thisField.setValue(selected);
						Blockly.Events.setGroup(group);
						thisField.refreshPreview();
						javabridge.triggerEvent();
					}
				});
				this.lastClickTime = -1;
			} else {
				this.lastClickTime = new Date().getTime();
			}
		}
	}

	doValueUpdate_(newValue) {
		this.value_ = newValue || '';
		this.refreshPreview();
	}

	refreshPreview() {
		if (!this.imageElement || !this.sourceBlock_) return;
		const textureType = this.getEffectiveTextureType();
		let uri = '';
		if (this.value_) {
			try {
				uri = texturebridge.getTextureURI(textureType, this.value_);
			} catch (e) {}
		}
		if (!uri) {
			uri = FieldTextureSelector.PLACEHOLDER;
		}
		this.imageElement.setAttributeNS(
			'http://www.w3.org/1999/xlink',
			'xlink:href',
			uri
		);
	}
}

Blockly.fieldRegistry.register('field_texture_selector', FieldTextureSelector);

Blockly.Extensions.register(
	'block_overlays_texture_type_onchange',
	function () {
		this.setOnChange(function (event) {
			if (
				event.type === Blockly.Events.BLOCK_CHANGE &&
				event.name === 'texture_type'
			) {
				const textureField = this.getField('texture');
				if (textureField) {
					textureField.setValue('');
					textureField.refreshPreview();
				}
			}
		});
	}
);

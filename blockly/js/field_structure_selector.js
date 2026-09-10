class FieldStructureSelector extends Blockly.FieldTextInput {
	EDITABLE = true;
	SERIALIZABLE = true;
	CURSOR = 'default';

	constructor(opt_validator) {
		super('', opt_validator);
		this.setTooltip(
			() => this.getValue() || 'Double-click to select a structure'
		);
	}

	static fromJson(options) {
		return new this(undefined);
	}

	doClassValidation_(newValue) {
		return newValue;
	}

	showEditor_() {
		// Structures are picked via a double-click dialog, not typed directly.
	}

	onMouseDown_(event) {
		if (this.sourceBlock_ && !this.sourceBlock_.isInFlyout) {
			if (
				this.lastClickTime !== undefined &&
				this.lastClickTime !== -1 &&
				new Date().getTime() - this.lastClickTime < 500
			) {
				event.stopPropagation();
				const thisField = this;
				structurebridge.openStructureSelector({
					callback: function (selected) {
						if (!selected) return;
						const group = Blockly.Events.getGroup();
						Blockly.Events.setGroup(true);
						thisField.setValue(selected);
						Blockly.Events.setGroup(group);
						javabridge.triggerEvent();
					}
				});
				this.lastClickTime = -1;
			} else {
				this.lastClickTime = new Date().getTime();
			}
		}
	}
}

Blockly.fieldRegistry.register('field_structure_selector', FieldStructureSelector);

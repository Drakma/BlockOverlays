package net.drakma.blockoverlays.elements;

import net.mcreator.ui.MCreator;
import net.mcreator.ui.blockly.BlocklyEditorType;
import net.mcreator.ui.blockly.BlocklyEditorToolbar;
import net.mcreator.ui.blockly.BlocklyPanel;
import net.mcreator.ui.modgui.ModElementGUI;
import net.mcreator.workspace.elements.ModElement;
import net.mcreator.blockly.InternalBlocksLoader;
import net.mcreator.blockly.data.BlocklyLoader;
import net.mcreator.blockly.data.DynamicBlockLoader;
import net.mcreator.blockly.data.ToolboxType;
import net.mcreator.element.types.Procedure;
import net.mcreator.element.util.AnnotationUtils;
import net.mcreator.element.parts.MItemBlock;
import net.mcreator.minecraft.DataListLoader;
import net.mcreator.minecraft.MCItem;
import net.mcreator.ui.minecraft.MCItemListField;
import net.mcreator.ui.modgui.ModElementGUIPage;
import net.mcreator.ui.validation.AggregatedValidationResult;
import net.mcreator.ui.validation.ValidationResult;

import javax.swing.BorderFactory;
import javax.swing.JCheckBox;
import javax.swing.JComboBox;
import javax.swing.JLabel;
import javax.swing.JList;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JSpinner;
import javax.swing.JTextField;
import javax.swing.SpinnerNumberModel;
import java.awt.Component;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Insets;
import java.awt.BorderLayout;
import java.awt.FlowLayout;
import java.awt.Dimension;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.List;

public class BlockOverlayElementGUI extends ModElementGUI<BlockOverlayElement> {
  private final MCreator mcreator;
  private final BlocklyPanel overlayBlockly;
  private final BlocklyEditorToolbar overlayBlocklyToolbar;
  private final MCItemListField targetBlocks;
  private final JComboBox<String> visibilityScope = new JComboBox<>(
      new String[] { "Always while visible", "Looking at target block" });
  private final JTextField blockStateProperty = new JTextField(18);
  private final JTextField blockStateValue = new JTextField(18);
  private final JCheckBox requiresCrouching = new JCheckBox("Player must be crouching");
  private final JTextField heldItemOrTag = new JTextField(26);
  private final JTextField heldItemNbt = new JTextField(26);
  private final JTextField blockEntityNbt = new JTextField(26);
  private final JSpinner maximumDistance = new JSpinner(new SpinnerNumberModel(16.0, 1.0, 128.0, 1.0));
  private final JComboBox<String> conditionProcedure = new JComboBox<>();
  private final JComboBox<String> layerType = new JComboBox<>(
      new String[] { "TEXT", "NUMBER", "ITEM", "TEXTURE", "OUTLINE" });
  private final JTextField layerValue = new JTextField("Label", 26);
  private final JComboBox<String> face = new JComboBox<>(
      new String[] { "NORTH", "SOUTH", "WEST", "EAST", "UP", "DOWN" });
  private final JComboBox<String> placement = new JComboBox<>(new String[] { "TOP_LEFT", "TOP_CENTER", "TOP_RIGHT",
      "MIDDLE_LEFT", "MIDDLE_CENTER", "MIDDLE_RIGHT", "BOTTOM_LEFT", "BOTTOM_CENTER", "BOTTOM_RIGHT" });
  private final JTextField color = new JTextField("#ffffff", 10);
  private final JSpinner scale = new JSpinner(new SpinnerNumberModel(1.0, 0.01, 10.0, 0.01));
  private final JSpinner lineWidth = new JSpinner(new SpinnerNumberModel(1.0, 0.1, 10.0, 0.1));
  private final JCheckBox throughWalls = new JCheckBox("Render outline through walls");

  public BlockOverlayElementGUI(MCreator mcreator, ModElement modElement, boolean editingMode) {
    super(mcreator, modElement, editingMode);
    this.mcreator = mcreator;
    targetBlocks = new MCItemListField(mcreator, workspace -> {
      List<MCItem> blocks = new ArrayList<>();
      DataListLoader.loadDataList("blocks").forEach(entry -> blocks.add(new MCItem(entry)));
      workspace.getModElements().forEach(element -> blocks.addAll(element.getMCItems()));
      return blocks;
    }) {
      {
        elementsList.setLayoutOrientation(JList.HORIZONTAL_WRAP);
        elementsList.setVisibleRowCount(1);
      }

      @Override
      public void setListElements(List<MItemBlock> elements) {
        super.setListElements(elements);
        updateTargetBlocksDynamicSize();
      }
    };
    targetBlocks.addChangeListener(e -> updateTargetBlocksDynamicSize());
    targetBlocks.setValidator(() -> {
      List<MItemBlock> elements = targetBlocks.getListElements();
      if (elements == null || elements.isEmpty()) {
        return new ValidationResult(ValidationResult.Type.ERROR, "At least one target block must be selected.");
      }
      boolean hasValidBlock = false;
      for (MItemBlock mb : elements) {
        if (mb != null && mb.getUnmappedValue() != null && !mb.getUnmappedValue().trim().isEmpty()) {
          hasValidBlock = true;
          break;
        }
      }
      if (!hasValidBlock) {
        return new ValidationResult(ValidationResult.Type.ERROR, "At least one target block must be selected.");
      }
      return ValidationResult.PASSED;
    });
    overlayBlockly = new BlocklyPanel(mcreator, BlocklyEditorType.PROCEDURE);
    overlayBlockly.addTaskToRunAfterLoaded(() -> {
      InternalBlocksLoader.loadBlocksAndCategoriesInPanel(overlayBlockly);
      DynamicBlockLoader.loadBlocksAndCategoriesInPanel(overlayBlockly);
      BlocklyLoader.INSTANCE.getBlockLoader(BlocklyEditorType.PROCEDURE)
          .loadBlocksAndCategoriesInPanel(overlayBlockly, ToolboxType.PROCEDURE);
      if (!editingMode) {
        overlayBlockly.setInitialXML(AnnotationUtils.getBlocklyXMLDefaultValue(Procedure.class, "procedurexml"));
      }
    });
    overlayBlocklyToolbar = new BlocklyEditorToolbar(mcreator, BlocklyEditorType.PROCEDURE, overlayBlockly);
    initGUI();
    finalizeGUI();
    updateTargetBlocksDynamicSize();
  }

  private void updateTargetBlocksDynamicSize() {
    int count = Math.max(1, targetBlocks.getListElements().size());
    int listWidth = Math.max(200, Math.min(650, count * 38 + 50));
    int listHeight = 36;
    for (Component c : targetBlocks.getComponents()) {
      if (c instanceof JScrollPane sp) {
        sp.setPreferredSize(new Dimension(listWidth, listHeight));
        sp.setMinimumSize(new Dimension(listWidth, listHeight));
        sp.revalidate();
      }
    }
    targetBlocks.setPreferredSize(new Dimension(listWidth + 85, listHeight + 6));
    targetBlocks.revalidate();
    targetBlocks.repaint();
    if (targetBlocks.getParent() != null) {
      targetBlocks.getParent().revalidate();
      targetBlocks.getParent().repaint();
    }
  }

  @Override
  protected void initGUI() {
    JPanel panel = new JPanel(new GridBagLayout());
    panel.setBorder(BorderFactory.createEmptyBorder(12, 12, 12, 12));
    int row = 0;
    row = addRow(panel, row, "Target blocks", targetBlocks);
    row = addRow(panel, row, "Show overlay", visibilityScope);
    row = addRow(panel, row, "Maximum distance", maximumDistance);
    JPanel editorPage = new JPanel(new BorderLayout());
    JPanel editorHeader = new JPanel(new BorderLayout());
    JPanel targetPanelHolder = new JPanel(new FlowLayout(FlowLayout.LEFT, 0, 0));
    targetPanelHolder.add(panel);
    editorHeader.add(targetPanelHolder, BorderLayout.NORTH);
    editorHeader.add(overlayBlocklyToolbar, BorderLayout.SOUTH);
    editorPage.add(editorHeader, BorderLayout.NORTH);
    editorPage.add(overlayBlockly, BorderLayout.CENTER);
    ModElementGUIPage page = addPage("Block Overlay", editorPage);
    page.validate(targetBlocks);
  }

  @Override
  public void reloadDataLists() {
    super.reloadDataLists();
    Object selected = conditionProcedure.getSelectedItem();
    List<String> procedures = new ArrayList<>();
    procedures.add("");
    mcreator.getWorkspace().getModElements().stream()
        .filter(element -> "procedure".equals(element.getType().getRegistryName()))
        .map(ModElement::getName)
        .sorted()
        .forEach(procedures::add);
    conditionProcedure.removeAllItems();
    procedures.forEach(conditionProcedure::addItem);
    conditionProcedure.setSelectedItem(selected);
  }

  private static int addRow(JPanel panel, int row, String label, java.awt.Component component) {
    GridBagConstraints labelConstraints = new GridBagConstraints();
    labelConstraints.gridx = 0;
    labelConstraints.gridy = row;
    labelConstraints.anchor = GridBagConstraints.WEST;
    labelConstraints.insets = new Insets(3, 0, 3, 10);
    panel.add(new JLabel(label), labelConstraints);
    GridBagConstraints fieldConstraints = new GridBagConstraints();
    fieldConstraints.gridx = 1;
    fieldConstraints.gridy = row;
    fieldConstraints.weightx = 1;
    fieldConstraints.fill = GridBagConstraints.HORIZONTAL;
    fieldConstraints.insets = new Insets(3, 0, 3, 0);
    panel.add(component, fieldConstraints);
    return row + 1;
  }

  private static void addWideRow(JPanel panel, int row, java.awt.Component component) {
    GridBagConstraints constraints = new GridBagConstraints();
    constraints.gridx = 0;
    constraints.gridy = row;
    constraints.gridwidth = 2;
    constraints.anchor = GridBagConstraints.WEST;
    constraints.insets = new Insets(3, 0, 3, 0);
    panel.add(component, constraints);
  }

  public static String migrateLegacyOverlayBlocks(String xml) {
    if (xml == null)
      return null;
    return xml
        .replace("block_overlay_item_face", "overlay_builder_item")
        .replace("block_overlay_item", "overlay_builder_item")
        .replace("block_overlay_number_face", "overlay_builder_number")
        .replace("block_overlay_number", "overlay_builder_number")
        .replace("block_overlay_text_face", "overlay_builder_text")
        .replace("block_overlay_text", "overlay_builder_text")
        .replace("block_overlay_texture_face", "overlay_builder_texture")
        .replace("block_overlay_texture", "overlay_builder_texture")
        .replace("block_overlay_outline_face", "overlay_builder_outline")
        .replace("block_overlay_outline", "overlay_builder_outline")
        .replace("block_overlay_precise_text_face", "overlay_builder_precise_text")
        .replace("block_overlay_precise_text", "overlay_builder_precise_text")
        .replace("block_overlay_screen_texture", "overlay_builder_screen_texture")
        .replace("block_overlay_spinning_item", "overlay_builder_spinning_item")
        .replace("block_overlay_center_spinning_item", "overlay_builder_center_spinning_item");
  }

  public static boolean hasLegacyOverlayBlocks(String xml) {
    return xml != null && xml.contains("block_overlay_");
  }

  @Override
  protected void openInEditingMode(BlockOverlayElement element) {
    List<MItemBlock> blocksList = new ArrayList<>();
    if (element.targetBlocks != null && !element.targetBlocks.isEmpty()) {
      for (String b : element.targetBlocks) {
        if (b != null && !b.isBlank()) {
          blocksList.add(new MItemBlock(mcreator.getWorkspace(), b));
        }
      }
    } else if (element.targetBlock != null && !element.targetBlock.isBlank()) {
      blocksList.add(new MItemBlock(mcreator.getWorkspace(), element.targetBlock));
    }
    targetBlocks.setListElements(blocksList);
    updateTargetBlocksDynamicSize();
    visibilityScope.setSelectedIndex("LOOKED_AT".equals(element.visibilityScope) ? 1 : 0);
    blockStateProperty.setText(element.blockStateProperty);
    blockStateValue.setText(element.blockStateValue);
    requiresCrouching.setSelected(element.requiresCrouching);
    heldItemOrTag.setText(element.heldItemOrTag);
    heldItemNbt.setText(element.heldItemNbt);
    blockEntityNbt.setText(element.blockEntityNbt);
    maximumDistance.setValue(element.maximumDistance);
    conditionProcedure.setSelectedItem(element.conditionProcedure);
    layerType.setSelectedItem(element.layerType);
    layerValue.setText(element.layerValue);
    face.setSelectedItem(element.face);
    placement.setSelectedItem(element.placement);
    color.setText(element.color);
    scale.setValue(element.scale);
    lineWidth.setValue(element.lineWidth);
    throughWalls.setSelected(element.throughWalls);
    if (element.overlayxml != null && !element.overlayxml.isBlank()) {
      overlayBlockly.setInitialXML(migrateLegacyOverlayBlocks(element.overlayxml));
    }
  }

  @Override
  protected AggregatedValidationResult getAdditionalValidationResult(BlockOverlayElement element) {
    if (element.targetBlocks == null || element.targetBlocks.isEmpty()) {
      return new AggregatedValidationResult.FAIL("At least one target block must be selected.");
    }
    return super.getAdditionalValidationResult(element);
  }

  @Override
  public BlockOverlayElement getElementFromGUI() {
    BlockOverlayElement element = new BlockOverlayElement(modElement);
    List<String> selectedBlocks = new ArrayList<>();
    for (MItemBlock mb : targetBlocks.getListElements()) {
      if (mb != null && mb.getUnmappedValue() != null && !mb.getUnmappedValue().trim().isEmpty()) {
        selectedBlocks.add(mb.getUnmappedValue());
      }
    }
    element.targetBlocks = selectedBlocks;
    element.targetBlock = selectedBlocks.isEmpty() ? "" : selectedBlocks.get(0);
    element.overlayxml = overlayBlockly.getXML();
    element.visibilityScope = visibilityScope.getSelectedIndex() == 1 ? "LOOKED_AT" : "NEARBY_MATCHING";
    element.visibleOnScreenOnly = true;
    element.blockStateProperty = blockStateProperty.getText().trim();
    element.blockStateValue = blockStateValue.getText().trim();
    element.requiresCrouching = requiresCrouching.isSelected();
    element.heldItemOrTag = heldItemOrTag.getText().trim();
    element.heldItemNbt = heldItemNbt.getText().trim();
    element.blockEntityNbt = blockEntityNbt.getText().trim();
    element.maximumDistance = ((Number) maximumDistance.getValue()).doubleValue();
    element.conditionProcedure = (String) conditionProcedure.getSelectedItem();
    element.layerType = (String) layerType.getSelectedItem();
    element.layerValue = layerValue.getText().trim();
    element.face = (String) face.getSelectedItem();
    element.placement = (String) placement.getSelectedItem();
    String colorValue = color.getText().trim();
    element.color = colorValue.matches("#[0-9a-fA-F]{6}") ? colorValue : "#ffffff";
    element.scale = ((Number) scale.getValue()).doubleValue();
    element.lineWidth = ((Number) lineWidth.getValue()).doubleValue();
    element.throughWalls = throughWalls.isSelected();
    return element;
  }

  @Override
  public void onViewClosed() {
    overlayBlockly.close();
    super.onViewClosed();
  }

  @Override
  public URI contextURL() throws URISyntaxException {
    return new URI("https://mcreator.net/");
  }
}

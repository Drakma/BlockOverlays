package net.drakma.blockoverlays.elements;

import net.mcreator.element.GeneratableElement;
import net.mcreator.element.types.Procedure;
import net.mcreator.generator.template.IAdditionalTemplateDataProvider;
import net.mcreator.workspace.elements.ModElement;

import java.util.ArrayList;
import java.util.List;

public class BlockOverlayElement extends GeneratableElement {
  public String targetBlock = "minecraft:stone";
  public List<String> targetBlocks = new ArrayList<>();
  public String overlayxml = "";
  public String visibilityScope = "NEARBY_MATCHING";
  public boolean visibleOnScreenOnly = true;
  public String blockStateProperty = "";
  public String blockStateValue = "";
  public boolean requiresCrouching;
  public String heldItemOrTag = "";
  public String heldItemNbt = "";
  public String blockEntityNbt = "";
  public double maximumDistance = 16.0;
  public String conditionProcedure = "";
  public String layerType = "TEXT";
  public String layerValue = "Label";
  public String face = "NORTH";
  public String placement = "MIDDLE_CENTER";
  public String color = "#ffffff";
  public double scale = 1.0;
  public double lineWidth = 1.0;
  public boolean throughWalls;

  public BlockOverlayElement(ModElement element) {
    super(element);
  }

  private String resolveBlockId(String block) {
    if (block == null || block.isBlank()) {
      return "minecraft:air";
    }
    if (!block.startsWith("CUSTOM:")) {
      return block;
    }
    ModElement targetElement = getModElement().getWorkspace()
        .getModElementByName(block.substring("CUSTOM:".length()));
    if (targetElement == null || targetElement.getRegistryName() == null || targetElement.getRegistryName().isBlank()) {
      return "minecraft:air";
    }
    return getModElement().getWorkspace().getWorkspaceSettings().getModID() + ":" + targetElement.getRegistryName();
  }

  public List<String> targetBlockIds() {
    List<String> ids = new ArrayList<>();
    if (targetBlocks != null && !targetBlocks.isEmpty()) {
      for (String block : targetBlocks) {
        String resolved = resolveBlockId(block);
        if (!ids.contains(resolved)) {
          ids.add(resolved);
        }
      }
    } else if (targetBlock != null && !targetBlock.isBlank()) {
      ids.add(resolveBlockId(targetBlock));
    } else {
      ids.add("minecraft:stone");
    }
    return ids;
  }

  @Override
  public IAdditionalTemplateDataProvider getAdditionalTemplateData() {
    return templateData -> {
      List<String> ids = targetBlockIds();
      templateData.put("targetBlockIds", ids);
      templateData.put("targetBlockId", ids.isEmpty() ? "minecraft:stone" : ids.get(0));
      if (overlayxml != null && !overlayxml.isBlank()) {
        Procedure procedure = new Procedure(getModElement());
        procedure.procedurexml = overlayxml;
        procedure.getAdditionalTemplateData().provideAdditionalData(templateData);
      }
    };
  }
}

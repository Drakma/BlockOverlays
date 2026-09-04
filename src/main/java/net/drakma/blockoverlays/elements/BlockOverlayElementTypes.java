package net.drakma.blockoverlays.elements;

import net.mcreator.element.ModElementType;
import net.mcreator.element.ModElementTypeLoader;

public final class BlockOverlayElementTypes {
  private BlockOverlayElementTypes() {
  }

  public static void load() {
    ModElementTypeLoader
        .register(new ModElementType<>("blockoverlay", 'O', BlockOverlayElementGUI::new, BlockOverlayElement.class));
  }
}

package net.drakma.blockoverlays;

import net.mcreator.element.types.Procedure;
import net.mcreator.plugin.JavaPlugin;
import net.mcreator.plugin.Plugin;
import net.mcreator.plugin.events.PreGeneratorsLoadingEvent;
import net.mcreator.plugin.events.ui.BlocklyPanelRegisterDOMData;
import net.mcreator.plugin.events.ui.ModElementGUIEvent;
import net.mcreator.ui.MCreator;
import net.mcreator.ui.dialogs.StringSelectorDialog;
import net.mcreator.ui.dialogs.TypedTextureSelectorDialog;
import net.mcreator.ui.modgui.ProcedureGUI;
import net.mcreator.ui.workspace.resources.TextureType;
import net.mcreator.workspace.resources.Texture;
import net.drakma.blockoverlays.elements.BlockOverlayElementGUI;
import net.drakma.blockoverlays.elements.BlockOverlayElementTypes;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import javax.swing.SwingUtilities;
import java.io.File;
import java.nio.file.Files;
import java.util.Base64;
import java.util.function.Consumer;

public class BlockOverlaysPlugin extends JavaPlugin {
  private static final Logger LOG = LogManager.getLogger("BlockOverlays");

  public BlockOverlaysPlugin(Plugin plugin) {
    super(plugin);
    addListener(PreGeneratorsLoadingEvent.class, event -> BlockOverlayElementTypes.load());

    addListener(BlocklyPanelRegisterDOMData.class, event -> {
      event.addJavaScriptBridge("texturebridge",
          new TextureBridge(event.getBlocklyPanel().getMCreator()));
      event.addJavaScriptBridge("structurebridge",
          new StructureBridge(event.getBlocklyPanel().getMCreator()));
    });

    // Migrate procedure XML lazily before ProcedureGUI loads it into BlocklyPanel
    addListener(ModElementGUIEvent.BeforeLoading.class, event -> {
      if (event.getModElementGUI() instanceof ProcedureGUI procedureGUI) {
        if (procedureGUI.getModElement().getGeneratableElement() instanceof Procedure procedure) {
          if (BlockOverlayElementGUI.hasLegacyOverlayBlocks(procedure.procedurexml)) {
            procedure.procedurexml = BlockOverlayElementGUI.migrateLegacyOverlayBlocks(procedure.procedurexml);
            LOG.info("Migrated legacy overlay blocks in procedure before GUI load: {}",
                procedureGUI.getModElement().getName());
          }
        }
      }
    });

    LOG.info("BlockOverlays plugin initialized");
  }

  public static final class TextureBridge {
    private final MCreator mcreator;

    public TextureBridge(MCreator mcreator) {
      this.mcreator = mcreator;
    }

    public void openTextureSelector(String textureTypeName, Consumer<String> callback) {
      SwingUtilities.invokeLater(() -> {
        TextureType textureType = textureType(textureTypeName);
        TypedTextureSelectorDialog dialog = new TypedTextureSelectorDialog(mcreator, textureType)
            .loadExternalTextures(true);
        dialog.getConfirmButton().addActionListener(event -> {
          Texture selected = dialog.list.getSelectedValue();
          if (selected != null)
            callback.accept(selected.getTextureName());
        });
        dialog.list.addMouseListener(new java.awt.event.MouseAdapter() {
          @Override
          public void mouseClicked(java.awt.event.MouseEvent e) {
            if (e.getClickCount() == 2) {
              Texture selected = dialog.list.getSelectedValue();
              if (selected != null) {
                callback.accept(selected.getTextureName());
                dialog.dispose();
              }
            }
          }
        });
        dialog.setVisible(true);
      });
    }

    public String getTextureURI(String textureTypeName, String textureName) {
      try {
        if (textureName == null || textureName.isBlank())
          return "";
        String baseName = textureName.endsWith(".png") ? textureName.substring(0, textureName.length() - 4)
            : textureName;
        Texture texture = Texture.fromName(mcreator.getWorkspace(), textureType(textureTypeName), baseName);
        if (texture != null) {
          javax.swing.ImageIcon icon = texture.getTextureIcon(mcreator.getWorkspace());
          if (icon != null && icon.getImage() != null) {
            java.awt.Image img = icon.getImage();
            java.awt.image.BufferedImage bimg;
            if (img instanceof java.awt.image.BufferedImage bi) {
              bimg = bi;
            } else {
              int w = Math.max(1, img.getWidth(null));
              int h = Math.max(1, img.getHeight(null));
              bimg = new java.awt.image.BufferedImage(w, h, java.awt.image.BufferedImage.TYPE_INT_ARGB);
              java.awt.Graphics2D g2 = bimg.createGraphics();
              g2.drawImage(img, 0, 0, null);
              g2.dispose();
            }
            java.io.ByteArrayOutputStream baos = new java.io.ByteArrayOutputStream();
            javax.imageio.ImageIO.write(bimg, "png", baos);
            return "data:image/png;base64," + Base64.getEncoder().encodeToString(baos.toByteArray());
          }
        }
        File file = mcreator.getWorkspace().getFolderManager().getTextureFile(baseName, textureType(textureTypeName));
        if (file.isFile())
          return "data:image/png;base64," + Base64.getEncoder().encodeToString(Files.readAllBytes(file.toPath()));
        return "";
      } catch (Exception exception) {
        LOG.warn("Unable to load texture preview for {}", textureName, exception);
        return "";
      }
    }

    private static TextureType textureType(String name) {
      try {
        return TextureType.valueOf(name);
      } catch (IllegalArgumentException | NullPointerException exception) {
        return TextureType.OTHER;
      }
    }
  }

  public static final class StructureBridge {
    private final MCreator mcreator;

    public StructureBridge(MCreator mcreator) {
      this.mcreator = mcreator;
    }

    public void openStructureSelector(Consumer<String> callback) {
      SwingUtilities.invokeLater(() -> {
        String selected = StringSelectorDialog.openSelectorDialog(mcreator,
            workspace -> workspace.getFolderManager().getStructureList().toArray(new String[0]),
            "Select structure", "Choose a structure resource (.nbt):");
        if (selected != null && !selected.isBlank())
          callback.accept(selected);
      });
    }
  }
}
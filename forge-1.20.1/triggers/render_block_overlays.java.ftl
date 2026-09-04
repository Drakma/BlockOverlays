<#include "procedures.java.ftl">
@OnlyIn(Dist.CLIENT)
@Mod.EventBusSubscriber(bus = Mod.EventBusSubscriber.Bus.FORGE, value = Dist.CLIENT)
public class ${name}Procedure {
	@SubscribeEvent
	public static void renderLevel(RenderLevelStageEvent event) {
		if (event.getStage() == RenderLevelStageEvent.Stage.AFTER_TRANSLUCENT_BLOCKS) {
			Minecraft minecraft = Minecraft.getInstance();
			if (minecraft.level == null || minecraft.player == null)
				return;
			<#assign dependenciesCode>
				<@procedureDependenciesCode dependencies, {
					"world": "minecraft.level",
					"entity": "minecraft.player",
					"x": "minecraft.player.getX()",
					"y": "minecraft.player.getY()",
					"z": "minecraft.player.getZ()"
				}/>
			</#assign>
			execute(event<#if dependenciesCode?has_content>,</#if>${dependenciesCode});
		}
	}

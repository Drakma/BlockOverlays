<#include "procedures.java.ftl">
@EventBusSubscriber(value = Dist.CLIENT)
public class ${name}Procedure {
	@SubscribeEvent
	public static void onSubmitCustomGeometry(SubmitCustomGeometryEvent event) {
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
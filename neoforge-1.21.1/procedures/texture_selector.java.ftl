<#assign textureFolder = {
	"BLOCK": "block/",
	"ITEM": "item/",
	"ENTITY": "entities/",
	"EFFECT": "mob_effect/",
	"PARTICLE": "particle/",
	"SCREEN": "screens/",
	"ARMOR": "models/armor/",
	"OTHER": ""
}>
<#assign tex = field$texture!"">
<#if tex?has_content>
<#if tex?contains(":")>
<#assign texName = (tex?ends_with(".png"))?then(tex, tex + ".png")>
Identifier.parse("${JavaConventions.escapeStringForJava(texName)}")
<#else>
<#assign texName = (tex?ends_with(".png"))?then(tex, tex + ".png")>
Identifier.parse("${modid}:textures/${textureFolder[field$texture_type]}${JavaConventions.escapeStringForJava(texName)}")
</#if>
<#else>
Identifier.parse("minecraft:textures/gui/sprites/widget/button.png")
</#if>
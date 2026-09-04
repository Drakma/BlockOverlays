<#assign tex = field$texture!"">
<#if tex?has_content>
<#if tex?contains(":")>
<#assign texName = (tex?ends_with(".png"))?then(tex, tex + ".png")>
new ResourceLocation("${JavaConventions.escapeStringForJava(texName)}")
<#else>
<#assign texName = (tex?ends_with(".png"))?then(tex, tex + ".png")>
new ResourceLocation("${modid}", "textures/screens/${JavaConventions.escapeStringForJava(texName)}")
</#if>
<#else>
new ResourceLocation("minecraft", "textures/gui/sprites/widget/button.png")
</#if>

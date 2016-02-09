modifier_str = class({})

function modifier_str:GetEffectName()
	return "particles/units/heroes/hero_troll_warlord/troll_warlord_battletrance_buff.vpcf"
end

function modifier_str:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_str:GetTexture()
	return "sven_storm_bolt"
end
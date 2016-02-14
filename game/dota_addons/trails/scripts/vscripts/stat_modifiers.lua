modifier_str_up = class({})

function modifier_str_up:GetEffectName()
	return "particles/units/heroes/hero_troll_warlord/troll_warlord_battletrance_buff.vpcf"
end

function modifier_str_up:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_str_up:GetTexture()
	return "sven_storm_bolt"
end

modifier_str_down = class({})

function modifier_str_down:GetEffectName()
	return "particles/units/heroes/hero_bane/bane_enfeeble.vpcf"
end

function modifier_str_down:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_str_down:GetTexture()
	return "bane_enfeeble"
end

function modifier_str_down:IsDebuff()
	return true
end

modifier_adf_down = class({})

function modifier_adf_down:GetEffectName()
	return "particles/items2_fx/veil_of_discord_debuff.vpcf"
end

function modifier_adf_down:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_adf_down:GetTexture()
	return "roshan_halloween_apocalypse"
end

function modifier_adf_down:IsDebuff()
	return true
end
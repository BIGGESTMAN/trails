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

modifier_def_up = class({})

modifier_def_down = class({})

function modifier_def_down:IsDebuff()
	return true
end

modifier_ats_up = class({})

modifier_ats_down = class({})

function modifier_ats_down:IsDebuff()
	return true
end

modifier_adf_up = class({})

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

modifier_spd_up = class({})

function modifier_spd_up:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE}
end

function modifier_spd_up:GetModifierAttackSpeedBonus_Constant()
	return 1 * self:GetStackCount()
end

function modifier_spd_up:GetModifierPercentageCooldown()
	return -1 * self:GetStackCount()
end

modifier_spd_down = class({})

function modifier_spd_down:IsDebuff()
	return true
end

function modifier_spd_down:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE}
end

function modifier_spd_down:GetModifierAttackSpeedBonus_Constant()
	return -1 * self:GetStackCount()
end

function modifier_spd_up:GetModifierPercentageCooldown()
	return 1 * self:GetStackCount()
end

modifier_mov_up = class({})

function modifier_mov_up:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_mov_up:GetModifierMoveSpeedBonus_Percentage()
	return 1 * self:GetStackCount()
end

modifier_mov_down = class({})

function modifier_mov_down:IsDebuff()
	return true
end

function modifier_mov_down:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_mov_down:GetModifierMoveSpeedBonus_Percentage()
	return -1 * self:GetStackCount()
end
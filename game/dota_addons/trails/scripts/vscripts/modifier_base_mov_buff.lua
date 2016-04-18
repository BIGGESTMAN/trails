modifier_base_mov_buff = class({})

function modifier_base_mov_buff:IsHidden()
	return true
end

function modifier_base_mov_buff:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_base_mov_buff:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_HEALTH_BONUS,
			MODIFIER_PROPERTY_MANA_BONUS,
			MODIFIER_EVENT_ON_ATTACK_LANDED}
end

function modifier_base_mov_buff:GetModifierMoveSpeedBonus_Constant()
	return getStats(self:GetParent()).mov - self:GetParent():GetBaseMoveSpeed()
end

function modifier_base_mov_buff:GetModifierHealthBonus()
	return getStats(self:GetParent()).hp - self:GetParent().stats.hp
end

function modifier_base_mov_buff:GetModifierManaBonus()
	return getStats(self:GetParent()).ep - self:GetParent().stats.ep
end

function modifier_base_mov_buff:OnAttackLanded(params)
	if params.attacker == self:GetParent() then
		local attacker = params.attacker
		local damage_scale = 1
		local damage_type = DAMAGE_TYPE_PHYSICAL
		if attacker:HasModifier("modifier_crit") then
			damage_scale = damage_scale * 2
			attacker:RemoveModifierByName("modifier_crit")
		end

		applyEffect(params.target, damage_type, function()
			dealScalingDamage(params.target, attacker, DAMAGE_TYPE_PHYSICAL, damage_scale, nil)
		end)
	end
end
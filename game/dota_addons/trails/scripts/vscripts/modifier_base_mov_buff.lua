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
			MODIFIER_PROPERTY_MANA_BONUS}
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
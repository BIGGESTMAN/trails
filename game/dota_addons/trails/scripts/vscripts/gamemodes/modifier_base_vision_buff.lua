modifier_base_vision_buff = class({})

function modifier_base_vision_buff:IsHidden()
	return true
end

function modifier_base_vision_buff:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_base_vision_buff:DeclareFunctions()
	return {MODIFIER_PROPERTY_BONUS_DAY_VISION}
end

function modifier_base_vision_buff:GetBonusDayVision()
	return -800
end
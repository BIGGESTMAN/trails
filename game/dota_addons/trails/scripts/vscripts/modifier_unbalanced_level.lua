modifier_unbalanced_level = class({})

if IsServer() then
	function modifier_unbalanced_level:IncreaseLevel(amount)
		local decay_delay = self:GetAbility():GetSpecialValueFor("unbalance_decay_delay")
		self:SetStackCount(self:GetStackCount() + amount)
		self:StartIntervalThink(-1)
		self:StartIntervalThink(decay_delay)
		self:SetDuration(decay_delay, true)
	end

	function modifier_unbalanced_level:OnCreated( kv )
		local decay_delay = self:GetAbility():GetSpecialValueFor("unbalance_decay_delay")
		self:IncreaseLevel(0)
	end

	function modifier_unbalanced_level:OnIntervalThink()
		local ability = self:GetAbility()

		local current_level = self:GetStackCount()
		local decay = ability:GetSpecialValueFor("unbalance_decay_per_second")
		local decay_interval = 1

		if current_level > decay then
			self:SetStackCount(current_level - decay)
			self:StartIntervalThink(-1)
			self:StartIntervalThink(decay_interval)
		else
			self:SetStackCount(0)
		end
	end
end

function modifier_unbalanced_level:GetTexture()
	return "bounty_hunter_track"
end

function modifier_unbalanced_level:DestroyOnExpire()
	return false
end

function modifier_unbalanced_level:IsHidden()
	return self:GetStackCount() < 1
end

function modifier_unbalanced_level:IsDebuff()
	return true
end
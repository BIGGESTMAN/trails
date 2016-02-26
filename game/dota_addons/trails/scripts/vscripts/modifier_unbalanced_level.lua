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

		local update_interval = 1/30

		-- Particle-based unbalance status bar -- unused due to using panorama instead
		-- self.particle = ParticleManager:CreateParticle("particles/unbalance_level_bar.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent())
		-- Timers:CreateTimer(0, function()
		-- 	local location = self:GetParent():GetAbsOrigin()
		-- 	local percent_filled = self:GetStackCount() / 100
		-- 	if self:GetParent():HasModifier("modifier_combat_link_unbalanced") then percent_filled = 1 end
		-- 	ParticleManager:SetParticleControl(self.particle, 1, Vector(percent_filled, percent_filled, percent_filled))
		-- 	ParticleManager:SetParticleControl(self.particle, 2, location + Vector(-100,0,200))
		-- 	ParticleManager:SetParticleControl(self.particle, 3, location + Vector(percent_filled * 200 - 100,0,200))
		-- 	ParticleManager:SetParticleControl(self.particle, 4, Vector(1.5 + percent_filled,0,0))
		-- 	return update_interval
		-- end)
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

function modifier_unbalanced_level:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_unbalanced_level:DeclareFunctions()
	return { MODIFIER_EVENT_ON_DEATH }
end

function modifier_unbalanced_level:OnDeath()
	self:SetStackCount(0)
end
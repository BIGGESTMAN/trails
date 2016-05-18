modifier_boss_vulnerable = class({})

function modifier_boss_vulnerable:GetEffectName()
	return "particles/bosses/vulnerable.vpcf"
end

function modifier_boss_vulnerable:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_boss_vulnerable:GetTexture()
	return "lone_druid_savage_roar"
end

if IsServer() then
	function modifier_boss_vulnerable:OnCreated(kv)
		CustomGameEventManager:Send_ServerToAllClients("boss_vulnerability_changed", {vulnerable = true, threshold_percent = VULNERABLE_PROC_THRESHOLD_FACTOR * 100})
		self.damage_remaining = VULNERABLE_PROC_THRESHOLD_FACTOR * self:GetParent():GetMaxHealth()
		self.damage_dealt_table = {}

		self:StartIntervalThink(1/30)
	end

	function modifier_boss_vulnerable:OnIntervalThink()
		CustomGameEventManager:Send_ServerToAllClients("boss_update_vulnerability_time_remaining", {percent = self:GetRemainingTime() / self:GetDuration() * 100})
	end

	function modifier_boss_vulnerable:DeclareFunctions()
		return {MODIFIER_EVENT_ON_TAKEDAMAGE}
	end

	function modifier_boss_vulnerable:OnTakeDamage(params)
		if params.unit == self:GetParent() then
			if not self.damage_dealt_table[params.attacker] then self.damage_dealt_table[params.attacker] = 0 end
			self.damage_dealt_table[params.attacker] = self.damage_dealt_table[params.attacker] + params.damage

			self.damage_remaining = self.damage_remaining - params.damage
			CustomGameEventManager:Send_ServerToAllClients("boss_vulnerability_changed", {vulnerable = true, threshold_percent = self.damage_remaining / self:GetParent():GetMaxHealth() * 100})

			if self.damage_remaining <= 0 then
				self:Destroy()
			end
		end
	end

	function modifier_boss_vulnerable:OnDestroy()
		if self.damage_remaining <= 0 then
			Gamemode_Boss:EnhanceHero(self.damage_dealt_table)
		end
		CustomGameEventManager:Send_ServerToAllClients("boss_vulnerability_changed", {vulnerable = false})
	end
end
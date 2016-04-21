LinkLuaModifier("modifier_boss_hp_tracker", "gamemodes/modifier_boss_hp_tracker.lua", LUA_MODIFIER_MOTION_NONE)

modifier_boss_hp_tracker = class({})

if IsServer() then
	function modifier_boss_hp_tracker:DeclareFunctions()
		return {MODIFIER_EVENT_ON_TAKEDAMAGE,
				MODIFIER_EVENT_ON_HEAL_RECEIVED}
	end

	function modifier_boss_hp_tracker:OnTakeDamage(params)
		if params.unit == self:GetParent() then
			self:UpdateLifebar()
		end
	end

	function modifier_boss_hp_tracker:OnHealReceived(params)
		if params.unit == self:GetParent() then
			self:UpdateLifebar()
		end
	end

	function modifier_boss_hp_tracker:UpdateLifebar()
		local health_percent = self:GetParent():GetHealth() / self:GetParent():GetMaxHealth() * 100
		CustomGameEventManager:Send_ServerToAllClients("boss_health_changed", {percent = health_percent})
	end
end
LinkLuaModifier("modifier_boss_out_of_combat_regen", "gamemodes/modifier_boss_out_of_combat_regen.lua", LUA_MODIFIER_MOTION_NONE)

modifier_boss_out_of_combat_regen = class({})

if IsServer() then
	function modifier_boss_out_of_combat_regen:OnCreated( kv )
		self.regen_interval = 1/30
		self.time_to_fully_regen = 10
		self:StartIntervalThink(self.regen_interval)
	end

	function modifier_boss_out_of_combat_regen:OnIntervalThink()
		local hero = self:GetParent()

		if hero:GetHealth() < hero:GetMaxHealth() then
			local healing = hero:GetMaxHealth() / self.time_to_fully_regen * self.regen_interval
			applyHealing(hero, hero, healing)
		end
		if hero:GetMana() < hero:GetMaxMana() then
			local mana = hero:GetMaxMana() / self.time_to_fully_regen * self.regen_interval
			hero:SetMana(hero:GetMana() + mana)
		end
		if getCP(hero) < 100 then
			modifyCP(hero, 100 / self.time_to_fully_regen * self.regen_interval)
		end
	end
end
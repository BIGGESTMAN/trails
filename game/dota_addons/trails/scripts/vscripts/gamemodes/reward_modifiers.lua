require "game_functions"
require "gamemodes/cp_rewards"

LinkLuaModifier("modifier_jelly_shroom_reward", "gamemodes/reward_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_grunoja_reward", "gamemodes/reward_modifiers.lua", LUA_MODIFIER_MOTION_NONE)

modifier_jelly_shroom_reward = class({})

function modifier_jelly_shroom_reward:IsHidden()
	return true
end

if IsServer() then
	function modifier_jelly_shroom_reward:DeclareFunctions()
		return {MODIFIER_EVENT_ON_TAKEDAMAGE}
	end

	function modifier_jelly_shroom_reward:OnTakeDamage(params)
		local unit = self:GetParent()
		if params.unit == unit then
			if params.damage_type == DAMAGE_TYPE_MAGICAL then
				CPRewards:RewardCP(params.attacker, unit)
			end
		end
	end
end

modifier_boss_grunoja_reward = class({})

function modifier_boss_grunoja_reward:IsHidden()
	return true
end

-- if IsServer() then
-- 	function modifier_boss_grunoja_reward:DeclareFunctions()
-- 		return {MODIFIER_EVENT_ON_TAKEDAMAGE}
-- 	end

-- 	function modifier_boss_grunoja_reward:OnTakeDamage(params)
-- 		local unit = self:GetParent()
-- 		if params.unit == unit then
-- 			if params.damage_type == DAMAGE_TYPE_MAGICAL then
-- 				CPRewards:RewardCP(params.attacker, unit)
-- 			end
-- 		end
-- 	end
-- end
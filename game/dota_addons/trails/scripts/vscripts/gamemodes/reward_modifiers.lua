require "game_functions"
require "gamemodes/cp_rewards"

LinkLuaModifier("modifier_generic_ondamage_reward", "gamemodes/reward_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_counterhit_passive", "gamemodes/reward_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_counterhit_ondamage_reward", "gamemodes/reward_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jelly_shroom_reward", "gamemodes/reward_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gordi_chief_reward", "gamemodes/reward_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_grunoja_reward", "gamemodes/reward_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_blade_horn_reward", "gamemodes/reward_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_blade_pincer_reward", "gamemodes/reward_modifiers.lua", LUA_MODIFIER_MOTION_NONE)

modifier_generic_ondamage_reward = class({})

if IsServer() then
	function modifier_generic_ondamage_reward:DeclareFunctions()
		return {MODIFIER_EVENT_ON_TAKEDAMAGE}
	end

	function modifier_generic_ondamage_reward:OnTakeDamage(params)
		local unit = self:GetParent()
		if params.unit == unit then
			CPRewards:RewardCP(params.attacker, unit)
			self:Destroy()
		end
	end
end

modifier_counterhit_passive = class({})

if IsServer() then
	function modifier_counterhit_passive:DeclareFunctions()
		return {MODIFIER_EVENT_ON_ATTACK_LANDED}
	end

	function modifier_counterhit_passive:OnAttackLanded(params)
		local unit = self:GetParent()
		if params.attacker == unit then
			self:GetParent():AddNewModifier(self:GetParent(), nil, "modifier_counterhit_ondamage_reward", {duration = 0.75})
		end
	end
end

function modifier_counterhit_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

modifier_counterhit_ondamage_reward = class({})

if IsServer() then
	function modifier_counterhit_ondamage_reward:DeclareFunctions()
		return {MODIFIER_EVENT_ON_TAKEDAMAGE}
	end

	function modifier_counterhit_ondamage_reward:OnTakeDamage(params)
		local unit = self:GetParent()
		if params.unit == unit then
			CPRewards:RewardCP(params.attacker, unit, 10)
			self:Destroy()
		end
	end
end

function modifier_counterhit_ondamage_reward:GetEffectName()
	return "particles/cp_rewards/counterhit_available_mark.vpcf"
end

function modifier_counterhit_ondamage_reward:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

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
				self:TriggerCPReward(params.attacker)
			end
		end
	end

	function modifier_jelly_shroom_reward:OnCreated()
		self:GetParent().reward_modifier = self
	end
end

function modifier_jelly_shroom_reward:TriggerCPReward(hero)
	CPRewards:RewardCP(hero, self:GetParent())
	CPRewards:UnlockCPCondition(CONDITION_SHROOM_MAGIC_DAMAGE)
end

function modifier_jelly_shroom_reward:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_jelly_shroom_reward:GetRewardConditions()
	return {CONDITION_SHROOM_MAGIC_DAMAGE}
end

modifier_boss_grunoja_reward = class({})

if IsServer() then
	function modifier_boss_grunoja_reward:OnCreated()
		self:GetParent().reward_modifier = self
	end
end

function modifier_boss_grunoja_reward:IsHidden()
	return true
end

function modifier_boss_grunoja_reward:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_boss_grunoja_reward:GetRewardConditions()
	return {CONDITION_DODGE_GROUND_SMASH, CONDITION_BREAK_FISTS_OF_FURY}
end

function modifier_boss_grunoja_reward:TriggerCPReward(ability_name, cp)
	if ability_name == "mob_boss_grunoja_fists_of_fury" then
		CPRewards:RewardCP(nil, self:GetParent(), cp)
		CPRewards:UnlockCPCondition(CONDITION_BREAK_FISTS_OF_FURY)
	elseif ability_name == "mob_boss_grunoja_ground_smash" then
		self:GetParent():AddNewModifier(self:GetParent(), nil, "modifier_generic_ondamage_reward", {duration = 3})
		CPRewards:UnlockCPCondition(CONDITION_DODGE_GROUND_SMASH)
	end
end

modifier_gordi_chief_reward = class({})

if IsServer() then
	function modifier_gordi_chief_reward:OnCreated()
		self:GetParent().reward_modifier = self
	end
end

function modifier_gordi_chief_reward:TriggerCPReward()
	CPRewards:RewardCP(nil, self:GetParent())
	CPRewards:UnlockCPCondition(CONDITION_SHARE_KNUCKLEDUSTER_DAMAGE)
end

function modifier_gordi_chief_reward:IsHidden()
	return true
end

function modifier_gordi_chief_reward:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_gordi_chief_reward:GetRewardConditions()
	return {CONDITION_SHARE_KNUCKLEDUSTER_DAMAGE}
end

modifier_blade_horn_reward = class({})

if IsServer() then
	function modifier_blade_horn_reward:OnCreated()
		self:GetParent().reward_modifier = self
	end
end

function modifier_blade_horn_reward:TriggerCPReward()
	self:GetParent():AddNewModifier(self:GetParent(), nil, "modifier_generic_ondamage_reward", {duration = 3})
	CPRewards:UnlockCPCondition(CONDITION_DODGE_GORE)
end

function modifier_blade_horn_reward:IsHidden()
	return true
end

function modifier_blade_horn_reward:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_blade_horn_reward:GetRewardConditions()
	return {CONDITION_DODGE_GORE}
end

modifier_blade_pincer_reward = class({})

if IsServer() then
	function modifier_blade_pincer_reward:OnCreated()
		self:GetParent().reward_modifier = self
	end
end

function modifier_blade_pincer_reward:IsHidden()
	return true
end

function modifier_blade_pincer_reward:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_blade_pincer_reward:GetRewardConditions()
	return {}
end
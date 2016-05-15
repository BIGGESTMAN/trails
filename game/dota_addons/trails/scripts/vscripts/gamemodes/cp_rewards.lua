CONDITION_INTERRUPT_CRAFTS = 0
CONDITION_LAST_HIT_ENEMIES = 1
CONDITION_COLLECT_CP_ORBS = 2
CONDITION_SHROOM_MAGIC_DAMAGE = 3
CONDITION_DODGE_GROUND_SMASH = 4
CONDITION_SHARE_KNUCKLEDUSTER_DAMAGE = 5
CONDITION_BREAK_FISTS_OF_FURY = 6

if not CPRewards then
	CPRewards = class({})
end

BASE_CP_REWARD = 30

function CPRewards:Initialize()
	self.reward_conditions = {}
	self.reward_conditions[CONDITION_INTERRUPT_CRAFTS] = {unlocked = true, description = "Interrupt an enemy ability", unique = false}
	self.reward_conditions[CONDITION_LAST_HIT_ENEMIES] = {unlocked = true, description = "Last hit an enemy", unique = false}
	self.reward_conditions[CONDITION_COLLECT_CP_ORBS] = {unlocked = true, description = "Gather CP orbs", unique = false}
	self.reward_conditions[CONDITION_SHROOM_MAGIC_DAMAGE] = {unlocked = false, description = "Deal magic damage to a shroom", unique = true}
	self.reward_conditions[CONDITION_SHARE_KNUCKLEDUSTER_DAMAGE] = {unlocked = false, description = "Share Knuckleduster damage among all party members", unique = true}
	self.reward_conditions[CONDITION_DODGE_GROUND_SMASH] = {unlocked = false, description = "Dodge Ground Smash", unique = true}
	self.reward_conditions[CONDITION_BREAK_FISTS_OF_FURY] = {unlocked = false, description = "Break Fists of Fury early", unique = true}
end

function CPRewards:RewardCP(recipient, enemy, cp)
	-- print("Rewarding CP", recipient, enemy, cp)
	if cp ~= 0 then
		cp = cp or BASE_CP_REWARD
		enemy = enemy or recipient
		if recipient then
			local particle = ParticleManager:CreateParticle("particles/bosses/cp_reward_rays.vpcf", PATTACH_ABSORIGIN_FOLLOW, recipient)
			ParticleManager:SetParticleControlEnt(particle, 1, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)

			modifyCP(recipient, cp)
		else
			for k,hero in pairs(getAllLivingHeroes()) do
				self:RewardCP(hero, enemy, cp)
			end
		end
		EmitSoundOn("Trails.Unbalanced", enemy)
	end
end

function CPRewards:UpdateCPConditionsWindow()
	local conditions = {}
	conditions[CONDITION_INTERRUPT_CRAFTS] = true
	conditions[CONDITION_LAST_HIT_ENEMIES] = true
	if Gamemode_Boss.active_boss then
		conditions[CONDITION_COLLECT_CP_ORBS] = true
	end
	for condition,v in pairs(self:GetUniqueCPConditions()) do
		conditions[condition] = true
	end

	local condition_ui_data = {}
	for condition,v in pairs(conditions) do
		table.insert(condition_ui_data, self.reward_conditions[condition])
	end

	CustomGameEventManager:Send_ServerToAllClients("update_cp_conditions_window", {conditions = condition_ui_data})
end

function CPRewards:GetUniqueCPConditions()
	local conditions = {}
	for k,enemy in pairs(Gamemode_Boss.active_enemies) do
		local modifier = enemy.reward_modifier
		if modifier.GetRewardConditions then
			for k,condition in pairs(modifier:GetRewardConditions()) do
				conditions[condition] = true
			end
		end
	end
	return conditions
end

function CPRewards:UnlockCPCondition(condition)
	self.reward_conditions[condition].unlocked = true
	self:UpdateCPConditionsWindow()
end
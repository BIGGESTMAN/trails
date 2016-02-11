STAT_STR = "modifier_str" -- Increases phys damage
STAT_ATS = "modifier_ats" -- Increases magic damage
STAT_DEF = "modifier_def" -- Decreases phys damage taken
STAT_ADF = "modifier_adf" -- Decreases magic damage taken
STAT_SPD = "modifier_spd" -- Increases AS and lowers CDs?
STAT_MOV = "modifier_mov" -- Increases MS
STAT_MAX_INCREASE = 50

LinkLuaModifier(STAT_STR, "stat_modifiers.lua", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_burn", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)

function dealDamage(target, source, damage, damage_type, ability)
	ApplyDamage({victim = target, attacker = source, damage = damage, damage_type = damage_type, abilityReturn = ability})
end

function dash(unit, direction, speed, range, find_clear_space, impactFunction)
	local update_interval = 1/30
	speed = speed * update_interval

	local distance_traveled = 0

	Timers:CreateTimer(0, function()
		if IsValidEntity(unit) and unit:IsAlive() then
			if distance_traveled < range then
				-- Move unit -- includes a distance check to prevent overshooting
				local distance = range - distance_traveled
				if speed < distance then
					unit:SetAbsOrigin(unit:GetAbsOrigin() + direction * speed)
				else
					unit:SetAbsOrigin(unit:GetAbsOrigin() + direction * distance)
				end
				distance_traveled = distance_traveled + speed
				return update_interval
			else
				if find_clear_space then FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), false) end
				if impactFunction then impactFunction(unit, direction, speed / update_interval, range, find_clear_space) end
			end
		end
	end)
end

function modifyStat(unit, stat, percent, duration)
	if not unit:HasModifier(stat) then
		unit:AddNewModifier(unit, nil, stat, {duration = duration}):SetStackCount(percent)
	else
		local modifier = unit:FindModifierByName(stat)
		modifier:SetStackCount(modifier:GetStackCount() + percent)
		if modifier:GetStackCount() > STAT_MAX_INCREASE then modifier:SetStackCount(STAT_MAX_INCREASE) end
		if modifier:GetRemainingTime() < duration then modifier:SetDuration(duration, true) end
	end
end

function modifyCP(unit, amount)
	if unit:HasAbility("cp_tracker") then
		local max_cp = unit:FindAbilityByName("cp_tracker"):GetSpecialValueFor("max_cp")

		local modifier = unit:FindModifierByName("modifier_cp_tracker_cp")
		modifier:SetStackCount(modifier:GetStackCount() + amount)
		if modifier:GetStackCount() > max_cp then modifier:SetStackCount(max_cp) end

		if amount > 0 then
			ParticleManager:CreateParticle("particles/items3_fx/octarine_core_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
		end

		setCraftActivatedStatus(unit)
	end
end

function setCraftActivatedStatus(unit)
	for i=0,unit:GetAbilityCount() - 1 do
		local ability = unit:GetAbilityByIndex(i)
		if ability and ability:GetName() ~= "combat_link" then ability:SetActivated(unit:FindModifierByName("modifier_cp_tracker_cp"):GetStackCount() >= getCPCost(ability)) else break end
	end
end

if not util_ability_keyvalues then util_ability_keyvalues = LoadKeyValues("scripts/npc/npc_abilities_custom.txt") end
function getCPCost(ability)
	local cost = 0
	local ability_kvs = util_ability_keyvalues[ability:GetName()]
	if ability_kvs and ability_kvs["CPCost"] then
		cost = ability_kvs["CPCost"]
	end
	return cost
end
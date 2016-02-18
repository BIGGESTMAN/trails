STAT_STR = "modifier_str_up" -- Increases phys damage
STAT_STR_DOWN = "modifier_str_down"
STAT_ATS = "modifier_ats" -- Increases magic damage
STAT_DEF = "modifier_def" -- Decreases phys damage taken
STAT_ADF = "modifier_adf" -- Decreases magic damage taken
STAT_ADF_DOWN = "modifier_adf_down" -- Decreases magic damage taken
STAT_SPD = "modifier_spd" -- Increases AS and lowers CDs?
STAT_MOV = "modifier_mov" -- Increases MS
STAT_MAX_INCREASE = 50

SCRAFT_MINIMUM_CP = 100
MAX_CP = 200
END_OF_ROUND_LOSER_CP = 50
DAMAGE_CP_GAIN_FACTOR = 0.125
SCRAFT_CP_GAIN_FACTOR = 0.25
TARGET_CP_GAIN_FACTOR = 1/3

LinkLuaModifier(STAT_STR, "stat_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(STAT_STR_DOWN, "stat_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(STAT_ADF_DOWN, "stat_modifiers.lua", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_burn", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_insight", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_passion", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)

-- Notifications:Top((hero.combat_linked_to):GetPlayerOwner(), {text="Alisa: ", duration=2, style={color="white", ["font-size"]="26px"}})
-- Notifications:Top((hero.combat_linked_to):GetPlayerOwner(), {text="I've Got You!", style={color="green", ["font-size"]="26px"}, continue = true})

function dealDamage(target, attacker, damage, damage_type, ability, cp_gain_factor)
	if target:HasModifier("modifier_insight") and target:FindModifierByName("modifier_insight").evasion_active and damage_type == DAMAGE_TYPE_PHYSICAL then
		target:FindModifierByName("modifier_insight"):StartEvasionCooldown()
		return
	end
	if attacker then
		if damage_type == DAMAGE_TYPE_PHYSICAL and attacker:HasModifier(STAT_STR) then
			event.damage = event.damage * (1 + (attacker:FindModifierByName(STAT_STR):GetStackCount() / 100))
		end
		if damage_type == DAMAGE_TYPE_PHYSICAL and attacker:HasModifier(STAT_STR_DOWN) then
			event.damage = event.damage * (1 - (attacker:FindModifierByName(STAT_STR_DOWN):GetStackCount() / 100))
		end
		if damage_type == DAMAGE_TYPE_PHYSICAL and attacker:HasModifier("modifier_azure_flame_slash_sword_inflamed") then
			local ability = attacker:FindAbilityByName("azure_flame_slash")
			local burn_duration = ability:GetSpecialValueFor("burn_duration")
			target:AddNewModifier(attacker, ability, "modifier_burn", {duration = burn_duration})
		end
	end
	if damage_type == DAMAGE_TYPE_MAGICAL and target:HasModifier(STAT_ADF) then
		event.damage = event.damage / (1 + (target:FindModifierByName(STAT_ADF):GetStackCount() / 100))
	end
	if damage_type == DAMAGE_TYPE_MAGICAL and target:HasModifier(STAT_ADF_DOWN) then
		event.damage = event.damage / (1 - (target:FindModifierByName(STAT_ADF_DOWN):GetStackCount() / 100))
	end
	if attacker and attacker ~= target then
		grantDamageCP(event.damage, attacker, target, cp_gain_factor)
	end

	ApplyDamage({victim = target, attacker = attacker, damage = damage, damage_type = damage_type, abilityReturn = ability})
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

function trackingDash(unit, target, speed, impactFunction)
	local update_interval = 1/30
	speed = speed * update_interval

	local target_location = target:GetAbsOrigin()

	local arrival_distance = target:GetModelRadius()
	local minimum_arrival_distance = speed / 2 + 5
	if arrival_distance < minimum_arrival_distance then arrival_distance = minimum_arrival_distance end

	Timers:CreateTimer(0, function()
		if not unit:IsNull() then
			if not target:IsNull() then
				target_location = target:GetAbsOrigin()
			end
			unit_location = unit:GetAbsOrigin()
			local distance = (target_location - unit_location):Length2D()
			local direction = (target_location - unit_location):Normalized()
			unit:SetForwardVector(direction)

			if distance > arrival_distance then
				unit:SetAbsOrigin(unit_location + direction * speed)
				return update_interval
			else
				impactFunction(unit, direction, speed / update_interval, target)
				FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), false)
			end
		end
	end)
end

function modifyStat(unit, stat, percent, duration)
	if not unit:HasModifier(stat) and not unit:HasModifier(getInverseStat(stat)) then
		unit:AddNewModifier(unit, nil, stat, {duration = duration}):SetStackCount(percent)
	else
		local modifier = unit:FindModifierByName(stat)
		local inverse_modifier = unit:FindModifierByName(getInverseStat(stat))
		if modifier then
			local new_percent = modifier:GetStackCount() + percent
			modifier:SetStackCount(new_percent)
			if modifier:GetStackCount() > STAT_MAX_INCREASE then modifier:SetStackCount(STAT_MAX_INCREASE) end
			if modifier:GetRemainingTime() < duration then modifier:SetDuration(duration, true) end
		else
			local new_percent = inverse_modifier:GetStackCount() - percent
			if new_percent > 0 then
				inverse_modifier:SetStackCount(new_percent)
			else
				inverse_modifier:Destroy()
				if new_percent < 0 then
					unit:AddNewModifier(unit, nil, getInverseStat(stat), {duration = duration}):SetStackCount(new_percent)
				end
			end
		end
	end
end

function getInverseStat(stat)
	if stat == STAT_STR then
		return STAT_STR_DOWN
	elseif stat == STAT_STR_DOWN then
		return STAT_STR
	elseif stat == STAT_ADF then
		return STAT_ADF_DOWN
	elseif stat == STAT_ADF_DOWN then
		return STAT_ADF
	end
end

function getCP(unit)
	return unit:FindModifierByName("modifier_cp_tracker_cp"):GetStackCount()
end

function modifyCP(unit, amount)
	if unit:HasAbility("cp_tracker") then
		local max_cp = unit:FindAbilityByName("cp_tracker"):GetSpecialValueFor("max_cp")

		local modifier = unit:FindModifierByName("modifier_cp_tracker_cp")
		modifier:SetStackCount(modifier:GetStackCount() + math.floor(amount))
		if modifier:GetStackCount() > max_cp then modifier:SetStackCount(max_cp) end

		if amount > 1 then -- ignore incremental increases
			ParticleManager:CreateParticle("particles/items3_fx/octarine_core_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
		end

		setCraftActivatedStatus(unit)
	end
end

function grantDamageCP(damage, attacker, target, multiplier)
	local multiplier = multiplier or 1
	local attacker_cp = damage * DAMAGE_CP_GAIN_FACTOR * multiplier
	local target_cp = attacker_cp * TARGET_CP_GAIN_FACTOR
	modifyCP(attacker, attacker_cp)
	modifyCP(target, target_cp)
end

function setCraftActivatedStatus(unit)
	for i=0,unit:GetAbilityCount() - 1 do
		local ability = unit:GetAbilityByIndex(i)
		if ability and not ability:IsHidden() then
			-- ability:SetActivated(true)
			ability:SetActivated(getCP(unit) >= getCPCost(ability))
		else
			break
		end
	end
end

function validEnhancedCraft(caster, target)
	return caster:HasModifier("modifier_combat_link_followup_available") and target and target:HasModifier("modifier_combat_link_unbalanced")
end

function applyDelayCooldowns(unit, ability_cast)
	for i=0,unit:GetAbilityCount() - 1 do
		local ability = unit:GetAbilityByIndex(i)
		if ability and not ability:IsHidden() then
			ability:StartCooldown(getDelay(ability_cast))
		else
			break
		end
	end
end

if not util_ability_keyvalues then util_ability_keyvalues = LoadKeyValues("scripts/npc/npc_abilities_custom.txt") end
function getAbilityValueForKey(ability, key)
	local value = 0
	local ability_kvs = util_ability_keyvalues[ability:GetName()]
	if ability_kvs and ability_kvs[key] then
		value = ability_kvs[key]
	end
	return value
end

function getCPCost(ability)
	return getAbilityValueForKey(ability, "CPCost")
end

function getDelay(ability)
	return ability:GetCooldown(ability:GetLevel())
end
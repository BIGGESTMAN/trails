STAT_STR = "modifier_str_up" -- Increases phys damage
STAT_STR_DOWN = "modifier_str_down"
STAT_ATS = "modifier_ats_up" -- Increases magic damage
STAT_ATS_DOWN = "modifier_ats_down"
STAT_DEF = "modifier_def_up" -- Decreases phys damage taken
STAT_DEF_DOWN = "modifier_def_down"
STAT_ADF = "modifier_adf_up" -- Decreases magic damage taken
STAT_ADF_DOWN = "modifier_adf_down"
STAT_SPD = "modifier_spd_up" -- Increases AS and lowers CDs?
STAT_SPD_DOWN = "modifier_spd_down"
STAT_MOV = "modifier_mov_up" -- Increases MS
STAT_MOV_DOWN = "modifier_mov_down"
STAT_MAX_INCREASE = 50

SCRAFT_MINIMUM_CP = 100
MAX_CP = 200
END_OF_ROUND_LOSER_CP = 50
DAMAGE_CP_GAIN_FACTOR = 0.125
SCRAFT_CP_GAIN_FACTOR = 0.25
TARGET_CP_GAIN_FACTOR = 1/3

CRIT_DAMAGE_FACTOR = 2

LinkLuaModifier(STAT_STR, "stat_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(STAT_ATS, "stat_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(STAT_DEF, "stat_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(STAT_ADF, "stat_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(STAT_SPD, "stat_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(STAT_MOV, "stat_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(STAT_STR_DOWN, "stat_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(STAT_ADF_DOWN, "stat_modifiers.lua", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_burn", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_insight", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_passion", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_freeze", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_confuse", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nightmare", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_crit", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_brute_force", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_link_broken", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)

-- Notifications:Top((hero.combat_linked_to):GetPlayerOwner(), {text="Alisa: ", duration=2, style={color="white", ["font-size"]="26px"}})
-- Notifications:Top((hero.combat_linked_to):GetPlayerOwner(), {text="I've Got You!", style={color="green", ["font-size"]="26px"}, continue = true})

function dealDamage(target, attacker, damage, damage_type, cp_gain_factor)
	if target:HasModifier("modifier_insight") and target:FindModifierByName("modifier_insight").evasion_active and damage_type == DAMAGE_TYPE_PHYSICAL then
		target:FindModifierByName("modifier_insight"):StartEvasionCooldown()
		return
	end
	if attacker then
		if damage_type == DAMAGE_TYPE_PHYSICAL and attacker:HasModifier("modifier_azure_flame_slash_sword_inflamed") then
			local ability = attacker:FindAbilityByName("azure_flame_slash")
			local burn_duration = ability:GetSpecialValueFor("burn_duration")
			target:AddNewModifier(attacker, ability, "modifier_burn", {duration = burn_duration})
		end
	end
	if target.stats then
		if damage_type == DAMAGE_TYPE_PHYSICAL then
			damage = damage * getDamageMultiplier(getStats(target).def)
		elseif damage_type == DAMAGE_TYPE_MAGICAL then
			damage = damage * getDamageMultiplier(getStats(target).adf)
		end
	end
	if attacker and attacker ~= target then
		grantDamageCP(damage, attacker, target, cp_gain_factor)
	end

	ApplyDamage({victim = target, attacker = attacker, damage = damage, damage_type = damage_type})
end

function dealScalingDamage(target, attacker, damage_type, scale, cp_gain_factor)
	if damage_type == DAMAGE_TYPE_PHYSICAL then
		dealDamage(target, attacker, scale * getStats(attacker).str, damage_type, cp_gain_factor)
	elseif damage_type == DAMAGE_TYPE_MAGICAL then
		dealDamage(target, attacker, scale * getStats(attacker).ats, damage_type, cp_gain_factor)
	end
end

function getDamageMultiplier(resist)
	local resist = resist - 100
	if resist > 0 then
		return 1 / (resist / 100)
	elseif resist < 0 then
		return 1 * (1 + math.abs(resist) / 100)
	else
		return 1
	end
end

function dash(unit, direction, speed, range, find_clear_space, impactFunction, other_args)
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
				if impactFunction then impactFunction(unit, direction, speed / update_interval, range, find_clear_space, other_args) end
			end
		end
	end)
end

function trackingDash(unit, target, speed, impactFunction, other_args)
	other_args = other_args or {}

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
				impactFunction(unit, direction, speed / update_interval, target, other_args)
				FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), false)
			end
		end
	end)
end

if not gamefunctions_hero_keyvalues then gamefunctions_hero_keyvalues = LoadKeyValues("scripts/npc/npc_heroes_custom.txt") end
function getHeroValueForKey(hero, key)
	local value = 0
	local hero_kvs = gamefunctions_hero_keyvalues[getCustomHeroName(hero:GetName())]
	if hero_kvs and hero_kvs[key] then
		value = hero_kvs[key]
	end
	return value
end

function getCustomHeroName(name)
	local custom_name = nil
	if name == "npc_dota_hero_windrunner" then
		custom_name = "npc_dota_hero_alisa"
	elseif name == "npc_dota_hero_ember_spirit" then
		custom_name = "npc_dota_hero_rean"
	elseif name == "npc_dota_hero_sniper" then
		custom_name = "npc_dota_hero_crow"
	end
	return custom_name
end

function initializeStats(hero)
	hero.stats = {
		str = getHeroValueForKey(hero, "Str"),
		ats = getHeroValueForKey(hero, "Ats"),
		def = getHeroValueForKey(hero, "Def"),
		adf = getHeroValueForKey(hero, "Adf"),
		spd = getHeroValueForKey(hero, "Spd"),
		mov = hero:GetBaseMoveSpeed()
	}
end

function getStats(hero)
	local stats = copyOfTable(hero.stats)
	if hero:HasModifier(STAT_STR) then stats.str = stats.str * (1 + hero:FindModifierByName(STAT_STR):GetStackCount() / 100) end
	if hero:HasModifier(STAT_STR_DOWN) then stats.str = stats.str * (1 - hero:FindModifierByName(STAT_STR_DOWN):GetStackCount() / 100) end
	if hero:HasModifier(STAT_DEF) then stats.def = stats.def * (1 + hero:FindModifierByName(STAT_DEF):GetStackCount() / 100) end
	if hero:HasModifier(STAT_DEF_DOWN) then stats.def = stats.def * (1 - hero:FindModifierByName(STAT_DEF_DOWN):GetStackCount() / 100) end
	if hero:HasModifier(STAT_ATS) then stats.ats = stats.ats * (1 + hero:FindModifierByName(STAT_ATS):GetStackCount() / 100) end
	if hero:HasModifier(STAT_ATS_DOWN) then stats.ats = stats.ats * (1 - hero:FindModifierByName(STAT_ATS_DOWN):GetStackCount() / 100) end
	if hero:HasModifier(STAT_ADF) then stats.adf = stats.adf * (1 + hero:FindModifierByName(STAT_ADF):GetStackCount() / 100) end
	if hero:HasModifier(STAT_ADF_DOWN) then stats.adf = stats.adf * (1 - hero:FindModifierByName(STAT_ADF_DOWN):GetStackCount() / 100) end
	if hero:HasModifier(STAT_SPD) then stats.spd = stats.spd + hero:FindModifierByName(STAT_SPD):GetStackCount() end
	if hero:HasModifier(STAT_SPD_DOWN) then stats.spd = stats.spd - hero:FindModifierByName(STAT_SPD_DOWN):GetStackCount() end
	if hero:HasModifier(STAT_MOV) then stats.mov = stats.mov * (1 + hero:FindModifierByName(STAT_MOV):GetStackCount() / 100) end
	if hero:HasModifier(STAT_MOV_DOWN) then stats.mov = stats.mov * (1 - hero:FindModifierByName(STAT_SPD_DOWN):GetStackCount() / 100) end
	return stats
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
	elseif stat == STAT_DEF then
		return STAT_DEF_DOWN
	elseif stat == STAT_DEF_DOWN then
		return STAT_DEF
	elseif stat == STAT_ATS then
		return STAT_ATS_DOWN
	elseif stat == STAT_ATS_DOWN then
		return STAT_ATS
	elseif stat == STAT_ADF then
		return STAT_ADF_DOWN
	elseif stat == STAT_ADF_DOWN then
		return STAT_ADF
	elseif stat == STAT_SPD then
		return STAT_SPD_DOWN
	elseif stat == STAT_SPD_DOWN then
		return STAT_SPD
	elseif stat == STAT_MOV then
		return STAT_MOV_DOWN
	elseif stat == STAT_MOV_DOWN then
		return STAT_MOV
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

function applyRandomDebuff(target, caster, duration, not_sleep_debuff)
	local debuffs = 					{"modifier_burn", "modifier_freeze", "modifier_confuse", "modifier_nightmare"}
	if not_sleep_debuff then debuffs = 	{"modifier_burn", "modifier_freeze", "modifier_confuse"} end
	local debuff = debuffs[RandomInt(1,#debuffs)]
	target:AddNewModifier(caster, nil, debuff, {duration = duration})
end

function inflictDelay(unit, amount)
	local amount = amount * (1 - getStats(unit).spd / 100)

	for i=0,unit:GetAbilityCount() - 1 do
		local ability = unit:GetAbilityByIndex(i)
		if ability and not ability:IsHidden() then
			ability:StartCooldown(amount + ability:GetCooldownTimeRemaining())
		else
			break
		end
	end
end

function applyDelayCooldowns(unit, ability)
	ability:EndCooldown()
	inflictDelay(unit, ability:GetCooldown(ability:GetLevel()))
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
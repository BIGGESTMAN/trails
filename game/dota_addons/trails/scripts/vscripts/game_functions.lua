require "round_recap"
require "libraries/util"

HERO_NAMES = {{"npc_dota_hero_windrunner", "npc_dota_hero_alisa"},
				{"npc_dota_hero_ember_spirit", "npc_dota_hero_rean"},
				{"npc_dota_hero_sniper", "npc_dota_hero_crow"},
				{"npc_dota_hero_omniknight", "npc_dota_hero_millium"}}

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
CRAFT_CP_GAIN_FACTOR = 0.25
SCRAFT_CP_GAIN_FACTOR = 0.25
TARGET_CP_GAIN_FACTOR = 1/3
CP_BOOST_GAIN_FACTOR = 1.5
PASSION_CP_PER_SECOND = 5

FREEZE_COMMAND_DELAY = 0.6
CRIT_DAMAGE_FACTOR = 2
FAINT_DAMAGE_FACTOR = 1.5
BALANCE_DOWN_UNBALANCE_FACTOR = 1.5

LINK_SKILL_SCALING_RANGE = 700
LINK_SKILL_SCALING_FACTOR = 0.5

LOW_HP_THRESHOLD_PERCENT = 20
SCRAFTS_REQUIRE_UNBALANCE = false

LinkLuaModifier("modifier_base_mov_buff", "modifier_base_mov_buff.lua", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier(STAT_STR, "stat_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(STAT_ATS, "stat_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(STAT_DEF, "stat_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(STAT_ADF, "stat_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(STAT_SPD, "stat_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(STAT_MOV, "stat_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(STAT_STR_DOWN, "stat_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(STAT_ATS_DOWN, "stat_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(STAT_DEF_DOWN, "stat_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(STAT_ADF_DOWN, "stat_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(STAT_SPD_DOWN, "stat_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(STAT_MOV_DOWN, "stat_modifiers.lua", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_seal", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mute", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_burn", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_insight", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_passion", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_freeze", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_confuse", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nightmare", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_deathblow", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_cp_boost", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_petrify", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_faint", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_intimidate", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_balance_down", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_physical_guard", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_magical_guard", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_guard_high_priority", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_crit", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_zero_arts", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_brute_force", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_link_broken", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_unshatterable_bonds", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)

-- Notifications:Top((hero.combat_linked_to):GetPlayerOwner(), {text="Alisa: ", duration=2, style={color="white", ["font-size"]="26px"}})
-- Notifications:Top((hero.combat_linked_to):GetPlayerOwner(), {text="I've Got You!", style={color="green", ["font-size"]="26px"}, continue = true})

function applyEffect(target, damage_type, effect)
	if IsValidAlive(target) then
		if target:HasModifier("modifier_guard_high_priority") and (damage_type == DAMAGE_TYPE_PHYSICAL or damage_type == DAMAGE_TYPE_MAGICAL) then
			return
		elseif target:HasModifier("modifier_physical_guard") and damage_type == DAMAGE_TYPE_PHYSICAL then
			target:RemoveModifierByName("modifier_physical_guard")
		elseif target:HasModifier("modifier_magical_guard") and damage_type == DAMAGE_TYPE_MAGICAL then
			target:RemoveModifierByName("modifier_magical_guard")
		else
			effect()
		end
	end
end

function dealDamage(target, attacker, damage, damage_type, ability, cp_gain_factor, enhanced, status)
	if target:GetUnitName() == "npc_dummy_unit_vulnerable" then
		if not status and target.freezingBulletWallShatter then target:freezingBulletWallShatter(target, attacker) end
		return
	end
	if target.combat_linked_to and target.combat_linked_to:HasModifier("modifier_master_force_passive") and pointIsBetweenPoints(target.combat_linked_to:GetAbsOrigin(), target:GetAbsOrigin(), attacker:GetAbsOrigin()) then
		local cover_damage_percent = getMasterQuartzSpecialValue(target.combat_linked_to, "cover_damage_reduction") / 100
		if cover_damage_percent > 0 then
			dealDamage(target.combat_linked_to, attacker, cover_damage_percent * damage, damage_type, ability, cp_gain_factor)
			damage = damage * (1 - cover_damage_percent)
			target.combat_linked_to:FindModifierByName("modifier_master_force_passive"):CreateCoverParticles(attacker:GetAbsOrigin())
		end
	end
	if target:HasModifier("modifier_insight") and target:FindModifierByName("modifier_insight").evasion_active and damage_type == DAMAGE_TYPE_PHYSICAL then
		target:FindModifierByName("modifier_insight"):StartEvasionCooldown()
		return
	end
	if target:HasModifier("modifier_petrify") and damage_type == DAMAGE_TYPE_MAGICAL then
		return
	end
	if target:HasModifier("modifier_faint") then
		damage = damage * FAINT_DAMAGE_FACTOR
	end
	if enhanced and attacker:HasModifier("modifier_master_force_passive") and target:GetHealthPercent() <= LOW_HP_THRESHOLD_PERCENT then
		damage = damage * (1 + getMasterQuartzSpecialValue(attacker, "finishing_blow_damage_bonus") / 100)
	end
	if attacker then
		if damage_type == DAMAGE_TYPE_PHYSICAL and attacker:HasModifier("modifier_azure_flame_slash_sword_inflamed") then
			local flame_slash_ability = attacker:FindAbilityByName("azure_flame_slash")
			local burn_duration = flame_slash_ability:GetSpecialValueFor("burn_duration")
			target:AddNewModifier(attacker, flame_slash_ability, "modifier_burn", {duration = burn_duration})
		end
	end
	if target.stats then
		if damage_type == DAMAGE_TYPE_PHYSICAL then
			damage = damage * getDamageMultiplier(getStats(target).def)
		elseif damage_type == DAMAGE_TYPE_MAGICAL then
			damage = damage * getDamageMultiplier(getStats(target).adf)
		end
	end
	if target:HasModifier("modifier_rapid_volley_casting") and ability and not status then
		target:RemoveModifierByName("modifier_rapid_volley_casting")
	end
	if target:HasModifier("modifier_chaos_trigger_casting") and ability and not status then
		target:RemoveModifierByName("modifier_chaos_trigger_casting")
	end
	if attacker and attacker ~= target then
		grantDamageCP(damage, attacker, target, cp_gain_factor)
	end

	ApplyDamage({victim = target, attacker = attacker, damage = damage, damage_type = damage_type})
	Round_Recap:AddAbilityDamage(attacker, ability, damage)
end

function dealScalingDamage(target, attacker, damage_type, scale, ability, cp_gain_factor, enhanced)
	if damage_type == DAMAGE_TYPE_PHYSICAL then
		dealDamage(target, attacker, scale * getStats(attacker).str, damage_type, ability, cp_gain_factor, enhanced)
	elseif damage_type == DAMAGE_TYPE_MAGICAL then
		dealDamage(target, attacker, scale * getStats(attacker).ats, damage_type, ability, cp_gain_factor, enhanced)
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
	other_args = other_args or {}
	other_args.range = range
	other_args.find_clear_space = find_clear_space

	local collision_rules = other_args.collision_rules
	local collisionFunction = other_args.collisionFunction
	local cannot_collide_with = other_args.cannot_collide_with or {}
	local units_hit = {}

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

				-- Check for unit collisions
				if collisionFunction and collision_rules then
					collision_rules["origin"] = unit:GetAbsOrigin()
					local targets = FindUnitsInRadiusTable(collision_rules)
					for k,target in pairs(targets) do
						if target ~= unit and not cannot_collide_with[target] and not units_hit[target] then
							collisionFunction(target, unit, direction, other_args)
							units_hit[target] = true
						end
					end
				end
				return update_interval
			else
				if find_clear_space then FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), false) end
				if impactFunction then impactFunction(unit, direction, speed / update_interval, other_args) end
			end
		end
	end)
end

function trackingDash(unit, target, speed, impactFunction, other_args)
	other_args = other_args or {}
	other_args.target = target

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
				impactFunction(unit, direction, speed / update_interval, other_args)
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
	for k,names in pairs(HERO_NAMES) do
		if names[1] == name then
			return names[2]
		end
	end
	return nil
end

function getDotaHeroName(name)
	for k,names in pairs(HERO_NAMES) do
		if names[2] == name then
			return names[1]
		end
	end
	return nil
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
	hero:AddNewModifier(hero, nil, "modifier_base_mov_buff", {})
	game_mode:initializeStats(hero)
end

function getStats(hero)
	local stats = copyOfTable(hero.stats)
	stats = getQuartzAdjustedStats(hero, stats)
	stats = getModifierAdjustedStats(hero, stats)
	stats = getDatadrivenModifierAdjustedStats(hero, stats)
	stats = getLuaModifierAdjustedStats(hero, stats)
	return stats
end

function getQuartzAdjustedStats(hero, stats)
	for i=0,5 do
		local quartz = hero:GetItemInSlot(i)
		if quartz then
			stats.str = stats.str + quartz:GetSpecialValueFor("bonus_str")
			stats.def = stats.def + quartz:GetSpecialValueFor("bonus_def")
			stats.ats = stats.ats + quartz:GetSpecialValueFor("bonus_ats")
			stats.adf = stats.adf + quartz:GetSpecialValueFor("bonus_adf")
			stats.spd = stats.spd + quartz:GetSpecialValueFor("bonus_spd")
			stats.mov = stats.mov + quartz:GetSpecialValueFor("bonus_mov")
		end
	end
	return stats
end

function getModifierAdjustedStats(hero, stats)
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
	if hero:HasModifier(STAT_MOV_DOWN) then stats.mov = stats.mov * (1 - hero:FindModifierByName(STAT_MOV_DOWN):GetStackCount() / 100) end
	return stats
end

function getDatadrivenModifierAdjustedStats(hero, stats)
	for k,modifier in pairs(hero:FindAllModifiers()) do
		local modifier_kvs = getDatadrivenModifierKVs(modifier)
		if modifier_kvs then
			stats.str = stats.str + (modifier_kvs["BonusStr"] or 0)
			stats.def = stats.def + (modifier_kvs["BonusDef"] or 0)
			stats.ats = stats.ats + (modifier_kvs["BonusAts"] or 0)
			stats.adf = stats.adf + (modifier_kvs["BonusAdf"] or 0)
			stats.spd = stats.spd + (modifier_kvs["BonusSpd"] or 0)
			stats.mov = stats.mov + (modifier_kvs["BonusMov"] or 0)
		end
	end
	return stats
end

function getLuaModifierAdjustedStats(hero, stats)
	for k,modifier in pairs(hero:FindAllModifiers()) do
		if modifier.GetUniqueStatModifiers then
			local stat_modifiers = modifier:GetUniqueStatModifiers()
			stats.str = stats.str + (stat_modifiers["BonusStr"] or 0)
			stats.def = stats.def + (stat_modifiers["BonusDef"] or 0)
			stats.ats = stats.ats + (stat_modifiers["BonusAts"] or 0)
			stats.adf = stats.adf + (stat_modifiers["BonusAdf"] or 0)
			stats.spd = stats.spd + (stat_modifiers["BonusSpd"] or 0)
			stats.mov = stats.mov + (stat_modifiers["BonusMov"] or 0)
		end
	end
	return stats
end

function modifyStat(unit, stat, percent, duration)
	if not unit:HasModifier(stat) and not unit:HasModifier(getInverseStat(stat)) then
		local modifier = unit:AddNewModifier(unit, nil, stat, {duration = duration})
		modifier:SetStackCount(percent)
		if modifier:GetStackCount() > STAT_MAX_INCREASE then modifier:SetStackCount(STAT_MAX_INCREASE) end
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
					local modifier = unit:AddNewModifier(unit, nil, getInverseStat(stat), {duration = duration})
					modifier:SetStackCount(new_percent)
					if modifier:GetStackCount() > STAT_MAX_INCREASE then modifier:SetStackCount(STAT_MAX_INCREASE) end
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
	return unit:FindModifierByName("modifier_cp_tracker_cp").cp
end

function modifyCP(unit, amount)
	if unit:HasAbility("cp_tracker") then
		if unit:HasModifier("modifier_cp_boost") then amount = amount * CP_BOOST_GAIN_FACTOR end
		if unit:HasModifier("modifier_intimidate") and amount > 0 then amount = 0 end
		
		local max_cp = unit:FindAbilityByName("cp_tracker"):GetSpecialValueFor("max_cp")

		local modifier = unit:FindModifierByName("modifier_cp_tracker_cp")
		modifier.cp = modifier.cp + amount
		if modifier.cp > max_cp then modifier.cp = max_cp end

		if amount > 1 then -- ignore incremental increases
			ParticleManager:CreateParticle("particles/items3_fx/octarine_core_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
		end

		modifier:SetStackCount(math.floor(modifier.cp))
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
	local debuffs = 					{"modifier_seal", "modifier_mute", "modifier_burn", "modifier_freeze", "modifier_confuse", "modifier_deathblow", "modifier_petrify", "modifier_faint", "modifier_intimidate", "modifier_nightmare"}
	if not_sleep_debuff then debuffs = 	{"modifier_seal", "modifier_mute", "modifier_burn", "modifier_freeze", "modifier_confuse", "modifier_deathblow", "modifier_petrify", "modifier_faint", "modifier_intimidate"} end
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

function getAbilityCPCosts(hero)
	local cp_costs = {}
	for i=0,hero:GetAbilityCount() - 1 do
		local ability = hero:GetAbilityByIndex(i)
		if ability and not ability:IsHidden() then
			cp_costs[i] = getCPCost(ability)
		else
			break
		end
	end
	return cp_costs
end

function LoadModifierKeyValues()
	local modifiers = {}
	for k,ability in pairs(util_ability_keyvalues) do
		if ability ~= 1 and ability["Modifiers"] then -- fucking "Version" "1"
			for modifier_name, modifier in pairs(ability["Modifiers"]) do
				modifiers[modifier_name] = modifier
			end
		end
	end
	return modifiers
end

if not gamefuncs_modifier_keyvalues then gamefuncs_modifier_keyvalues = LoadModifierKeyValues() end
function getDatadrivenModifierKVs(modifier)
	return gamefuncs_modifier_keyvalues[modifier:GetName()]
end

function getAllHeroes()
	local heroes = {}
	local player_count = PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS) + PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_BADGUYS)
	for i = 0, player_count - 1 do
		table.insert(heroes, PlayerResource:GetPlayer(i):GetAssignedHero())
	end
	return heroes
end

function triggerModifierEvent(event_name, args)
	local modifier_function = nil

	for k,hero in pairs(getAllHeroes()) do
		for k,modifier in pairs(hero:FindAllModifiers()) do
			if event_name == "unit_unbalanced" then
				if modifier.UnitUnbalanced then
					modifier:UnitUnbalanced(args)
				end
			elseif event_name == "round_started" then
				if modifier.RoundStarted then
					modifier:RoundStarted(args)
				end
			end
		end
	end
end

function getMasterQuartzSpecialValue(hero, value_name, master_quartz)
	master_quartz = master_quartz or getMasterQuartz(hero)
	local base_value = master_quartz:GetSpecialValueFor(value_name)
	if hero.combat_linked_to then
		base_value = base_value * getHeroLinkScaling(hero)
	else
		base_value = 0
	end
	return base_value
end

function getHeroLinkScaling(hero)
	local distance = (hero:GetAbsOrigin() - hero.combat_linked_to:GetAbsOrigin()):Length2D()
	if distance > LINK_SKILL_SCALING_RANGE and not hero:HasModifier("modifier_unshatterable_bonds") then
		return LINK_SKILL_SCALING_FACTOR
	else
		return 1
	end
end

function getMasterQuartz(hero)
	local master_quartz = nil
	for i=0, 5 do
		if hero:GetItemInSlot(i) and not hero:GetItemInSlot(i):IsPurchasable() then
			master_quartz = hero:GetItemInSlot(i)
			break
		end
	end
	return master_quartz
end

function getOpposingTeam(team)
	if team == DOTA_TEAM_GOODGUYS then
		return DOTA_TEAM_BADGUYS
	elseif team == DOTA_TEAM_BADGUYS then
		return DOTA_TEAM_GOODGUYS
	end
	return nil
end
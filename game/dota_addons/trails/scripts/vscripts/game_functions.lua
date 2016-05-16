require "round_recap"
require "libraries/util"
require "damage_numbers"

HERO_NAMES = {{"npc_dota_hero_windrunner", "npc_dota_hero_alisa"},
				{"npc_dota_hero_ember_spirit", "npc_dota_hero_rean"},
				{"npc_dota_hero_sniper", "npc_dota_hero_crow"},
				{"npc_dota_hero_legion_commander", "npc_dota_hero_estelle"},
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

ONE_HIT_UNBALANCE = false

CP_COSTS_MODE_NORMAL = 0
CP_COSTS_MODE_NONE = 1
CP_COSTS_MODE_DECAYING = 2
CP_COSTS_MODE = CP_COSTS_MODE_DECAYING
CP_COSTS_DECAY_TIME_FACTOR = 5 -- multiplied by ability's Delay to get total time until cost reverts

COOLDOWNS_MODE_SHARED = 0
COOLDOWNS_MODE_INDIVIDUAL = 1
COOLDOWNS_MODE = COOLDOWNS_MODE_SHARED

SCRAFT_MINIMUM_CP = 100
MAX_CP = 200
END_OF_ROUND_LOSER_CP = 0
DAMAGE_CP_GAIN_FACTOR = 0.125
CRAFT_CP_GAIN_FACTOR = 0.25
SCRAFT_CP_GAIN_FACTOR = 0.25
TARGET_CP_GAIN_FACTOR = 1/3
CP_BOOST_GAIN_FACTOR = 1.5
PASSION_CP_PER_SECOND = 5
HP_REGEN_HEALTH_PERCENT_PER_SECOND = 3

CRIT_DAMAGE_FACTOR = 2
FAINT_DAMAGE_FACTOR = 1.5
BALANCE_DOWN_UNBALANCE_FACTOR = 1.5

LINK_SKILL_SCALING_RANGE = 600
LINK_SKILL_SCALING_FACTOR = 0.5

LOW_HP_THRESHOLD_PERCENT = 20
SCRAFTS_REQUIRE_UNBALANCE = false

PURGABLE_BUFFS = {}
PURGABLE_BUFFS["modifier_go_ape_stat_buff"] = true
PURGABLE_BUFFS["modifier_go_bananas"] = true
PURGABLE_BUFFS["modifier_stridulate"] = true

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
LinkLuaModifier("modifier_hp_regen", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_freeze", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_confuse", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sleep", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nightmare", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_deathblow", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_cp_boost", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_petrify", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_faint", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_intimidate", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sear", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
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
		if (target:HasModifier("modifier_guard_high_priority") or target:HasModifier("modifier_aegis_last_bastion")) and (damage_type == DAMAGE_TYPE_PHYSICAL or damage_type == DAMAGE_TYPE_MAGICAL) then
			triggerModifierEvent(target, "guard_triggered", {})
			return
		elseif target:HasModifier("modifier_physical_guard") and damage_type == DAMAGE_TYPE_PHYSICAL then
			triggerModifierEvent(target, "guard_triggered", {})
			target:RemoveModifierByName("modifier_physical_guard")
		elseif target:HasModifier("modifier_magical_guard") and damage_type == DAMAGE_TYPE_MAGICAL then
			triggerModifierEvent(target, "guard_triggered", {})
			target:RemoveModifierByName("modifier_magical_guard")
		else
			effect()
		end
	end
end

function dealDamage(target, attacker, damage, damage_type, ability, cp_gain_factor, enhanced, status, bonus_unbalance, args)
	args = args or {}

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
	if target:HasModifier("modifier_faint") or target:HasModifier("modifier_sleep") or target:HasModifier("modifier_nightmare") then
		damage = damage * FAINT_DAMAGE_FACTOR
	end
	if target:HasModifier("modifier_aegis_counterattack") and attacker == target:FindModifierByName("modifier_aegis_counterattack"):GetCaster() then
		damage = damage * (1 + getMasterQuartzSpecialValue(attacker, "counterattack_damage_bonus") / 100)
	end
	if target:HasModifier("modifier_cypher_counterattack") and attacker == target:FindModifierByName("modifier_cypher_counterattack"):GetCaster() then
		damage = damage * (1 + getMasterQuartzSpecialValue(attacker, "counterattack_damage_bonus") / 100)
	end
	if enhanced and attacker:HasModifier("modifier_master_force_passive") and target:GetHealthPercent() <= LOW_HP_THRESHOLD_PERCENT then
		damage = damage * (1 + getMasterQuartzSpecialValue(attacker, "finishing_blow_damage_bonus") / 100)
	end
	if attacker then -- pls move this to a lua modifier, pls
		if damage_type == DAMAGE_TYPE_PHYSICAL and attacker:HasModifier("modifier_azure_flame_slash_sword_inflamed") then
			local flame_slash_ability = attacker:FindAbilityByName("azure_flame_slash")
			local burn_duration = flame_slash_ability:GetSpecialValueFor("burn_duration")
			target:AddNewModifier(attacker, flame_slash_ability, "modifier_burn", {duration = burn_duration})
		end
	end
	damage = damage * getDamageMultiplierForType(target, damage_type)
	if target:HasModifier("modifier_rapid_volley_casting") and ability and not status then
		target:RemoveModifierByName("modifier_rapid_volley_casting")
	end
	if target:HasModifier("modifier_chaos_trigger_casting") and ability and not status then
		target:RemoveModifierByName("modifier_chaos_trigger_casting")
	end
	if target:HasModifier("modifier_sear") and not args.sear_damage then
		target:FindModifierByName("modifier_sear"):DealSearDamage()
	end
	if attacker:HasModifier("modifier_cypher_gambling_strike") and attacker.combat_linked_to and ability and not status and ability:GetName():find("item_") then -- janky checks to see if damage is from an art
		attacker:FindModifierByName("modifier_cypher_gambling_strike"):DealGamblingDamage()
	end
	if attacker:HasModifier("modifier_cypher_gambling_magic") and attacker.combat_linked_to and ability and not status and not ability:GetName():find("item_") then
		attacker:FindModifierByName("modifier_cypher_gambling_magic"):DealGamblingDamage()
	end
	if target:HasModifier("modifier_heavenly_gift_enemy") then
		target:FindModifierByName("modifier_heavenly_gift_enemy"):GrantDamageCP(damage, attacker)
	end
	if GameMode:IsPvPGamemode() and attacker and attacker:HasAbility("combat_link") and attacker ~= target and not enhanced and not status then
		grantDamageCP(damage, attacker, target, cp_gain_factor)
		increaseUnbalance(attacker, target, bonus_unbalance)
	end
	
	ApplyDamage({victim = target, attacker = attacker, damage = damage, damage_type = damage_type})
	Round_Recap:AddAbilityDamage(attacker, ability, damage)
	PopupDamageNumbers(attacker, target, damage)
end

function dealScalingDamage(target, attacker, damage_type, scale, ability, cp_gain_factor, enhanced, status, bonus_unbalance, args)
	if damage_type == DAMAGE_TYPE_PHYSICAL then
		dealDamage(target, attacker, scale * getStats(attacker).str, damage_type, ability, cp_gain_factor, enhanced, status, bonus_unbalance, args)
	elseif damage_type == DAMAGE_TYPE_MAGICAL then
		dealDamage(target, attacker, scale * getStats(attacker).ats, damage_type, ability, cp_gain_factor, enhanced, status, bonus_unbalance, args)
	end
end

function getDamageMultiplierForType(unit, damage_type)
	local multiplier = 1
	if unit.stats then
		if damage_type == DAMAGE_TYPE_PHYSICAL then
			multiplier = getDamageMultiplier(getStats(unit).def)
		elseif damage_type == DAMAGE_TYPE_MAGICAL then
			multiplier = getDamageMultiplier(getStats(unit).adf)
		end
	end
	return multiplier
end

function getDamageMultiplier(resist)
	if resist > 0 then
		return 1 / ((resist + 100) / 100)
	elseif resist < 0 then
		return 1 + math.abs(resist) / 100
	else
		return 1
	end
end

function applyHealing(target, source, healing)
	if target:HasModifier("modifier_angel_quick_thelas_heal_increase") then
		healing = healing * target:FindModifierByName("modifier_angel_quick_thelas_heal_increase"):GetHealingRecievedMultiplier()
	end
	target:Heal(healing, source)
end

function purgePositiveBuffs(target)
	local modifiers_to_purge = {}
	for k,modifier in pairs(target:FindAllModifiers()) do
		if PURGABLE_BUFFS[modifier:GetName()] then
			table.insert(modifiers_to_purge, modifier)
		end
	end

	local count = #modifiers_to_purge
	for k,modifier in pairs(modifiers_to_purge) do
		modifier:Destroy()
	end
	return count
end

function applyImpede(target, source)
	if target:IsChanneling() then
		CPRewards:RewardCP(source, target)
	end
	target:InterruptChannel()
end

function rangedAttackLaunched(origin, target, speed)
	if not origin:HasModifier("modifier_judgment_arrow_empowered") then
		ProjectileList:CreateTrackingProjectile(origin, target, speed)
	else
		origin:FindModifierByName("modifier_judgment_arrow_empowered"):FireHolyArrow(target)
	end
end

function dash(unit, direction, speed, range, find_clear_space, impactFunction, other_args)
	other_args = other_args or {}
	other_args.range = range
	other_args.find_clear_space = find_clear_space

	local collision_rules = other_args.collision_rules
	local collisionFunction = other_args.collisionFunction
	local cannot_collide_with = other_args.cannot_collide_with or {}
	other_args.units_hit = {}

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
						if target ~= unit and not cannot_collide_with[target] and not other_args.units_hit[target] then
							collisionFunction(target, unit, direction, other_args)
							other_args.units_hit[target] = true
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

if not gamefunctions_unit_keyvalues then gamefunctions_unit_keyvalues = mergeTables(LoadKeyValues("scripts/npc/npc_heroes_custom.txt"), LoadKeyValues("scripts/npc/npc_units_custom.txt")) end
function getUnitValueForKey(unit, key)
	local value = 0
	local unit_name = unit:GetUnitName()
	if unit:IsHero() then unit_name = getCustomHeroName(unit:GetName()) end
	local unit_kvs = gamefunctions_unit_keyvalues[unit_name]
	if unit_kvs and unit_kvs[key] then
		value = unit_kvs[key]
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

function initializeStats(unit)
	unit.stats = {
		str = getUnitValueForKey(unit, "Str"),
		ats = getUnitValueForKey(unit, "Ats"),
		def = getUnitValueForKey(unit, "Def"),
		adf = getUnitValueForKey(unit, "Adf"),
		spd = getUnitValueForKey(unit, "Spd"),
		mov = unit:GetBaseMoveSpeed(),
		hp = getUnitValueForKey(unit, "StatusHealth"),
		ep = getUnitValueForKey(unit, "StatusMana"),
	}
	unit:AddNewModifier(unit, nil, "modifier_base_mov_buff", {}) -- NOTE: misleadingly named; also governs base hp and mana increases (and causes autoattack damage now, too; what a modifier)
	game_mode:initializeStats(unit)
	if unit:IsHero() then
		updateHPAndMana(unit)
	end
end

function updateHPAndMana(hero)
	-- this seems dumb but whatever yolo
	Timers:CreateTimer(0, function()
		hero:CalculateStatBonus()
		return 1/30
	end)
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
			stats.hp = stats.hp + quartz:GetSpecialValueFor("bonus_health")
			stats.ep = stats.ep + quartz:GetSpecialValueFor("bonus_ep")
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
			stats.str = stats.str + (modifier_kvs["BonusStr"] or 0) * modifier:GetStackCount()
			stats.def = stats.def + (modifier_kvs["BonusDef"] or 0) * modifier:GetStackCount()
			stats.ats = stats.ats + (modifier_kvs["BonusAts"] or 0) * modifier:GetStackCount()
			stats.adf = stats.adf + (modifier_kvs["BonusAdf"] or 0) * modifier:GetStackCount()
			stats.spd = stats.spd + (modifier_kvs["BonusSpd"] or 0) * modifier:GetStackCount()
			stats.mov = stats.mov + (modifier_kvs["BonusMov"] or 0) * modifier:GetStackCount()
			stats.hp = stats.hp + (modifier_kvs["BonusHP"] or 0) * modifier:GetStackCount()
			stats.ep = stats.ep + (modifier_kvs["BonusEP"] or 0) * modifier:GetStackCount()
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
			stats.hp = stats.hp + (stat_modifiers["BonusHP"] or 0)
			stats.ep = stats.ep + (stat_modifiers["BonusEP"] or 0)
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

function getStatModifierName(stat, inverse)
	if not inverse then
		return "modifier_"..stat.."_up"
	else
		return "modifier_"..stat.."_down"
	end
	-- return (stat.sub(string.len("modifier_"), string.len("modifier_") + 3))
end

function getCP(unit)
	return unit:FindModifierByName("modifier_cp_tracker_cp").cp
end

function modifyCP(unit, amount)
	if unit:HasAbility("cp_tracker") and not unit:HasModifier("modifier_interround_invulnerability") then
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

function spendCP(unit, ability)
	modifyCP(unit, getCPCost(ability) * -1)
	if CP_COSTS_MODE == CP_COSTS_MODE_DECAYING then
		ability.current_cp_cost = ability.max_cp_cost
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
	for k,ability in pairs(getAllActiveAbilities(unit)) do
		ability:SetActivated(getCP(unit) >= getCPCost(ability) and getCP(unit) >= getAbilityValueForKey(ability, "CPCost"))
	end
end

function validEnhancedCraft(caster, target, require_target)
	return caster:HasModifier("modifier_combat_link_followup_available") and (not require_target or target)
end

function executeEnhancedCraft(caster)
	caster:RemoveModifierByName("modifier_combat_link_followup_available")
	triggerModifierEventOnAll("enhanced_craft_used", {unit = caster})
end

function applyRandomDebuff(target, caster, duration, not_sleep_debuff)
	local debuffs = 					{"modifier_seal", "modifier_mute", "modifier_burn", "modifier_freeze", "modifier_confuse", "modifier_deathblow", "modifier_petrify", "modifier_faint", "modifier_intimidate", "modifier_nightmare", "modifier_sleep"}
	if not_sleep_debuff then debuffs = 	{"modifier_seal", "modifier_mute", "modifier_burn", "modifier_freeze", "modifier_confuse", "modifier_deathblow", "modifier_petrify", "modifier_faint", "modifier_intimidate"} end
	local debuff = debuffs[RandomInt(1,#debuffs)]
	target:AddNewModifier(caster, nil, debuff, {duration = duration})
end

function inflictDelay(unit, amount)
	local amount = amount * (1 - getStats(unit).spd / 100)

	for k,ability in pairs(getAllActiveAbilities(unit)) do
		ability:StartCooldown(amount + ability:GetCooldownTimeRemaining())
	end
end

function reduceDelay(unit, amount)
	for k,ability in pairs(getAllActiveAbilities(unit)) do
		if ability:GetCooldownTimeRemaining() >= amount then
			ability:StartCooldown(ability:GetCooldownTimeRemaining() - amount)
		else
			ability:EndCooldown()
		end
	end
end

function removeDelay(unit)
	for k,ability in pairs(getAllActiveAbilities(unit)) do
		ability:EndCooldown()
	end
end

function applyDelayCooldowns(unit, ability)
	if COOLDOWNS_MODE == COOLDOWNS_MODE_SHARED then
		ability:EndCooldown()
		inflictDelay(unit, ability:GetCooldown(ability:GetLevel()))
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
	local cost = 0
	if CP_COSTS_MODE == CP_COSTS_MODE_NORMAL then
		cost = getAbilityValueForKey(ability, "CPCost")
	elseif CP_COSTS_MODE == CP_COSTS_MODE_DECAYING then
		cost = ability.current_cp_cost
	end

	if ability:GetAbilityType() == 1 then
		cost = math.max(SCRAFT_MINIMUM_CP, getCP(ability:GetCaster()))
	end
	return cost
end

function getAbilityCPCosts(hero)
	local cp_costs = {}
	for k,ability in pairs(getAllActiveAbilities(hero)) do
		cp_costs[k] = getCPCost(ability)
	end
	return cp_costs
end

function getAllActiveAbilities(hero)
	local abilities = {}
	for k,ability in pairs(getAllAbilities(hero)) do
		if not ability:IsHidden() then
			abilities[k] = ability
		end
	end
	return abilities
end

function getAllAbilities(hero)
	local abilities = {}
	for i=0,hero:GetAbilityCount() - 1 do
		local ability = hero:GetAbilityByIndex(i)
		if ability then
			abilities[i] = ability
		end
	end
	return abilities
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

function getAllLivingHeroes(team)
	local living_heroes = {}
	for k,hero in pairs(getAllHeroes()) do
		if hero:IsAlive() and (not team or team == hero:GetTeamNumber()) then
			table.insert(living_heroes, hero)
		end
	end
	return living_heroes
end

function triggerModifierEvent(hero, event_name, args)
	for k,modifier in pairs(hero:FindAllModifiers()) do
		if event_name == "unit_unbalanced" then
			if modifier.UnitUnbalanced then
				modifier:UnitUnbalanced(args)
			end
		elseif event_name == "round_started" then
			if modifier.RoundStarted then
				modifier:RoundStarted(args)
			end
		elseif event_name == "guard_triggered" then
			if modifier.GuardTriggered then
				modifier:GuardTriggered(args)
			end
		elseif event_name == "enhanced_craft_used" then
			if modifier.EnhancedCraftUsed then
				modifier:EnhancedCraftUsed(args)
			end
		end
	end
end

function triggerModifierEventOnAll(event_name, args)
	for k,hero in pairs(getAllHeroes()) do
		triggerModifierEvent(hero, event_name, args)
	end
end

function getMasterQuartzSpecialValue(hero, value_name, master_quartz, inverse_scaling)
	master_quartz = master_quartz or getMasterQuartz(hero)
	local base_value = master_quartz:GetSpecialValueFor(value_name)
	if not inverse_scaling then
		base_value = base_value * getHeroLinkScaling(hero)
	else
		if getHeroLinkScaling(hero) > 0 then
			base_value = base_value / getHeroLinkScaling(hero)
		else
			base_value = 0
		end
	end
	return base_value
end

function getHeroLinkScaling(hero)
	local scaling = 0
	if hero.combat_linked_to then
		local distance = (hero:GetAbsOrigin() - hero.combat_linked_to:GetAbsOrigin()):Length2D()
		if distance > LINK_SKILL_SCALING_RANGE and not hero:HasModifier("modifier_unshatterable_bonds") then
			scaling = LINK_SKILL_SCALING_FACTOR
		else
			scaling = 1
		end
	end
	return scaling
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

function upgradeMasterQuartz(hero, level)
	local existing_quartz = getMasterQuartz(hero)
	local slot = getSlotOfItem(existing_quartz, hero)
	local level = level or math.min(existing_quartz:GetLevel(), 4) + 1
	hero:RemoveItem(existing_quartz)

	local quartz_name = getUnitValueForKey(hero, "MasterQuartz")
	local new_quartz = CreateItem("item_master_"..quartz_name.."_"..level, hero, hero)
	hero:AddItem(new_quartz)
	hero:SwapItems(getSlotOfItem(new_quartz, hero), slot)
end

function getOpposingTeam(team)
	if team == DOTA_TEAM_GOODGUYS then
		return DOTA_TEAM_BADGUYS
	elseif team == DOTA_TEAM_BADGUYS then
		return DOTA_TEAM_GOODGUYS
	end
	return nil
end

function reviveHero(hero, health, mana)
	local health = health or hero:GetMaxHealth()
	local mana = mana or hero:GetMana()
	hero:SetRespawnPosition(hero:GetAbsOrigin())
	hero:RespawnHero(false, false, false)
	hero:SetHealth(health)
	hero:SetMana(mana)
	ParticleManager:CreateParticle("particles/status_effects/revive/revive_rays.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
end

function getAbilityCount(unit)
	local count = 0
	for i=0,15 do
		if unit:GetAbilityByIndex(i) then
			count = count + 1
		end
	end
	return count
end
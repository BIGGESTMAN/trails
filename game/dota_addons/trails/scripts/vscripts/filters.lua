require "libraries/util"
require "game_functions"

if not Filters then 
	Filters = {}
	Filters.__index = Filters
end

function Filters:DamageFilter(event)
	if event.entindex_attacker_const then local attacker = EntIndexToHScript(event.entindex_attacker_const) end
	local target = EntIndexToHScript(event.entindex_victim_const)
	local damage_type = event.damagetype_const
	local damage = event.damage
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
	return true
end

function Filters:ModifierGainedFilter(event)
	local caster = EntIndexToHScript(event.entindex_caster_const)
	local target = EntIndexToHScript(event.entindex_parent_const)
	if target:HasModifier("modifier_hells_tokamak_active") and caster:GetTeamNumber() ~= target:GetTeamNumber() then
		return false
	end
	return true
end

function Filters:ModifyGoldFilter(event)
	local hero = PlayerResource:GetPlayer(event.player_id_const):GetAssignedHero()
	if hero:HasModifier("modifier_clever_commander_debuff") and event.reliable == 0 then
		local modifier = hero:FindModifierByName("modifier_clever_commander_debuff")
		local gold_drained = event.gold * (1 - modifier.gold_drain_percent / 100)
		modifier.rat.gold_stolen = 	modifier.rat.gold_stolen + gold_drained
		event.gold = event.gold - gold_drained
	end
	return true
end
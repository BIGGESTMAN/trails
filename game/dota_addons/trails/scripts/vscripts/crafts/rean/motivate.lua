require "game_functions"

motivate = class({})

if IsServer() then
	function motivate:OnSpellStart()
		local caster = self:GetCaster()
		local ability = self
		local target = self:GetCursorTarget()

		local radius = ability:GetSpecialValueFor("radius")
		local damage_increase_percent = ability:GetSpecialValueFor("damage_increase_percent")
		local damage_increase_duration = ability:GetSpecialValueFor("damage_increase_duration")
		local bonus_cp = ability:GetSpecialValueFor("bonus_cp")

		if caster:HasModifier("modifier_combat_link_followup_available") and target and target:HasModifier("modifier_combat_link_unbalanced") then
			caster:RemoveModifierByName("modifier_combat_link_followup_available")
			target:RemoveModifierByName("modifier_combat_link_unbalanced")
			modifyStat(target, STAT_STR_DOWN, damage_increase_percent, damage_increase_duration)
			modifyCP(target, bonus_cp * -1)

			damage_increase_percent = ability:GetSpecialValueFor("unbalanced_damage_increase_percent")
			bonus_cp = ability:GetSpecialValueFor("unbalanced_bonus_cp")
		end

		modifyCP(caster, getCPCost(ability) * -1)

		local team = caster:GetTeamNumber()
		local origin = caster:GetAbsOrigin()
		local iTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY
		local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_ANY_ORDER
		local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

		for k,unit in pairs(targets) do
			modifyStat(unit, STAT_STR, damage_increase_percent, damage_increase_duration)
			if unit ~= caster then modifyCP(unit, bonus_cp) end
		end

		ParticleManager:CreateParticle("particles/econ/items/sven/sven_cyclopean_marauder/sven_cyclopean_warcry.vpcf", PATTACH_ABSORIGIN, caster)
	end
end

function motivate:GetBehavior()
	local behavior = DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_AOE
	if self:GetCaster():HasModifier("modifier_combat_link_followup_available") then
		behavior = DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
	end
	return behavior
end

function motivate:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function motivate:CastFilterResultTarget(target)
	if target:HasModifier("modifier_combat_link_unbalanced") then
		return UF_SUCCESS
	else
		return UF_FAIL_CUSTOM
	end
end

function motivate:GetCustomCastErrorTarget(target)
	return "must_target_unbalanced"
end
require "game_functions"
require "libraries/util"
require "libraries/physics"
require "aoe_previews"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability

	local radius = ability:GetSpecialValueFor("radius")

	caster.stridulate_preview = {}
	caster.stridulate_preview = AOEPreviews:Create(AOE_TYPE_CIRCLE, {radius = radius, follow = caster})
end

function channelFinished(keys)
	local caster = keys.caster
	
	AOEPreviews:Remove(caster.stridulate_preview)
	caster.stridulate_preview = nil
end

function channelSucceeded(keys)
	local caster = keys.caster
	local ability = keys.ability

	local radius = ability:GetSpecialValueFor("radius")
	local stat_increase = ability:GetSpecialValueFor("stat_increase")
	local stat_increase_duration = ability:GetSpecialValueFor("stat_increase_duration")

	local team = caster:GetTeamNumber()
	local origin = caster:GetAbsOrigin()
	local iTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY
	local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
	for k,unit in pairs(targets) do
		if unit:GetUnitName() == "trailsadventure_mob_blade_pincer" or unit:GetUnitName() == "trailsadventure_mob_blade_horn" then
			modifyStat(unit, STAT_SPD, stat_increase, stat_increase_duration)
			modifyStat(unit, STAT_MOV, stat_increase, stat_increase_duration)
		end
	end
end
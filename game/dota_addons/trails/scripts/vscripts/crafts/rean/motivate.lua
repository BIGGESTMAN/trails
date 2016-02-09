require "game_functions"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability

	local radius = ability:GetSpecialValueFor("radius")
	local damage_increase_percent = ability:GetSpecialValueFor("damage_increase_percent")
	local damage_increase_duration = ability:GetSpecialValueFor("damage_increase_duration")
	local bonus_cp = ability:GetSpecialValueFor("bonus_cp")

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
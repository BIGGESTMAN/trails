require "game_functions"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability

	local radius = ability:GetSpecialValueFor("radius")
	local str_increase = ability:GetSpecialValueFor("str_increase")
	local buff_duration = ability:GetSpecialValueFor("buff_duration")

	local team = caster:GetTeamNumber()
	local origin = caster:GetAbsOrigin()
	local iTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY
	local iType = DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
	for k,unit in pairs(targets) do
		if getCP(unit) < 100 then
			unit:AddNewModifier(caster, ability, "modifier_cp_boost", {duration = buff_duration})
		else
			modifyStat(unit, STAT_STR, str_increase, buff_duration)
		end
	end

	spendCP(caster, ability)
	applyDelayCooldowns(caster, ability)

	local particle = ParticleManager:CreateParticle("particles/crafts/estelle/morale/aoe.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(particle, 5, Vector(1,1,radius))
	-- DebugDrawCircle(origin, Vector(255,0,0), 0.5, radius, true, 3)
end
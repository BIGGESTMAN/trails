require "game_functions"
require "libraries/util"
require "aoe_previews"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability

	local radius = ability:GetSpecialValueFor("radius")

	local team = caster:GetTeamNumber()
	local origin = caster:GetAbsOrigin()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
	if #targets > 0 then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_go_ape_stat_buff", {}):SetStackCount(#targets)
	end

	local particle = ParticleManager:CreateParticle("particles/mobs/gordi_chief_go_ape/buff.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
end

function increaseModelSize(keys)
	local stackCount = keys.caster:FindModifierByName("modifier_go_ape_stat_buff"):GetStackCount()
	keys.caster:SetModelScale(1 + 0.2 * stackCount)
end

function revertModelSize(keys)
	keys.caster:SetModelScale(1)
end
require "game_functions"
require "libraries/util"
require "aoe_previews"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability

	local radius = ability:GetSpecialValueFor("radius")

	caster.spores_aoe_preview = AOEPreviews:Create(AOE_TYPE_CIRCLE, {radius = radius, follow = caster})
end

function channelFinished(keys)
	local caster = keys.caster
	
	AOEPreviews:Remove(caster.spores_aoe_preview)
	caster.spores_aoe_preview = nil
end

function channelSucceeded(keys)
	local caster = keys.caster
	local ability = keys.ability

	local radius = ability:GetSpecialValueFor("radius")
	local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100
	local damage_type = ability:GetAbilityDamageType()
	local sleep_duration = ability:GetSpecialValueFor("sleep_duration")

	local origin = caster:GetAbsOrigin()

	-- local spell_result = BOSS_SPELL_RESULT_FAILURE

	local particle = ParticleManager:CreateParticle("particles/mobs/jelly_shroom_spores/spores.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, origin)

	local team = caster:GetTeamNumber()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
	for k,unit in pairs(targets) do
		-- spell_result = BOSS_SPELL_RESULT_SUCCESS
		applyEffect(unit, damage_type, function()
			dealScalingDamage(unit, caster, damage_type, damage_scale, ability)
			unit:AddNewModifier(caster, ability, "modifier_sleep", {duration = sleep_duration})
		end)
	end

	-- BossAI:ReportSpellResult(boss, spell_result)
end
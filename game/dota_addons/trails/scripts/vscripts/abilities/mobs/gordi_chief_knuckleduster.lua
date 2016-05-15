require "game_functions"
require "libraries/util"
require "libraries/physics"
require "aoe_previews"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local radius = ability:GetSpecialValueFor("radius")

	caster.knuckleduster_state = {}
	caster.knuckleduster_state.preview = AOEPreviews:Create(AOE_TYPE_CIRCLE, {radius = radius, follow = target})
	caster.knuckleduster_state.target = target
end

function channelFinished(keys)
	local caster = keys.caster
	
	AOEPreviews:Remove(caster.knuckleduster_state.preview)
	caster.knuckleduster_state.preview = nil
end

function channelSucceeded(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = caster.knuckleduster_state.target
	caster.knuckleduster_state.target = nil

	local radius = ability:GetSpecialValueFor("radius")
	local damage_type = ability:GetAbilityDamageType()
	local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100
	local faint_duration = ability:GetSpecialValueFor("faint_duration")
	local knockback_distance = ability:GetSpecialValueFor("knockback_distance")
	local knockback_duration = ability:GetSpecialValueFor("knockback_duration")

	local team = caster:GetTeamNumber()
	local origin = target:GetAbsOrigin()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
	for k,unit in pairs(targets) do
		applyEffect(unit, damage_type, function()
			dealScalingDamage(unit, caster, damage_type, damage_scale / #targets, ability)
			if #targets == 1 then unit:AddNewModifier(caster, ability, "modifier_faint", {duration = faint_duration}) end
			ability:ApplyDataDrivenModifier(caster, unit, "modifier_knuckleduster_knockback", {})
			dash(unit, (unit:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized(), knockback_distance / knockback_duration, knockback_distance, true)
		end)
	end

	local particle = ParticleManager:CreateParticle("particles/mobs/gordi_chief_knuckleduster/area.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, origin)

	if #targets == #getAllLivingHeroes() then
		caster.reward_modifier:TriggerCPReward()
	end
end
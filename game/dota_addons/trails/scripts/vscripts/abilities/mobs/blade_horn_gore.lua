require "game_functions"
require "libraries/util"
require "libraries/physics"
require "aoe_previews"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target_points[1]

	local radius = ability:GetSpecialValueFor("width")
	local direction = (target_point - caster:GetAbsOrigin()):Normalized()
	local range = ability:GetSpecialValueFor("range")

	caster.gore_state = {}
	caster.gore_state.preview = AOEPreviews:Create(AOE_TYPE_LINE, {radius = radius, origin = caster:GetAbsOrigin(), direction = direction, range = range})
	caster.gore_state.direction = direction
end

function channelFinished(keys)
	local caster = keys.caster
	
	AOEPreviews:Remove(caster.gore_state.preview)
	caster.gore_state.preview = nil
end

function channelSucceeded(keys)
	local caster = keys.caster
	local ability = keys.ability
	local direction = caster.gore_state.direction
	caster.gore_state.direction = nil

	local speed = ability:GetSpecialValueFor("speed")
	local range = ability:GetSpecialValueFor("range")
	local radius = ability:GetSpecialValueFor("width")

	local collisionRules = {
		team = caster:GetTeamNumber(),
		radius = radius,
		iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL,
		iFlag = DOTA_UNIT_TARGET_FLAG_NONE,
		iOrder = FIND_ANY_ORDER
	}
	local collisionFunction = goreHit

	caster:FindAbilityByName("mob_blade_horn_gore"):ApplyDataDrivenModifier(caster, caster, "modifier_gore_dashing", {})
	dash(caster, direction, speed, range, true, reportSpellSuccess, {collision_rules = collisionRules, collisionFunction = collisionFunction})
end

function goreHit(unit, caster, direction, args)
	local ability = caster:FindAbilityByName("mob_blade_horn_gore")
	local damage_type = ability:GetAbilityDamageType()
	local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100
	local faint_duration = ability:GetSpecialValueFor("faint_duration")

	applyEffect(unit, damage_type, function()
		dealScalingDamage(unit, caster, damage_type, damage_scale, ability)
		unit:AddNewModifier(caster, ability, "modifier_faint", {duration = faint_duration})
	end)
end

function reportSpellSuccess(caster, direction, speed, args)
	caster:RemoveModifierByName("modifier_gore_dashing")
	if sizeOfTable(args.units_hit) == 0 then
		caster.reward_modifier:TriggerCPReward()
	end
end
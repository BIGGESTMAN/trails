require "game_functions"

function abilityPhaseStart(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	if validEnhancedCraft(caster, target) then
		caster:RemoveModifierByName("modifier_combat_link_followup_available")
		target:RemoveModifierByName("modifier_combat_link_unbalanced")
		ability:SetOverrideCastPoint(ability:GetSpecialValueFor("enhanced_cast_point"))
	end
end

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target_points[1]

	local radius = ability:GetSpecialValueFor("radius")
	local range = ability:GetSpecialValueFor("range")
	local travel_speed = ability:GetSpecialValueFor("travel_speed")
	local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100
	local freeze_duration = ability:GetSpecialValueFor("freeze_duration")

	modifyCP(caster, getCPCost(ability) * -1)
	applyDelayCooldowns(caster, ability)

	if ability:GetCastPoint() == 0 then
		freeze_duration = ability:GetSpecialValueFor("unbalanced_freeze_duration")
		ability:SetOverrideCastPoint(ability:GetSpecialValueFor("normal_cast_point"))
	end

	if caster:HasModifier("modifier_crit") then
		damage_scale = damage_scale * 2
		caster:RemoveModifierByName("modifier_crit")
	end

	collisionRules = {
		team = caster:GetTeamNumber(),
		radius = radius,
		iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL,
		iFlag = DOTA_UNIT_TARGET_FLAG_NONE,
		iOrder = FIND_ANY_ORDER
	}
	local direction = (target_point - caster:GetAbsOrigin()):Normalized()
	local origin_location = caster:GetAbsOrigin()

	ProjectileList:CreateLinearProjectile(caster, origin_location, direction, travel_speed, range, nil, collisionRules, freezingBulletHit, "particles/crafts/crow/freezing_bullet.vpcf", {damage_scale = damage_scale, freeze_duration = freeze_duration})
end

function freezingBulletHit(caster, unit, other_args)
	local ability = caster:FindAbilityByName("freezing_bullet")
	local damage_scale = other_args.damage_scale
	local damage_type = ability:GetAbilityDamageType()
	local freeze_duration = other_args.freeze_duration

	dealScalingDamage(unit, caster, damage_type, damage_scale)
	increaseUnbalance(caster, unit)
	unit:AddNewModifier(caster, ability, "modifier_freeze", {duration = freeze_duration})
end
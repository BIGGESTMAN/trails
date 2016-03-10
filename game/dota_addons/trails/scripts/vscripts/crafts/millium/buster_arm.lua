require "game_functions"
require "libraries/util"
require "libraries/physics"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target_points[1]
	local target = keys.target

	local radius = ability:GetSpecialValueFor("radius")
	local range = ability:GetSpecialValueFor("range")
	local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100
	local faint_duration = ability:GetSpecialValueFor("faint_duration")

	modifyCP(caster, getCPCost(ability) * -1)
	applyDelayCooldowns(caster, ability)

	local enhanced = false
	if validEnhancedCraft(caster, target) then
		caster:RemoveModifierByName("modifier_combat_link_followup_available")
		target:RemoveModifierByName("modifier_combat_link_unbalanced")
		damage_scale = ability:GetSpecialValueFor("unbalanced_damage_percent") / 100
		faint_duration = ability:GetSpecialValueFor("unbalanced_faint_duration")
		enhanced = true
	end

	if caster:HasModifier("modifier_crit") then
		damage_scale = damage_scale * 2
		caster:RemoveModifierByName("modifier_crit")
	end

	local direction = (target_point - caster:GetAbsOrigin()):Normalized()
	local end_point = caster:GetAbsOrigin() + direction * range

	local team = caster:GetTeamNumber()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInLine(team, caster:GetAbsOrigin(), end_point, nil, radius, iTeam, iType, iOrder)
	for k,unit in pairs(targets) do
		if pointIsInFront(unit:GetAbsOrigin(), caster:GetAbsOrigin(), direction) then
			busterArmHit(caster, unit, damage_scale, faint_duration, enhanced)
		end
	end
end

function busterArmHit(caster, unit, damage_scale, faint_duration, enhanced)
	local ability = caster:FindAbilityByName("buster_arm")
	local damage_type = ability:GetAbilityDamageType()
	local knockback_distance = ability:GetSpecialValueFor("knockback_distance")
	local knockback_duration = ability:GetSpecialValueFor("knockback_duration") / 2
	local direction = (unit:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
	direction.z = 0
	local velocity = direction * knockback_distance / knockback_duration

	dealScalingDamage(unit, caster, damage_type, damage_scale, ability, CRAFT_CP_GAIN_FACTOR)
	increaseUnbalance(caster, unit)
	ability:ApplyDataDrivenModifier(caster, unit, "modifier_buster_arm_knockback", {})
	unit:SetForwardVector(direction * -1)
	unit.buster_arm_faint_duration = faint_duration

	Physics:Unit(unit)
	unit:SetPhysicsVelocity(velocity)
	unit:SetPhysicsFriction(0)
	unit:SetGroundBehavior(PHYSICS_GROUND_NOTHING)
	unit:SetAutoUnstuck(false)

	unit:FollowNavMesh(true)
	unit:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
	unit:SetBounceMultiplier(0)
	unit:OnPreBounce(function()
		unit:RemoveModifierByName("modifier_buster_arm_knockback")
		unit:AddNewModifier(caster, ability, "modifier_faint", {duration = faint_duration})
		unit.buster_arm_faint_duration = nil
		unit:OnPhysicsFrame(nil)
	end)
	unit:OnPhysicsFrame(checkForUnitCollision)

	Timers:CreateTimer(knockback_duration, function()
		unit:SetPhysicsVelocity(Vector(0,0,0))
		if enhanced then unit:AddNewModifier(caster, ability, "modifier_faint", {duration = faint_duration}) end
		unit.buster_arm_faint_duration = nil
	end)
end

function checkForUnitCollision(unit)
	local collision_radius = unit:GetModelRadius()
	local caster = unit:FindModifierByName("modifier_buster_arm_knockback"):GetCaster()
	local ability = caster:FindAbilityByName("buster_arm")
	local faint_duration = unit.buster_arm_faint_duration
	unit.buster_arm_faint_duration = nil

	local team = unit:GetTeamNumber()
	local origin = unit:GetAbsOrigin()
	local iTeam = DOTA_UNIT_TARGET_TEAM_BOTH
	local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, origin, nil, collision_radius, iTeam, iType, iFlag, iOrder, false)
	if #targets > 1 then
		unit:AddNewModifier(caster, ability, "modifier_faint", {duration = faint_duration})
		unit:RemoveModifierByName("modifier_buster_arm_knockback")
		unit:SetPhysicsVelocity(Vector(0,0,0))
	end
end
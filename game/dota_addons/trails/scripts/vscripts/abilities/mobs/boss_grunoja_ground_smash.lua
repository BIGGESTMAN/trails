require "game_functions"
require "libraries/util"
require "libraries/physics"
require "aoe_previews"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local radius = ability:GetSpecialValueFor("radius")

	caster.ground_smash_state = {}
	caster.ground_smash_state.preview = AOEPreviews:Create(AOE_TYPE_CIRCLE, {radius = radius, origin = target:GetAbsOrigin()})
	caster.ground_smash_state.target = target:GetAbsOrigin()
end

function channelFinished(keys)
	local caster = keys.caster
	
	AOEPreviews:Remove(caster.ground_smash_state.preview)
	caster.ground_smash_state.preview = nil
end

function channelSucceeded(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = caster.ground_smash_state.target
	caster.ground_smash_state.target = nil

	local jump_duration = ability:GetSpecialValueFor("flight_time")

	jumpToPosition(caster, target_point, jump_duration, impact)
end

function jumpToPosition(caster, target_point, duration, callback)
	caster:FindAbilityByName("mob_boss_grunoja_ground_smash"):ApplyDataDrivenModifier(caster, caster, "modifier_ground_smash_jumping", {})

	Physics:Unit(caster)
	local horizontal_velocity = (target_point - caster:GetAbsOrigin()) / duration
	local velocity = Vector(0,0,2000) / duration
	caster:SetPhysicsAcceleration(velocity * -2 / duration)
	velocity = velocity + horizontal_velocity
	caster:SetPhysicsVelocity(velocity)
	caster:SetPhysicsFriction(0)
	caster:SetGroundBehavior(PHYSICS_GROUND_NOTHING)
	caster:SetAutoUnstuck(false)
	caster:FollowNavMesh(false)
	caster:SetNavCollisionType(PHYSICS_NAV_NOTHING)

	Timers:CreateTimer(duration, function()
		caster:RemoveModifierByName("modifier_ground_smash_jumping")
		caster:SetPhysicsVelocity(Vector(0,0,0))
		caster:SetPhysicsAcceleration(Vector(0,0,0))
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), false)
		if caster:IsAlive() then
			callback(caster, target_point)
		end
	end)
end

function impact(caster, target_point)
	local ability = caster:FindAbilityByName("mob_boss_grunoja_ground_smash")
	local radius = ability:GetSpecialValueFor("radius")
	local damage_type = ability:GetAbilityDamageType()
	local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100
	local center_damage_scale = ability:GetSpecialValueFor("center_damage_percent") / 100
	local faint_duration = ability:GetSpecialValueFor("faint_duration")
	local center_radius = ability:GetSpecialValueFor("center_radius")
	local knockback_distance = ability:GetSpecialValueFor("knockback_distance")
	local knockback_duration = ability:GetSpecialValueFor("knockback_duration")

	local team = caster:GetTeamNumber()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, target_point, nil, radius, iTeam, iType, iFlag, iOrder, false)
	for k,unit in pairs(targets) do
		local distance = distanceBetween(unit:GetAbsOrigin(), target_point)
		if distance > center_radius then
			applyEffect(unit, damage_type, function()
				dealScalingDamage(unit, caster, damage_type, damage_scale, ability)
				ability:ApplyDataDrivenModifier(caster, unit, "modifier_ground_smash_knockback", {})
				dash(unit, (unit:GetAbsOrigin() - target_point):Normalized(), (knockback_distance - distance) / knockback_duration, (knockback_distance - distance), true)
			end)
		else
			applyEffect(unit, damage_type, function()
				dealScalingDamage(unit, caster, damage_type, center_damage_scale, ability)
				unit:AddNewModifier(caster, ability, "modifier_faint", {duration = faint_duration})
				ability:ApplyDataDrivenModifier(caster, unit, "modifier_ground_smash_knockback", {})
				dash(unit, (unit:GetAbsOrigin() - target_point):Normalized(), (knockback_distance - distance) / knockback_duration, (knockback_distance - distance), true)
			end)
		end
	end

	caster:FindModifierByName("modifier_boss_grunoja_reward"):ReportSpellSuccess(#targets > 0)

	local particle = ParticleManager:CreateParticle("particles/crafts/millium/megaton_press_shockwave.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, target_point)
	ScreenShake(target_point, 300, 2, 1, 1000, 0, true)
end
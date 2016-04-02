require "game_functions"
require "libraries/util"
require "libraries/physics"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target_points[1]

	local dash_speed = ability:GetSpecialValueFor("dash_speed")
	local range = dash_speed * ability:GetSpecialValueFor("dash_duration")
	local dash_knockback_radius = ability:GetSpecialValueFor("dash_knockback_radius")

	local args = {}
	args.max_cp = getCP(caster) == MAX_CP
	
	if caster:HasModifier("modifier_crit") then
		args.crit = true
		caster:RemoveModifierByName("modifier_crit")
	end

	local direction = (target_point - caster:GetAbsOrigin()):Normalized()
	direction.z = 0
	args.collision_rules = {
		team = caster:GetTeamNumber(),
		radius = dash_knockback_radius,
		iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL,
		iFlag = DOTA_UNIT_TARGET_FLAG_NONE,
		iOrder = FIND_ANY_ORDER
	}
	args.collisionFunction = dashKnockback
	caster:SetForwardVector(direction)
	dash(caster, direction, dash_speed, range, true, jump, args)
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_gigant_breaker_dashing", {})

	spendCP(caster, ability)
	applyDelayCooldowns(caster, ability)
end

function dashKnockback(target, caster, direction, args)
	local left_vector = RotatePosition(Vector(0,0,0), QAngle(0,-90,0), direction)
	local right_vector = RotatePosition(Vector(0,0,0), QAngle(0,90,0), direction)
	local knockback_direction = left_vector
	if pointIsInFront(target:GetAbsOrigin(), caster:GetAbsOrigin(), right_vector) then knockback_direction = right_vector end

	local ability = caster:FindAbilityByName("gigant_breaker")
	local knockback_distance = ability:GetSpecialValueFor("dash_knockback_distance")
	local knockback_speed = knockback_distance / ability:GetSpecialValueFor("dash_knockback_duration")

	dash(target, knockback_direction, knockback_speed, knockback_distance, true)
	ability:ApplyDataDrivenModifier(caster, target, "modifier_gigant_breaker_knockback", {})
end

function jump(caster, direction, speed, args)
	local ability = caster:FindAbilityByName("gigant_breaker")
	local slam_delay = ability:GetSpecialValueFor("slam_delay")

	Physics:Unit(caster)
	local velocity = Vector(0,0,2000)
	caster:SetPhysicsVelocity(velocity)
	caster:SetPhysicsAcceleration(velocity * -2 / slam_delay)
	caster:SetPhysicsFriction(0)
	caster:SetGroundBehavior(PHYSICS_GROUND_NOTHING)
	caster:SetAutoUnstuck(false)
	caster:FollowNavMesh(false)
	caster:SetNavCollisionType(PHYSICS_NAV_NOTHING)

	Timers:CreateTimer(slam_delay, function()
		caster:RemoveModifierByName("modifier_gigant_breaker_dashing")
		caster:SetPhysicsVelocity(Vector(0,0,0))
		caster:SetPhysicsAcceleration(Vector(0,0,0))
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), false)
		slam(caster, args)
	end)
end

function slam(caster, args)
	local ability = caster:FindAbilityByName("gigant_breaker")
	local damage_scale = ability:GetSpecialValueFor("slam_damage_percent") / 100
	local damage_type = ability:GetAbilityDamageType()
	local radius = ability:GetSpecialValueFor("slam_radius")
	local max_cp_shockwave_delay = ability:GetSpecialValueFor("max_cp_shockwave_delay")

	if args.crit then damage_scale = damage_scale * 2 end
	if args.max_cp then radius = ability:GetSpecialValueFor("max_cp_slam_radius") end

	local team = caster:GetTeamNumber()
	local origin = caster:GetAbsOrigin()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
	for k,unit in pairs(targets) do
		applyEffect(unit, damage_type, function()
			dealScalingDamage(unit, caster, damage_type, damage_scale, ability, SCRAFT_CP_GAIN_FACTOR, false, false, 0)
		end)
	end

	local particle = ParticleManager:CreateParticle("particles/crafts/millium/gigant_breaker/slam_impact.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, origin)
	-- DebugDrawCircle(origin, Vector(255,0,0), 0.5, radius, true, 3)

	createShockwave(caster, origin, args)
	if args.max_cp then
		local shockwaves = ability:GetSpecialValueFor("max_cp_shockwave_count") - 1
		Timers:CreateTimer(max_cp_shockwave_delay, function()
			createShockwave(caster, origin, args)
			shockwaves = shockwaves - 1
			if shockwaves > 0 then return max_cp_shockwave_delay end
		end)
	end
end

function createShockwave(caster, origin, args)
	local ability = caster:FindAbilityByName("gigant_breaker")
	local damage_scale = ability:GetSpecialValueFor("shockwave_damage_percent") / 100
	local damage_type = ability:GetAbilityDamageType()
	local initial_radius = ability:GetSpecialValueFor("shockwave_width")
	local end_radius = ability:GetSpecialValueFor("shockwave_end_radius")
	if args.max_cp then end_radius = ability:GetSpecialValueFor("max_cp_shockwave_end_radius") end
	local speed = ability:GetSpecialValueFor("shockwave_speed")
	local stat_down = ability:GetSpecialValueFor("stat_reduction_percent")
	local stat_down_duration = ability:GetSpecialValueFor("stat_reduction_duration")

	local update_interval = 1/30
	local radius_increase = speed * update_interval

	local current_min_radius = 0
	local current_max_radius = initial_radius
	local units_hit = {}

	local particle = ParticleManager:CreateParticle("particles/crafts/millium/gigant_breaker/shockwave.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, origin)

	Timers:CreateTimer(0, function()
		local team = caster:GetTeamNumber()
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_ANY_ORDER
		local targets = FindUnitsInRadius(team, origin, nil, current_max_radius, iTeam, iType, iFlag, iOrder, false)
		for k,unit in pairs(targets) do
			local distance = (unit:GetAbsOrigin() - origin):Length2D()
			if distance >= current_min_radius and not units_hit[unit] then
				units_hit[unit] = true
				applyEffect(unit, damage_type, function()
					dealScalingDamage(unit, caster, damage_type, damage_scale, ability, SCRAFT_CP_GAIN_FACTOR, false, false, 0)
					modifyStat(unit, STAT_SPD_DOWN, stat_down, stat_down_duration)
					modifyStat(unit, STAT_MOV_DOWN, stat_down, stat_down_duration)
				end)
			end
		end
		current_min_radius = current_min_radius + radius_increase
		current_max_radius = current_max_radius + radius_increase
		if current_max_radius < end_radius then
			return update_interval
		else
			ParticleManager:DestroyParticle(particle, false)
		end
	end)
end

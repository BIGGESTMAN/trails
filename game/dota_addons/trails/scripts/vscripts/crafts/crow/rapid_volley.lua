require "game_functions"
require "combat_links"
require "libraries/animations"
require "libraries/util"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local total_duration = ability:GetSpecialValueFor("duration")
	local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100
	local max_range = ability:GetSpecialValueFor("max_range")
	local shot_interval = ability:GetSpecialValueFor("shot_interval")
	local shot_interval_reduction = ability:GetSpecialValueFor("shot_interval_reduction")
	local update_interval = 1/30

	local enhanced = false
	if validEnhancedCraft(caster, target) then
		executeEnhancedCraft(caster, target)
		shot_interval = ability:GetSpecialValueFor("unbalanced_shot_interval")
		max_range = ability:GetSpecialValueFor("unbalanced_max_range")
		enhanced = true
	end

	if caster:HasModifier("modifier_crit") then
		damage_scale = damage_scale * 2
		caster:RemoveModifierByName("modifier_crit")
	end

	spendCP(caster, ability)
	applyDelayCooldowns(caster, ability)

	local last_shot_fired_quadrant = 0
	-- local shots_fired = 0
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_rapid_volley_casting", {})
	local time_since_last_shot = shot_interval

	Timers:CreateTimer(0, function()
		if caster:HasModifier("modifier_rapid_volley_casting") then
			local distance = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()
			if distance > max_range then
				caster:RemoveModifierByName("modifier_rapid_volley_casting")
			else
				shot_interval = shot_interval - shot_interval_reduction * update_interval
				if time_since_last_shot >= shot_interval then
					last_shot_fired_quadrant = last_shot_fired_quadrant + 1
					if last_shot_fired_quadrant > 4 then last_shot_fired_quadrant = 1 end
					fireShot(caster, target, damage_scale, last_shot_fired_quadrant, enhanced)
					StartAnimation(caster, {duration = shot_interval, activity = ACT_DOTA_ATTACK, rate = 30/shot_interval})

					time_since_last_shot = time_since_last_shot - shot_interval
					-- shots_fired = shots_fired + 1
					-- print(shots_fired, shot_interval)
				else
					time_since_last_shot = time_since_last_shot + update_interval
				end
				return update_interval
			end
		end
	end)
end

function fireShot(caster, target, damage_scale, quadrant, enhanced)
	local ability = caster:FindAbilityByName("rapid_volley")
	local bullet_min_spawn_radius = ability:GetSpecialValueFor("bullet_min_spawn_radius")
	local bullet_max_spawn_radius = ability:GetSpecialValueFor("bullet_max_spawn_radius")
	local damage_type = ability:GetAbilityDamageType()
	local damage_radius = ability:GetSpecialValueFor("damage_radius")
	local delay = ability:GetSpecialValueFor("unbalanced_delay")

	local target_point = randomShotLocation(target:GetAbsOrigin(), bullet_min_spawn_radius, bullet_max_spawn_radius, quadrant)

	local team = caster:GetTeamNumber()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, target_point, nil, damage_radius, iTeam, iType, iFlag, iOrder, false)
	for k,unit in pairs(targets) do
		applyEffect(unit, damage_type, function()
			dealScalingDamage(unit, caster, damage_type, damage_scale, ability, CRAFT_CP_GAIN_FACTOR)
			increaseUnbalance(caster, unit)
			if enhanced then
				knockback(caster, target)
				inflictDelay(target, delay)
			end
		end)
	end

	local particle = ParticleManager:CreateParticle("particles/crafts/crow/rapid_volley_crater.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 3, target_point)

	DebugDrawCircle(target_point, Vector(255,0,0), 0.5, damage_radius, true, 0.2)
end

function randomShotLocation(area_center, min_radius, max_radius, quadrant)
	local target_point = randomPointInCircle(area_center, max_radius)
	local max_iterations = 100
	local iterations = 0
	while (target_point - area_center):Length2D() < min_radius or not shotLocationInQuadrant(area_center, target_point, quadrant) and iterations < max_iterations do
		target_point = randomPointInCircle(area_center, max_radius)
		iterations = iterations + 1
	end
	return target_point
end

function shotLocationInQuadrant(area_center, location, quadrant)
	local direction_towards_origin = (location - area_center):Normalized()
	local facing_north = Vector(0,1,0):Dot(direction_towards_origin) >= 0
	local facing_east = Vector(1,0,0):Dot(direction_towards_origin) >= 0
	local in_quadrant = false
	if quadrant == 1 and facing_north and facing_east then
		in_quadrant = true
	elseif quadrant == 2 and facing_north and not facing_east then
		in_quadrant = true
	elseif quadrant == 3 and not facing_north and not facing_east then
		in_quadrant = true
	elseif quadrant == 4 and not facing_north and facing_east then
		in_quadrant = true
	end
	-- DebugDrawLine(location, area_center, 255, 0, 0, true, 0.25)
	-- print(in_quadrant, quadrant, facing_north, facing_east)
	return in_quadrant
end

function knockback(caster, target)
	local ability = caster:FindAbilityByName("rapid_volley")
	local knockback_distance = ability:GetSpecialValueFor("unbalanced_knockback_distance")
	local knockback_speed = knockback_distance / ability:GetSpecialValueFor("unbalanced_knockback_duration")
	local direction = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
	direction.z = 0

	ability:ApplyDataDrivenModifier(caster, target, "modifier_rapid_volley_knockback", {})
	dash(target, direction, knockback_speed, knockback_distance, true)
end
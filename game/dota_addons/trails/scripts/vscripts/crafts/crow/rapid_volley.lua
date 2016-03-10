require "game_functions"
require "combat_links"
require "libraries/animations"
require "libraries/util"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target_points[1]
	local target = keys.target

	local total_shots = ability:GetSpecialValueFor("shots")
	local total_duration = ability:GetSpecialValueFor("duration")
	local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100

	if validEnhancedCraft(caster, target) then
		caster:RemoveModifierByName("modifier_combat_link_followup_available")
		target:RemoveModifierByName("modifier_combat_link_unbalanced")
		total_shots = ability:GetSpecialValueFor("unbalanced_shots")
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_rapid_volley_enhanced_casting", {})
	else
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_rapid_volley_casting", {})
	end

	local shot_interval = total_duration / (total_shots - 1)

	if caster:HasModifier("modifier_crit") then
		damage_scale = damage_scale * 2
		caster:RemoveModifierByName("modifier_crit")
	end

	modifyCP(caster, getCPCost(ability) * -1)
	applyDelayCooldowns(caster, ability)
	
	local shots_fired = 0
	local last_shot_fired_quadrant = 0
	caster.rapid_volley_targets_hit = {}

	Timers:CreateTimer(0, function()
		if caster:HasModifier("modifier_rapid_volley_casting") or caster:HasModifier("modifier_rapid_volley_enhanced_casting") then
			last_shot_fired_quadrant = last_shot_fired_quadrant + 1
			if last_shot_fired_quadrant > 4 then last_shot_fired_quadrant = 1 end
			fireShot(caster, target_point, damage_scale, last_shot_fired_quadrant)
			slowUnitsInArea(caster, target_point, shot_interval)
			StartAnimation(caster, {duration = shot_interval, activity = ACT_DOTA_ATTACK, rate = 30/shot_interval})
			shots_fired = shots_fired + 1
			if shots_fired < total_shots then
				return shot_interval
			else
				caster.rapid_volley_targets_hit = nil
				caster:RemoveModifierByName("modifier_rapid_volley_casting")
				caster:RemoveModifierByName("modifier_rapid_volley_enhanced_casting")
			end
		end
	end)
end

function slowUnitsInArea(caster, area_center, duration)
	local ability = caster:FindAbilityByName("rapid_volley")
	local radius = ability:GetSpecialValueFor("area_slow_radius")

	local team = caster:GetTeamNumber()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, area_center, nil, radius, iTeam, iType, iFlag, iOrder, false)
	for k,unit in pairs(targets) do
		ability:ApplyDataDrivenModifier(caster, unit, "modifier_rapid_volley_area_slow", {duration = duration + 1/30})
	end
end

function fireShot(caster, area_center, damage_scale, quadrant)
	local ability = caster:FindAbilityByName("rapid_volley")
	local bullet_min_spawn_radius = ability:GetSpecialValueFor("bullet_min_spawn_radius")
	local bullet_max_spawn_radius = ability:GetSpecialValueFor("bullet_max_spawn_radius")
	local damage_type = ability:GetAbilityDamageType()
	local damage_radius = ability:GetSpecialValueFor("damage_radius")

	local target_point = randomShotLocation(area_center, bullet_min_spawn_radius, bullet_max_spawn_radius, quadrant)

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
			if not caster.rapid_volley_targets_hit[unit] then
				ability:ApplyDataDrivenModifier(caster, unit, "modifier_rapid_volley_bullet_slow", {})
			end
		end)
	end

	local particle = ParticleManager:CreateParticle("particles/crafts/crow/rapid_volley_crater.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 3, target_point)

	-- DebugDrawCircle(target_point, Vector(255,0,0), 0.5, 100, true, 0.2)
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

function endVolley(keys)
	keys.caster:RemoveModifierByName("modifier_rapid_volley_enhanced_casting")
end
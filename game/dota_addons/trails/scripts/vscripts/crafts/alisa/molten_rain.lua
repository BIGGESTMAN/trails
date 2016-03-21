require "game_functions"
require "libraries/util"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target_points[1]
	local target = keys.target

	local total_arrows = ability:GetSpecialValueFor("total_arrows")
	local duration = ability:GetSpecialValueFor("duration")
	local arrow_interval = duration / total_arrows

	local arrow_origin_offset = (caster:GetAbsOrigin() - target_point) / 2 + Vector(0,0,600)
	local enhanced = false

	spendCP(caster, ability)
	applyDelayCooldowns(caster, ability)

	if validEnhancedCraft(caster, target) then
		executeEnhancedCraft(caster, target)
		enhanced = true
	end

	local crit = false
	if caster:HasModifier("modifier_crit") then
		crit = true
		caster:RemoveModifierByName("modifier_crit")
	end

	local arrows_fired = 0
	Timers:CreateTimer(0, function()
		fireArrow(caster, target_point, arrow_origin_offset, enhanced, crit)
		arrows_fired = arrows_fired + 1
		if arrows_fired < total_arrows then
			return arrow_interval
		end
	end)
end

function fireArrow(caster, origin, arrow_origin_offset, enhanced, crit)
	local ability = caster:FindAbilityByName("molten_rain")
	local arrow_impact_delay = ability:GetSpecialValueFor("arrow_impact_delay")
	local radius = ability:GetSpecialValueFor("radius")

	local arrow_destination = GetGroundPosition(randomPointInCircle(origin, radius), caster)
	local arrow_origin = arrow_origin_offset + arrow_destination
	local direction = (arrow_destination - arrow_origin):Normalized()
	local range = (arrow_origin_offset:Length())
	local travel_speed = range / arrow_impact_delay
	local args = {non_flat = true, enhanced = enhanced, crit = crit}

	-- local arrow_particle = ParticleManager:CreateParticle("particles/crafts/alisa/molten_rain/arrow_start_pos.vpcf", PATTACH_CUSTOMORIGIN, nil)
	-- ParticleManager:SetParticleControl(arrow_particle, 0, arrow_destination)
	-- ParticleManager:SetParticleControl(arrow_particle, 1, arrow_origin)

	-- Timers:CreateTimer(arrow_impact_delay, function()
	-- 	-- ParticleManager:DestroyParticle(arrow_particle, false)

	-- 	local team = caster:GetTeamNumber()
	-- 	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	-- 	local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
	-- 	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	-- 	local iOrder = FIND_ANY_ORDER
	-- 	local targets = FindUnitsInRadius(team, arrow_destination, nil, arrow_radius, iTeam, iType, iFlag, iOrder, false)
	-- 	for k,unit in pairs(targets) do
	-- 		dealDamage(unit, caster, damage, damage_type, ability)
	-- 		ability:ApplyDataDrivenModifier(caster, unit, "modifier_molten_rain_slow", {})
	-- 	end
	-- end)

	ProjectileList:CreateLinearProjectile(caster, arrow_origin, direction, travel_speed, range, arrowImpact, nil, nil, "particles/crafts/alisa/molten_rain/arrow_linear.vpcf", args)
end

function arrowImpact(caster, origin_location, direction, speed, range, collisionRules, collisionFunction, other_args, units_hit)
	local ability = caster:FindAbilityByName("molten_rain")
	local arrow_radius = ability:GetSpecialValueFor("arrow_radius")
	local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100
	local damage_type = ability:GetAbilityDamageType()
	local sear_duration = ability:GetSpecialValueFor("sear_duration")
	local burn_duration = ability:GetSpecialValueFor("unbalanced_burn_duration")
	local adf_reduction = ability:GetSpecialValueFor("unbalanced_adf_down")
	local adf_reduction_duration = ability:GetSpecialValueFor("unbalanced_adf_down_duration")
	if other_args.enhanced then
		damage_scale = ability:GetSpecialValueFor("unbalanced_damage_percent") / 100
	end
	if other_args.crit then damage_scale = damage_scale * 2 end

	local team = caster:GetTeamNumber()
	local target_point = origin_location + direction * range
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, target_point, nil, arrow_radius, iTeam, iType, iFlag, iOrder, false)
	for k,unit in pairs(targets) do
		applyEffect(unit, damage_type, function()
			dealScalingDamage(unit, caster, damage_type, damage_scale, ability, CRAFT_CP_GAIN_FACTOR, enhanced)
			unit:AddNewModifier(caster, ability, "modifier_sear", {duration = sear_duration})
			if other_args.enhanced then
				unit:AddNewModifier(caster, ability, "modifier_burn", {duration = burn_duration})
				modifyStat(unit, STAT_ADF_DOWN, adf_reduction, adf_reduction_duration)
			end
		end)
	end
	-- DebugDrawCircle(target_point, Vector(255,0,0), 0.5, arrow_radius, true, 1)
end
require "projectile_list"
require "combat_links"
require "game_functions"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target_points[1]
	local target = keys.target

	local radius = ability:GetSpecialValueFor("radius")
	local range = ability:GetSpecialValueFor("range")
	local travel_speed = ability:GetSpecialValueFor("travel_speed")
	local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100
	local impactFunction = nil

	modifyCP(caster, getCPCost(ability) * -1)
	applyDelayCooldowns(caster, ability)

	if validEnhancedCraft(caster, target) then
		caster:RemoveModifierByName("modifier_combat_link_followup_available")
		target:RemoveModifierByName("modifier_combat_link_unbalanced")

		damage_scale = ability:GetSpecialValueFor("unbalanced_damage_percent") / 100
		travel_speed = ability:GetSpecialValueFor("unbalanced_travel_speed")
		range = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() 
		impactFunction = explode
	end

	local crit = false
	if caster:HasModifier("modifier_crit") then
		crit = true
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

	ProjectileList:CreateLinearProjectile(caster, origin_location, direction, travel_speed, range, impactFunction, collisionRules, flambergeHit, "particles/crafts/alisa/flamberge/flamberge.vpcf", {damage_scale = damage_scale, crit = crit})
end

function flambergeHit(caster, unit, other_args)
	local ability = caster:FindAbilityByName("flamberge")
	local damage_scale = other_args.damage_scale
	local damage_type = ability:GetAbilityDamageType()
	local bonus_unbalance = ability:GetSpecialValueFor("bonus_unbalance")
	local duration = ability:GetSpecialValueFor("burn_duration")

	if other_args.crit then damage_scale = damage_scale * 2 end

	dealScalingDamage(unit, caster, damage_type, damage_scale, ability)
	increaseUnbalance(caster, unit, bonus_unbalance)
	unit:AddNewModifier(caster, ability, "modifier_burn", {duration = duration})
	unit:Interrupt()
end

function explode(caster, origin_location, direction, speed, range, collisionRules, collisionFunction, other_args, units_hit)
	local ability = caster:FindAbilityByName("flamberge")
	local radius = ability:GetSpecialValueFor("unbalanced_explosion_radius")
	local target_point = origin_location + direction * range

	local team = caster:GetTeamNumber()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, target_point, nil, radius, iTeam, iType, iFlag, iOrder, false)
	for k,unit in pairs(targets) do
		if not units_hit[unit] then
			flambergeHit(caster, unit, other_args)
		end
	end

	createFireField(caster, target_point, other_args.crit)
end

function createFireField(caster, location, crit)
	local ability = caster:FindAbilityByName("flamberge")
	local damage_interval = ability:GetSpecialValueFor("unbalanced_field_damage_interval")
	local damage_scale = ability:GetSpecialValueFor("unbalanced_field_damage_percent") * damage_interval / 100 
	local damage_type = ability:GetAbilityDamageType()
	local duration = ability:GetSpecialValueFor("unbalanced_field_duration")
	local radius = ability:GetSpecialValueFor("unbalanced_explosion_radius")
	-- DebugDrawCircle(location, Vector(255,0,0), 0.5, radius, true, duration)

	if crit then damage_scale = damage_scale * 2 end

	local fire_field_particle = ParticleManager:CreateParticle("particles/crafts/alisa/flamberge/fire_field.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(fire_field_particle, 0, location)
	ParticleManager:SetParticleControl(fire_field_particle, 1, location)

	local duration_elapsed = 0

	Timers:CreateTimer(damage_interval, function()
		local team = caster:GetTeamNumber()
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_ANY_ORDER
		local targets = FindUnitsInRadius(team, location, nil, radius, iTeam, iType, iFlag, iOrder, false)
		for k,unit in pairs(targets) do
			dealScalingDamage(unit, caster, damage_type, damage_scale)
			ability:ApplyDataDrivenModifier(caster, unit, "modifier_flamberge_silence", {})
		end
		duration_elapsed = duration_elapsed + damage_interval
		if duration_elapsed < duration then
			return damage_interval
		else
			ParticleManager:DestroyParticle(fire_field_particle, false)
		end
	end)
end
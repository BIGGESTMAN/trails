require "projectile_list"
require "combat_links"
require "game_functions"

function channelFinished(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local min_multiplier = 0.3
	local submax_chargetime_multiplier = 0.7
	local radius = ability:GetSpecialValueFor("radius")
	local range = ability:GetSpecialValueFor("range")
	local travel_speed = ability:GetSpecialValueFor("travel_speed")
	local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100
	local burn_duration = ability:GetSpecialValueFor("burn_duration")
	local impactFunction = nil

	local strength_multiplier = 0.3
	local channel_time_percent = (GameRules:GetGameTime() - ability:GetChannelStartTime()) / ability:GetChannelTime()
	if channel_time_percent < 1 then
		strength_multiplier = channel_time_percent * (submax_chargetime_multiplier - min_multiplier) + min_multiplier
	else
		strength_multiplier = 1
	end

	range = range * strength_multiplier
	travel_speed = travel_speed * strength_multiplier
	burn_duration = burn_duration * strength_multiplier

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
	local origin_location = caster:GetAbsOrigin()

	ProjectileList:CreateLinearProjectile(caster, origin_location, caster.flamberge_direction, travel_speed, range, impactFunction, collisionRules, flambergeHit, "particles/crafts/alisa/flamberge/flamberge.vpcf", {damage_scale = damage_scale, crit = crit, burn_duration = burn_duration})
	caster.flamberge_direction = nil
end

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target_points[1]
	local direction = (target_point - caster:GetAbsOrigin()):Normalized()
	caster.flamberge_direction = direction

	spendCP(caster, ability)
	applyDelayCooldowns(caster, ability)
end

function flambergeHit(caster, unit, other_args)
	local ability = caster:FindAbilityByName("flamberge")
	local damage_scale = other_args.damage_scale
	local damage_type = ability:GetAbilityDamageType()
	local bonus_unbalance = ability:GetSpecialValueFor("bonus_unbalance")

	if other_args.crit then damage_scale = damage_scale * 2 end

	applyEffect(unit, damage_type, function()
		dealScalingDamage(unit, caster, damage_type, damage_scale, ability, CRAFT_CP_GAIN_FACTOR)
		increaseUnbalance(caster, unit, bonus_unbalance)
		unit:AddNewModifier(caster, ability, "modifier_burn", {duration = other_args.burn_duration})
		unit:Interrupt()
	end)
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
			dealScalingDamage(unit, caster, damage_type, damage_scale, ability, CRAFT_CP_GAIN_FACTOR)
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
require "game_functions"
require "combat_links"
require "projectile_list"
require "crafts/rean/gale"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target_points[1]
	local target = keys.target

	local direction = (target_point - caster:GetAbsOrigin()):Normalized()
	local range = ability:GetSpecialValueFor("range")
	local speed = ability:GetSpecialValueFor("projectile_speed")
	local radius = ability:GetSpecialValueFor("radius")
	local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100
	local delay_inflicted = ability:GetSpecialValueFor("delay_inflicted")
	local impactFunction = nil

	local enhanced = false
	if validEnhancedCraft(caster, target) then
		caster:RemoveModifierByName("modifier_combat_link_followup_available")
		target:RemoveModifierByName("modifier_combat_link_unbalanced")

		damage_scale = ability:GetSpecialValueFor("unbalanced_damage_percent") / 100
		delay_inflicted = ability:GetSpecialValueFor("unbalanced_delay_inflicted")
		impactFunction = createWindPath
		enhanced = true
	end
	
	if caster:HasModifier("modifier_crit") then
		damage_scale = damage_scale * 2
		caster:RemoveModifierByName("modifier_crit")
	end

	modifyCP(caster, getCPCost(ability) * -1)
	applyDelayCooldowns(caster, ability)

	collisionRules = {
		team = caster:GetTeamNumber(),
		radius = radius,
		iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL,
		iFlag = DOTA_UNIT_TARGET_FLAG_NONE,
		iOrder = FIND_ANY_ORDER
	}
	ProjectileList:CreateLinearProjectile(caster, caster:GetAbsOrigin(), direction, speed, range, impactFunction, collisionRules, arcSlashHit, "particles/crafts/rean/arc_slash/arc_slash.vpcf", {damage_scale = damage_scale, delay_inflicted = delay_inflicted, enhanced = enhanced})
end

function arcSlashHit(caster, unit, other_args)
	local ability = caster:FindAbilityByName("arc_slash")
	local damage_type = ability:GetAbilityDamageType()

	dealScalingDamage(unit, caster, damage_type, other_args.damage_scale, ability, CRAFT_CP_GAIN_FACTOR, other_args.enhanced)
	increaseUnbalance(caster, unit)
	inflictDelay(unit, other_args.delay_inflicted)
	applyGaleMark(caster, unit)
end

function createWindPath(caster, origin_location, direction, speed, range)
	local ability = caster:FindAbilityByName("arc_slash")
	local wind_path_duration = ability:GetSpecialValueFor("unbalanced_wind_duration")
	local radius = ability:GetSpecialValueFor("radius")
	local duration_elapsed = 0
	local update_interval = 1/30

	-- local particle_dummy = CreateUnitByName("npc_dummy_unit", origin_location, false, caster, caster, caster:GetTeamNumber())
	-- particle_dummy:SetAbsOrigin(origin_location + direction * range / 2)
	-- particle_dummy:SetForwardVector(direction)
	local particle = ParticleManager:CreateParticle("particles/crafts/rean/arc_slash/wind_path.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, origin_location)
	ParticleManager:SetParticleControl(particle, 1, direction * range + origin_location)

	Timers:CreateTimer(0, function()
		local team = caster:GetTeamNumber()
		local iTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY
		local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
		local iOrder = FIND_ANY_ORDER
		local targets = FindUnitsInLine(team, origin_location, origin_location + direction * range, nil, radius, iTeam, iType, iOrder)
		for k,unit in pairs(targets) do
			ability:ApplyDataDrivenModifier(unit, unit, "modifier_arc_slash_speedbuff", {})
		end
		duration_elapsed = duration_elapsed + update_interval
		if duration_elapsed < wind_path_duration then return update_interval else ParticleManager:DestroyParticle(particle, false) end
	end)
end
require "game_functions"
require "combat_links"
require "projectile_list"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target_points[1]
	local target = keys.target

	local direction = (target_point - caster:GetAbsOrigin()):Normalized()
	local range = ability:GetSpecialValueFor("range")
	local speed = ability:GetSpecialValueFor("projectile_speed")
	local radius = ability:GetSpecialValueFor("radius")
	local damage = caster:GetAverageTrueAttackDamage() * ability:GetSpecialValueFor("damage_percent") / 100
	local stun_duration = ability:GetSpecialValueFor("stun_duration")
	local impactFunction = nil

	if validEnhancedCraft(caster, target) then
		caster:RemoveModifierByName("modifier_combat_link_followup_available")
		target:RemoveModifierByName("modifier_combat_link_unbalanced")

		damage = caster:GetAverageTrueAttackDamage() * ability:GetSpecialValueFor("unbalanced_damage_percent") / 100
		stun_duration = ability:GetSpecialValueFor("unbalanced_stun_duration")
		impactFunction = createWindPath
	end

	modifyCP(caster, getCPCost(ability) * -1)

	collisionRules = {
		team = caster:GetTeamNumber(),
		radius = radius,
		iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL,
		iFlag = DOTA_UNIT_TARGET_FLAG_NONE,
		iOrder = FIND_ANY_ORDER
	}
	ProjectileList:CreateLinearProjectile(caster, caster:GetAbsOrigin(), direction, speed, range, impactFunction, collisionRules, arcSlashHit, "particles/crafts/rean/arc_slash/arc_slash.vpcf", {damage = damage, stun_duration = stun_duration})
end

function arcSlashHit(caster, unit, other_args)
	local ability = caster:FindAbilityByName("arc_slash")
	local damage_type = ability:GetAbilityDamageType()

	dealDamage(unit, caster, other_args.damage, damage_type, ability)
	increaseUnbalance(caster, unit)
	ability:ApplyDataDrivenModifier(caster, unit, "modifier_arc_slash_stun", {duration = other_args.stun_duration})
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
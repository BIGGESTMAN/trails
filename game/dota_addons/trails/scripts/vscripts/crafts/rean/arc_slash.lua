require "game_functions"
require "combat_links"
require "projectile_list"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target_points[1]

	local direction = (target - caster:GetAbsOrigin()):Normalized()
	local range = ability:GetSpecialValueFor("range")
	local speed = ability:GetSpecialValueFor("projectile_speed")
	local radius = ability:GetSpecialValueFor("radius")

	modifyCP(caster, getCPCost(ability) * -1)

	collisionRules = {
		team = caster:GetTeamNumber(),
		radius = radius,
		iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL,
		iFlag = DOTA_UNIT_TARGET_FLAG_NONE,
		iOrder = FIND_ANY_ORDER
	}
	ProjectileList:CreateLinearProjectile(caster, caster:GetAbsOrigin(), direction, speed, range, nil, collisionRules, arcSlashHit, "particles/crafts/rean/arc_slash/arc_slash.vpcf")
end

function arcSlashHit(caster, unit)
	local ability = caster:FindAbilityByName("arc_slash")
	local damage = caster:GetAverageTrueAttackDamage() * ability:GetSpecialValueFor("damage_percent") / 100
	local damage_type = ability:GetAbilityDamageType()

	dealDamage(unit, caster, damage, damage_type, ability)
	attemptUnbalance(caster, unit)
	ability:ApplyDataDrivenModifier(caster, unit, "modifier_arc_slash_stun", {})
end
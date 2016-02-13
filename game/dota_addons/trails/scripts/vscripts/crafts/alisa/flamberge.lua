require "projectile_list"
require "combat_links"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target:GetAbsOrigin()

	local radius = ability:GetSpecialValueFor("radius")
	local range = ability:GetSpecialValueFor("range")
	local travel_speed = ability:GetSpecialValueFor("travel_speed")

	-- modifyCP(caster, getCPCost(ability) * -1)

	collisionRules = {
		team = caster:GetTeamNumber(),
		radius = radius,
		iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL,
		iFlag = DOTA_UNIT_TARGET_FLAG_NONE,
		iOrder = FIND_ANY_ORDER
	}
	local direction = (target_point - caster:GetAbsOrigin()):Normalized()
	local origin_location = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_attack1"))

	ProjectileList:CreateLinearProjectile(caster, origin_location, direction, travel_speed, range, nil, collisionRules, flambergeHit, "particles/crafts/alisa/flamberge/flamberge.vpcf")
end

function flambergeHit(caster, unit)
	local ability = caster:FindAbilityByName("flamberge")
	local damage = caster:GetAverageTrueAttackDamage() * ability:GetSpecialValueFor("damage_percent") / 100
	local damage_type = ability:GetAbilityDamageType()
	local bonus_unbalance_chance = ability:GetSpecialValueFor("bonus_unbalance_chance")
	local duration = ability:GetSpecialValueFor("burn_duration")

	dealDamage(unit, caster, damage, damage_type, ability)
	increaseUnbalance(caster, unit, bonus_unbalance_chance)
	unit:AddNewModifier(caster, ability, "modifier_burn", {duration = duration})
	unit:Interrupt()
end
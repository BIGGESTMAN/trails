require "game_functions"

LinkLuaModifier("modifier_judgment_arrow_empowered", "abilities/crafts/alisa/judgment_arrow.lua", LUA_MODIFIER_MOTION_NONE)

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability

	fireArrow(caster)
	if getCP(caster) == MAX_CP then empowerCaster(caster) end
	spendCP(caster, keys.ability)
	applyDelayCooldowns(caster, keys.ability)
end

function fireArrow(caster)
	local ability = caster:FindAbilityByName("judgment_arrow")

	local range = ability:GetSpecialValueFor("range")
	local travel_speed = ability:GetSpecialValueFor("travel_speed")
	local radius = ability:GetSpecialValueFor("radius")
	local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100
	
	if caster:HasModifier("modifier_crit") then
		damage_scale = damage_scale * 2
		caster:RemoveModifierByName("modifier_crit")
	end

	local collisionRules = {
		team = caster:GetTeamNumber(),
		radius = radius,
		iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL,
		iFlag = DOTA_UNIT_TARGET_FLAG_NONE,
		iOrder = FIND_ANY_ORDER
	}
	local direction = caster:GetForwardVector()
	local origin_location = caster:GetAbsOrigin()

	ProjectileList:CreateLinearProjectile(caster, origin_location, direction, travel_speed, range, nil, collisionRules, judgmentArrowHit, "particles/crafts/alisa/judgment_arrow/projectile.vpcf", {damage_scale = damage_scale, stationary_particle = true})
end

function empowerCaster(caster)
	local ability = caster:FindAbilityByName("judgment_arrow")
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_judgment_arrow_empowered", {duration = ability:GetSpecialValueFor("empowered_duration")})
end

function judgmentArrowHit(caster, unit, other_args, projectile)
	local ability = caster:FindAbilityByName("judgment_arrow")
	local damage_scale = other_args.damage_scale
	local damage_type = ability:GetAbilityDamageType()
	local adf_down = ability:GetSpecialValueFor("adf_down")
	local adf_down_duration = ability:GetSpecialValueFor("adf_down_duration")

	applyEffect(unit, damage_type, function()
		dealScalingDamage(unit, caster, damage_type, damage_scale, ability, SCRAFT_CP_GAIN_FACTOR)
		modifyStat(unit, STAT_ADF_DOWN, adf_down, adf_down_duration)
	end)
end

modifier_judgment_arrow_empowered = class({})

function modifier_judgment_arrow_empowered:FireHolyArrow(target)
	local ability = self:GetAbility()
	local caster = self:GetParent()

	local range = ability:GetSpecialValueFor("empowered_arrows_range")
	local travel_speed = ability:GetSpecialValueFor("empowered_arrows_speed")
	local radius = ability:GetSpecialValueFor("empowered_arrows_radius")

	local collisionRules = {
		team = caster:GetTeamNumber(),
		radius = radius,
		iTeam = DOTA_UNIT_TARGET_TEAM_BOTH,
		iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL,
		iFlag = DOTA_UNIT_TARGET_FLAG_NONE,
		iOrder = FIND_ANY_ORDER
	}
	local direction = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
	local origin_location = caster:GetAbsOrigin()

	local cannot_collide_with = {}
	cannot_collide_with[caster] = true
	ProjectileList:CreateLinearProjectile(caster, origin_location, direction, travel_speed, range, nil, collisionRules, holyArrowHit, "particles/crafts/alisa/judgment_arrow/empowered_arrow.vpcf", {allies_hit = 0, cannot_collide_with = cannot_collide_with})
end

function holyArrowHit(caster, unit, args, projectile)
	local ability = caster:FindAbilityByName("judgment_arrow")

	if unit:GetTeamNumber() == caster:GetTeamNumber() then
		modifyCP(unit, ability:GetSpecialValueFor("empowered_arrows_cp"))
		args.allies_hit = args.allies_hit + 1
	else
		local damage_scale = ability:GetSpecialValueFor("empowered_arrows_damage_percent_per_ally") / 100 * args.allies_hit
		local damage_type = ability:GetAbilityDamageType()
		applyEffect(unit, damage_type, function()
			dealScalingDamage(unit, caster, damage_type, damage_scale, ability)
		end)
		caster:PerformAttack(unit, true, true, true, true, false)
	end
end
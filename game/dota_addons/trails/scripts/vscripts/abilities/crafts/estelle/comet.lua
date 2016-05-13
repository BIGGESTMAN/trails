require "game_functions"
require "libraries/util"

LinkLuaModifier("modifier_comet_passive", "abilities/crafts/estelle/comet.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_comet_mark", "abilities/crafts/estelle/comet.lua", LUA_MODIFIER_MOTION_NONE)
comet = class({})

if IsServer() then
	function comet:OnSpellStart()
		local caster = self:GetCaster()
		local ability = self
		local target_point = self:GetCursorPosition()

		local range = ability:GetSpecialValueFor("range")
		local speed = ability:GetSpecialValueFor("projectile_speed")
		local radius = ability:GetSpecialValueFor("projectile_radius")

		spendCP(caster, ability)
		applyDelayCooldowns(caster, ability)

		local particle_name = "particles/crafts/estelle/comet/projectile.vpcf"
		local direction = (target_point - caster:GetAbsOrigin()):Normalized()
		collisionRules = {
			team = caster:GetTeamNumber(),
			radius = radius,
			iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL,
			iFlag = DOTA_UNIT_TARGET_FLAG_NONE,
			iOrder = FIND_ANY_ORDER
		}
		ProjectileList:CreateLinearProjectile(caster, caster:GetAbsOrigin(), direction, speed, range, nil, collisionRules, cometHit, particle_name, {stationary_particle = true})
	end
end

function comet:GetIntrinsicModifierName()
	return "modifier_comet_passive"
end

function comet:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_3
end

function comet:GetPlaybackRateOverride()
	return 0.5
end

function cometHit(caster, target, args, projectile, range, collisionRules, collisionFunction, particle_name, speed)
	local ability = caster:FindAbilityByName("comet")
	local damage_type = ability:GetAbilityDamageType()
	local base_damage_scale = ability:GetSpecialValueFor("damage_percent") / 100
	local damage_scale_per_instance = ability:GetSpecialValueFor("damage_percent_per_instance") / 100

	local marks_on_enemy = getNumberOfModifierInstances(target, "modifier_comet_mark")
	local damage_scale = base_damage_scale + damage_scale_per_instance * marks_on_enemy

	applyEffect(target, damage_type, function()
		dealScalingDamage(target, caster, damage_type, damage_scale, ability, CRAFT_CP_GAIN_FACTOR)
	end)
end

modifier_comet_passive = class({})

function modifier_comet_passive:IsHidden()
	return true
end

if IsServer() then
	function modifier_comet_passive:OnTakeDamage(params)
		local hero = self:GetParent()
		local target = params.unit
		local ability = self:GetAbility()
		if params.attacker == hero and params.damage_type == DAMAGE_TYPE_PHYSICAL then
			target:AddNewModifier(hero, ability, "modifier_comet_mark", {duration = ability:GetSpecialValueFor("mark_duration")})
		end
	end
end

function modifier_comet_passive:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE}
end

modifier_comet_mark = class({})

function modifier_comet_mark:IsHidden()
	return true
end

function modifier_comet_mark:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end
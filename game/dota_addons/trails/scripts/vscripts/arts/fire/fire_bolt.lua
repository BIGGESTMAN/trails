require "game_functions"
require "arts"
require "projectile_list"

item_fire_bolt = class({})

if IsServer() then
	function item_fire_bolt:OnSpellStart()
		local caster = self:GetCaster()
		local ability = self
		local target = self:GetCursorTarget()

		local projectile_speed = 900
		local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100

		if caster:HasModifier("modifier_crit") then
			damage_scale = damage_scale * 2
			caster:RemoveModifierByName("modifier_crit")
		end

		applyArtsDelayCooldowns(caster, ability)

		ProjectileList:CreateTrackingProjectile(caster, target, projectile_speed, fireBoltHit, "particles/units/heroes/hero_invoker/invoker_forged_spirit_projectile.vpcf", {ability = ability, damage_scale = damage_scale})

		endCastParticle(caster)
	end

	function fireBoltHit(caster, target, projectile_speed, args)
		local ability = args.ability
		local damage_scale = args.damage_scale
		local damage_type = DAMAGE_TYPE_MAGICAL
		local burn_duration = ability:GetSpecialValueFor("duration")

		target:AddNewModifier(caster, ability, "modifier_burn", {duration = burn_duration})
		dealScalingDamage(target, caster, damage_type, damage_scale, ability)
	end

	function item_fire_bolt:OnAbilityPhaseStart()
		createCastParticle(self:GetCaster())
		return true
	end

	function item_fire_bolt:OnAbilityPhaseInterrupted()
		endCastParticle(self:GetCaster())
	end
end
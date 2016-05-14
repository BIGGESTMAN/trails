require "game_functions"
require "arts"
require "projectile_list"

item_tear = class({})

if IsServer() then
	function item_tear:OnSpellStart()
		local caster = self:GetCaster()
		local ability = self
		local target = self:GetCursorTarget()

		local healing_scale = ability:GetSpecialValueFor("healing_percent") / 100

		if caster:HasModifier("modifier_crit") then
			healing_scale = healing_scale * 2
			caster:RemoveModifierByName("modifier_crit")
		end

		applyHealing(target, caster, getStats(caster).ats * healing_scale)

		ParticleManager:CreateParticle("particles/arts/water/tear/heal.vpcf", PATTACH_ABSORIGIN, target)

		applyArtsDelayCooldowns(caster, ability)

		endCastParticle(caster)
	end

	function item_tear:OnAbilityPhaseStart()
		createCastParticle(self:GetCaster(), self)
		return true
	end

	function item_tear:OnAbilityPhaseInterrupted()
		endCastParticle(self:GetCaster())
	end
end
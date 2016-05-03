require "game_functions"
require "arts"

item_earth_pulse = class({})

if IsServer() then
	function item_earth_pulse:OnSpellStart()
		local caster = self:GetCaster()
		local ability = self
		local target = self:GetCursorTarget()

		local duration = 15

		applyArtsDelayCooldowns(caster, ability)

		target:AddNewModifier(caster, ability, "modifier_hp_regen", {duration = duration})

		endCastParticle(caster)
	end

	function item_earth_pulse:OnAbilityPhaseStart()
		createCastParticle(self:GetCaster(), self)
		return true
	end

	function item_earth_pulse:OnAbilityPhaseInterrupted()
		endCastParticle(self:GetCaster())
	end

	function item_earth_pulse:GetCastAnimation()
		return ACT_DOTA_TELEPORT
	end
end
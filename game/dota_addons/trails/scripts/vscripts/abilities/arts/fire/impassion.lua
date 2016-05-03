require "game_functions"
require "arts"

item_impassion = class({})

if IsServer() then
	function item_impassion:OnSpellStart()
		local caster = self:GetCaster()
		local ability = self
		local target = self:GetCursorTarget()

		local duration = 10

		applyArtsDelayCooldowns(caster, ability)

		target:AddNewModifier(caster, ability, "modifier_passion", {duration = duration})

		endCastParticle(caster)
	end

	function item_impassion:OnAbilityPhaseStart()
		createCastParticle(self:GetCaster(), self)
		return true
	end

	function item_impassion:OnAbilityPhaseInterrupted()
		endCastParticle(self:GetCaster())
	end
end
require "game_functions"
require "arts"
require "libraries/util"

item_thelas = class({})

if IsServer() then
	function item_thelas:OnSpellStart()
		local caster = self:GetCaster()
		local ability = self
		local target_point = self:GetCursorPosition()

		local radius = 200
		local healing_scale = ability:GetSpecialValueFor("healing_percent") / 100

		if caster:HasModifier("modifier_crit") then
			healing_scale = healing_scale * 2
			caster:RemoveModifierByName("modifier_crit")
		end

		local target = nil
		local team = caster:GetTeamNumber()
		local iTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY
		local iType = DOTA_UNIT_TARGET_HERO
		local iFlag = DOTA_UNIT_TARGET_FLAG_DEAD
		local iOrder = FIND_ANY_ORDER
		local targets = FindUnitsInRadius(team, target_point, nil, radius, iTeam, iType, iFlag, iOrder, false)
		for k,unit in pairs(targets) do
			if unit ~= caster and not unit:IsAlive() then
				target = unit
				break
			end
		end

		if target then
			reviveHero(target, getStats(caster).ats * healing_scale)
		end

		applyArtsDelayCooldowns(caster, ability)

		endCastParticle(caster)
	end

	function item_thelas:OnAbilityPhaseStart()
		createCastParticle(self:GetCaster())
		return true
	end

	function item_thelas:OnAbilityPhaseInterrupted()
		endCastParticle(self:GetCaster())
	end
end
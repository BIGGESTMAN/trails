require "game_functions"
require "arts"

item_luminous_ray = class({})

if IsServer() then
	function item_luminous_ray:OnSpellStart()
		local caster = self:GetCaster()
		local ability = self
		local target_point = self:GetCursorPosition()

		local range = 800
		local radius = ability:GetSpecialValueFor("width")
		local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100
		local damage_type = DAMAGE_TYPE_MAGICAL

		if caster:HasModifier("modifier_crit") then
			damage_scale = damage_scale * 2
			caster:RemoveModifierByName("modifier_crit")
		end

		applyArtsDelayCooldowns(caster, ability)

		local direction = (target_point - caster:GetAbsOrigin()):Normalized()
		local end_point = caster:GetAbsOrigin() + direction * range

		local team = caster:GetTeamNumber()
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
		local iOrder = FIND_ANY_ORDER
		local targets = FindUnitsInLine(team, caster:GetAbsOrigin(), end_point, nil, radius, iTeam, iType, iOrder)
		for k,unit in pairs(targets) do
			dealScalingDamage(unit, caster, damage_type, damage_scale, ability)
		end

		local particle = ParticleManager:CreateParticle("particles/arts/mirage/luminous_ray/beam.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
		ParticleManager:SetParticleControl(particle, 1, GetGroundPosition(end_point, caster))

		endCastParticle(caster)
	end

	function item_luminous_ray:OnAbilityPhaseStart()
		createCastParticle(self:GetCaster())
		return true
	end

	function item_luminous_ray:OnAbilityPhaseInterrupted()
		endCastParticle(self:GetCaster())
	end
end
require "game_functions"
require "arts"

item_earth_lance = class({})

if IsServer() then
	function item_earth_lance:OnSpellStart()
		local caster = self:GetCaster()
		local ability = self
		local target = self:GetCursorTarget()

		local radius = ability:GetSpecialValueFor("radius")
		local petrify_duration = ability:GetSpecialValueFor("petrify_duration")

		applyArtsDelayCooldowns(caster, ability)

		local team = caster:GetTeamNumber()
		local origin = caster:GetAbsOrigin()
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_ANY_ORDER
		local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

		ability.targets_hit = {}
		for k,unit in pairs(targets) do
			createSpike(caster, ability, unit)
			if ability.targets_hit[unit] == 1 then
				unit:AddNewModifier(caster, ability, "modifier_petrify", {duration = petrify_duration})
			end
		end
		ability.targets_hit = nil

		endCastParticle(caster)
	end

	function createSpike(caster, ability, target)
		local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100
		local spike_radius = ability:GetSpecialValueFor("spike_radius")
		local damage_type = DAMAGE_TYPE_MAGICAL

		local team = caster:GetTeamNumber()
		local origin = target:GetAbsOrigin()
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_ANY_ORDER
		local targets = FindUnitsInRadius(team, origin, nil, spike_radius, iTeam, iType, iFlag, iOrder, false)
		for k,unit in pairs(targets) do
			if not ability.targets_hit[unit] then
				dealScalingDamage(target, caster, damage_type, damage_scale, ability)
				ability.targets_hit[unit] = 0
			end
			ability.targets_hit[unit] = ability.targets_hit[unit] + 1
		end
		-- DebugDrawCircle(origin, Vector(255,0,0), 0.5, spike_radius, true, 3)
		local particle = ParticleManager:CreateParticle("particles/arts/earth/earth_lance/spikes.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(particle, 0, origin)
	end

	function item_earth_lance:OnAbilityPhaseStart()
		createCastParticle(self:GetCaster())
		return true
	end

	function item_earth_lance:OnAbilityPhaseInterrupted()
		endCastParticle(self:GetCaster())
	end
end
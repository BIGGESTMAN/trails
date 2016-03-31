require "game_functions"
require "arts"
require "libraries/util"

item_seraphic_ring = class({})

if IsServer() then
	function SeraphicHeal(caster, unit, healing_percent, hp_regen_duration)
		if not unit:IsAlive() then
			reviveHero(unit, 1)
		end
		applyHealing(unit, caster, unit:GetMaxHealth() * healing_percent)
		unit:AddNewModifier(caster, ability, "modifier_hp_regen", {duration = hp_regen_duration})
	end

	function item_seraphic_ring:OnSpellStart()
		local caster = self:GetCaster()
		local ability = self

		local origin = caster:GetAbsOrigin()
		local hp_regen_duration = 6
		local initial_radius = 200
		local end_radius = 2000
		local speed = 600
		local healing_multiplier_per_unit = 0.6
		local healing_percent = 1

		if caster:HasModifier("modifier_crit") then
			healing_percent = healing_percent * 2
			caster:RemoveModifierByName("modifier_crit")
		end

		local update_interval = 1/30
		local radius_increase = speed * update_interval

		local current_min_radius = 0
		local current_max_radius = initial_radius
		SeraphicHeal(caster, caster, healing_percent, hp_regen_duration)
		units_hit = {caster = true}

		local particle = ParticleManager:CreateParticle("particles/arts/space/seraphic_ring/ring.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(particle, 0, origin)

		Timers:CreateTimer(0, function()
			local team = caster:GetTeamNumber()
			local iTeam = DOTA_UNIT_TARGET_TEAM_BOTH
			local iType = DOTA_UNIT_TARGET_HERO
			local iFlag = DOTA_UNIT_TARGET_FLAG_DEAD
			local iOrder = FIND_ANY_ORDER
			local targets = FindUnitsInRadius(team, origin, nil, current_max_radius, iTeam, iType, iFlag, iOrder, false)
			for k,unit in pairs(targets) do
				local distance = (unit:GetAbsOrigin() - origin):Length2D()
				if distance >= current_min_radius and not units_hit[unit] then
					units_hit[unit] = true
					if unit:GetTeamNumber() == team then
						SeraphicHeal(caster, unit, healing_percent, hp_regen_duration)
					else
						healing_percent = healing_percent * healing_multiplier_per_unit
					end
				end
			end
			current_min_radius = current_min_radius + radius_increase
			current_max_radius = current_max_radius + radius_increase
			if current_max_radius < end_radius then
				return update_interval
			else
				ParticleManager:DestroyParticle(particle, false)
			end
		end)

		applyArtsDelayCooldowns(caster, ability)

		endCastParticle(caster)
	end

	function item_seraphic_ring:OnAbilityPhaseStart()
		createCastParticle(self:GetCaster())
		return true
	end

	function item_seraphic_ring:OnAbilityPhaseInterrupted()
		endCastParticle(self:GetCaster())
	end
end
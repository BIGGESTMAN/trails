require "game_functions"
require "projectile_list"
require "libraries/notifications"

LinkLuaModifier("modifier_unbalanced_level", "modifier_unbalanced_level.lua", LUA_MODIFIER_MOTION_NONE)

function checkForLink(keys)
	local caster = keys.caster
	local ability = keys.ability
	local link_range = ability:GetSpecialValueFor("link_radius")
	local link_break_range = ability:GetSpecialValueFor("link_break_range")

	if caster.combat_linked_to then
		if not IsValidEntity(caster.combat_linked_to) or not caster.combat_linked_to:IsAlive() or
		(((caster.combat_linked_to:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() > link_break_range or caster:HasModifier("modifier_link_broken") or caster.combat_linked_to:HasModifier("modifier_link_broken"))
		and not caster:HasModifier("modifier_unshatterable_bonds")) then
			if IsValidEntity(caster.combat_linked_to) then
				removeLink(caster.combat_linked_to)
			end
			removeLink(caster)
		end
	end

	if not caster.combat_linked_to then
		local team = caster:GetTeamNumber()
		local origin = caster:GetAbsOrigin()
		local radius = link_range
		local iTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY
		local iType = DOTA_UNIT_TARGET_HERO
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_CLOSEST
		local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

		for k,target in pairs(targets) do
			if target ~= caster and not target.combat_linked_to and not caster:HasModifier("modifier_link_broken") and not target:HasModifier("modifier_link_broken") then
				caster.combat_linked_to = target
				target.combat_linked_to = caster
				ability:ApplyDataDrivenModifier(caster, caster, "modifier_combat_link_linked", {})
				ability:ApplyDataDrivenModifier(target, target, "modifier_combat_link_linked", {})

				caster.tether_particle = ParticleManager:CreateParticle("particles/combat_links/link.vpcf", PATTACH_POINT_FOLLOW, caster)
				ParticleManager:SetParticleControlEnt(caster.tether_particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
				ParticleManager:SetParticleControlEnt(caster.tether_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
				CustomGameEventManager:Send_ServerToPlayer(caster:GetOwner(), "ally_ability_bar_start", {heroIndex = target:GetEntityIndex(), cpCosts = getAbilityCPCosts(target)})
				CustomGameEventManager:Send_ServerToPlayer(target:GetOwner(), "ally_ability_bar_start", {heroIndex = caster:GetEntityIndex(), cpCosts = getAbilityCPCosts(caster)})
				break
			end
		end
	end
end

function removeLink(unit)
	unit.combat_linked_to = nil
	unit:RemoveModifierByName("modifier_combat_link_linked")
	if unit.tether_particle then
		ParticleManager:DestroyParticle(unit.tether_particle, false)
		unit.tether_particle = nil
	end
	CustomGameEventManager:Send_ServerToPlayer(unit:GetOwner(), "ally_ability_bar_remove", {})
end

function attackLanded(keys)
	increaseUnbalance(keys.caster, keys.target)
end

function increaseUnbalance(caster, target, bonus_increase)
	local ability = caster:FindAbilityByName("combat_link")

	local base_increase = ability:GetSpecialValueFor("base_unbalance_increase")
	-- local base_increase = 100 -- for testing
	local unbalance_threshold = ability:GetSpecialValueFor("unbalance_threshold")
	bonus_increase = bonus_increase or 0

	if caster.combat_linked_to then
		local modifier = target:FindModifierByName("modifier_unbalanced_level")
		if modifier then -- to make script not crash when hitting creeps ~_~
			local unbalance_increase = (base_increase + bonus_increase) * getHeroLinkScaling(hero)
			modifier:IncreaseLevel(unbalance_increase)
			if modifier:GetStackCount() >= unbalance_threshold or caster:HasModifier("modifier_brute_force") then
				ability:ApplyDataDrivenModifier(caster, caster.combat_linked_to, "modifier_combat_link_followup_available", {})
				ability:ApplyDataDrivenModifier(caster, target, "modifier_combat_link_unbalanced", {})
				modifier:SetStackCount(0)
				caster:RemoveModifierByName("modifier_brute_force")
				triggerUnbalanceEvent(target)
			end
		end
	end
end

function triggerUnbalanceEvent(target)
	triggerModifierEvent("unit_unbalanced", {unit = target})
end

function followupAvailable(keys)
	if getCP(keys.target) >= SCRAFT_MINIMUM_CP then
		keys.target:GetAbilityByIndex(4):SetActivated(true)
	end
end

function followupUnavailable(keys)
	-- Disable s-crafts except as enhanced crafts
	keys.target:GetAbilityByIndex(4):SetActivated(false)
end

function createUnbalanceModifier(keys)
	local caster = keys.caster
	local ability = keys.ability

	caster:AddNewModifier(caster, ability, "modifier_unbalanced_level", {})
end
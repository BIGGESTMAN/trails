require "game_functions"
require "libraries/notifications"
require "libraries/util"

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
		for k,target in pairs(getAllLivingHeroes()) do
			if distanceBetween(target:GetAbsOrigin(), caster:GetAbsOrigin()) <= link_range and target:GetTeamNumber() == caster:GetTeamNumber() and target ~= caster and not target.combat_linked_to and not caster:HasModifier("modifier_link_broken") and not target:HasModifier("modifier_link_broken") then
				formLink(caster, target, ability)
				break
			end
		end
	end
end

function formLink(unit, target, ability)
	unit.combat_linked_to = target
	target.combat_linked_to = unit
	ability:ApplyDataDrivenModifier(unit, unit, "modifier_combat_link_linked", {})
	ability:ApplyDataDrivenModifier(target, target, "modifier_combat_link_linked", {})

	unit.tether_particle = ParticleManager:CreateParticle("particles/combat_links/link.vpcf", PATTACH_POINT_FOLLOW, unit)
	ParticleManager:SetParticleControlEnt(unit.tether_particle, 0, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(unit.tether_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	CustomGameEventManager:Send_ServerToPlayer(unit:GetOwner(), "ally_ability_bar_start", {heroIndex = target:GetEntityIndex(), cpCosts = getAbilityCPCosts(target)})
	CustomGameEventManager:Send_ServerToPlayer(target:GetOwner(), "ally_ability_bar_start", {heroIndex = unit:GetEntityIndex(), cpCosts = getAbilityCPCosts(unit)})

	CustomNetTables:SetTableValue("combat_links", tostring(unit:entindex()), {link_target = tostring(target:entindex())})
	CustomNetTables:SetTableValue("combat_links", tostring(target:entindex()), {link_target = tostring(unit:entindex())})
	CustomGameEventManager:Send_ServerToPlayer(unit:GetOwner(), "link_formed_or_broken", {})
	CustomGameEventManager:Send_ServerToPlayer(target:GetOwner(), "link_formed_or_broken", {})
end

function removeLink(unit)
	unit.combat_linked_to = nil
	unit:RemoveModifierByName("modifier_combat_link_linked")
	if unit.tether_particle then
		ParticleManager:DestroyParticle(unit.tether_particle, false)
		unit.tether_particle = nil
	end
	CustomGameEventManager:Send_ServerToPlayer(unit:GetOwner(), "ally_ability_bar_remove", {})
	CustomGameEventManager:Send_ServerToPlayer(unit:GetOwner(), "link_formed_or_broken", {})

	CustomNetTables:SetTableValue("combat_links", tostring(unit:entindex()), {link_target = nil})
end

function attackLanded(keys)
	-- increaseUnbalance(keys.caster, keys.target)
end

function increaseUnbalance(caster, target, bonus_increase)
	local ability = caster:FindAbilityByName("combat_link")

	local base_increase = ability:GetSpecialValueFor("base_unbalance_increase")
	-- local base_increase = 100 -- for testing
	local unbalance_threshold = ability:GetSpecialValueFor("unbalance_threshold")
	bonus_increase = bonus_increase or 0

	if caster.combat_linked_to and IsValidAlive(target) and not target:HasModifier("modifier_combat_link_unbalanced") then
		local modifier = target:FindModifierByName("modifier_unbalanced_level")
		if modifier then -- to make script not crash when hitting creeps ~_~
			local unbalance_increase = (base_increase + bonus_increase) * getHeroLinkScaling(caster)
			if target:HasModifier("modifier_balance_down") then unbalance_increase = unbalance_increase * BALANCE_DOWN_UNBALANCE_FACTOR end
			print(unbalance_increase)
			modifier:IncreaseLevel(unbalance_increase)
			if modifier:GetStackCount() >= unbalance_threshold or caster:HasModifier("modifier_brute_force") or ONE_HIT_UNBALANCE then
				applyEnhancedState(caster.combat_linked_to, target)

				ability:ApplyDataDrivenModifier(caster, target, "modifier_combat_link_unbalanced", {})
				modifier:SetStackCount(0)
				caster:RemoveModifierByName("modifier_brute_force")
			end
		end
	end
end

function applyEnhancedState(hero, target)
	hero:FindAbilityByName("combat_link"):ApplyDataDrivenModifier(hero, hero, "modifier_combat_link_followup_available", {})
	triggerUnbalanceEvent(target)
	EmitSoundOn("Trails.Unbalanced", target)
	ParticleManager:CreateParticle("particles/units/heroes/hero_sven/sven_spell_gods_strength.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
end

function triggerUnbalanceEvent(target)
	triggerModifierEventOnAll("unit_unbalanced", {unit = target})
end

function followupAvailable(keys)
	if SCRAFTS_REQUIRE_UNBALANCE and getCP(keys.target) >= SCRAFT_MINIMUM_CP then
		keys.target:GetAbilityByIndex(4):SetActivated(true)
	end
end

function followupUnavailable(keys)
	-- Disable s-crafts except as enhanced crafts
	if SCRAFTS_REQUIRE_UNBALANCE then
		keys.target:GetAbilityByIndex(4):SetActivated(false)
	end
end

function createUnbalanceModifier(keys)
	local caster = keys.caster
	local ability = keys.ability

	caster:AddNewModifier(caster, ability, "modifier_unbalanced_level", {})
end

function createUnbalancedParticle(keys)
	local particle_owners = nil
	for k,hero in pairs(getAllHeroes()) do
		if hero:HasModifier("modifier_combat_link_followup_available") and hero:GetTeamNumber() ~= keys.target:GetTeamNumber() then
			if not hero.unbalance_targetable_particles then hero.unbalance_targetable_particles = {} end
			if not hero.unbalance_targetable_particles[keys.target] then
				hero.unbalance_targetable_particles[keys.target] = ParticleManager:CreateParticleForPlayer("particles/combat_links/enhanced_targetable_beam_continuous.vpcf", PATTACH_ABSORIGIN_FOLLOW, keys.target, hero:GetPlayerOwner())
			end
		end
	end
end

function removeUnbalancedParticle(keys)
	for k,hero in pairs(getAllHeroes()) do
		if hero.unbalance_targetable_particles and hero.unbalance_targetable_particles[keys.target] then
			ParticleManager:DestroyParticle(hero.unbalance_targetable_particles[keys.target], false)
			hero.unbalance_targetable_particles[keys.target] = nil
		end
	end
end
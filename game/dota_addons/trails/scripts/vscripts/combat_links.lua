require "game_functions"
require "libraries/notifications"
require "libraries/util"

LinkLuaModifier("modifier_unbalanced_level", "modifier_unbalanced_level.lua", LUA_MODIFIER_MOTION_NONE)

function formLink(unit, target)
	local ability = unit:FindAbilityByName("combat_link")
	unit.combat_linked_to = target
	target.combat_linked_to = unit
	ability:ApplyDataDrivenModifier(unit, unit, "modifier_combat_link_linked", {}).time_formed = GameRules:GetGameTime()
	ability:ApplyDataDrivenModifier(target, target, "modifier_combat_link_linked", {}).time_formed = GameRules:GetGameTime()

	unit.tether_particle = ParticleManager:CreateParticle("particles/combat_links/link.vpcf", PATTACH_POINT_FOLLOW, unit)
	target.tether_particle = unit.tether_particle
	ParticleManager:SetParticleControlEnt(unit.tether_particle, 0, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(unit.tether_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	CustomGameEventManager:Send_ServerToPlayer(unit:GetOwner(), "ally_ability_bar_start", {heroIndex = target:GetEntityIndex(), cpCosts = getAbilityCPCosts(target)})
	CustomGameEventManager:Send_ServerToPlayer(target:GetOwner(), "ally_ability_bar_start", {heroIndex = unit:GetEntityIndex(), cpCosts = getAbilityCPCosts(unit)})

	CustomNetTables:SetTableValue("combat_links", tostring(unit:entindex()), {link_target = tostring(target:entindex())})
	CustomNetTables:SetTableValue("combat_links", tostring(target:entindex()), {link_target = tostring(unit:entindex())})
	CustomGameEventManager:Send_ServerToPlayer(unit:GetOwner(), "link_formed_or_broken", {})
	CustomGameEventManager:Send_ServerToPlayer(target:GetOwner(), "link_formed_or_broken", {})

	triggerModifierEvent(unit, "link_formed", {})
	triggerModifierEvent(target, "link_formed", {})
end

function checkForLinkBreak(keys)
	local hero = keys.target
	local ability = keys.ability

	-- this function also processes ongoing link costs cause uhhhhhhh idk datadriven's a pain, w/e
	local time_since_link_creation = GameRules:GetGameTime() - hero:FindModifierByName("modifier_combat_link_linked").time_formed
	local cost = (ability:GetSpecialValueFor("link_cost_per_second") + (ability:GetSpecialValueFor("link_cost_increase_per_second") * time_since_link_creation)) / 30 / 2 -- divided by 2 because this function is run by both sides of the link, aka im really good at code
	Gamemode_Boss:SpendBravePoints(cost)

	if hero.combat_linked_to then
		if not IsValidEntity(hero.combat_linked_to) or (not hero.combat_linked_to:IsAlive() and not hero.combat_linked_to.reviving) or Gamemode_Boss.brave_points <= 0 or Gamemode_Boss.state ~= ENCOUNTER then
			if IsValidEntity(hero.combat_linked_to) then
				removeLink(hero.combat_linked_to)
			end
			removeLink(hero)
		end
	end
end

function linkExpired(keys)
	removeLink(keys.target)
end

function removeLink(unit)
	unit:RemoveModifierByName("modifier_combat_link_linked")
	if unit.tether_particle then
		ParticleManager:DestroyParticle(unit.tether_particle, false)
		unit.tether_particle = nil
	end
	CustomGameEventManager:Send_ServerToPlayer(unit:GetOwner(), "ally_ability_bar_remove", {})
	CustomGameEventManager:Send_ServerToPlayer(unit:GetOwner(), "link_formed_or_broken", {})

	CustomNetTables:SetTableValue("combat_links", tostring(unit:entindex()), {link_target = nil})

	triggerModifierEvent(unit, "link_broken", {})
	unit.combat_linked_to = nil
end

function changeLinkParticle(unit, particle_name)
	if unit.tether_particle then
		ParticleManager:DestroyParticle(unit.tether_particle, true)
		unit.tether_particle = ParticleManager:CreateParticle(particle_name, PATTACH_POINT_FOLLOW, unit)
		ParticleManager:SetParticleControlEnt(unit.tether_particle, 0, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(unit.tether_particle, 1, unit.combat_linked_to, PATTACH_POINT_FOLLOW, "attach_hitloc", unit.combat_linked_to:GetAbsOrigin(), true)
		unit.combat_linked_to.tether_particle = unit.tether_particle
	end
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
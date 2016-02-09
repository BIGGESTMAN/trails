require "game_functions"
require "projectile_list"
require "libraries/notifications"

function checkForLink(keys)
	local caster = keys.caster
	local ability = keys.ability
	local link_range = ability:GetSpecialValueFor("link_radius")
	local link_break_range = ability:GetSpecialValueFor("link_break_range")

	if caster.combat_linked_to then
		if (caster.combat_linked_to:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() > link_break_range then
			removeLink(caster.combat_linked_to)
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
			if target ~= caster and not target.combat_linked_to then
				caster.combat_linked_to = target
				target.combat_linked_to = caster
				ability:ApplyDataDrivenModifier(caster, caster, "modifier_combat_link_linked", {})
				ability:ApplyDataDrivenModifier(target, target, "modifier_combat_link_linked", {})

				caster.tether_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_wisp/wisp_tether.vpcf", PATTACH_POINT_FOLLOW, caster)
				ParticleManager:SetParticleControlEnt(caster.tether_particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
				ParticleManager:SetParticleControlEnt(caster.tether_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
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
end

function attackLanded(keys)
	attemptUnbalance(keys.caster, keys.target)
end

function attemptUnbalance(caster, target, bonus_chance)
	local ability = caster:FindAbilityByName("combat_link")

	local unbalance_chance = ability:GetSpecialValueFor("unbalance_chance")
	bonus_chance = bonus_chance or 0

	if caster.combat_linked_to and RandomInt(0, 99) < unbalance_chance + bonus_chance then
		ability:ApplyDataDrivenModifier(caster, caster.combat_linked_to, "modifier_combat_link_followup_available", {})
		caster.combat_linked_to:FindAbilityByName("combat_link"):SetActivated(true)
		ability:ApplyDataDrivenModifier(caster, target, "modifier_combat_link_unbalanced", {})
	end
end

function deactivateActive(keys)
	keys.target:FindAbilityByName("combat_link"):SetActivated(false)
end

function followupAttack(keys)
	if keys.target:HasModifier("modifier_combat_link_unbalanced") then
		executeFollowupAttack(keys.caster, keys.target)
		keys.caster:RemoveModifierByName("modifier_combat_link_followup_available")
	else
		Notifications:Bottom(keys.caster:GetPlayerOwner(), {text="Must Target An Unbalanced Enemy", duration=1, style={color="red"}})
	end
end

function executeFollowupAttack(hero, target)
	local name = hero:GetName()
	if name == "npc_dota_hero_ember_spirit" then
		local damage = hero:GetAverageTrueAttackDamage() * 2
		local damage_type = DAMAGE_TYPE_PHYSICAL
		local teleport_distance_from_target = 100

		dealDamage(target, hero, damage, damage_type, ability)
		local direction_from_target = (hero:GetAbsOrigin() - target:GetAbsOrigin()):Normalized()
		FindClearSpaceForUnit(hero, target:GetAbsOrigin() + (direction_from_target * teleport_distance_from_target), true)

		local new_facing = (target:GetAbsOrigin() - hero:GetAbsOrigin()):Normalized()
		new_facing.z = 0
		hero:SetForwardVector(new_facing)
	end
	if name == "npc_dota_hero_windrunner" then
		local damage = hero:GetAverageTrueAttackDamage() * 2
		local damage_type = DAMAGE_TYPE_PHYSICAL

		ProjectileList:CreateTrackingProjectile(hero, target, hero:GetProjectileSpeed(), function()
			dealDamage(target, hero, damage, damage_type, ability)
			end)

		local new_facing = (target:GetAbsOrigin() - hero:GetAbsOrigin()):Normalized()
		new_facing.z = 0
		hero:SetForwardVector(new_facing)
		EmitSoundOn("Alisa.Followup_Attack", hero)
		Notifications:Top((hero.combat_linked_to):GetPlayerOwner(), {text="Alisa: ", duration=2, style={color="white", ["font-size"]="26px"}})
		Notifications:Top((hero.combat_linked_to):GetPlayerOwner(), {text="I've Got You!", style={color="green", ["font-size"]="26px"}, continue = true})
	end
end
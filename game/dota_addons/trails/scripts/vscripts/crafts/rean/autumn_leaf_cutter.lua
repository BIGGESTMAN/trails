require "game_functions"
require "combat_links"
require "libraries/animations"
require "libraries/notifications"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target_points[1]

	local dash_speed = ability:GetSpecialValueFor("dash_speed")
	local radius = ability:GetSpecialValueFor("radius")

	local team = caster:GetTeamNumber()
	local origin = target
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

	if #targets > 0 then
		modifyCP(caster, getCPCost(ability) * -1)
		dash(caster, (target - caster:GetAbsOrigin()):Normalized(), dash_speed, (target - caster:GetAbsOrigin()):Length2D(), false, secondaryDash)
	else
		Notifications:Bottom(keys.caster:GetPlayerOwner(), {text="Target Area Must Contain Enemies", duration=1, style={color="red"}})
	end
end

function secondaryDash(caster, direction, speed, range)
	local ability = caster:FindAbilityByName("autumn_leaf_cutter")

	local radius = ability:GetSpecialValueFor("radius")
	local dash_through_range = ability:GetSpecialValueFor("dash_through_range")
	local damage = caster:GetAverageTrueAttackDamage() * ability:GetSpecialValueFor("damage_percent") / 100
	local damage_type = ability:GetAbilityDamageType()
	local bonus_unbalance_chance = ability:GetSpecialValueFor("bonus_unbalance_chance")
	local slash_particle_instances = 10

	local team = caster:GetTeamNumber()
	local origin = caster:GetAbsOrigin()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

	for k,unit in pairs(targets) do
		dealDamage(unit, caster, damage, damage_type, ability)
		attemptUnbalance(caster, unit, bonus_unbalance_chance)
		ability:ApplyDataDrivenModifier(caster, unit, "modifier_autumn_leaf_cutter_slow", {})
		unit:Interrupt()

		-- Slash particles
		for i=1,slash_particle_instances do 
			local slashFxIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_ember_spirit/ember_spirit_sleightoffist_tgt.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
			Timers:CreateTimer( 0.1, function()
				ParticleManager:DestroyParticle( slashFxIndex, false )
				ParticleManager:ReleaseParticleIndex( slashFxIndex )
				return nil
			end)
		end
	end

	ParticleManager:CreateParticle("particles/econ/items/axe/axe_weapon_practos/axe_attack_blur_counterhelix_practos.vpcf", PATTACH_ABSORIGIN, caster)

	StartAnimation(caster, {duration = 0.5, activity = ACT_DOTA_CAST_ABILITY_1, rate = 15/23})

	dash(caster, direction, speed, dash_through_range, true)
end
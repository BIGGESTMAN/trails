require "game_functions"
require "combat_links"
require "libraries/animations"
require "libraries/notifications"
require "crafts/rean/gale"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target_points[1]
	local target = keys.target

	local dash_speed = ability:GetSpecialValueFor("dash_speed")
	local radius = ability:GetSpecialValueFor("radius")

	local crit = false
	if caster:HasModifier("modifier_crit") then
		crit = true
		caster:RemoveModifierByName("modifier_crit")
	end

	if validEnhancedCraft(caster, target) then
		caster:RemoveModifierByName("modifier_combat_link_followup_available")
		target:RemoveModifierByName("modifier_combat_link_unbalanced")
		caster.unbalanced_autumn_leaf_cutter_target = target
		modifyCP(caster, getCPCost(ability) * -1)
		applyDelayCooldowns(caster, ability)
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_autumn_leaf_cutter_dashing", {})
		trackingDash(caster, target, dash_speed, secondaryDash, {crit = crit})
	else
		local team = caster:GetTeamNumber()
		local origin = target_point
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_ANY_ORDER
		local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

		if #targets > 0 then
			modifyCP(caster, getCPCost(ability) * -1)
			applyDelayCooldowns(caster, ability)
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_autumn_leaf_cutter_dashing", {})
			dash(caster, (target_point - caster:GetAbsOrigin()):Normalized(), dash_speed, (target_point - caster:GetAbsOrigin()):Length2D(), false, secondaryDash, {crit = crit})
		else
			Notifications:Bottom(keys.caster:GetPlayerOwner(), {text="Target Area Must Contain Enemies", duration=1, style={color="red"}})
			ability:EndCooldown()
		end
	end
end

function secondaryDash(caster, direction, speed, range, find_clear_space, other_args)
	local ability = caster:FindAbilityByName("autumn_leaf_cutter")

	local radius = ability:GetSpecialValueFor("radius")
	local dash_through_range = ability:GetSpecialValueFor("dash_through_range")
	local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100
	local damage_type = ability:GetAbilityDamageType()
	local bonus_unbalance = ability:GetSpecialValueFor("bonus_unbalance")
	local slash_particle_instances = 10
	local slow_modifier_name = "modifier_autumn_leaf_cutter_slow"

	local unbalanced_knockback_duration = ability:GetSpecialValueFor("unbalanced_knockback_duration")
	local unbalanced_knockback_distance = ability:GetSpecialValueFor("unbalanced_knockback_distance")
	if caster.unbalanced_autumn_leaf_cutter_target then
		damage_scale = ability:GetSpecialValueFor("unbalanced_damage_percent") / 100
		slow_modifier_name = "modifier_autumn_leaf_cutter_unbalanced_slow"
	end
	if other_args.crit then damage_scale = damage_scale * 2 end

	local team = caster:GetTeamNumber()
	local origin = caster:GetAbsOrigin()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

	for k,unit in pairs(targets) do
		dealScalingDamage(unit, caster, damage_type, damage_scale, ability, CRAFT_CP_GAIN_FACTOR)
		increaseUnbalance(caster, unit, bonus_unbalance)
		ability:ApplyDataDrivenModifier(caster, unit, slow_modifier_name, {})
		unit:Interrupt()
		applyGaleMark(caster, unit)

		if caster.unbalanced_autumn_leaf_cutter_target and unit ~= caster.unbalanced_autumn_leaf_cutter_target then
			ability:ApplyDataDrivenModifier(caster, unit, "modifier_autumn_leaf_cutter_knockback", {})
			dash(unit, (unit:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized(), unbalanced_knockback_distance / unbalanced_knockback_duration, unbalanced_knockback_distance, true)
		end

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

	dash(caster, direction, speed, dash_through_range, true, function() caster:RemoveModifierByName("modifier_autumn_leaf_cutter_dashing") end)
end
require "game_functions"
require "libraries/util"

LinkLuaModifier("modifier_gale_slow", "crafts/rean/modifier_gale_slow.lua", LUA_MODIFIER_MOTION_NONE)

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target_points[1]
	local target = keys.target

	local dash_speed = ability:GetSpecialValueFor("dash_speed")
	local radius = ability:GetSpecialValueFor("radius")

	local team = caster:GetTeamNumber()
	local origin = target_point
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	caster.gale_targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

	local invalid_targets = {}
	for k,unit in pairs(caster.gale_targets) do
		if not (unit:HasModifier("modifier_gale_mark") and unit:FindModifierByName("modifier_gale_mark"):GetStackCount() == 2) then
			table.insert(invalid_targets, unit)
		else
			unit:RemoveModifierByName("modifier_gale_mark")
		end
	end
	for k,unit in pairs(invalid_targets) do
		removeElementFromTable(caster.gale_targets, unit)
	end

	local enhanced = false
	if validEnhancedCraft(caster, target, true) then
		enhanced = true
		executeEnhancedCraft(caster, target)
		caster.gale_secondary_targets = copyOfTable(caster.gale_targets)
		caster.gale_original_target = target
		for k,unit in pairs(caster.gale_secondary_targets) do
			if unit == target then
				table.remove(caster.gale_secondary_targets, k)
			end
		end
	else
		caster.gale_original_location = caster:GetAbsOrigin()
	end

	local crit = false
	if caster:HasModifier("modifier_crit") then
		crit = true
		caster:RemoveModifierByName("modifier_crit")
	end

	if #caster.gale_targets > 0 then
		spendCP(caster, ability)
		applyDelayCooldowns(caster, ability)
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_gale_dashing", {})
		dashToNextTarget(caster, nil, nil, {crit = crit, enhanced = enhanced})
	else
		Notifications:Bottom(keys.caster:GetPlayerOwner(), {text="Target Area Must Contain Marked Enemies", duration=1, style={color="red"}})
		ability:EndCooldown()
		caster.gale_original_location = nil
		caster.gale_targets = nil
		caster.gale_secondary_targets = nil
		caster.gale_original_target = nil
	end
end

function hitTarget(caster, direction, speed, other_args)
	local ability = caster:FindAbilityByName("gale")
	local target = other_args.target

	local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100
	local damage_type = ability:GetAbilityDamageType()
	local bonus_unbalance = ability:GetSpecialValueFor("bonus_unbalance")
	local dash_speed = ability:GetSpecialValueFor("dash_speed")
	local dash_through_range = ability:GetSpecialValueFor("dash_through_range")
	local slow_duration = ability:GetSpecialValueFor("unbalanced_slow_duration")
	local seal_duration = ability:GetSpecialValueFor("disarm_duration")

	if IsValidAlive(target) then
		if caster.gale_secondary_phase then
			damage_scale = ability:GetSpecialValueFor("unbalanced_damage_percent") / 100
			target:AddNewModifier(caster, ability, "modifier_gale_slow", {duration = slow_duration})
		end
		if other_args.crit then damage_scale = damage_scale * 2 end
		applyEffect(target, damage_type, function()
			dealScalingDamage(target, caster, damage_type, damage_scale, ability, CRAFT_CP_GAIN_FACTOR, other_args.enhanced, false, bonus_unbalance)
			target:AddNewModifier(caster, ability, "modifier_seal", {duration = seal_duration})
			ParticleManager:CreateParticle("particles/units/heroes/hero_bounty_hunter/bounty_hunter_jinda_slow.vpcf", PATTACH_ABSORIGIN, target)
		end)
	end

	if target == caster.gale_original_target and caster.gale_secondary_phase then
		caster.gale_secondary_phase = nil
		caster.gale_original_target = nil
	end
	dash(caster, direction, dash_speed, dash_through_range, false, dashToNextTarget, other_args)
end

function dashToNextTarget(caster, direction, speed, args)
	local ability = caster:FindAbilityByName("gale")
	local dash_speed = ability:GetSpecialValueFor("dash_speed")

	if #caster.gale_targets > 0 then -- Regular slashes
		local target_index = randomIndexOfTable(caster.gale_targets)
		local dash_target = caster.gale_targets[target_index]
		table.remove(caster.gale_targets, target_index)
		if IsValidAlive(dash_target) then
			local facing = (dash_target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
			facing.z = 0
			caster:SetForwardVector(facing)
			trackingDash(caster, dash_target, dash_speed, hitTarget, args)
		else
			dashToNextTarget(caster, direction, speed, args)
		end
	elseif caster.gale_secondary_targets then -- Secondary slashes
		caster.gale_targets = caster.gale_secondary_targets
		caster.gale_secondary_targets = nil
		caster.gale_secondary_phase = true
		dashToNextTarget(caster, direction, speed, args)
	elseif caster.gale_secondary_phase and IsValidAlive(caster.gale_original_target) then -- Final slash against original unbalanced target
		local dash_target = caster.gale_original_target
		local facing = (dash_target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
		facing.z = 0
		caster:SetForwardVector(facing)
		trackingDash(caster, dash_target, dash_speed, hitTarget, args)
	else -- Dash back to original location, or stay at unbalanced target's location
		if caster.gale_original_location then
			local original_location_vector = caster.gale_original_location - caster:GetAbsOrigin()
			caster.gale_original_location = nil
			local facing = original_location_vector:Normalized()
			facing.z = 0
			caster:SetForwardVector(facing)
			dash(caster, original_location_vector:Normalized(), dash_speed, original_location_vector:Length2D(), true, function() caster:RemoveModifierByName("modifier_gale_dashing") end)
		else
			caster:RemoveModifierByName("modifier_gale_dashing")
		end
		caster.gale_targets = nil
		caster:RemoveModifierByName("modifier_gale_dashing")
	end
end

function attackLanded(keys)
	applyGaleMark(keys.attacker, keys.target)
end

function applyGaleMark(caster, target)
	local ability = caster:FindAbilityByName("gale")

	if target:IsAlive() then
		local modifier = target:FindModifierByName("modifier_gale_mark")
		if not modifier then
			modifier = ability:ApplyDataDrivenModifier(caster, target, "modifier_gale_mark", {})
			modifier:SetStackCount(1)
		else
			modifier = ability:ApplyDataDrivenModifier(caster, target, "modifier_gale_mark", {})
			modifier:SetStackCount(2)
		end

		if target.gale_mark_particle then ParticleManager:DestroyParticle(target.gale_mark_particle, false) end
		target.gale_mark_particle = ParticleManager:CreateParticle("particles/crafts/rean/gale/mark.vpcf", PATTACH_OVERHEAD_FOLLOW, target)
		ParticleManager:SetParticleControl(target.gale_mark_particle, 2, Vector(0,modifier:GetStackCount(),0))
	end
end

function removeMarkParticle(keys)
	ParticleManager:DestroyParticle(keys.target.gale_mark_particle, false)
	keys.target.gale_mark_particle = nil
end
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
	if caster:HasModifier("modifier_combat_link_followup_available") and target and target:HasModifier("modifier_combat_link_unbalanced") then
		caster:RemoveModifierByName("modifier_combat_link_followup_available")
		target:RemoveModifierByName("modifier_combat_link_unbalanced")
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

	if #caster.gale_targets > 0 or caster.gale_original_target then
		modifyCP(caster, getCPCost(ability) * -1)
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_gale_dashing", {})
		dashToNextTarget(caster)
	else
		Notifications:Bottom(keys.caster:GetPlayerOwner(), {text="Target Area Must Contain Enemies", duration=1, style={color="red"}})
		caster.gale_original_location = nil
		caster.gale_targets = nil
	end
end

function hitTarget(caster, direction, speed, target)
	local ability = caster:FindAbilityByName("gale")

	local damage = caster:GetAverageTrueAttackDamage() * ability:GetSpecialValueFor("damage_percent") / 100
	local damage_type = ability:GetAbilityDamageType()
	local bonus_unbalance = ability:GetSpecialValueFor("bonus_unbalance")
	local dash_speed = ability:GetSpecialValueFor("dash_speed")
	local dash_through_range = ability:GetSpecialValueFor("dash_through_range")
	local slow_duration = ability:GetSpecialValueFor("unbalanced_slow_duration")

	if IsValidAlive(target) then
		if caster.gale_secondary_phase then
			damage = caster:GetAverageTrueAttackDamage() * ability:GetSpecialValueFor("unbalanced_damage_percent") / 100
			target:AddNewModifier(caster, ability, "modifier_gale_slow", {duration = slow_duration})
		end
		dealDamage(target, caster, damage, damage_type, ability)
		increaseUnbalance(caster, target, bonus_unbalance)
		ability:ApplyDataDrivenModifier(caster, target, "modifier_gale_disarm", {})
		ParticleManager:CreateParticle("particles/units/heroes/hero_bounty_hunter/bounty_hunter_jinda_slow.vpcf", PATTACH_ABSORIGIN, target)
	end

	if target == caster.gale_original_target and caster.gale_secondary_phase then
		caster.gale_secondary_phase = nil
		caster.gale_original_target = nil
	end
	dash(caster, direction, dash_speed, dash_through_range, false, dashToNextTarget)
end

function dashToNextTarget(caster)
	local ability = caster:FindAbilityByName("gale")
	local dash_speed = ability:GetSpecialValueFor("dash_speed")

	if #caster.gale_targets > 0 then -- Regular slashes
		local target_index = randomIndexOfTable(caster.gale_targets)
		local dash_target = caster.gale_targets[target_index]
		table.remove(caster.gale_targets, target_index)
		if IsValidAlive(dash_target) then
			caster:SetForwardVector((dash_target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized())
			trackingDash(caster, dash_target, dash_speed, hitTarget)
		else
			dashToNextTarget(caster)
		end
	elseif caster.gale_secondary_targets then -- Secondary slashes
		caster.gale_targets = caster.gale_secondary_targets
		caster.gale_secondary_targets = nil
		caster.gale_secondary_phase = true
		dashToNextTarget(caster)
	elseif caster.gale_secondary_phase and IsValidAlive(caster.gale_original_target) then -- Final slash against original unbalanced target
		local dash_target = caster.gale_original_target
		caster:SetForwardVector((dash_target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized())
		trackingDash(caster, dash_target, dash_speed, hitTarget)
	else -- Dash back to original location, or stay at unbalanced target's location
		if caster.gale_original_location then
			local original_location_vector = caster.gale_original_location - caster:GetAbsOrigin()
			caster.gale_original_location = nil
			caster:SetForwardVector(original_location_vector:Normalized())
			dash(caster, original_location_vector:Normalized(), dash_speed, original_location_vector:Length2D(), true, function() caster:RemoveModifierByName("modifier_gale_dashing") end)
		else
			caster:RemoveModifierByName("modifier_gale_dashing")
		end
		caster.gale_targets = nil
		caster:RemoveModifierByName("modifier_gale_dashing")
	end
end
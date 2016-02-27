require "game_functions"
require "projectile_list"
require "libraries/animations"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target_points[1]
	local target = keys.target

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_chaos_trigger_casting", {duration = ability:GetChannelTime()})
	caster.chaos_trigger_targets = {}

	modifyCP(caster, getCPCost(ability) * -1)
	applyDelayCooldowns(caster, ability)

	if validEnhancedCraft(caster, target) then
		caster:RemoveModifierByName("modifier_combat_link_followup_available")
		target:RemoveModifierByName("modifier_combat_link_unbalanced")
		caster.chaos_trigger_enhanced = true
	end

	local direction = (target_point - caster:GetAbsOrigin()):Normalized()
	caster.chaos_trigger_aim_area_particle = ParticleManager:CreateParticle("particles/crafts/crow/chaos_trigger/aim_area.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControlForward(caster.chaos_trigger_aim_area_particle, 0, direction)
	ParticleManager:SetParticleControl(caster.chaos_trigger_aim_area_particle, 0, caster:GetAbsOrigin())
end

function channelFinish(keys)
	local caster = keys.caster
	caster:RemoveModifierByName("modifier_chaos_trigger_casting")
	ParticleManager:DestroyParticle(caster.chaos_trigger_aim_area_particle, false)
	caster.chaos_trigger_aim_area_particle = nil
	for unit,aimtime in pairs(caster.chaos_trigger_targets) do
		ParticleManager:DestroyParticle(unit.chaos_trigger_lockon_particle, true)
		unit.chaos_trigger_lockon_particle = nil
	end
end

function channelSucceeded(keys)
	local caster = keys.caster
	fireShots(caster, caster.chaos_trigger_targets)
	caster.chaos_trigger_targets = nil
	if caster.chaos_trigger_enhanced then
		keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_chaos_trigger_casting_secondary", {})
	end
end

function fireShots(caster, targets)
	local ability = caster:FindAbilityByName("chaos_trigger")
	local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100
	local damage_type = ability:GetAbilityDamageType()
	local debuff_duration = ability:GetSpecialValueFor("debuff_duration")
	local units_in_front = findUnitsInFront(caster)

	if caster.chaos_trigger_enhanced then
		damage_scale = ability:GetSpecialValueFor("unbalanced_damage_percent") / 100
	end

	if caster:HasModifier("modifier_crit") then
		damage_scale = damage_scale * 2
		caster:RemoveModifierByName("modifier_crit")
	end

	for unit,aimtime in pairs(targets) do
		if unit:HasModifier("modifier_chaos_trigger_locked_on") then
			unit:RemoveModifierByName("modifier_chaos_trigger_locked_on")
			dealScalingDamage(unit, caster, damage_type, damage_scale)
			increaseUnbalance(caster, unit)
			if tableContains(units_in_front, unit) then
				unit:AddNewModifier(caster, ability, "modifier_confuse", {duration = debuff_duration})
			else
				unit:AddNewModifier(caster, ability, "modifier_nightmare", {duration = debuff_duration})
			end

			ProjectileList:CreateTrackingProjectile(caster, unit, 2000, function() end, "particles/units/heroes/hero_bane/bane_projectile.vpcf")
		end
	end

end

function aim(keys)
	local caster = keys.caster
	local ability = keys.ability
	local lockon_time = ability:GetSpecialValueFor("lockon_time")
	local units_in_front = findUnitsInFront(caster)

	for k,unit in pairs(units_in_front) do
		if not caster.chaos_trigger_targets[unit] then
			caster.chaos_trigger_targets[unit] = 0
			unit.chaos_trigger_lockon_particle = ParticleManager:CreateParticle("particles/crafts/crow/chaos_trigger/lockon.vpcf", PATTACH_OVERHEAD_FOLLOW, unit)
		end
		caster.chaos_trigger_targets[unit] = caster.chaos_trigger_targets[unit] + 1/30
	end
	for unit,aimtime in pairs(caster.chaos_trigger_targets) do
		if aimtime < lockon_time then
			if not tableContains(units_in_front, unit) then
				caster.chaos_trigger_targets[unit] = nil
				ParticleManager:DestroyParticle(unit.chaos_trigger_lockon_particle, true)
				unit.chaos_trigger_lockon_particle = nil
			end
		else
			ability:ApplyDataDrivenModifier(caster, unit, "modifier_chaos_trigger_locked_on", {})
		end
	end
end

function findUnitsInFront(caster)
	local ability = caster:FindAbilityByName("chaos_trigger")
	local range = ability:GetSpecialValueFor("range")
	local radius = ability:GetSpecialValueFor("width")
	local direction = caster:GetForwardVector()

	local team = caster:GetTeamNumber()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
	local iOrder = FIND_ANY_ORDER
	return FindUnitsInLine(team, caster:GetAbsOrigin(), caster:GetAbsOrigin() + direction * range, nil, radius, iTeam, iType, iOrder)
end

function endSecondaryShot(keys)
	local caster = keys.caster
	caster.chaos_trigger_enhanced = nil
	caster:RemoveModifierByName("modifier_chaos_trigger_casting_secondary")
end

function secondaryAimingEnded(keys)
	local caster = keys.caster
	local ability = keys.ability
	local damage_scale = ability:GetSpecialValueFor("unbalanced_secondary_damage_percent") / 100
	local damage_type = ability:GetAbilityDamageType()
	local debuff_duration = ability:GetSpecialValueFor("debuff_duration")
	if caster.chaos_trigger_enhanced then
		caster.chaos_trigger_enhanced = nil
		for k,unit in pairs(findUnitsInFront(caster)) do
			dealScalingDamage(unit, caster, damage_type, damage_scale)
			increaseUnbalance(caster, unit)
			unit:AddNewModifier(caster, ability, "modifier_confuse", {duration = debuff_duration})
		end
		StartAnimation(caster, {duration = 1, activity = ACT_DOTA_ATTACK, rate = 1})
	end
end
require "game_functions"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target_points[1]
	local target = keys.target

	local radius = ability:GetSpecialValueFor("radius")
	local duration = ability:GetSpecialValueFor("duration")

	spendCP(caster, ability)
	applyDelayCooldowns(caster, ability)

	if validEnhancedCraft(caster, target, true) then
		executeEnhancedCraft(caster, target)

		local cp_drained = getCP(target)
		modifyCP(target, cp_drained * -1)
		caster.enhanced_heavenly_gift_cp_drained = cp_drained
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_heavenly_gift_cp_restore", {})
	end

	local sun_particle = ParticleManager:CreateParticle("particles/crafts/alisa/heavenly_gift/sun.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(sun_particle, 0, target_point + Vector(0,0,300))

	local area_particle = ParticleManager:CreateParticle("particles/crafts/alisa/heavenly_gift/area.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(area_particle, 0, target_point)

	local update_interval = 1/30
	local duration_elapsed = 0
	local affected_units = {}
	Timers:CreateTimer(0, function()
		duration_elapsed = duration_elapsed + update_interval

		for unit,v in pairs(affected_units) do
			affected_units[unit] = false
		end

		local team = caster:GetTeamNumber()
		local iTeam = DOTA_UNIT_TARGET_TEAM_BOTH
		local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_ANY_ORDER
		local targets = FindUnitsInRadius(team, target_point, nil, radius, iTeam, iType, iFlag, iOrder, false)
		for k,unit in pairs(targets) do
			affected_units[unit] = true
			if unit:GetTeamNumber() == caster:GetTeamNumber() then
				unit:AddNewModifier(caster, ability, "modifier_insight", {}):StartEvasionCooldown() -- start on cooldown to prevent skirting-in-and-out on edge of aoe shenanigans
			else
				ability:ApplyDataDrivenModifier(caster, unit, "modifier_heavenly_gift_enemy", {})
			end
		end

		for unit,v in pairs(affected_units) do
			if not affected_units[unit] then
				unit:RemoveModifierByName("modifier_insight")
				unit:RemoveModifierByName("modifier_heavenly_gift_enemy")
			end
		end

		if duration_elapsed < duration then
			return update_interval
		else
			for unit,v in pairs(affected_units) do
				unit:RemoveModifierByName("modifier_insight")
				unit:RemoveModifierByName("modifier_heavenly_gift_enemy")
			end
		end
	end)
end

function restoreCPTick(keys)
	local caster = keys.caster
	local ability = keys.ability

	local radius = ability:GetSpecialValueFor("unbalanced_cp_restore_radius")
	local cp_restore_interval = ability:GetSpecialValueFor("unbalanced_cp_restore_interval")
	local total_duration = ability:GetSpecialValueFor("unbalanced_cp_restore_duration")
	local cp = caster.enhanced_heavenly_gift_cp_drained * cp_restore_interval / total_duration

	if not caster.enhanced_heavenly_gift_accrued_cp then caster.enhanced_heavenly_gift_accrued_cp = 0 end
	caster.enhanced_heavenly_gift_accrued_cp = caster.enhanced_heavenly_gift_accrued_cp + cp
	if caster.enhanced_heavenly_gift_accrued_cp >= 1 then
		local team = caster:GetTeamNumber()
		local iTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY
		local iType = DOTA_UNIT_TARGET_HERO
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_ANY_ORDER
		local targets = FindUnitsInRadius(team, caster:GetAbsOrigin(), nil, radius, iTeam, iType, iFlag, iOrder, false)
		for k,unit in pairs(targets) do
			modifyCP(unit, math.floor(caster.enhanced_heavenly_gift_accrued_cp))
		end
		caster.enhanced_heavenly_gift_accrued_cp = caster.enhanced_heavenly_gift_accrued_cp - math.floor(caster.enhanced_heavenly_gift_accrued_cp)
	end
end

function cpRestoreBuffEnded(keys)
	local caster = keys.caster
	caster.enhanced_heavenly_gift_accrued_cp = nil
	caster.enhanced_heavenly_gift_cp_drained = nil
end
require "game_functions"

LinkLuaModifier("modifier_heavenly_gift_enemy", "abilities/crafts/alisa/heavenly_gift.lua", LUA_MODIFIER_MOTION_NONE)

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

modifier_heavenly_gift_enemy = class({})

function modifier_heavenly_gift_enemy:IsDebuff()
	return true
end

function modifier_heavenly_gift_enemy:GrantDamageCP(damage, attacker)
	local ability = self:GetAbility()
	local cp_factor = ability:GetSpecialValueFor("cp_gained_percent") / 100
	modifyCP(attacker, damage * cp_factor)
end
require "game_functions"

function createCPModifier(keys)
	local caster = keys.caster
	local ability = keys.ability

	local modifier = ability:ApplyDataDrivenModifier(caster, caster, "modifier_cp_tracker_cp", {})
	modifier.cp = 0
	modifier:SetStackCount(0)

	initializeAbilityCPCosts(caster)
end

function initializeAbilityCPCosts(caster)
	for k,ability in pairs(getAllActiveAbilities(caster)) do
		ability.max_cp_cost = getAbilityValueForKey(ability, "CPCost")
		ability.current_cp_cost = 0
	end
end

function passiveCPGain(keys)
	local update_interval = keys.ability:GetSpecialValueFor("update_interval")
	if not keys.caster:HasModifier("modifier_interround_invulnerability") and keys.caster:IsAlive() then
		modifyCP(keys.caster, keys.ability:GetSpecialValueFor("passive_cp_per_second") * update_interval)
	end

	for k,ability in pairs(getAllActiveAbilities(keys.caster)) do
		if ability.current_cp_cost and ability.current_cp_cost > 0 then --ability.current_cp_cost check makes sure we don't try to reduce cost of normally hidden stuff like cross raven retarget
			ability.current_cp_cost = ability.current_cp_cost - ability.max_cp_cost * update_interval / CP_COSTS_DECAY_TIME
			if ability.current_cp_cost < 0 then ability.current_cp_cost = 0 end
		end
	end
end

function attackLanded(keys)
	local attacker = keys.attacker
	local damage_scale = 1
	local damage_type = DAMAGE_TYPE_PHYSICAL
	if attacker:HasModifier("modifier_crit") then
		damage_scale = damage_scale * 2
		attacker:RemoveModifierByName("modifier_crit")
	end

	applyEffect(keys.target, damage_type, function()
		dealScalingDamage(keys.target, attacker, DAMAGE_TYPE_PHYSICAL, damage_scale, nil)
	end)
end
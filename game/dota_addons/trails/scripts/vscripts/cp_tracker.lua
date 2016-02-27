require "game_functions"

function createCPModifier(keys)
	local caster = keys.caster
	local ability = keys.ability

	local modifier = ability:ApplyDataDrivenModifier(caster, caster, "modifier_cp_tracker_cp", {})
	modifier.cp = 0
	modifier:SetStackCount(0)
end

function passiveCPGain(keys)
	if not keys.caster:HasModifier("modifier_interround_invulnerability") and keys.caster:IsAlive() then
		modifyCP(keys.caster, keys.ability:GetSpecialValueFor("passive_cp_per_second"))
	end
end

function attackLanded(keys)
	local attacker = keys.attacker
	local damage_scale = 1
	if attacker:HasModifier("modifier_crit") then
		damage_scale = damage_scale * 2
		attacker:RemoveModifierByName("modifier_crit")
	end

	dealScalingDamage(keys.target, attacker, DAMAGE_TYPE_PHYSICAL, damage_scale, nil)
end
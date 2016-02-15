require "game_functions"

function createCPModifier(keys)
	local caster = keys.caster
	local ability = keys.ability

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_cp_tracker_cp", {}):SetStackCount(0)
end

function passiveCPGain(keys)
	modifyCP(keys.caster, keys.ability:GetSpecialValueFor("passive_cp_per_second"))
end
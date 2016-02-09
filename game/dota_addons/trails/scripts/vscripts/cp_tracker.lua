require "game_functions"

function createCPModifier(keys)
	local caster = keys.caster
	local ability = keys.ability

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_cp_tracker_cp", {}):SetStackCount(0)
end

function damageDealt(keys)
	local cp_increase = 5

	modifyCP(keys.caster, cp_increase)
end

function damageTaken(keys)
	local cp_increase = 5

	modifyCP(keys.caster, cp_increase)
end
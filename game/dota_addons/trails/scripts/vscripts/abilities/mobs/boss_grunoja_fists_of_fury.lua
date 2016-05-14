require "game_functions"
require "libraries/animations"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100
	local damage_to_break = ability:GetSpecialValueFor("damage_to_break")

	caster.fists_of_fury_state = {}
	caster.fists_of_fury_state.damage_to_break = damage_to_break
	caster.fists_of_fury_state.target = target
	caster.fists_of_fury_state.cp_reward = ability:GetSpecialValueFor("cp_reward")

	target:AddNewModifier(caster, ability, "modifier_faint", {duration = 0.28})
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_fists_of_fury", {})
end

function dealChannelDamage(keys)
	local caster = keys.caster
	local ability = keys.ability
	local unit = caster.fists_of_fury_state.target

	local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100
	local damage_scale_per_tick = damage_scale * 0.25 / ability:GetSpecialValueFor("duration")
	local damage_type = ability:GetAbilityDamageType()

	applyEffect(unit, damage_type, function()
		dealScalingDamage(unit, caster, damage_type, damage_scale_per_tick, ability)
		unit:AddNewModifier(caster, ability, "modifier_faint", {duration = 0.28})
	end)

	caster.fists_of_fury_state.cp_reward = caster.fists_of_fury_state.cp_reward - ability:GetSpecialValueFor("cp_reward") / ability:GetSpecialValueFor("duration") * 0.25

	StartAnimation(caster, {duration = 0.25, activity = ACT_DOTA_ATTACK, rate = 4})
end

function damageTaken(keys)
	local caster = keys.caster
	local target = caster.fists_of_fury_state.target

	caster.fists_of_fury_state.damage_to_break = caster.fists_of_fury_state.damage_to_break - keys.damage
	if caster.fists_of_fury_state.damage_to_break <= 0 then
		caster:RemoveModifierByName("modifier_fists_of_fury")
	end
end

function endFaint(keys)
	local caster = keys.caster

	local cp = caster.fists_of_fury_state.cp_reward
	CPRewards:RewardCP(nil, caster, cp)

	caster.fists_of_fury_state = nil
end
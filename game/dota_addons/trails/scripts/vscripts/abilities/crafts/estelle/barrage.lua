require "game_functions"
require "libraries/animations"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local dash_speed = ability:GetSpecialValueFor("flight_speed")

	local args = {}
	args.crit = false
	args.max_cp = getCP(caster) == MAX_CP

	if caster:HasModifier("modifier_crit") then
		args.crit = true
		caster:RemoveModifierByName("modifier_crit")
	end

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_barrage_dashing", {})
	trackingDash(caster, target, dash_speed, beginBarrage, args)

	spendCP(caster, ability)
	applyDelayCooldowns(caster, ability)
end

function beginBarrage(caster, direction, speed, args)
	local ability = caster:FindAbilityByName("barrage")
	local target = args.target
	caster:RemoveModifierByName("modifier_barrage_dashing")

	local barrage_duration = ability:GetSpecialValueFor("barrage_duration")
	if args.max_cp then barrage_duration = ability:GetSpecialValueFor("max_cp_barrage_duration") end

	if IsValidAlive(args.target) then
		caster.barrage_state = {}
		caster.barrage_state.target = target
		caster.barrage_state.crit = args.crit
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_barrage_active", {duration = barrage_duration})
		ability:ApplyDataDrivenModifier(caster, target, "modifier_barrage_stun", {duration = barrage_duration})
	end

	local damage_scale = ability:GetSpecialValueFor("kick_damage_percent") / 100
	local damage_type = ability:GetAbilityDamageType()
	applyEffect(target, damage_type, function()
		dealScalingDamage(target, caster, damage_type, damage_scale, ability)
	end)
end

function dealBarrageDamage(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = caster.barrage_state.target

	if IsValidAlive(target) then
		local damage_scale = ability:GetSpecialValueFor("barrage_hit_damage_percent") / 100
		local damage_type = ability:GetAbilityDamageType()
		local lifesteal = ability:GetSpecialValueFor("lifesteal_percent") / 100 * damage_scale * getStats(caster).str
		applyHealing(caster, caster, lifesteal)

		applyEffect(target, damage_type, function()
			dealScalingDamage(target, caster, damage_type, damage_scale, ability)
		end)

		StartAnimation(caster, {duration = 0.15, activity = ACT_DOTA_ATTACK, rate = 4})
	else
		caster:RemoveModifierByName("modifier_barrage_active")
	end
end

function endBarrage(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = caster.barrage_state.target

	if IsValidAlive(target) then
		target:RemoveModifierByName("modifier_barrage_stun")

		local damage_scale = ability:GetSpecialValueFor("kick_damage_percent") / 100
		local damage_type = ability:GetAbilityDamageType()
		applyEffect(target, damage_type, function()
			dealScalingDamage(target, caster, damage_type, damage_scale, ability)
		end)
	end

	caster.barrage_state = nil
end
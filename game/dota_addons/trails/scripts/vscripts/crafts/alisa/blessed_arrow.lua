require "game_functions"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target_points[1]
	local target = keys.target

	local arrow_destination = target_point + Vector(0,0,300)
	local arrow_travel_time = ability:GetSpecialValueFor("arrow_travel_time")
	local range = (arrow_destination - caster:GetAbsOrigin()):Length()
	local travel_speed = range / arrow_travel_time
	local healing = getStats(caster).ats * ability:GetSpecialValueFor("healing_percent") / 100
	local bonus_cp = ability:GetSpecialValueFor("bonus_cp")
	local args = {non_flat = true, healing = healing, bonus_cp = bonus_cp}

	modifyCP(caster, getCPCost(ability) * -1)
	applyDelayCooldowns(caster, ability)

	if validEnhancedCraft(caster, target) then
		caster:RemoveModifierByName("modifier_combat_link_followup_available")
		target:RemoveModifierByName("modifier_combat_link_unbalanced")

		args.healing = getStats(caster).ats * ability:GetSpecialValueFor("unbalanced_healing_percent") / 100
		args.bonus_cp = ability:GetSpecialValueFor("unbalanced_bonus_cp")
		args.apply_debuff_to = target
	end
	
	if caster:HasModifier("modifier_crit") then
		args.healing = args.healing * 2
		caster:RemoveModifierByName("modifier_crit")
	end

	local direction = (arrow_destination - caster:GetAbsOrigin()):Normalized()
	local origin_location = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_attack1"))

	ProjectileList:CreateLinearProjectile(caster, origin_location, direction, travel_speed, range, blessedArrowExplode, nil, nil, "particles/crafts/alisa/blessed_arrow/arrow.vpcf", args)
end

function blessedArrowExplode(caster, origin_location, direction, speed, range, collisionRules, collisionFunction, other_args)
	local ability = caster:FindAbilityByName("blessed_arrow")
	local healing = other_args.healing
	local bonus_cp = other_args.bonus_cp
	local radius = ability:GetSpecialValueFor("radius")
	local target_point = origin_location + direction * range

	local team = caster:GetTeamNumber()
	local iTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY
	local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, target_point, nil, radius, iTeam, iType, iFlag, iOrder, false)
	for k,unit in pairs(targets) do
		if unit ~= caster then
			unit:Heal(healing, caster)
			modifyCP(unit, bonus_cp)
		end
	end

	if other_args.apply_debuff_to then
		ability:ApplyDataDrivenModifier(caster, other_args.apply_debuff_to, "modifier_blessed_arrow_mischievous_blessing", {})
	end
end

function mischievousBlessingAttacked(keys)
	local caster = keys.caster
	local ability = keys.ability
	local unit = keys.attacker

	local healing = getStats(caster).ats * ability:GetSpecialValueFor("unbalanced_mischievous_healing_percent") / 100
	local bonus_cp = ability:GetSpecialValueFor("unbalanced_mischievous_bonus_cp")

	unit:Heal(healing, caster)
	modifyCP(unit, bonus_cp)
end
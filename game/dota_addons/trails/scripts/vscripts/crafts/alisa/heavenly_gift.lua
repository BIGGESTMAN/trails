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
	local args = {non_flat = true}

	spendCP(caster, ability)
	applyDelayCooldowns(caster, ability)

	if validEnhancedCraft(caster, target) then
		caster:RemoveModifierByName("modifier_combat_link_followup_available")
		target:RemoveModifierByName("modifier_combat_link_unbalanced")

		args.drain_cp_from = target
	end

	local direction = (arrow_destination - caster:GetAbsOrigin()):Normalized()
	local origin_location = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_attack1"))

	local sun_particle = ParticleManager:CreateParticle("particles/crafts/alisa/heavenly_gift/sun.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(sun_particle, 0, arrow_destination)

	ProjectileList:CreateLinearProjectile(caster, origin_location, direction, travel_speed, range, heavenlyGiftExplode, nil, nil, "particles/crafts/alisa/blessed_arrow/arrow.vpcf", args)
end

function heavenlyGiftExplode(caster, origin_location, direction, speed, range, collisionRules, collisionFunction, other_args)
	local ability = caster:FindAbilityByName("heavenly_gift")
	local radius = ability:GetSpecialValueFor("radius")
	local insight_duration = ability:GetSpecialValueFor("buffs_duration")
	local passion_duration = ability:GetSpecialValueFor("buffs_duration")
	local cp_per_second = ability:GetSpecialValueFor("passion_cp_regen")
	local target_point = origin_location + direction * range

	local team = caster:GetTeamNumber()
	local iTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY
	local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, target_point, nil, radius, iTeam, iType, iFlag, iOrder, false)
	for k,unit in pairs(targets) do
		unit:AddNewModifier(caster, ability, "modifier_insight", {duration = insight_duration})
		if unit ~= caster then
			unit:AddNewModifier(caster, ability, "modifier_passion", {duration = passion_duration, cp_per_second = cp_per_second})
		end
	end

	if other_args.drain_cp_from then
		local cp_drained = getCP(other_args.drain_cp_from)
		modifyCP(other_args.drain_cp_from, cp_drained * -1)
		caster.enhanced_heavenly_gift_cp_drained = cp_drained
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_heavenly_gift_cp_restore", {})
	end
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
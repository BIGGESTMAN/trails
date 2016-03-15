require "game_functions"
require "projectile_list"
require "libraries/animations"
require "libraries/util"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target_points[1]
	local target = keys.target

	local aim_period = ability:GetSpecialValueFor("aim_period")

	if validEnhancedCraft(caster, target) then
		caster:RemoveModifierByName("modifier_combat_link_followup_available")
		target:RemoveModifierByName("modifier_combat_link_unbalanced")
		aim_period = ability:GetSpecialValueFor("unbalanced_aim_period")
		caster.chaos_trigger_enhanced = true
	end

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_chaos_trigger_casting", {duration = aim_period})
	caster.chaos_trigger_targets = {}

	spendCP(caster, ability)
	applyDelayCooldowns(caster, ability)

	if caster:HasModifier("modifier_crit") then
		caster.chaos_trigger_crit = true
		caster:RemoveModifierByName("modifier_crit")
	end

	local direction = (target_point - caster:GetAbsOrigin()):Normalized()
	caster.chaos_trigger_aim_area_particle = ParticleManager:CreateParticle("particles/crafts/crow/chaos_trigger/aim_area.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControlForward(caster.chaos_trigger_aim_area_particle, 0, direction)
	ParticleManager:SetParticleControl(caster.chaos_trigger_aim_area_particle, 0, caster:GetAbsOrigin())

	caster:SetForwardVector(direction)
	caster.chaos_trigger_last_angle = VectorToAngles(direction).y
end

function aimingFinished(keys)
	local caster = keys.caster
	ParticleManager:DestroyParticle(caster.chaos_trigger_aim_area_particle, false)
	caster.chaos_trigger_aim_area_particle = nil
	resetLockonTimes(caster)
	caster.chaos_trigger_targets = nil
	caster.chaos_trigger_crit = nil
	caster.chaos_trigger_enhanced = nil
	caster.chaos_trigger_last_angle = nil
	caster.chaos_trigger_enhanced_has_fired = nil
end

function aim(keys)
	local caster = keys.caster
	local ability = keys.ability
	local lockon_time = ability:GetSpecialValueFor("lockon_time")
	local units_in_front = findUnitsInFront(caster)
	local update_interval = 1/30

	updateFacing(caster)

	ParticleManager:SetParticleControlForward(caster.chaos_trigger_aim_area_particle, 0, caster:GetForwardVector())
	ParticleManager:SetParticleControl(caster.chaos_trigger_aim_area_particle, 0, caster:GetAbsOrigin())

	for k,unit in pairs(units_in_front) do
		if not caster.chaos_trigger_targets[unit] then
			caster.chaos_trigger_targets[unit] = 0
			unit.chaos_trigger_lockon_particle = ParticleManager:CreateParticle("particles/crafts/crow/chaos_trigger/lockon.vpcf", PATTACH_OVERHEAD_FOLLOW, unit)
		end
		caster.chaos_trigger_targets[unit] = caster.chaos_trigger_targets[unit] + update_interval
	end
	for unit,aimtime in pairs(caster.chaos_trigger_targets) do
		if aimtime < lockon_time then
			if not tableContains(units_in_front, unit) then
				caster.chaos_trigger_targets[unit] = nil
				ParticleManager:DestroyParticle(unit.chaos_trigger_lockon_particle, true)
				unit.chaos_trigger_lockon_particle = nil
			end
		else
			fireShotAt(caster, unit)
			if not caster.chaos_trigger_enhanced then
				caster:RemoveModifierByName("modifier_chaos_trigger_casting")
			else
				caster.chaos_trigger_enhanced_has_fired = true
				resetLockonTimes(caster)
			end
			break
		end
	end
end

function resetLockonTimes(caster)
	for unit,aimtime in pairs(caster.chaos_trigger_targets) do
		if unit.chaos_trigger_lockon_particle then
			ParticleManager:DestroyParticle(unit.chaos_trigger_lockon_particle, true)
			unit.chaos_trigger_lockon_particle = nil
		end
	end
	caster.chaos_trigger_targets = {}
end

function updateFacing(caster)
	local ability = caster:FindAbilityByName("chaos_trigger")
	local max_allowed_turn = ability:GetSpecialValueFor("turn_rate") * 180 / math.pi

	local current_caster_y = VectorToAngles(caster:GetForwardVector()).y
	local last_angle = caster.chaos_trigger_last_angle
	local angle_delta = current_caster_y - last_angle
	if angle_delta > 180 then angle_delta = 360 - angle_delta end
	if math.abs(angle_delta) > max_allowed_turn then
		if angle_delta > 0 then
			angle_delta = max_allowed_turn
		else
			angle_delta = max_allowed_turn * -1
		end
	end
	caster.chaos_trigger_last_angle = caster.chaos_trigger_last_angle + angle_delta
	caster:SetForwardVector(RotatePosition(Vector(0,0,0), QAngle(0,caster.chaos_trigger_last_angle - 90,0), Vector(0,1,0)))
end

function findUnitsInFront(caster)
	local ability = caster:FindAbilityByName("chaos_trigger")
	local range = ability:GetSpecialValueFor("range")
	local radius = ability:GetSpecialValueFor("width") / 2
	local direction = caster:GetForwardVector()

	local team = caster:GetTeamNumber()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
	local iOrder = FIND_CLOSEST
	return FindUnitsInLine(team, caster:GetAbsOrigin(), caster:GetAbsOrigin() + direction * range, nil, radius, iTeam, iType, iOrder)
end

function fireShotAt(caster, target)
	local ability = caster:FindAbilityByName("chaos_trigger")
	local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100
	if caster.chaos_trigger_crit then damage_scale = damage_scale * 2 end
	local damage_type = ability:GetAbilityDamageType()
	local debuff_duration = ability:GetSpecialValueFor("debuff_duration")

	local targets = findUnitsInFront(caster)
	table.sort(targets, function(unit1, unit2)
		return distanceBetween(caster:GetAbsOrigin(), unit1:GetAbsOrigin()) <= distanceBetween(caster:GetAbsOrigin(), unit2:GetAbsOrigin())
	end)
	for k,unit in ipairs(targets) do
		local distance = (unit:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()
		local debuff_name = "modifier_nightmare"
		if k ~= 1 then debuff_name = "modifier_confuse" end
		applyEffect(unit, damage_type, function()
			dealScalingDamage(unit, caster, damage_type, damage_scale, ability, CRAFT_CP_GAIN_FACTOR)
			increaseUnbalance(caster, unit)
			if not caster.chaos_trigger_enhanced_has_fired then
				unit:AddNewModifier(caster, ability, debuff_name, {duration = debuff_duration})
			end
		end)
	end

	StartAnimation(caster, {duration = 1, activity = ACT_DOTA_ATTACK, rate = 1})
	local particle = ParticleManager:CreateParticle("particles/crafts/crow/chaos_trigger/bullet.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle, 1, (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized())
end
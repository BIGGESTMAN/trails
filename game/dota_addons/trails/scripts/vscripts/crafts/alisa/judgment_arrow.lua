require "game_functions"
require "libraries/notifications"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	if validEnhancedCraft(caster, target) then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_judgment_arrow_casting", {duration = ability:GetChannelTime()})
		caster.judgment_arrow_target = target
	else
		Notifications:Bottom(keys.caster:GetPlayerOwner(), {text="Must Target An Unbalanced Enemy", duration=1, style={color="red"}})
		caster:Interrupt()
	end
end

function updateFacing(keys)
	local caster = keys.caster
	if IsValidEntity(caster.judgment_arrow_target) then
		local direction = (caster.judgment_arrow_target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
		direction.z = 0
		keys.caster:SetForwardVector(direction)
	end
end

function channelFinish(keys)
	local caster = keys.caster
	caster:RemoveModifierByName("modifier_judgment_arrow_casting")
	if caster.judgment_arrow_target then
		local target = caster.judgment_arrow_target
		caster.judgment_arrow_target = nil
		caster:RemoveModifierByName("modifier_combat_link_followup_available")
		target:RemoveModifierByName("modifier_combat_link_unbalanced")
		fireArrow(caster, target, getCP(caster) == MAX_CP)
		modifyCP(caster, getCP(caster) * -1)
	end
end

function fireArrow(caster, target, max_cp)
	local ability = caster:FindAbilityByName("judgment_arrow")

	local range = ability:GetSpecialValueFor("range")
	local travel_speed = ability:GetSpecialValueFor("travel_speed")
	local radius = ability:GetSpecialValueFor("radius")
	damage = caster:GetAverageTrueAttackDamage() * ability:GetSpecialValueFor("damage_percent") / 100
	if max_cp then damage = caster:GetAverageTrueAttackDamage() * ability:GetSpecialValueFor("max_cp_damage_percent") / 100 end

	collisionRules = {
		team = caster:GetTeamNumber(),
		radius = radius,
		iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL,
		iFlag = DOTA_UNIT_TARGET_FLAG_NONE,
		iOrder = FIND_ANY_ORDER
	}
	local direction = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
	local origin_location = caster:GetAbsOrigin()

	ProjectileList:CreateLinearProjectile(caster, origin_location, direction, travel_speed, range, nil, collisionRules, arrowHit, "particles/crafts/alisa/blessed_arrow/arrow.vpcf", {damage = damage, max_cp = max_cp})
end

function arrowHit(caster, unit, other_args, projectile)
	local ability = caster:FindAbilityByName("judgment_arrow")
	local damage = other_args.damage
	local damage_type = ability:GetAbilityDamageType()
	local silence_duration = ability:GetSpecialValueFor("silence_duration")

	dealDamage(unit, caster, damage, damage_type, ability)
	ability:ApplyDataDrivenModifier(caster, unit, "modifier_judgment_arrow_silence", {})
	pullUnit(caster, unit, projectile, other_args.max_cp)
end

function pullUnit(caster, unit, projectile, max_cp)
	local pull_speed = 300
	local update_interval = 1/30

	local ability = caster:FindAbilityByName("judgment_arrow")
	ability:ApplyDataDrivenModifier(caster, unit, "modifier_judgment_arrow_pulled", {})
	local unit_vector = (unit:GetAbsOrigin() - projectile:GetAbsOrigin())
	Timers:CreateTimer(0, function()
		if IsValidEntity(projectile) then
			unit_vector = unit_vector - (unit_vector:Normalized() * pull_speed * update_interval)
			print(unit_vector)
			unit:SetAbsOrigin(projectile:GetAbsOrigin() + unit_vector)
			return update_interval
		else
			unit:RemoveModifierByName("modifier_judgment_arrow_pulled")
			if max_cp then
				ability:ApplyDataDrivenModifier(caster, unit, "modifier_judgment_arrow_stun", {})
			end
		end
	end)
end
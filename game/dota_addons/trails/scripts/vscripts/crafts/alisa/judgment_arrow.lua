require "game_functions"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_judgment_arrow_casting", {duration = ability:GetChannelTime()})
	ability:EndCooldown()
end

function channelFinish(keys)
	local caster = keys.caster
	caster:RemoveModifierByName("modifier_judgment_arrow_casting")
end

function channelSucceeded(keys)
	local caster = keys.caster
	fireArrow(caster, getCP(caster) == MAX_CP)
	modifyCP(caster, getCP(caster) * -1)
	applyDelayCooldowns(caster, keys.ability)
end

function fireArrow(caster, max_cp)
	local ability = caster:FindAbilityByName("judgment_arrow")

	local range = ability:GetSpecialValueFor("range")
	local travel_speed = ability:GetSpecialValueFor("travel_speed")
	local radius = ability:GetSpecialValueFor("radius")
	local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100
	if max_cp then damage_scale = ability:GetSpecialValueFor("max_cp_damage_percent") / 100 end
	
	if caster:HasModifier("modifier_crit") then
		damage_scale = damage_scale * 2
		caster:RemoveModifierByName("modifier_crit")
	end

	collisionRules = {
		team = caster:GetTeamNumber(),
		radius = radius,
		iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL,
		iFlag = DOTA_UNIT_TARGET_FLAG_NONE,
		iOrder = FIND_ANY_ORDER
	}
	local direction = caster:GetForwardVector()
	local origin_location = caster:GetAbsOrigin()

	ProjectileList:CreateLinearProjectile(caster, origin_location, direction, travel_speed, range, nil, collisionRules, arrowHit, "particles/crafts/alisa/blessed_arrow/arrow.vpcf", {damage_scale = damage_scale, max_cp = max_cp})
end

function arrowHit(caster, unit, other_args, projectile)
	local ability = caster:FindAbilityByName("judgment_arrow")
	local damage_scale = other_args.damage_scale
	local damage_type = ability:GetAbilityDamageType()
	local silence_duration = ability:GetSpecialValueFor("silence_duration")

	dealScalingDamage(unit, caster, damage_type, damage_scale, SCRAFT_CP_GAIN_FACTOR)
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
			-- print(unit_vector)
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
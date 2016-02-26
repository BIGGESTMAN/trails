require "game_functions"
require "libraries/notifications"
require "crafts/rean/gale"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_azure_flame_slash_casting", {duration = ability:GetChannelTime()})
	caster.azure_flame_slash_target = target
	ability:EndCooldown()
end

function updateFacing(keys)
	local caster = keys.caster
	if IsValidEntity(caster.azure_flame_slash_target) then
		local direction = (caster.azure_flame_slash_target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
		local distance = (caster.azure_flame_slash_target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()
		local max_distance = keys.ability:GetSpecialValueFor("break_range")
		direction.z = 0
		keys.caster:SetForwardVector(direction)
		if distance > max_distance then
			caster.azure_flame_slash_target = nil
			caster:InterruptChannel()
			Notifications:Bottom(caster:GetPlayerOwner(), {text="Target Out Of Range", duration=1, style={color="red"}})
		end
	end
end

function channelFinish(keys)
	local caster = keys.caster
	caster:RemoveModifierByName("modifier_azure_flame_slash_casting")
end

function channelSucceeded(keys)
	local caster = keys.caster
	if caster.azure_flame_slash_target then
		local target = caster.azure_flame_slash_target
		caster.azure_flame_slash_target = nil
		executeSlash(caster, target, getCP(caster) == MAX_CP)
		modifyCP(caster, getCP(caster) * -1)
		applyDelayCooldowns(caster, keys.ability)
	end
end

function executeSlash(caster, target, max_cp)
	local ability = caster:FindAbilityByName("azure_flame_slash")

	local radius = ability:GetSpecialValueFor("radius")
	local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100
	local damage_type = ability:GetAbilityDamageType()
	local burn_duration = ability:GetSpecialValueFor("burn_duration")

	if max_cp then damage_scale = ability:GetSpecialValueFor("max_cp_damage_percent") / 100 end
	
	if caster:HasModifier("modifier_crit") then
		damage_scale = damage_scale * 2
		caster:RemoveModifierByName("modifier_crit")
	end

	local team = caster:GetTeamNumber()
	local origin = target:GetAbsOrigin()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

	for k,unit in pairs(targets) do
		dealScalingDamage(unit, caster, damage_type, damage_scale, SCRAFT_CP_GAIN_FACTOR)
		increaseUnbalance(caster, unit)
		unit:AddNewModifier(caster, ability, "modifier_burn", {duration = burn_duration})
		applyGaleMark(caster, unit)
		if max_cp then increaseUnbalance(caster, target, ability:GetSpecialValueFor("max_cp_bonus_unbalance") - caster:FindAbilityByName("combat_link"):GetSpecialValueFor("base_unbalance_increase")) end
	end

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_azure_flame_slash_sword_inflamed", {})

	ParticleManager:CreateParticle("particles/crafts/rean/azure_flame_slash/slash.vpcf", PATTACH_ABSORIGIN, caster)
end
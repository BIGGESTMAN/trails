require "game_functions"
require "libraries/notifications"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_azure_flame_slash_casting", {duration = ability:GetChannelTime()})
	caster.azure_flame_slash_target = target
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
	if caster.azure_flame_slash_target then
		executeSlash(caster, caster.azure_flame_slash_target)
		caster.azure_flame_slash_target = nil
	end
end

function executeSlash(caster, target)
	local ability = caster:FindAbilityByName("azure_flame_slash")

	local radius = ability:GetSpecialValueFor("radius")
	local damage = caster:GetAverageTrueAttackDamage() * ability:GetSpecialValueFor("damage_percent") / 100
	local damage_type = ability:GetAbilityDamageType()
	local burn_duration = ability:GetSpecialValueFor("burn_duration")

	local team = caster:GetTeamNumber()
	local origin = target:GetAbsOrigin()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

	for k,unit in pairs(targets) do
		dealDamage(unit, caster, damage, damage_type, ability)
		unit:AddNewModifier(caster, ability, "modifier_burn", {duration = burn_duration})
	end

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_azure_flame_slash_sword_inflamed", {})

	ParticleManager:CreateParticle("particles/crafts/rean/azure_flame_slash/slash.vpcf", PATTACH_ABSORIGIN, caster)
end
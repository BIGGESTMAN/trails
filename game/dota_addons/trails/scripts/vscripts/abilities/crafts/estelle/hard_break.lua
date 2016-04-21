require "game_functions"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local radius = ability:GetSpecialValueFor("radius")
	local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100
	local damage_type = ability:GetAbilityDamageType()

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
		applyEffect(unit, damage_type, function()
			dealScalingDamage(unit, caster, damage_type, damage_scale, ability, CRAFT_CP_GAIN_FACTOR)
			if not unit:IsChanneling() then
				local buffs_purged = purgePositiveBuffs(unit)
				if buffs_purged > 0 then
					ability:ApplyDataDrivenModifier(caster, unit, "modifier_hard_break_purge_damage", {}):SetStackCount(buffs_purged)
				end
				print(buffs_purged)
			end
			unit:Interrupt()
		end)
	end

	spendCP(caster, ability)
	applyDelayCooldowns(caster, ability)

	ParticleManager:CreateParticle("particles/crafts/estelle/hard_break/cast.vpcf", PATTACH_ABSORIGIN, caster)
end

function dealPurgeDamage(keys)
	local caster = keys.caster
	local target = keys.target

	
end
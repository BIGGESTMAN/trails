require "game_functions"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability

	local radius = ability:GetSpecialValueFor("radius")

	spendCP(caster, ability)
	applyDelayCooldowns(caster, ability)

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_hurricane_casting", {duration = ability:GetChannelTime()})

	caster.hurricane_particle = ParticleManager:CreateParticle("particles/econ/items/juggernaut/jugg_sword_fireborn_odachi/juggernaut_blade_fury_fireborn_odachi.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(caster.hurricane_particle, 5, Vector(radius,1,radius))
	-- DebugDrawCircle(origin, Vector(255,0,0), 0.5, radius, true, 3)
end

function channelFinished(keys)
	keys.caster:RemoveModifierByName("modifier_hurricane_casting")
	ParticleManager:DestroyParticle(keys.caster.hurricane_particle, false)
	keys.caster.hurricane_particle = nil
end

function dealDamage(keys)
	local caster = keys.caster
	local ability = keys.ability
	
	local radius = ability:GetSpecialValueFor("radius")
	local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100
	local knockback_duration = ability:GetSpecialValueFor("knockback_duration")
	local knockback_distance = ability:GetSpecialValueFor("knockback_distance")
	local damage_type = ability:GetAbilityDamageType()

	local team = caster:GetTeamNumber()
	local origin = caster:GetAbsOrigin()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
	for k,unit in pairs(targets) do
		applyEffect(unit, damage_type, function()
			dealScalingDamage(unit, caster, damage_type, damage_scale, ability, CRAFT_CP_GAIN_FACTOR)
			dash(unit, (unit:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized(), knockback_distance / knockback_duration, knockback_distance, true)
		end)
	end
end
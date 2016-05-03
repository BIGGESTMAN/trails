require "game_functions"
require "libraries/util"

function onUpgrade(keys)
	local ability = keys.ability
	if not ability.SpellStart then
		ability.SpellStart = abilityPhaseStart
		ability.SpellCast = spellCast
	end
end

function abilityPhaseStart(ability, caster)
	local target_inaccuracy = 300
	local strikes = ability:GetSpecialValueFor("strikes")
	local search_radius = ability:GetSpecialValueFor("search_radius")
	local impact_radius = ability:GetSpecialValueFor("impact_radius")

	local origin = caster:GetAbsOrigin()

	caster.sunstrike_state = {}
	caster.sunstrike_state.targets = {}
	caster.sunstrike_state.aoe_previews = {}
	for i=1,strikes do
		local strike_destination = GetGroundPosition(randomPointInCircle(origin, search_radius), caster)

		local team = caster:GetTeamNumber()
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_HERO
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_ANY_ORDER
		local targets = FindUnitsInRadius(team, origin, nil, search_radius, iTeam, iType, iFlag, iOrder, false)
		if #targets > 0 then
			local unit = targets[RandomInt(1, #targets)]
			strike_destination = GetGroundPosition(randomPointInCircle(unit:GetAbsOrigin(), target_inaccuracy), caster)
		end

		table.insert(caster.sunstrike_state.targets, strike_destination)

		local preview_particle = ParticleManager:CreateParticle("particles/aoe_previews/circle.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(preview_particle, 0, strike_destination)
		ParticleManager:SetParticleControl(preview_particle, 1, Vector(impact_radius,0,0))
		table.insert(caster.sunstrike_state.aoe_previews, preview_particle)
	end
end

function abilityPhaseInterrupted(keys)
	for k,particle in pairs(keys.caster.sunstrike_state.aoe_previews) do
		ParticleManager:DestroyParticle(particle, false)
	end

	keys.caster.sunstrike_state = nil
end

function spellCast(ability, caster)
	local target_points = caster.sunstrike_state.targets
	for k,particle in pairs(caster.sunstrike_state.aoe_previews) do
		ParticleManager:DestroyParticle(particle, false)
	end
	caster.sunstrike_state = nil

	local radius = ability:GetSpecialValueFor("impact_radius")
	local damage = ability:GetSpecialValueFor("damage")
	local damage_type = ability:GetAbilityDamageType()

	local spell_result = BOSS_SPELL_RESULT_FAILURE
	for k,target_point in pairs(target_points) do
		local particle = ParticleManager:CreateParticle("particles/econ/items/invoker/invoker_apex/invoker_sun_strike_immortal1.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(particle, 0, target_point)

		local team = caster:GetTeamNumber()
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_ANY_ORDER
		local targets = FindUnitsInRadius(team, target_point, nil, radius, iTeam, iType, iFlag, iOrder, false)
		for k,unit in pairs(targets) do
			spell_result = BOSS_SPELL_RESULT_SUCCESS
			applyEffect(unit, damage_type, function()
				dealDamage(unit, caster, damage, damage_type, ability)
			end)
		end
	end
	BossAI:ReportSpellResult(boss, spell_result)
end
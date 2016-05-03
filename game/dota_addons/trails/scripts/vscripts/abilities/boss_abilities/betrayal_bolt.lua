require "game_functions"

function onUpgrade(keys)
	local ability = keys.ability
	if not ability.SpellStart then
		ability.SpellStart = abilityPhaseStart
		ability.SpellCast = spellCast
	end
end

function abilityPhaseStart(ability, caster)
	local search_radius = ability:GetSpecialValueFor("search_radius")
	local origin = caster:GetAbsOrigin()

	caster.betrayal_bolt_state = {}
	caster.betrayal_bolt_state.targets = {}
	caster.betrayal_bolt_state.aoe_previews = {}

	local team = caster:GetTeamNumber()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, origin, nil, search_radius, iTeam, iType, iFlag, iOrder, false)
	for k,unit in pairs(targets) do
		table.insert(caster.betrayal_bolt_state.targets, unit)
		for k,betrayal_target in pairs(targets) do
			if betrayal_target ~= unit then
				local preview_particle = ParticleManager:CreateParticle("particles/bosses/betrayal_bolt_targeting.vpcf", PATTACH_CUSTOMORIGIN, nil)
				ParticleManager:SetParticleControlEnt(preview_particle, 0, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true)
				ParticleManager:SetParticleControlEnt(preview_particle, 1, betrayal_target, PATTACH_POINT_FOLLOW, "attach_hitloc", betrayal_target:GetAbsOrigin(), true)
				table.insert(caster.betrayal_bolt_state.aoe_previews, preview_particle)
			end
		end
	end
end

function abilityPhaseInterrupted(keys)
	for k,particle in pairs(keys.caster.betrayal_bolt_state.aoe_previews) do
		ParticleManager:DestroyParticle(particle, false)
	end

	keys.caster.betrayal_bolt_state = nil
end

function spellCast(ability, caster)
	local targets = caster.betrayal_bolt_state.targets
	for k,particle in pairs(caster.betrayal_bolt_state.aoe_previews) do
		ParticleManager:DestroyParticle(particle, false)
	end
	caster.betrayal_bolt_state = nil

	-- local radius = ability:GetSpecialValueFor("projectile_radius")
	-- local speed = ability:GetSpecialValueFor("projectile_speed")
	-- local range = ability:GetSpecialValueFor("projectile_range")
	-- local bolts = ability:GetSpecialValueFor("bolts")
	-- local delay_between_bolts = ability:GetSpecialValueFor("delay_between_bolts")
	-- local damage = ability:GetSpecialValueFor("damage")
	-- local damage_type = ability:GetAbilityDamageType()

	-- local spell_result = BOSS_SPELL_RESULT_FAILURE
	-- for k,target_point in pairs(target_points) do
	-- 	local particle = ParticleManager:CreateParticle("particles/econ/items/invoker/invoker_apex/invoker_sun_strike_immortal1.vpcf", PATTACH_CUSTOMORIGIN, nil)
	-- 	ParticleManager:SetParticleControl(particle, 0, target_point)

	-- 	local team = caster:GetTeamNumber()
	-- 	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	-- 	local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
	-- 	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	-- 	local iOrder = FIND_ANY_ORDER
	-- 	local targets = FindUnitsInRadius(team, target_point, nil, radius, iTeam, iType, iFlag, iOrder, false)
	-- 	for k,unit in pairs(targets) do
	-- 		spell_result = BOSS_SPELL_RESULT_SUCCESS
	-- 		applyEffect(unit, damage_type, function()
	-- 			dealDamage(unit, caster, damage, damage_type, ability)
	-- 		end)
	-- 	end
	-- end
	-- BossAI:ReportSpellResult(boss, spell_result)
end
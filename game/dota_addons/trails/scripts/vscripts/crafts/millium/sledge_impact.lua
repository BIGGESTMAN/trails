require "game_functions"

LinkLuaModifier("modifier_sledge_impact_slow", "crafts/millium/sledge_impact.lua", LUA_MODIFIER_MOTION_NONE)
sledge_impact = class({})

if IsServer() then
	function sledge_impact:OnSpellStart()
		local caster = self:GetCaster()
		local ability = self
		local target = self:GetCursorTarget()

		local radius = ability:GetSpecialValueFor("radius")
		local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100
		local damage_type = ability:GetAbilityDamageType()
		local bonus_unbalance = ability:GetSpecialValueFor("bonus_unbalance")
		local balance_down_duration = ability:GetSpecialValueFor("balance_down_duration")
		local crater_duration = ability:GetSpecialValueFor("unbalanced_crater_duration")
		local spd_and_mov_down_duration = ability:GetSpecialValueFor("spd_and_mov_down_duration")
		local particle_name = "particles/crafts/millium/sledge_impact/shockwave_normal.vpcf"

		local enhanced = false
		if validEnhancedCraft(caster, target) then
			caster:RemoveModifierByName("modifier_combat_link_followup_available")
			target:RemoveModifierByName("modifier_combat_link_unbalanced")
			damage_scale = ability:GetSpecialValueFor("unbalanced_damage_percent") / 100
			radius = ability:GetSpecialValueFor("unbalanced_radius")
			particle_name = "particles/crafts/millium/sledge_impact/shockwave_enhanced.vpcf"
			enhanced = true
		end

		spendCP(caster, ability)
		applyDelayCooldowns(caster, ability)

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
				increaseUnbalance(caster, unit, bonus_unbalance)
				unit:AddNewModifier(caster, ability, "modifier_balance_down", {duration = balance_down_duration})
			end)
		end

		if enhanced then
			local crater_particle = ParticleManager:CreateParticle("particles/crafts/millium/sledge_impact/crater.vpcf", PATTACH_CUSTOMORIGIN, nil)
			ParticleManager:SetParticleControl(crater_particle, 0, origin)

			local update_interval = 1/30
			local duration_elapsed = 0
			Timers:CreateTimer(0, function()
				duration_elapsed = duration_elapsed + update_interval
				local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
				for k,unit in pairs(targets) do
					unit:AddNewModifier(caster, ability, "modifier_sledge_impact_slow", {duration = spd_and_mov_down_duration})
				end
				if duration_elapsed < crater_duration then return update_interval end
			end)
		end

		local particle = ParticleManager:CreateParticle(particle_name, PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(particle, 0, origin)
		-- DebugDrawCircle(origin, Vector(255,0,0), 0.5, radius, true, 3)
	end
end

function sledge_impact:GetBehavior()
	local behavior = DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_AOE
	if self:GetCaster():HasModifier("modifier_combat_link_followup_available") then
		behavior = DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
	end
	return behavior
end

function sledge_impact:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function sledge_impact:CastFilterResultTarget(target)
	if target:HasModifier("modifier_combat_link_unbalanced") then
		return UF_SUCCESS
	else
		return UF_FAIL_CUSTOM
	end
end

function sledge_impact:GetCustomCastErrorTarget(target)
	return "must_target_unbalanced"
end

function sledge_impact:GetCastAnimation()
	return ACT_DOTA_ATTACK
end

function sledge_impact:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	caster.sledge_impact_casting_particle = ParticleManager:CreateParticle("particles/crafts/millium/sledge_impact/lammy_hammer.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	return true
end

function sledge_impact:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
	if caster.sledge_impact_casting_particle then
		ParticleManager:DestroyParticle(caster.sledge_impact_casting_particle, true)
		caster.sledge_impact_casting_particle = nil
	end
end

modifier_sledge_impact_slow = class({})

function modifier_sledge_impact_slow:GetTexture()
	return "millium_sledge_impact"
end

function modifier_sledge_impact_slow:IsDebuff()
	return true
end

function modifier_sledge_impact_slow:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_sledge_impact_slow:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("spd_and_mov_down") * -1
end

function modifier_sledge_impact_slow:GetUniqueStatModifiers()
	local ability = self:GetAbility()
	local stat_reduction = ability:GetSpecialValueFor("spd_and_mov_down") * -1
	return {BonusSpd = stat_reduction}
end
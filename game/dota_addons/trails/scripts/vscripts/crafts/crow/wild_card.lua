require "game_functions"

wild_card = class({})

if IsServer() then
	function wild_card:OnSpellStart()
		local caster = self:GetCaster()
		local ability = self
		local target = self:GetCursorTarget()

		local enhanced = false

		if validEnhancedCraft(caster, target) then
			caster:RemoveModifierByName("modifier_combat_link_followup_available")
			target:RemoveModifierByName("modifier_combat_link_unbalanced")
			enhanced = true
		end

		modifyCP(caster, getCPCost(ability) * -1)
		applyDelayCooldowns(caster, ability)

		local targets = getAllLivingHeroes()
		if not enhanced then
			local unit = targets[RandomInt(1, #targets)]
			wildCardEffect(caster, unit)
		else
			for k,unit in pairs(targets) do
				wildCardEffect(caster, unit)
			end
		end
	end
end

function wildCardEffect(caster, target)
	local ability = caster:FindAbilityByName("wild_card")

	local stat_increase_percent = ability:GetSpecialValueFor("stat_increase_percent")
	local stat_increase_duration = ability:GetSpecialValueFor("stat_increase_duration")
	local bonus_cp = ability:GetSpecialValueFor("cp_increase")
	local debuff_duration = ability:GetSpecialValueFor("debuff_duration")

	local friendly_effects = {"str_up", "def_adf_up", "modifier_cp_boost"}
	local enemy_effects = {"modifier_confuse", "modifier_deathblow"}

	if caster:GetTeam() == target:GetTeam() then
		local effect = friendly_effects[RandomInt(1, #friendly_effects)]
		if effect == "str_up" then
			modifyStat(target, STAT_STR, stat_increase_percent, stat_increase_duration)
		elseif effect == "def_adf_up" then
			modifyStat(target, STAT_DEF, stat_increase_percent, stat_increase_duration)
			modifyStat(target, STAT_ADF, stat_increase_percent, stat_increase_duration)
		elseif effect == "modifier_cp_boost" then
			target:AddNewModifier(caster, ability, "modifier_cp_boost", {duration = stat_increase_duration})
		end
	else
		local modifier_name = enemy_effects[RandomInt(1, #enemy_effects)]
		target:AddNewModifier(caster, ability, modifier_name, {duration = debuff_duration})
	end

	ParticleManager:CreateParticle("particles/units/heroes/hero_chen/chen_penitence.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
end

function wild_card:GetBehavior()
	local behavior = DOTA_ABILITY_BEHAVIOR_NO_TARGET
	if self:GetCaster():HasModifier("modifier_combat_link_followup_available") then
		behavior = DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
	end
	return behavior
end

function wild_card:CastFilterResultTarget(target)
	if target:HasModifier("modifier_combat_link_unbalanced") then
		return UF_SUCCESS
	else
		return UF_FAIL_CUSTOM
	end
end

function wild_card:GetCustomCastErrorTarget(target)
	return "must_target_unbalanced"
end
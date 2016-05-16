require "game_functions"
require "libraries/util"

LinkLuaModifier("modifier_pincer_attack_passive", "abilities/mobs/blade_pincer_pincer_attack.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pincer_attack_recently_attacked", "abilities/mobs/blade_pincer_pincer_attack.lua", LUA_MODIFIER_MOTION_NONE)
mob_blade_pincer_pincer_attack = class({})

if IsServer() then
	function mob_blade_pincer_pincer_attack:OnSpellStart()
		local caster = self:GetCaster()
		local ability = self
		local target = self:GetCursorTarget()

		local damage_type = ability:GetAbilityDamageType()
		local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100
		local bonus_damage_scale = ability:GetSpecialValueFor("bonus_damage_percent") / 100

		if target:HasModifier("modifier_pincer_attack_recently_attacked") then
			damage_scale = damage_scale + bonus_damage_scale
		end

		applyEffect(target, damage_type, function()
			dealScalingDamage(target, caster, damage_type, damage_scale, ability)
		end)
	end
end

function mob_blade_pincer_pincer_attack:GetIntrinsicModifierName()
	return "modifier_pincer_attack_passive"
end

modifier_pincer_attack_passive = class({})

function modifier_pincer_attack_passive:IsHidden()
	return true
end

if IsServer() then
	function modifier_pincer_attack_passive:OnAttackLanded(params)
		local hero = self:GetParent()
		local ability = self:GetAbility()
		if params.attacker:GetUnitName() == "trailsadventure_mob_blade_pincer" or params.attacker:GetUnitName() == "trailsadventure_mob_blade_horn" then
			params.target:AddNewModifier(hero, ability, "modifier_pincer_attack_recently_attacked", {duration = ability:GetSpecialValueFor("blade_horn_attack_window")})
		end
	end
end

function modifier_pincer_attack_passive:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK_LANDED}
end

modifier_pincer_attack_recently_attacked = class({})

function modifier_pincer_attack_recently_attacked:IsHidden()
	return true
end
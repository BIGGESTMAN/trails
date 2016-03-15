require "game_functions"
require "arts/earth/earth_pulse"

LinkLuaModifier("modifier_master_aegis_passive", "master_quartz/aegis.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aegis_counterattack", "master_quartz/aegis.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aegis_last_bastion", "master_quartz/aegis.lua", LUA_MODIFIER_MOTION_NONE)
item_master_aegis = class({})
item_master_aegis.OnSpellStart = item_earth_pulse.OnSpellStart
item_master_aegis.OnAbilityPhaseStart = item_earth_pulse.OnAbilityPhaseStart
item_master_aegis.OnAbilityPhaseInterrupted = item_earth_pulse.OnAbilityPhaseInterrupted
item_master_aegis.GetCastAnimation = item_earth_pulse.GetCastAnimation

function item_master_aegis:GetIntrinsicModifierName()
	return "modifier_master_aegis_passive"
end

item_master_aegis_1 = item_master_aegis
item_master_aegis_2 = item_master_aegis
item_master_aegis_3 = item_master_aegis
item_master_aegis_4 = item_master_aegis
item_master_aegis_5 = item_master_aegis

modifier_master_aegis_passive = class({})

function modifier_master_aegis_passive:IsHidden()
	return true
end

if IsServer() then
	function modifier_master_aegis_passive:OnCreated( kv )
		self.update_interval = 1/30
		self.vanguard_time_accumulated = 0
		self:StartIntervalThink(self.update_interval)
	end

	function modifier_master_aegis_passive:OnIntervalThink()
		local ability = self:GetAbility()
		local vanguard_cooldown = ability:GetSpecialValueFor("vanguard_cooldown")
		if vanguard_cooldown > 0 then
			self.vanguard_time_accumulated = self.vanguard_time_accumulated + self.update_interval * getHeroLinkScaling(self:GetParent())
			if self.vanguard_time_accumulated >= vanguard_cooldown then
				self:GetParent():AddNewModifier(self:GetParent(), ability, "modifier_physical_guard", {})
				self:GetParent():AddNewModifier(self:GetParent(), ability, "modifier_magical_guard", {})
				self.vanguard_time_accumulated = 0
			end
		end
	end

	function modifier_master_aegis_passive:DeclareFunctions()
		return {MODIFIER_EVENT_ON_TAKEDAMAGE,
				MODIFIER_EVENT_ON_HERO_KILLED}
	end

	function modifier_master_aegis_passive:OnTakeDamage(params)
		local ability = self:GetAbility()
		local hero = self:GetParent()
		if params.unit == hero then
			self.vanguard_time_accumulated = 0

			if hero:GetHealthPercent() <= LOW_HP_THRESHOLD_PERCENT and self.last_bastion_available then
				self.last_bastion_available = false
				hero:AddNewModifier(hero, ability, "modifier_aegis_last_bastion", {duration = getMasterQuartzSpecialValue(hero, "last_bastion_duration")})
			end
		end
		if params.unit == hero.combat_linked_to and self.counterattack_damage_taken and distanceBetween(hero:GetAbsOrigin(), params.attacker) <= ability:GetSpecialValueFor("counterattack_range") then
			self.counterattack_damage_taken = self.counterattack_damage_taken + params.damage
			if self.counterattack_damage_taken >= ability:GetSpecialValueFor("counterattack_damage_threshold_percent") / 100 * params.unit:GetMaxHealth() then
				self.counterattack_damage_taken = 0
				if IsValidAlive(params.attacker) then
					params.attacker:AddNewModifier(hero, ability, "modifier_aegis_counterattack", {duration = ability:GetSpecialValueFor("counterattack_damage_bonus_duration")})
				end
				reduceDelay(hero, getMasterQuartzSpecialValue(self:GetParent(), "counterattack_delay_reduction"))
			end
		end
	end

	function modifier_master_aegis_passive:OnHeroKilled(params)
		if params.unit == self:GetParent().combat_linked_to then
			if IsValidAlive(params.attacker) then
				params.attacker:AddNewModifier(self:GetParent(), ability, "modifier_aegis_counterattack", {})
			end
			removeDelay(self:GetParent())
		end
	end
end

function modifier_master_aegis_passive:RoundStarted(args)
	if self:GetAbility():GetSpecialValueFor("last_bastion_duration") > 0 then
		self.last_bastion_available = true
	end
	if self:GetAbility():GetSpecialValueFor("counterattack_damage_bonus") > 0 then
		self.counterattack_damage_taken = 0
	end
end

function modifier_master_aegis_passive:GuardTriggered(args)
	local ability = self:GetAbility()
	modifyStat(self:GetParent(), STAT_STR, getMasterQuartzSpecialValue(self:GetParent(), "vanguard_stat_increase"), ability:GetSpecialValueFor("vanguard_stat_increase_duration"))
	modifyStat(self:GetParent(), STAT_MOV, getMasterQuartzSpecialValue(self:GetParent(), "vanguard_stat_increase"), ability:GetSpecialValueFor("vanguard_stat_increase_duration"))
end

-- function modifier_master_aegis_passive:CreateCoverParticles(damage_origin)
-- 	local caster = self:GetParent()
-- 	local ally = caster.combat_linked_to
-- 	local arc_particle = ParticleManager:CreateParticle("particles/master_quartz/force/cover_shield_arc.vpcf", PATTACH_CUSTOMORIGIN, caster)
-- 	ParticleManager:SetParticleControl(arc_particle, 0, caster:GetAbsOrigin())
-- 	ParticleManager:SetParticleControlForward(arc_particle, 0, (damage_origin - caster:GetAbsOrigin()):Normalized())
-- 	local ally_particle = ParticleManager:CreateParticle("particles/master_quartz/force/cover_shield_sphere.vpcf", PATTACH_POINT_FOLLOW, ally)
-- end

modifier_aegis_counterattack = class({})

function modifier_aegis_counterattack:GetTexture()
	return "alpha_wolf_critical_strike"
end

function modifier_aegis_counterattack:IsDebuff()
	return true
end

function modifier_aegis_counterattack:GetEffectName()
	return "particles/units/heroes/hero_rubick/rubick_fade_bolt_debuff.vpcf"
end

function modifier_aegis_counterattack:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

modifier_aegis_last_bastion = class({})

function modifier_aegis_last_bastion:GetTexture()
	return "master_aegis"
end

function modifier_aegis_last_bastion:GetEffectName()
	return "particles/master_quartz/aegis/last_bastion_shield.vpcf"
end

function modifier_aegis_last_bastion:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
require "game_functions"
require "arts/mirage/phantom_phobia"

LinkLuaModifier("modifier_cypher_gambling_strike", "master_quartz/cypher.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_cypher_gambling_magic", "master_quartz/cypher.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_cypher_counterattack", "master_quartz/cypher.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_master_cypher_passive", "master_quartz/cypher.lua", LUA_MODIFIER_MOTION_NONE)
item_master_cypher = class({})
item_master_cypher.OnSpellStart = item_phantom_phobia.OnSpellStart
item_master_cypher.OnAbilityPhaseStart = item_phantom_phobia.OnAbilityPhaseStart
item_master_cypher.OnAbilityPhaseInterrupted = item_phantom_phobia.OnAbilityPhaseInterrupted
item_master_cypher.GetCastAnimation = item_phantom_phobia.GetCastAnimation

function item_master_cypher:GetIntrinsicModifierName()
	return "modifier_master_cypher_passive"
end

item_master_cypher_1 = item_master_cypher
item_master_cypher_2 = item_master_cypher
item_master_cypher_3 = item_master_cypher
item_master_cypher_4 = item_master_cypher
item_master_cypher_5 = item_master_cypher

modifier_master_cypher_passive = class({})

function modifier_master_cypher_passive:IsHidden()
	return true
end

if IsServer() then
	-- function modifier_master_cypher_passive:OnCreated( kv )
	-- 	self.update_interval = 1/30
	-- 	self.vanguard_time_accumulated = 0
	-- 	self:StartIntervalThink(self.update_interval)
	-- end

	-- function modifier_master_cypher_passive:OnIntervalThink()
	-- 	local ability = self:GetAbility()
	-- 	local vanguard_cooldown = ability:GetSpecialValueFor("vanguard_cooldown")
	-- 	if vanguard_cooldown > 0 then
	-- 		self.vanguard_time_accumulated = self.vanguard_time_accumulated + self.update_interval * getHeroLinkScaling(self:GetParent())
	-- 		if self.vanguard_time_accumulated >= vanguard_cooldown then
	-- 			self:GetParent():AddNewModifier(self:GetParent(), ability, "modifier_physical_guard", {})
	-- 			self:GetParent():AddNewModifier(self:GetParent(), ability, "modifier_magical_guard", {})
	-- 			self.vanguard_time_accumulated = 0
	-- 		end
	-- 	end
	-- end

	function modifier_master_cypher_passive:DeclareFunctions()
		return {MODIFIER_EVENT_ON_TAKEDAMAGE}
	end

	function modifier_master_cypher_passive:OnTakeDamage(params)
		local ability = self:GetAbility()
		local hero = self:GetParent()
		if params.attacker == hero then
			if params.damage_type == DAMAGE_TYPE_PHYSICAL and not hero:HasModifier("modifier_cypher_gambling_strike") then
				self.gambling_strike_damage_dealt = self.gambling_strike_damage_dealt + params.damage
				if self.gambling_strike_damage_dealt >= ability:GetSpecialValueFor("gambling_strike_damage_threshold") then
					hero:AddNewModifier(hero, self:GetAbility(), "modifier_cypher_gambling_strike", {})
					self.gambling_strike_damage_dealt = 0
				end
			elseif self.gambling_magic_damage_dealt and params.damage_type == DAMAGE_TYPE_MAGICAL and not hero:HasModifier("modifier_cypher_gambling_magic") then
				self.gambling_magic_damage_dealt = self.gambling_magic_damage_dealt + params.damage
				if self.gambling_magic_damage_dealt >= ability:GetSpecialValueFor("gambling_magic_damage_threshold") then
					hero:AddNewModifier(hero, self:GetAbility(), "modifier_cypher_gambling_magic", {})
					self.gambling_magic_damage_dealt = 0
				end
			end
		end
		if params.unit == hero.combat_linked_to and self.counterattack_damage_taken and distanceBetween(hero:GetAbsOrigin(), params.attacker:GetAbsOrigin()) <= ability:GetSpecialValueFor("counterattack_range") then
			self.counterattack_damage_taken = self.counterattack_damage_taken + params.damage
			if self.counterattack_damage_taken >= ability:GetSpecialValueFor("counterattack_damage_threshold_percent") / 100 * params.unit:GetMaxHealth() then
				self.counterattack_damage_taken = 0
				if IsValidAlive(params.attacker) then
					params.attacker:AddNewModifier(hero, ability, "modifier_cypher_counterattack", {duration = ability:GetSpecialValueFor("counterattack_damage_bonus_duration")})
				end
				reduceDelay(hero, getMasterQuartzSpecialValue(self:GetParent(), "counterattack_delay_reduction"))
			end
		end
	end
end

function modifier_master_cypher_passive:RoundStarted(args)
	self.gambling_strike_damage_dealt = 0
	if self:GetAbility():GetSpecialValueFor("counterattack_damage_bonus") > 0 then
		self.counterattack_damage_taken = 0
	end
	if self:GetAbility():GetSpecialValueFor("gambling_magic_damage_threshold") > 0 then
		self.gambling_magic_damage_dealt = 0
	end
	if self:GetAbility():GetSpecialValueFor("auto_charge_cooldown") > 0 then
		self.auto_charge_available = true
	end
end

modifier_cypher_counterattack = class({})

function modifier_cypher_counterattack:GetTexture()
	return "alpha_wolf_critical_strike"
end

function modifier_cypher_counterattack:IsDebuff()
	return true
end

function modifier_cypher_counterattack:GetEffectName()
	return "particles/units/heroes/hero_rubick/rubick_fade_bolt_debuff.vpcf"
end

function modifier_cypher_counterattack:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

modifier_cypher_gambling_strike = class({})

function modifier_cypher_gambling_strike:GetTexture()
	return "item_master_cypher"
end

function modifier_cypher_gambling_strike:DealGamblingDamage()
	local hero = self:GetParent()
	local targets = getAllLivingHeroes(hero:GetOpposingTeamNumber())
	local target = targets[RandomInt(1, #targets)]
	local damage_scale = getMasterQuartzSpecialValue(hero, "gambling_strike_damage_percent") / 100
	local damage_type = DAMAGE_TYPE_MAGICAL

	self:Destroy()
	dealScalingDamage(target, hero, damage_scale, damage_type, self:GetAbility())

	local particle = ParticleManager:CreateParticle("particles/master_quartz/cypher/gambling_strike_link.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControlEnt(particle, 0, hero, PATTACH_POINT_FOLLOW, "attach_hitloc", hero:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
end

modifier_cypher_gambling_magic = class({})

function modifier_cypher_gambling_magic:GetTexture()
	return "item_master_cypher"
end

function modifier_cypher_gambling_magic:DealGamblingDamage()
	local hero = self:GetParent()
	local targets = getAllLivingHeroes(hero:GetOpposingTeamNumber())
	local target = targets[RandomInt(1, #targets)]
	local damage_scale = getMasterQuartzSpecialValue(hero, "gambling_magic_damage_percent") / 100
	local damage_type = DAMAGE_TYPE_PHYSICAL

	self:Destroy()
	dealScalingDamage(target, hero, damage_scale, damage_type, self:GetAbility())

	local particle = ParticleManager:CreateParticle("particles/master_quartz/cypher/gambling_strike_link.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControlEnt(particle, 0, hero, PATTACH_POINT_FOLLOW, "attach_hitloc", hero:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
end
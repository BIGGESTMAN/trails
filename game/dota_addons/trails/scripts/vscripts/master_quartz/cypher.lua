require "game_functions"
require "arts/mirage/phantom_phobia"

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
	function modifier_master_cypher_passive:OnCreated( kv )
		self.cp_interval = 1/30
		self:StartIntervalThink(self.cp_interval)
	end

	function modifier_master_cypher_passive:OnIntervalThink()
		local cp_per_second = getMasterQuartzSpecialValue(self:GetParent(), "heated_mind_cp_regen", self:GetAbility())
		modifyCP(self:GetParent(), cp_per_second * self.cp_interval)
	end

	function modifier_master_cypher_passive:DeclareFunctions()
		return {MODIFIER_EVENT_ON_TAKEDAMAGE,
				MODIFIER_EVENT_ON_HERO_KILLED}
	end

	function modifier_master_cypher_passive:OnTakeDamage(params)
		if params.unit == self:GetParent() then
			if self:GetParent():GetHealthPercent() <= LOW_HP_THRESHOLD_PERCENT and self.fighting_spirit_available then
				self.fighting_spirit_available = false
				modifyCP(self:GetParent(), getMasterQuartzSpecialValue(self:GetParent(), "fighting_spirit_cp"))
			end
		end
	end

	function modifier_master_cypher_passive:OnHeroKilled(params)
		if params.attacker == self:GetParent() then
			modifyCP(self:GetParent(), getMasterQuartzSpecialValue(self:GetParent(), "thrill_of_battle_cp") * 2)
		end
	end
end

function modifier_master_cypher_passive:RoundStarted(args)
	if self:GetAbility():GetSpecialValueFor("fighting_spirit_cp") > 0 then
		self.fighting_spirit_available = true
	end
end

function modifier_master_cypher_passive:UnitUnbalanced(args)
	local caster = self:GetParent()
	local target = args.unit
	local distance = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()
	if target:GetTeamNumber() ~= caster:GetTeamNumber() and distance <= self:GetAbility():GetSpecialValueFor("thrill_of_battle_range") then
		modifyCP(caster, getMasterQuartzSpecialValue(caster, "thrill_of_battle_cp"))
	end
end

function modifier_master_cypher_passive:CreateCoverParticles(damage_origin)
	local caster = self:GetParent()
	local ally = caster.combat_linked_to
	local arc_particle = ParticleManager:CreateParticle("particles/master_quartz/cypher/cover_shield_arc.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(arc_particle, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControlForward(arc_particle, 0, (damage_origin - caster:GetAbsOrigin()):Normalized())
	local ally_particle = ParticleManager:CreateParticle("particles/master_quartz/cypher/cover_shield_sphere.vpcf", PATTACH_POINT_FOLLOW, ally)
end


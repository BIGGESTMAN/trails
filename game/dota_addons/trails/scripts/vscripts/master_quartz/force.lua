require "game_functions"
require "arts/fire/impassion"

LinkLuaModifier("modifier_master_force_passive", "master_quartz/force.lua", LUA_MODIFIER_MOTION_NONE)
item_master_force = class({})
item_master_force.OnSpellStart = item_impassion.OnSpellStart
item_master_force.OnAbilityPhaseStart = item_impassion.OnAbilityPhaseStart
item_master_force.OnAbilityPhaseInterrupted = item_impassion.OnAbilityPhaseInterrupted
item_master_force.GetCastAnimation = item_impassion.GetCastAnimation

function item_master_force:GetIntrinsicModifierName()
	return "modifier_master_force_passive"
end

item_master_force_1 = item_master_force
item_master_force_2 = item_master_force
item_master_force_3 = item_master_force
item_master_force_4 = item_master_force
item_master_force_5 = item_master_force

modifier_master_force_passive = class({})

function modifier_master_force_passive:IsHidden()
	return true
end

if IsServer() then
	function modifier_master_force_passive:OnCreated( kv )
		self.cp_interval = 1/30
		self:StartIntervalThink(self.cp_interval)
	end

	function modifier_master_force_passive:OnIntervalThink()
		local cp_per_second = getMasterQuartzSpecialValue(self:GetParent(), "heated_mind_cp_regen", self:GetAbility())
		modifyCP(self:GetParent(), cp_per_second * self.cp_interval)
	end

	function modifier_master_force_passive:DeclareFunctions()
		return {MODIFIER_EVENT_ON_TAKEDAMAGE,
				MODIFIER_EVENT_ON_HERO_KILLED}
	end

	function modifier_master_force_passive:OnTakeDamage(params)
		if params.unit == self:GetParent() then
			if self:GetParent():GetHealthPercent() <= LOW_HP_THRESHOLD_PERCENT and self.fighting_spirit_available then
				self.fighting_spirit_available = false
				modifyCP(self:GetParent(), getMasterQuartzSpecialValue(self:GetParent(), "fighting_spirit_cp"))
			end
		end
	end

	function modifier_master_force_passive:OnHeroKilled(params)
		if params.attacker == self:GetParent() then
			modifyCP(self:GetParent(), getMasterQuartzSpecialValue(self:GetParent(), "thrill_of_battle_cp") * 2)
		end
	end
end

function modifier_master_force_passive:RoundStarted(args)
	if self:GetAbility():GetSpecialValueFor("fighting_spirit_cp") > 0 then
		self.fighting_spirit_available = true
	end
end

function modifier_master_force_passive:UnitUnbalanced(args)
	local caster = self:GetParent()
	local target = args.unit
	local distance = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()
	if target:GetTeamNumber() ~= caster:GetTeamNumber() and distance <= self:GetAbility():GetSpecialValueFor("thrill_of_battle_range") then
		modifyCP(caster, getMasterQuartzSpecialValue(caster, "thrill_of_battle_cp"))
	end
end

function modifier_master_force_passive:GetCoverDamageReduction()
	return getMasterQuartzSpecialValue(self:GetParent(), "cover_damage_reduction") / 100
end

function modifier_master_force_passive:CreateCoverParticles(damage_origin)
	local caster = self:GetParent()
	local ally = caster.combat_linked_to
	local arc_particle = ParticleManager:CreateParticle("particles/master_quartz/force/cover_shield_arc.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(arc_particle, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControlForward(arc_particle, 0, (damage_origin - caster:GetAbsOrigin()):Normalized())
	local ally_particle = ParticleManager:CreateParticle("particles/master_quartz/force/cover_shield_sphere.vpcf", PATTACH_POINT_FOLLOW, ally)
end


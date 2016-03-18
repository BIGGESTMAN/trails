require "game_functions"
require "arts/water/thelas"
require "arts/space/seraphic_ring"
require "round_manager"

LinkLuaModifier("modifier_master_angel_passive", "master_quartz/angel.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_angel_guardian_reviving", "master_quartz/angel.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_angel_belief_healing", "master_quartz/angel.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_angel_quick_thelas_heal_increase", "master_quartz/angel.lua", LUA_MODIFIER_MOTION_NONE)
item_master_angel = class({})
item_master_angel.OnSpellStart = item_thelas.OnSpellStart
item_master_angel.OnAbilityPhaseStart = item_thelas.OnAbilityPhaseStart
item_master_angel.OnAbilityPhaseInterrupted = item_thelas.OnAbilityPhaseInterrupted
item_master_angel.GetCastAnimation = item_thelas.GetCastAnimation

function item_master_angel:GetIntrinsicModifierName()
	return "modifier_master_angel_passive"
end

item_master_angel_1 = item_master_angel
item_master_angel_2 = item_master_angel
item_master_angel_3 = item_master_angel
item_master_angel_4 = item_master_angel
item_master_angel_5 = copyOfTable(item_master_angel)

item_master_angel_5.OnSpellStart = item_seraphic_ring.OnSpellStart
item_master_angel_5.OnAbilityPhaseStart = item_seraphic_ring.OnAbilityPhaseStart
item_master_angel_5.OnAbilityPhaseInterrupted = item_seraphic_ring.OnAbilityPhaseInterrupted
item_master_angel_5.GetCastAnimation = item_seraphic_ring.GetCastAnimation

modifier_master_angel_passive = class({})

function modifier_master_angel_passive:IsHidden()
	return true
end

-- function modifier_master_angel_passive:OnFatalDamage(args)
-- 	if self.guardian_revive_available and self:GetParent().combat_linked_to then
-- 		self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_angel_guardian_reviving", {duration = self:GetAbility():GetSpecialValueFor("guardian_duration")})
-- 		self.guardian_revive_available = false
-- 		return false
-- 	else
-- 		return true
-- 	end
-- end

function modifier_master_angel_passive:DeclareFunctions()
	return {MODIFIER_EVENT_ON_DEATH,
			MODIFIER_EVENT_ON_SPENT_MANA }
end

function modifier_master_angel_passive:OnDeath(params)
	local hero = self:GetParent()
	if params.unit == hero and self.guardian_revive_available and hero.combat_linked_to then
		hero.reviving = true
		self.guardian_revive_available = false
		hero.guardian_healing_percent = getMasterQuartzSpecialValue(hero, "guardian_hp_and_mana_percent") / 100
		Timers:CreateTimer(1/30, function()
			if RoundManager.round_started then
				reviveHero(hero, 1)
				hero.reviving = nil
				hero:AddNewModifier(hero, self:GetAbility(), "modifier_angel_guardian_reviving", {duration = self:GetAbility():GetSpecialValueFor("guardian_duration")})
			end
		end)
	end

	if params.unit == hero.combat_linked_to and self.quick_thelas_available then
		self.quick_thelas_available = false
		hero.combat_linked_to.reviving = true
		local linked_hero = hero.combat_linked_to
		local health = getMasterQuartzSpecialValue(hero, "quick_thelas_health") / 100 * hero.combat_linked_to:GetMaxHealth()
		Timers:CreateTimer(1/30, function()
			if RoundManager.round_started then
				reviveHero(linked_hero, health)
				hero.reviving = nil
				hero:AddNewModifier(hero, self:GetAbility(), "modifier_angel_quick_thelas_heal_increase", {duration = self:GetAbility():GetSpecialValueFor("quick_thelas_healing_increase_duration")})
			end
		end)
	end
end

function modifier_master_angel_passive:RoundStarted(args)
	self.guardian_revive_available = true
	if self:GetAbility():GetSpecialValueFor("quick_thelas_health") > 0 then
		self.quick_thelas_available = true
	end
end

function modifier_master_angel_passive:EnhancedCraftUsed(args)
	local hero = self:GetParent()
	if args.unit == hero.combat_linked_to and getMasterQuartzSpecialValue(hero, "cheer_missing_health_percent") > 0 then
		local healing_percent = getMasterQuartzSpecialValue(hero, "cheer_missing_health_percent") / 100
		hero.combat_linked_to:Heal(healing_percent * hero.combat_linked_to:GetHealthDeficit(), hero)
		local particle = ParticleManager:CreateParticle("particles/master_quartz/angel/cheer_heal.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControlEnt(particle, 0, hero, PATTACH_POINT_FOLLOW, "attach_hitloc", hero:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(particle, 1, hero.combat_linked_to, PATTACH_POINT_FOLLOW, "attach_hitloc", hero.combat_linked_to:GetAbsOrigin(), true)
	end
end

function modifier_master_angel_passive:OnSpentMana(params)
	local hero = self:GetParent()
	if params.unit == hero and hero.combat_linked_to and params.cost > 0 then
		local ep_spent = params.cost
		local healing = ep_spent * getMasterQuartzSpecialValue(hero, "belief_healing_per_ep")
		for k,unit in pairs({hero, hero.combat_linked_to}) do
			if not unit.belief_healing then unit.belief_healing = 0 end
			unit.belief_healing = unit.belief_healing + healing
			unit:AddNewModifier(hero, self:GetAbility(), "modifier_angel_belief_healing", {duration = self:GetAbility():GetSpecialValueFor("belief_duration"), healing = healing})
		end
	end
end

function modifier_master_angel_passive:GetArtDelayMultiplier(element)
	if element == ELEMENT_SPACE then
		return 1 - getMasterQuartzSpecialValue(self:GetParent(), "space_mastery_delay_reduction") / 100
	else
		return 1
	end
end

modifier_angel_guardian_reviving = class({})

function modifier_angel_guardian_reviving:GetTexture()
	return "item_master_angel"
end

function modifier_angel_guardian_reviving:DeclareFunctions()
	return { MODIFIER_PROPERTY_OVERRIDE_ANIMATION }
end
 
function modifier_angel_guardian_reviving:GetOverrideAnimation( params )
	return ACT_DOTA_DISABLED
end

if IsServer() then
	function modifier_angel_guardian_reviving:OnCreated( kv )
		self.healing_interval = 1/30
		self.total_healing = self:GetParent().guardian_healing_percent * self:GetParent():GetMaxHealth()
		self.total_mana_restoration = self:GetParent().guardian_healing_percent * self:GetParent():GetMaxMana()
		self:GetParent().guardian_healing_percent = nil
		self:StartIntervalThink(self.healing_interval)
	end

	function modifier_angel_guardian_reviving:OnIntervalThink()
		local hero = self:GetParent()

		hero:Heal(self.total_healing * self.healing_interval / self:GetAbility():GetSpecialValueFor("guardian_duration"), self:GetCaster())
		hero:GiveMana(self.total_mana_restoration * self.healing_interval / self:GetAbility():GetSpecialValueFor("guardian_duration"))
	end
end

function modifier_angel_guardian_reviving:CheckState()
	local state = {
	[MODIFIER_STATE_STUNNED] = true,
	[MODIFIER_STATE_INVULNERABLE] = true,
	}

	return state
end

function modifier_angel_guardian_reviving:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

modifier_angel_belief_healing = class({})

function modifier_angel_belief_healing:GetTexture()
	return "item_master_angel"
end

function modifier_angel_belief_healing:DeclareFunctions()
	return { MODIFIER_EVENT_ON_TAKEDAMAGE }
end

if IsServer() then
	function modifier_angel_belief_healing:OnCreated( kv )
		self.healing_interval = 0.5
		self.total_healing = kv.healing
		self:StartIntervalThink(self.healing_interval)
	end

	function modifier_angel_belief_healing:OnIntervalThink()
		local hero = self:GetParent()

		hero:Heal(self.total_healing * self.healing_interval / self:GetAbility():GetSpecialValueFor("belief_duration"), self:GetCaster())
	end
end

function modifier_angel_belief_healing:GetAttributes()
	return MODIFER_ATTRIBUTE_MULTIPLE
end

function modifier_angel_belief_healing:GetEffectName()
	return "particles/master_quartz/angel/belief_heal.vpcf"
end

function modifier_angel_belief_healing:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_angel_belief_healing:OnTakeDamage(params)
	if params.unit == self:GetParent() then
		self:Destroy()
	end
end


modifier_angel_quick_thelas_heal_increase = class({})

function modifier_angel_quick_thelas_heal_increase:GetTexture()
	return "item_master_angel"
end

function modifier_angel_quick_thelas_heal_increase:DeclareFunctions()
	return { MODIFIER_EVENT_ON_HEAL_RECEIVED  }
end

function modifier_angel_quick_thelas_heal_increase:OnHealReceived(params)
	if params.unit == self:GetParent() then
		for k,v in pairs(params) do
			print(k,v)
		end
	end
end
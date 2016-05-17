require "game_functions"
require "master_quartz"

LinkLuaModifier("modifier_master_vermillion_passive", "master_quartz/vermillion.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_master_vermillion_combination_ready", "master_quartz/vermillion.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_master_vermillion_combination_mark", "master_quartz/vermillion.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_master_vermillion_combination_cooldown", "master_quartz/vermillion.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_master_vermillion_fiery_bond_ready", "master_quartz/vermillion.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_master_vermillion_fiery_bond_cooldown", "master_quartz/vermillion.lua", LUA_MODIFIER_MOTION_NONE)
item_master_vermillion = class({})
item_master_vermillion.OnSpellStart = MasterQuartz.OnSpellStart
item_master_vermillion.CastFilterResultTarget = MasterQuartz.CastFilterResultTarget
item_master_vermillion.GetCustomCastErrorTarget = MasterQuartz.GetCustomCastErrorTarget

function item_master_vermillion:GetIntrinsicModifierName()
	return "modifier_master_vermillion_passive"
end

item_master_vermillion_1 = item_master_vermillion
item_master_vermillion_2 = item_master_vermillion
item_master_vermillion_3 = item_master_vermillion
item_master_vermillion_4 = item_master_vermillion
item_master_vermillion_5 = item_master_vermillion

modifier_master_vermillion_passive = class({})

function modifier_master_vermillion_passive:IsHidden()
	return true
end

if IsServer() then
-- 	function modifier_master_vermillion_passive:DeclareFunctions()
-- 		return {MODIFIER_EVENT_ON_TAKEDAMAGE,
-- 				MODIFIER_EVENT_ON_HERO_KILLED}
-- 	end

-- 	function modifier_master_vermillion_passive:OnTakeDamage(params)
-- 		local ability = self:GetAbility()
-- 		local hero = self:GetParent()
-- 		if params.unit == hero then
-- 			self.vanguard_time_accumulated = 0

-- 			if hero:GetHealthPercent() <= LOW_HP_THRESHOLD_PERCENT and self.last_bastion_available then
-- 				self.last_bastion_available = false
-- 				hero:AddNewModifier(hero, ability, "modifier_vermillion_last_bastion", {duration = getMasterQuartzSpecialValue(hero, "last_bastion_duration")})
-- 			end
-- 		end
-- 		if params.unit == hero.combat_linked_to and self.counterattack_damage_taken and distanceBetween(hero:GetAbsOrigin(), params.attacker:GetAbsOrigin()) <= ability:GetSpecialValueFor("counterattack_range") then
-- 			self.counterattack_damage_taken = self.counterattack_damage_taken + params.damage
-- 			if self.counterattack_damage_taken >= ability:GetSpecialValueFor("counterattack_damage_threshold_percent") / 100 * params.unit:GetMaxHealth() then
-- 				self.counterattack_damage_taken = 0
-- 				if IsValidAlive(params.attacker) then
-- 					params.attacker:AddNewModifier(hero, ability, "modifier_vermillion_counterattack", {duration = ability:GetSpecialValueFor("counterattack_damage_bonus_duration")})
-- 				end
-- 				reduceDelay(hero, getMasterQuartzSpecialValue(self:GetParent(), "counterattack_delay_reduction"))
-- 			end
-- 		end
-- 	end

-- 	function modifier_master_vermillion_passive:OnHeroKilled(params)
-- 		if params.unit == self:GetParent().combat_linked_to then
-- 			if IsValidAlive(params.attacker) then
-- 				params.attacker:AddNewModifier(self:GetParent(), ability, "modifier_vermillion_counterattack", {})
-- 			end
-- 			removeDelay(self:GetParent())
-- 		end
-- 	end
end

function modifier_master_vermillion_passive:GetSophisticatedFightDamageMultiplier()
	local hero = self:GetParent()
	local max_damage_increase = self:GetAbility():GetSpecialValueFor("sophisticated_fight_max_damage_increase")
	local health_percent = hero:GetHealth() / hero:GetMaxHealth()
	return 1 + health_percent * max_damage_increase / 100
end

function modifier_master_vermillion_passive:GetCoverDamageReduction()
	return self:GetAbility():GetSpecialValueFor("cover_damage_reduction") / 100
end

function modifier_master_vermillion_passive:CreateCoverParticles(damage_origin)
	local caster = self:GetParent()
	local ally = caster.combat_linked_to
	local arc_particle = ParticleManager:CreateParticle("particles/master_quartz/force/cover_shield_arc.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(arc_particle, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControlForward(arc_particle, 0, (damage_origin - caster:GetAbsOrigin()):Normalized())
	local ally_particle = ParticleManager:CreateParticle("particles/master_quartz/force/cover_shield_sphere.vpcf", PATTACH_POINT_FOLLOW, ally)
end

function modifier_master_vermillion_passive:EncounterStarted(args)
	if self:GetAbility():GetSpecialValueFor("combination_cooldown") > 0 then
		self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_master_vermillion_combination_ready", {})
	end
end

function modifier_master_vermillion_passive:LinkFormed()
	if self:GetAbility():GetSpecialValueFor("fiery_bond_cooldown") > 0 then
		self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_master_vermillion_fiery_bond_ready", {})
	end
end

function modifier_master_vermillion_passive:LinkBroken()
	self:GetCaster():RemoveModifierByName("modifier_master_vermillion_fiery_bond_ready")
end

function modifier_master_vermillion_passive:ApplyCombinationMark(target)
	target:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_master_vermillion_combination_mark", {duration = self:GetAbility():GetSpecialValueFor("combination_mark_duration")})
	self:GetCaster():RemoveModifierByName("modifier_master_vermillion_combination_ready")
end

function modifier_master_vermillion_passive:CPConditionAchieved()
	applyHealing(self:GetParent(), self:GetParent(), self:GetAbility():GetSpecialValueFor("invigorate_healing"))
end

modifier_master_vermillion_combination_ready = class({})

if IsServer() then
	function modifier_master_vermillion_combination_ready:OnDestroy()
		local hero = self:GetCaster()
		hero:AddNewModifier(hero, self:GetAbility(), "modifier_master_vermillion_combination_cooldown", {duration = self:GetAbility():GetSpecialValueFor("combination_cooldown")})
	end
end

modifier_master_vermillion_combination_mark = class({})

function modifier_master_vermillion_combination_mark:IsDebuff()
	return true
end

function modifier_master_vermillion_combination_mark:TriggerMark(attacker)
	local ability = self:GetAbility()
	local target = self:GetParent()
	if attacker == self:GetCaster().combat_linked_to then
		self:Destroy(false)
		local damage_scale = ability:GetSpecialValueFor("combination_physical_damage_percent") / 100
		applyEffect(target, DAMAGE_TYPE_PHYSICAL, function()
			dealScalingDamage(target, attacker, DAMAGE_TYPE_PHYSICAL, damage_scale, ability)
		end)
		if IsValidAlive(target) then
			target:AddNewModifier(attacker, ability, "modifier_master_vermillion_combination_mark", {duration = ability:GetSpecialValueFor("combination_mark_duration")})
		end
	end
end

function modifier_master_vermillion_combination_mark:GetEffectName()
	return "particles/master_quartz/vermillion/combination_mark.vpcf"
end

function modifier_master_vermillion_combination_mark:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

modifier_master_vermillion_combination_cooldown = class({})

function modifier_master_vermillion_combination_cooldown:IsHidden()
	return true
end

if IsServer() then
	function modifier_master_vermillion_combination_cooldown:OnDestroy()
		local hero = self:GetCaster()
		if hero.combat_linked_to then
			hero:AddNewModifier(hero, self:GetAbility(), "modifier_master_vermillion_combination_ready", {})
		end
	end
end

modifier_master_vermillion_fiery_bond_ready = class({})

if IsServer() then
	function modifier_master_vermillion_fiery_bond_ready:OnCreated()
		changeLinkParticle(self:GetParent(), "particles/master_quartz/vermillion/fiery_bond_link.vpcf")
		self:StartIntervalThink(1/30)
	end

	function modifier_master_vermillion_fiery_bond_ready:OnIntervalThink()
		local ability = self:GetAbility()
		local caster = self:GetParent()

		local radius = ability:GetSpecialValueFor("fiery_bond_radius")
		local origin = caster:GetAbsOrigin()
		local direction = (caster.combat_linked_to:GetAbsOrigin() - origin):Normalized()
		local end_point = caster.combat_linked_to:GetAbsOrigin()
		local team = caster:GetTeamNumber()
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
		local iOrder = FIND_ANY_ORDER
		local targets = FindUnitsInLine(team, origin, end_point, nil, radius, iTeam, iType, iOrder)
		for k,unit in pairs(targets) do
			if pointIsBetweenPoints(unit:GetAbsOrigin(), origin, caster.combat_linked_to:GetAbsOrigin()) then
				unit:AddNewModifier(caster, ability, "modifier_sear", {duration = ability:GetSpecialValueFor("fiery_bond_duration")})
				self:Destroy(false)
				break
			end
		end
	end

	function modifier_master_vermillion_fiery_bond_ready:OnDestroy()
		local hero = self:GetCaster()
		hero:AddNewModifier(hero, self:GetAbility(), "modifier_master_vermillion_fiery_bond_cooldown", {duration = self:GetAbility():GetSpecialValueFor("fiery_bond_cooldown")})
		changeLinkParticle(hero, "particles/combat_links/link.vpcf")
	end
end

modifier_master_vermillion_fiery_bond_cooldown = class({})

function modifier_master_vermillion_fiery_bond_cooldown:IsHidden()
	return true
end

if IsServer() then
	function modifier_master_vermillion_fiery_bond_cooldown:OnDestroy()
		local hero = self:GetCaster()
		hero:AddNewModifier(hero, self:GetAbility(), "modifier_master_vermillion_fiery_bond_ready", {})
	end
end

-- function modifier_master_vermillion_passive:GuardTriggered(args)
-- 	local ability = self:GetAbility()
-- 	modifyStat(self:GetParent(), STAT_STR, getMasterQuartzSpecialValue(self:GetParent(), "vanguard_stat_increase"), ability:GetSpecialValueFor("vanguard_stat_increase_duration"))
-- 	modifyStat(self:GetParent(), STAT_MOV, getMasterQuartzSpecialValue(self:GetParent(), "vanguard_stat_increase"), ability:GetSpecialValueFor("vanguard_stat_increase_duration"))
-- end

-- function modifier_master_vermillion_passive:UnitUnbalanced(args)
-- 	local hero = self:GetParent()
-- 	local target = args.unit
-- 	if target == hero.combat_linked_to then
-- 		modifyCP(hero, getMasterQuartzSpecialValue(hero, "lively_yell_cp"))
-- 		modifyCP(hero.combat_linked_to, getMasterQuartzSpecialValue(hero, "lively_yell_cp"))
-- 	end
-- end

-- function modifier_master_vermillion_passive:GetArtDelayMultiplier(element)
-- 	if element == ELEMENT_EARTH then
-- 		return 1 - getMasterQuartzSpecialValue(self:GetParent(), "earth_mastery_delay_reduction") / 100
-- 	else
-- 		return 1
-- 	end
-- end

-- modifier_vermillion_counterattack = class({})

-- function modifier_vermillion_counterattack:GetTexture()
-- 	return "alpha_wolf_critical_strike"
-- end

-- function modifier_vermillion_counterattack:IsDebuff()
-- 	return true
-- end

-- function modifier_vermillion_counterattack:GetEffectName()
-- 	return "particles/units/heroes/hero_rubick/rubick_fade_bolt_debuff.vpcf"
-- end

-- function modifier_vermillion_counterattack:GetEffectAttachType()
-- 	return PATTACH_ABSORIGIN_FOLLOW
-- end

-- modifier_vermillion_last_bastion = class({})

-- function modifier_vermillion_last_bastion:GetTexture()
-- 	return "master_vermillion"
-- end

-- function modifier_vermillion_last_bastion:GetEffectName()
-- 	return "particles/master_quartz/vermillion/last_bastion_shield.vpcf"
-- end

-- function modifier_vermillion_last_bastion:GetEffectAttachType()
-- 	return PATTACH_ABSORIGIN_FOLLOW
-- end
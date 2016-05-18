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

function item_master_vermillion:GetNetTableInfo()
	return {name = self:GetAbilityName():sub(0, self:GetAbilityName():len() - 2), abilities = {
											{unlocked = self:GetLevel() >= 1, name = "Sophisticated Fight", description = "Increases your physical damage based on how full your health is.", icon = "vermillion_sophisticated_fight", ability_specials = {"sophisticated_fight_max_damage_increase"}},
											{unlocked = self:GetLevel() >= 2, name = "Cover", description = "Reduces the damage your link partner takes and deals half of the damage reduced to you. Must be in between damage source and link partner.", icon = "spectre_dispersion", ability_specials = {"cover_damage_reduction"}},
											{unlocked = self:GetLevel() >= 3, name = "Combination", description = "Your damaging crafts place a Combination mark on enemies hit for 3 seconds. Combination marks can only be triggered by the link partner of the hero who placed them. When triggered by craft damage, the partner inflicts bonus physical damage and places a new Combination mark. Has a cooldown.", icon = "troll_warlord_fervor", ability_specials = {"combination_physical_damage_percent", "combination_cooldown"}},
											{unlocked = self:GetLevel() >= 4, name = "Invigorate", description = "You heal whenever you achieve a CP Condition.", icon = "huskar_inner_vitality", ability_specials = {"invigorate_healing"}},
											{unlocked = self:GetLevel() >= 5, name = "Fiery Bonds", description = "Your link Sears the first enemy it touches for 2 seconds. Has a cooldown.", icon = "phoenix_sun_ray", ability_specials = {"fiery_bond_cooldown"}},
													}}
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

function modifier_master_vermillion_passive:CPConditionAchieved(args)
	if args.recipient == self:GetParent() then
		applyHealing(self:GetParent(), self:GetParent(), self:GetAbility():GetSpecialValueFor("invigorate_healing"))
	end
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
		self:Destroy()
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
				self:Destroy()
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
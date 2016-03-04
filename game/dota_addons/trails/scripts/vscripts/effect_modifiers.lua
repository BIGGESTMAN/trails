require "game_functions"

modifier_burn = class({})

if IsServer() then
	function modifier_burn:OnCreated( kv )
		local ability = self:GetAbility()

		self.damage_interval = 0.5
		self:StartIntervalThink(self.damage_interval)
	end

	function modifier_burn:OnIntervalThink()
		local caster = self:GetCaster()
		local target = self:GetParent()

		local damage_percent = 3
		local damage = target:GetMaxHealth() * damage_percent * self.damage_interval / 100
		local damage_type = DAMAGE_TYPE_PURE
		dealDamage(target, caster, damage, damage_type, self:GetAbility(), 0)
	end
end

function modifier_burn:GetEffectName()
	return "particles/units/heroes/hero_phoenix/phoenix_icarus_dive_burn_debuff.vpcf"
end

function modifier_burn:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_burn:GetTexture()
	return "ogre_magi_ignite"
end

function modifier_burn:IsDebuff()
	return true
end

modifier_insight = class({})

if IsServer() then
	function modifier_insight:OnCreated( kv )
		self.evasion_active = true
		self.evasion_cooldown_time = 1
	end

	function modifier_insight:StartEvasionCooldown()
		self.evasion_active = false
		self:StartIntervalThink(self.evasion_cooldown_time)
	end

	function modifier_insight:OnIntervalThink()
		self.evasion_active = true
		self:StartIntervalThink(-1)
	end
end

function modifier_insight:GetEffectName()
	return "particles/units/heroes/hero_omniknight/omniknight_repel_buff_b.vpcf"
end

function modifier_insight:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_insight:GetTexture()
	return "windrunner_windrun"
end

modifier_passion = class({})

if IsServer() then
	function modifier_passion:OnCreated( kv )
		self.cp_interval = 1/30
		self.cp_per_second = kv.cp_per_second
		self.accrued_cp = 0
		self:StartIntervalThink(self.cp_interval)
	end

	function modifier_passion:OnIntervalThink()
		self.accrued_cp = self.accrued_cp + self.cp_per_second * self.cp_interval
		if self.accrued_cp >= 1 then
			modifyCP(self:GetParent(), math.floor(self.accrued_cp))
			self.accrued_cp = self.accrued_cp - math.floor(self.accrued_cp)
		end
	end
end

function modifier_passion:GetTexture()
	return "lina_light_strike_array"
end

modifier_freeze = class({})

if IsServer() then
	function modifier_freeze:OnCreated( kv )
		self:GetParent():Interrupt()
		self:GetParent():Stop()
	end

	function modifier_freeze:OnDestroy()
		local caster = self:GetCaster()
		local target = self:GetParent()

		local damage_percent = 10
		local damage = target:GetMaxHealth() * damage_percent / 100
		local damage_type = DAMAGE_TYPE_PURE
		dealDamage(target, caster, damage, damage_type, self:GetAbility(), 0)
	end
end

function modifier_freeze:GetEffectName()
	return "particles/units/heroes/hero_crystalmaiden/maiden_frostbite_buff.vpcf"
end

function modifier_freeze:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_freeze:GetTexture()
	return "crystal_maiden_frostbite"
end

function modifier_freeze:IsDebuff()
	return true
end

modifier_confuse = class({})

LinkLuaModifier("modifier_confuse_specially_deniable", "effect_modifiers.lua", LUA_MODIFIER_MOTION_NONE)
if IsServer() then
	function modifier_confuse:OnCreated( kv )
		self:GetParent():Interrupt()
		self:GetParent():Stop()

		self:StartIntervalThink(0.03)
	end

	function modifier_confuse:OnIntervalThink()
		local caster = self:GetCaster()
		local target = self:GetParent()
		local target_radius = 350
		local attack_target = nil

		local team = target:GetTeamNumber()
		local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_CLOSEST
		local ally_targets = FindUnitsInRadius(team, target:GetAbsOrigin(), nil, target_radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, iType, iFlag, iOrder, false)
		local enemy_targets = FindUnitsInRadius(team, target:GetAbsOrigin(), nil, target_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, iType, iFlag, iOrder, false)
		if #ally_targets > 1 then
			attack_target = ally_targets[2]
		elseif #enemy_targets > 0 then
			attack_target = enemy_targets[1]
		else
			target:Stop()
		end
		if attack_target then
			attack_target:AddNewModifier(target, nil, "modifier_confuse_specially_deniable", {duration = 0.06})
			local attack_order = 
			{
				UnitIndex = target:entindex(),
				OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET + 200,
				TargetIndex = attack_target:entindex()
			}
			ExecuteOrderFromTable(attack_order)
		end
		target:SetForceAttackTarget(attack_target)
	end

	function modifier_confuse:OnDestroy()
		self:GetParent():SetForceAttackTarget(nil)
		self:GetParent():Interrupt()
		self:GetParent():Stop()
	end
end

function modifier_confuse:GetEffectName()
	return "particles/units/heroes/hero_witchdoctor/witchdoctor_maledict_dot.vpcf"
end

function modifier_confuse:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_confuse:GetTexture()
	return "mud_golem_rock_destroy"
end

function modifier_confuse:IsDebuff()
	return true
end

modifier_confuse_specially_deniable = class({})

function modifier_confuse_specially_deniable:IsHidden()
	return true
end

function modifier_confuse_specially_deniable:CheckState()
	local state = {
	[MODIFIER_STATE_SPECIALLY_DENIABLE] = true,
	}

	return state
end

modifier_nightmare = class({})

if IsServer() then
	function modifier_nightmare:OnDestroy()
		local caster = self:GetCaster()
		local target = self:GetParent()
		local debuff_duration = 3

		applyRandomDebuff(target, caster, debuff_duration, true)
	end
end

function modifier_nightmare:CheckState()
	local state = {
	[MODIFIER_STATE_STUNNED] = true,
	[MODIFIER_STATE_LOW_ATTACK_PRIORITY] = true,
	}

	return state
end

function modifier_nightmare:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE}
end

function modifier_nightmare:OnTakeDamage(params)
	if params.unit == self:GetParent() then self:Destroy() end
end

function modifier_nightmare:GetEffectName()
	return "particles/units/heroes/hero_bane/bane_nightmare.vpcf"
end

function modifier_nightmare:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_nightmare:GetTexture()
	return "bane_nightmare"
end

function modifier_nightmare:IsDebuff()
	return true
end

modifier_petrify = class({})

if IsServer() then
	function modifier_petrify:OnTakeDamage(params)
		if params.unit == self:GetParent() then
			if damage_type == DAMAGE_TYPE_PHYSICAL then
				self:Destroy()

				local damage_percent = 20
				local damage = self:GetParent():GetHealthDeficit() * damage_percent / 100
				local damage_type = DAMAGE_TYPE_PURE
				dealDamage(self:GetParent(), caster, damage, damage_type, self:GetAbility(), 0)
			end
		end
	end
end

function modifier_petrify:CheckState()
	local state = {
	[MODIFIER_STATE_STUNNED] = true,
	[MODIFIER_STATE_FROZEN] = true,
	[MODIFIER_STATE_LOW_ATTACK_PRIORITY] = true,
	}

	return state
end

function modifier_petrify:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE}
end

function modifier_petrify:GetStatusEffectName()
	return "particles/status_fx/status_effect_medusa_stone_gaze.vpcf"
end

function modifier_petrify:HeroEffectPriority()
	return 10
end

function modifier_petrify:GetTexture()
	return "earthshaker_fissure_egset"
end

function modifier_petrify:IsDebuff()
	return true
end

modifier_deathblow = class({})

if IsServer() then
	function modifier_deathblow:OnCreated()
		local target = self:GetParent()

		self.kill_threshold = 15
		local health_percent = target:GetHealthPercent()
		if health_percent <= self.kill_threshold then
			target:Kill(self:GetAbility(), self:GetCaster())
		end
	end

	function modifier_deathblow:OnTakeDamage(params)
		local target = self:GetParent()

		if params.unit == target then
			local health_percent = target:GetHealthPercent()
			if health_percent <= self.kill_threshold then
				target:Kill(self:GetAbility(), self:GetCaster())
			end
		end
	end
end

function modifier_deathblow:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE}
end

function modifier_deathblow:GetEffectName()
	return "particles/units/heroes/hero_necrolyte/necrolyte_scythe_mist.vpcf"
end

function modifier_deathblow:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_deathblow:GetTexture()
	return "necrolyte_reapers_scythe"
end

function modifier_deathblow:IsDebuff()
	return true
end

modifier_cp_boost = class({})

function modifier_cp_boost:GetEffectName()
	return "particles/units/heroes/hero_earth_spirit/espirit_stoneremnant_gravity_grndglow.vpcf"
end

function modifier_cp_boost:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_cp_boost:GetTexture()
	return "earth_spirit_petrify"
end

modifier_crit = class({})

function modifier_crit:GetTexture()
	return "phantom_assassin_arcana_phantom_strike"
end

modifier_brute_force = class({})

function modifier_brute_force:GetTexture()
	return "tusk_walrus_punch"
end

modifier_link_broken = class({})

function modifier_link_broken:GetTexture()
	return "wisp_tether_break"
end

function modifier_link_broken:IsDebuff()
	return true
end
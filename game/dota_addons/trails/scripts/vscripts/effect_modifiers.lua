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
		local ability = self:GetAbility()
		local target = self:GetParent()

		local damage_percent = 3
		local damage = target:GetMaxHealth() * damage_percent * self.damage_interval / 100
		local damage_type = DAMAGE_TYPE_PURE
		dealDamage(target, caster, damage, damage_type, 0)
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

modifier_insight = class({})

if IsServer() then
	function modifier_insight:OnCreated( kv )
		local ability = self:GetAbility()

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
		local ability = self:GetAbility()


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
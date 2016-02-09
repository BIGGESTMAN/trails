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
		dealDamage(target, caster, damage, damage_type, ability)
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
require "game_functions"
require "arts"
require "projectile_list"

LinkLuaModifier("modifier_soul_blur_illusion", "arts/time/soul_blur.lua", LUA_MODIFIER_MOTION_NONE)
item_soul_blur = class({})

if IsServer() then
	function item_soul_blur:OnSpellStart()
		local caster = self:GetCaster()
		local ability = self
		local target = self:GetCursorTarget()

		local damage_type = DAMAGE_TYPE_MAGICAL
		local illusion_duration = 3
		local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100

		if caster:HasModifier("modifier_crit") then
			damage_scale = damage_scale * 2
			caster:RemoveModifierByName("modifier_crit")
		end

		applyArtsDelayCooldowns(caster, ability)

		applyEffect(target, damage_type, function()
			dealScalingDamage(target, caster, damage_type, damage_scale, ability)
			createSoulBlurIllusion(caster, ability, target, illusion_duration)
		end)

		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_terrorblade/terrorblade_reflection_cast.vpcf", PATTACH_POINT_FOLLOW, caster)
		ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)

		endCastParticle(caster)
	end

	function createSoulBlurIllusion(caster, ability, target, illusion_duration)
		local unit_name = target:GetUnitName()
		local origin = target:GetAbsOrigin()

		local illusion = CreateUnitByName(unit_name, origin, true, caster, nil, caster:GetTeamNumber())
		illusion:SetPlayerID(caster:GetPlayerID())

		illusion:AddNewModifier(caster, ability, "modifier_illusion", { duration = illusion_duration, outgoing_damage = 0, incoming_damage = 0 })
		illusion:MakeIllusion()
		illusion:AddNewModifier(caster, ability, "modifier_soul_blur_illusion", {})
		illusion.target = target
	end

	function item_soul_blur:OnAbilityPhaseStart()
		createCastParticle(self:GetCaster())
		return true
	end

	function item_soul_blur:OnAbilityPhaseInterrupted()
		endCastParticle(self:GetCaster())
	end
end

modifier_soul_blur_illusion = class({})

function modifier_soul_blur_illusion:CheckState()
	local state = {
	[MODIFIER_STATE_INVULNERABLE] = true,
	[MODIFIER_STATE_STUNNED] = true,
	[MODIFIER_STATE_UNSELECTABLE] = true,
	[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
	[MODIFIER_STATE_NO_HEALTH_BAR] = true,
	[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}

	return state
end

function modifier_soul_blur_illusion:GetStatusEffectName()
	return "particles/status_fx/status_effect_terrorblade_reflection.vpcf"
end

function modifier_soul_blur_illusion:HeroEffectPriority()
	return 100
end

if IsServer() then
	function modifier_soul_blur_illusion:OnCreated( kv )
		self:StartIntervalThink(1/30)
	end

	function modifier_soul_blur_illusion:OnIntervalThink()
		local caster = self:GetCaster()
		local target = self:GetParent()
		local ability = self:GetAbility()
		local faint_range = ability:GetSpecialValueFor("faint_range")
		local faint_duration = ability:GetSpecialValueFor("faint_duration")

		local distance = (target.target:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()
		if distance > faint_range then
			target.target:AddNewModifier(caster, ability, "modifier_faint", {duration = faint_duration})
			target:RemoveSelf()
		end
	end
end
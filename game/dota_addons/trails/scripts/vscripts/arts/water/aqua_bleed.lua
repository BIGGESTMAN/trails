require "game_functions"
require "arts"
require "libraries/util"

LinkLuaModifier("modifier_aqua_bleed_knockback", "arts/water/aqua_bleed.lua", LUA_MODIFIER_MOTION_NONE)
item_aqua_bleed = class({})

if IsServer() then
	function item_aqua_bleed:OnSpellStart()
		local caster = self:GetCaster()
		local ability = self
		local target = self:GetCursorTarget()

		local damage_interval = 0.2
		local radius = 125
		local total_duration = ability:GetChannelTime()
		local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100 * damage_interval / total_duration

		if caster:HasModifier("modifier_crit") then
			damage_scale = damage_scale * 2
			caster:RemoveModifierByName("modifier_crit")
		end

		caster.casting_aqua_bleed = true
		caster.aqua_bleed_particle = ParticleManager:CreateParticle("particles/arts/water/aqua_bleed/stream.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControlEnt(caster.aqua_bleed_particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(caster.aqua_bleed_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)

		Timers:CreateTimer(0, function()
			if caster.casting_aqua_bleed and target then
				local direction = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
				direction.z = 0
				caster:SetForwardVector(direction)

				local unit_hit = findFirstUnitInLine(caster, caster:GetAbsOrigin(), target:GetAbsOrigin(), radius)
				if unit_hit then
					aquaBleedHit(caster, ability, unit_hit, damage_scale, direction)
				end
				return damage_interval
			end
		end)

		applyArtsDelayCooldowns(caster, ability)

		endCastParticle(caster)
	end

	function aquaBleedHit(caster, ability, target, damage_scale, knockback_direction)
		local knockback_duration = 0.1
		local knockback_distance = 90
		local damage_type = DAMAGE_TYPE_MAGICAL

		applyEffect(target, damage_type, function()
			dealScalingDamage(target, caster, damage_type, damage_scale, ability)
			target:AddNewModifier(caster, ability, "modifier_aqua_bleed_knockback", {duration = knockback_duration})
			dash(target, knockback_direction, knockback_distance / knockback_duration, knockback_distance, true)
		end)
	end

	function item_aqua_bleed:OnChannelFinish( bInterrupted )
		local caster = self:GetCaster()
		caster.casting_aqua_bleed = false
		ParticleManager:DestroyParticle(caster.aqua_bleed_particle, false)
		caster.aqua_bleed_particle = nil
	end

	function item_aqua_bleed:OnAbilityPhaseStart()
		createCastParticle(self:GetCaster())
		return true
	end

	function item_aqua_bleed:OnAbilityPhaseInterrupted()
		endCastParticle(self:GetCaster())
	end
end

modifier_aqua_bleed_knockback = class({})

function modifier_aqua_bleed_knockback:CheckState()
	local state = {
	[MODIFIER_STATE_STUNNED] = true,
	}

	return state
end

function modifier_aqua_bleed_knockback:DeclareFunctions()
	return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION}
end

function modifier_aqua_bleed_knockback:GetOverrideAnimation(params)
	return ACT_DOTA_FLAIL
end

function modifier_aqua_bleed_knockback:GetTexture()
	return "quartz_water_1"
end

function modifier_aqua_bleed_knockback:IsDebuff()
	return true
end
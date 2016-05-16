require "projectile_list"
require "combat_links"
require "game_functions"

LinkLuaModifier("modifier_flamberge_heated", "abilities/crafts/alisa/flamberge.lua", LUA_MODIFIER_MOTION_NONE)
flamberge = class({})

if IsServer() then
	function flamberge:OnSpellStart()
		local caster = self:GetCaster()
		local ability = self
		local target_point = self:GetCursorPosition()
		local target = self:GetCursorTarget()
		local direction = (target_point - caster:GetAbsOrigin()):Normalized()
		caster.flamberge_direction = direction

		spendCP(caster, ability)
		applyDelayCooldowns(caster, ability)
	end

	function flamberge:OnChannelFinish( bInterrupted )
		local caster = self:GetCaster()
		local ability = self
		local target = self:GetCursorTarget()

		local radius = ability:GetSpecialValueFor("radius")
		local range = ability:GetSpecialValueFor("range")
		local travel_speed = ability:GetSpecialValueFor("travel_speed")
		local burn_duration = ability:GetSpecialValueFor("burn_duration")

		local channel_time_percent = (GameRules:GetGameTime() - ability:GetChannelStartTime()) / ability:GetChannelTime()
		local heat_air = channel_time_percent >= 1

		local crit = false
		if caster:HasModifier("modifier_crit") then
			crit = true
			caster:RemoveModifierByName("modifier_crit")
		end

		collisionRules = {
			team = caster:GetTeamNumber(),
			radius = radius,
			iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL,
			iFlag = DOTA_UNIT_TARGET_FLAG_NONE,
			iOrder = FIND_ANY_ORDER
		}
		local origin_location = caster:GetAbsOrigin()

		ProjectileList:CreateLinearProjectile(caster, origin_location, caster.flamberge_direction, travel_speed, range, nil, collisionRules, flambergeHit, "particles/crafts/alisa/flamberge/flamberge.vpcf", {crit = crit, destroy_on_collision = true, heat_air = heat_air})
		caster.flamberge_direction = nil
	end
end

function flamberge:GetBehavior()
	return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_CHANNELLED
end

function flamberge:GetChannelTime()
	return self:GetSpecialValueFor("normal_channel_time")
end

function flamberge:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_2
end

function flamberge:GetPlaybackRateOverride()
	return 1.4 / self:GetChannelTime()
end

function flambergeHit(caster, unit, args)
	local ability = caster:FindAbilityByName("flamberge")
	local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100
	local damage_type = ability:GetAbilityDamageType()
	local mark_duration = ability:GetSpecialValueFor("mark_duration")

	if args.crit then damage_scale = damage_scale * 2 end

	applyEffect(unit, damage_type, function()
		dealScalingDamage(unit, caster, damage_type, damage_scale, ability, CRAFT_CP_GAIN_FACTOR)
		if args.heat_air then
			unit:AddNewModifier(caster, ability, "modifier_flamberge_heated", {duration = mark_duration})
		end
		applyImpede(unit, caster)
	end)
end

function flamberge:DealIgniteDamage(unit)
	local caster = self:GetCaster()
	local ability = self
	local damage_scale = ability:GetSpecialValueFor("mark_trigger_damage_percent") / 100
	local damage_type = ability:GetAbilityDamageType()

	applyEffect(unit, damage_type, function()
		dealScalingDamage(unit, caster, damage_type, damage_scale, ability, CRAFT_CP_GAIN_FACTOR)
	end)

	local particle = ParticleManager:CreateParticle("particles/crafts/alisa/flamberge/heated_ignite.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
end

modifier_flamberge_heated = class({})

function modifier_flamberge_heated:GetEffectName()
	return "particles/crafts/alisa/flamberge/heated_status.vpcf"
end

function modifier_flamberge_heated:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

-- function modifier_flamberge_heated:GetTexture()
-- 	return "silencer_last_word"
-- end

function modifier_flamberge_heated:IsDebuff()
	return true
end

function modifier_flamberge_heated:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE}
end

if IsServer() then
	function modifier_flamberge_heated:OnCreated()
		self.hp_to_trigger = self:GetParent():GetMaxHealth() * self:GetAbility():GetSpecialValueFor("mark_trigger_health_threshold") / 100
	end

	function modifier_flamberge_heated:OnTakeDamage(params)
		if params.unit == self:GetParent() then
			self.hp_to_trigger = self.hp_to_trigger - params.damage
			if self.hp_to_trigger <= 0 then
				local ability = self:GetAbility()
				local unit = self:GetParent()
				self:Destroy()
				ability:DealIgniteDamage(unit)
			end
		end
	end
end
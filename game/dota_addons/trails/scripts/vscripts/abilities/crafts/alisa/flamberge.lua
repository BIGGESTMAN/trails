require "projectile_list"
require "combat_links"
require "game_functions"

LinkLuaModifier("modifier_flamberge_channeling", "crafts/alisa/flamberge.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_flamberge_mute", "crafts/alisa/flamberge.lua", LUA_MODIFIER_MOTION_NONE)
flamberge = class({})

if IsServer() then
	function flamberge:OnSpellStart()
		local caster = self:GetCaster()
		local ability = self
		local target_point = self:GetCursorPosition()
		local target = self:GetCursorTarget()
		local direction = (target_point - caster:GetAbsOrigin()):Normalized()
		caster.flamberge_direction = direction

		if validEnhancedCraft(caster, target, true) then
			caster.flamberge_target = target
			caster:AddNewModifier(caster, ability, "modifier_flamberge_channeling", {})
		end

		spendCP(caster, ability)
		applyDelayCooldowns(caster, ability)
	end

	function flamberge:OnChannelFinish( bInterrupted )
		local caster = self:GetCaster()
		local ability = self
		local target = self:GetCursorTarget()

		local min_multiplier = 0.3
		local submax_chargetime_multiplier = 0.7
		local radius = ability:GetSpecialValueFor("radius")
		local range = ability:GetSpecialValueFor("range")
		local travel_speed = ability:GetSpecialValueFor("travel_speed")
		local burn_duration = ability:GetSpecialValueFor("burn_duration")
		local impactFunction = nil

		local enhanced = false
		if validEnhancedCraft(caster) then
			executeEnhancedCraft(caster)
			burn_duration = ability:GetSpecialValueFor("unbalanced_burn_duration")
			impactFunction = createFireTrail
			enhanced = true
		end

		local strength_multiplier = 0.3
		local channel_time_percent = (GameRules:GetGameTime() - ability:GetChannelStartTime()) / ability:GetChannelTime()
		if channel_time_percent < 1 then
			strength_multiplier = channel_time_percent * (submax_chargetime_multiplier - min_multiplier) + min_multiplier
		else
			strength_multiplier = 1
		end

		if not enhanced then
			range = range * strength_multiplier
			travel_speed = travel_speed * strength_multiplier
		end
		burn_duration = burn_duration * strength_multiplier

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

		ProjectileList:CreateLinearProjectile(caster, origin_location, caster.flamberge_direction, travel_speed, range, impactFunction, collisionRules, flambergeHit, "particles/crafts/alisa/flamberge/flamberge.vpcf", {crit = crit, burn_duration = burn_duration, enhanced = enhanced})
		caster.flamberge_direction = nil
		caster.flamberge_target = nil
		caster:RemoveModifierByName("modifier_flamberge_channeling")
	end
end

function flamberge:GetBehavior()
	local behavior = DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_DIRECTIONAL + DOTA_ABILITY_BEHAVIOR_CHANNELLED + DOTA_ABILITY_BEHAVIOR_AOE
	if self:GetCaster():HasModifier("modifier_combat_link_followup_available") then
		behavior = behavior + DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
	end
	return behavior
end

function flamberge:GetAOERadius()
	if self:GetCaster():HasModifier("modifier_combat_link_followup_available") then
		return self:GetSpecialValueFor("unbalanced_range")
	else
		return self:GetSpecialValueFor("range")
	end
end

function flamberge:GetChannelTime()
	if self:GetCaster():HasModifier("modifier_combat_link_followup_available") then
		return self:GetSpecialValueFor("unbalanced_channel_time")
	else
		return self:GetSpecialValueFor("normal_channel_time")
	end
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
	local bonus_unbalance = ability:GetSpecialValueFor("bonus_unbalance")

	if args.crit then damage_scale = damage_scale * 2 end

	applyEffect(unit, damage_type, function()
		dealScalingDamage(unit, caster, damage_type, damage_scale, ability, CRAFT_CP_GAIN_FACTOR, args.enhanced, false, bonus_unbalance)
		unit:AddNewModifier(caster, ability, "modifier_burn", {duration = args.burn_duration})
		unit:Interrupt()
	end)
end

function createFireTrail(caster, origin, direction, speed, range, collisionRules, collisionFunction, args)
	local ability = caster:FindAbilityByName("flamberge")
	local endpoint = origin + direction * range
	local radius = ability:GetSpecialValueFor("unbalanced_trail_radius")
	local duration = ability:GetSpecialValueFor("unbalanced_trail_duration")
	local damage_interval = ability:GetSpecialValueFor("unbalanced_trail_damage_interval")
	local damage_scale = ability:GetSpecialValueFor("unbalanced_damage_percent") / 100 * damage_interval
	local damage_type = ability:GetAbilityDamageType()

	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_jakiro/jakiro_macropyre.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, origin)
	ParticleManager:SetParticleControl(particle, 1, endpoint)
	ParticleManager:SetParticleControl(particle, 2, Vector(duration,0,0))

	local time_elapsed = 0
	local time_elapsed_since_damage = 0
	local update_interval = 1/30
	local units_muted = {}

	DebugDrawCircle(origin, Vector(255,0,0), 0.5, radius, true, duration)
	DebugDrawCircle(endpoint, Vector(255,0,0), 0.5, radius, true, duration)

	Timers:CreateTimer(0, function()
		for unit,v in pairs(units_muted) do
			units_muted[unit] = false
		end

		local team = caster:GetTeamNumber()
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
		local iOrder = FIND_ANY_ORDER
		local targets = FindUnitsInLine(team, origin, endpoint, nil, radius, iTeam, iType, iOrder)
		for k,unit in pairs(targets) do
			units_muted[unit] = true
			unit:AddNewModifier(caster, ability, "modifier_flamberge_mute", {})
		end
		time_elapsed_since_damage = time_elapsed_since_damage + update_interval
		if time_elapsed_since_damage > damage_interval then
			for k,unit in pairs(targets) do
				dealScalingDamage(unit, caster, damage_type, damage_scale, ability, CRAFT_CP_GAIN_FACTOR, args.enhanced, true)
			end
			time_elapsed_since_damage = time_elapsed_since_damage - damage_interval
		end

		for unit,v in pairs(units_muted) do
			if not units_muted[unit] then
				unit:RemoveModifierByName("modifier_flamberge_mute")
			end
		end

		time_elapsed = time_elapsed + update_interval
		if time_elapsed < duration then
			return update_interval
		else
			for unit,v in pairs(units_muted) do
				unit:RemoveModifierByName("modifier_flamberge_mute")
			end
		end
	end)
end

modifier_flamberge_channeling = class({})

function modifier_flamberge_channeling:IsHidden()
	return true
end

if IsServer() then
	function modifier_flamberge_channeling:OnCreated( kv )
		self.healing_interval = 1/30
		self:StartIntervalThink(self.healing_interval)
	end

	function modifier_flamberge_channeling:OnIntervalThink()
		local hero = self:GetParent()
		local direction = (hero.flamberge_target:GetAbsOrigin() - hero:GetAbsOrigin()):Normalized()
		direction.z = 0
		hero:SetForwardVector(direction)
		hero.flamberge_direction = direction
	end
end

modifier_flamberge_mute = class({})

function modifier_flamberge_mute:CheckState()
	local state = {
	[MODIFIER_STATE_MUTED] = true,
	}

	return state
end

function modifier_flamberge_mute:GetEffectName()
	return "particles/generic_gameplay/generic_silence.vpcf"
end

function modifier_flamberge_mute:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_flamberge_mute:GetTexture()
	return "silencer_last_word"
end

function modifier_flamberge_mute:IsDebuff()
	return true
end
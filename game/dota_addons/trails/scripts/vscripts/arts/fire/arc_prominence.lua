require "game_functions"
require "arts"
require "projectile_list"

LinkLuaModifier("modifier_arc_prominence_charging", "arts/fire/arc_prominence.lua", LUA_MODIFIER_MOTION_NONE)
item_arc_prominence = class({})

if IsServer() then
	function item_arc_prominence:OnSpellStart()
		local caster = self:GetCaster()
		local ability = self

		local max_duration = 6
		local health_percent_damage_threshold = 0.5
		local effect_increase_multiplier = 1 + ability:GetSpecialValueFor("effect_increase_per_second") / 100
		local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100

		if caster:HasModifier("modifier_crit") then
			damage_scale = damage_scale * 2
			caster:RemoveModifierByName("modifier_crit")
		end

		applyArtsDelayCooldowns(caster, ability)

		endCastParticle(caster)

		caster:AddNewModifier(caster, ability, "modifier_arc_prominence_charging", {duration = max_duration, damage_threshold = health_percent_damage_threshold * caster:GetHealth(), effect_increase_multiplier = effect_increase_multiplier, damage_scale = damage_scale})
	end

	function item_arc_prominence:OnAbilityPhaseStart()
		createCastParticle(self:GetCaster())
		return true
	end

	function item_arc_prominence:OnAbilityPhaseInterrupted()
		endCastParticle(self:GetCaster())
	end
end

modifier_arc_prominence_charging = class({})

function modifier_arc_prominence_charging:CheckState()
	local state = {
	[MODIFIER_STATE_STUNNED] = true,
	}

	return state
end

if IsServer() then
	function modifier_arc_prominence_charging:OnCreated(params)
		self.damage_threshold = params.damage_threshold
		self.effect_increase_multiplier = params.effect_increase_multiplier
		self.damage_scale = params.damage_scale
		self.damage_taken = 0
		self.seconds_charged = 0

		self.update_interval = 1
		self:StartIntervalThink(self.update_interval)
	end

	function modifier_arc_prominence_charging:OnIntervalThink()
		self.seconds_charged = self.seconds_charged + 1
	end

	function modifier_arc_prominence_charging:DeclareFunctions()
		return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
				MODIFIER_EVENT_ON_TAKEDAMAGE}
	end

	function modifier_arc_prominence_charging:OnTakeDamage(params)
		if params.unit == self:GetParent() then
			self.damage_taken = self.damage_taken + params.damage
			if self.damage_taken >= self.damage_threshold then
				self:Destroy()
			end
		end
	end

	function modifier_arc_prominence_charging:OnDestroy()
		local ability = self:GetAbility()
		local caster = self:GetParent()
		local damage_scale = self.damage_scale
		local damage_type = DAMAGE_TYPE_MAGICAL
		local burn_duration = ability:GetSpecialValueFor("burn_duration")
		local radius = ability:GetSpecialValueFor("radius")

		local effect_multiplier = math.pow(self.effect_increase_multiplier, self.seconds_charged)
		damage_scale = damage_scale * effect_multiplier
		burn_duration = burn_duration * effect_multiplier

		local team = caster:GetTeamNumber()
		local origin = caster:GetAbsOrigin()
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_ANY_ORDER
		local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

		for k,unit in pairs(targets) do
			applyEffect(unit, damage_type, function()
				unit:AddNewModifier(caster, ability, "modifier_burn", {duration = burn_duration})
				dealScalingDamage(unit, caster, damage_type, damage_scale, ability)
			end)
		end

		local particle = ParticleManager:CreateParticle("particles/arts/fire/arc_prominence/explosion.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(particle, 0, origin)
		-- DebugDrawCircle(origin, Vector(255,0,0), 0.5, radius, true, 1)
	end
end

function modifier_arc_prominence_charging:GetOverrideAnimation(params)
	return ACT_DOTA_TELEPORT
end

function modifier_arc_prominence_charging:GetTexture()
	return "quartz_fire_3"
end

function modifier_arc_prominence_charging:GetEffectName()
	return "particles/arts/fire/arc_prominence/charging.vpcf"
end

function modifier_arc_prominence_charging:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
require "game_functions"
require "arts"

LinkLuaModifier("modifier_phantom_phobia", "arts/mirage/phantom_phobia.lua", LUA_MODIFIER_MOTION_NONE)
item_phantom_phobia = class({})

if IsServer() then
	function item_phantom_phobia:OnSpellStart()
		local caster = self:GetCaster()
		local ability = self
		local target_point = self:GetCursorPosition()

		local stat_reduction = 25
		local radius = ability:GetSpecialValueFor("radius")
		local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100
		local duration = ability:GetSpecialValueFor("duration")
		local damage_type = DAMAGE_TYPE_MAGICAL

		if caster:HasModifier("modifier_crit") then
			damage_scale = damage_scale * 2
			caster:RemoveModifierByName("modifier_crit")
		end

		local team = caster:GetTeamNumber()
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_HERO
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_ANY_ORDER
		local targets = FindUnitsInRadius(team, target_point, nil, radius, iTeam, iType, iFlag, iOrder, false)
		for k,unit in pairs(targets) do
			applyEffect(unit, damage_type, function()
				unit:AddNewModifier(caster, ability, "modifier_phantom_phobia", {duration = duration, damage_scale = damage_scale})
				for k,stat in pairs({"str", "ats", "def", "adf"}) do
					if getStats(unit)[stat] < getStats(caster)[stat] then
						modifyStat(unit, getStatModifierName(stat, true), stat_reduction, duration)
					end
				end
			end)
		end

		applyArtsDelayCooldowns(caster, ability)

		local particle = ParticleManager:CreateParticle("particles/arts/mirage/phantom_phobia/area.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(particle, 0, target_point)
		ParticleManager:SetParticleControl(particle, 1, Vector(radius,0,1))
		ParticleManager:SetParticleControl(particle, 2, Vector(0,radius,0))

		endCastParticle(caster)
	end

	function item_phantom_phobia:OnAbilityPhaseStart()
		createCastParticle(self:GetCaster(), self)
		return true
	end

	function item_phantom_phobia:OnAbilityPhaseInterrupted()
		endCastParticle(self:GetCaster())
	end
end

modifier_phantom_phobia = class({})

function modifier_phantom_phobia:GetTexture()
	return "item_quartz_mirage_2"
end

if IsServer() then
	function modifier_phantom_phobia:OnCreated( kv )
		self.damage_interval = 0.5
		self.damage_scale = kv.damage_scale
		self:StartIntervalThink(self.damage_interval)
	end

	function modifier_phantom_phobia:OnIntervalThink()
		local hero = self:GetParent()
		local damage_type = DAMAGE_TYPE_MAGICAL
		local damage_scale = self.damage_scale * self.damage_interval / self:GetDuration()

		dealScalingDamage(hero, self:GetCaster(), damage_type, damage_scale, self:GetAbility())
	end
end

function modifier_phantom_phobia:GetEffectName()
	return "particles/arts/mirage/phantom_phobia/debuff.vpcf"
end

function modifier_phantom_phobia:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
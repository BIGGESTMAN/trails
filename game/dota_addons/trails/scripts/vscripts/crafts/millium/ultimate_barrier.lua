require "game_functions"

LinkLuaModifier("modifier_ultimate_barrier_force_field", "crafts/millium/ultimate_barrier.lua", LUA_MODIFIER_MOTION_NONE)
ultimate_barrier = class({})

if IsServer() then
	function ultimate_barrier:OnSpellStart()
		local caster = self:GetCaster()
		local ability = self
		local target = self:GetCursorTarget()

		local guard_duration = ability:GetSpecialValueFor("duration")
		local force_field_duration = ability:GetSpecialValueFor("unbalanced_field_duration")

		if validEnhancedCraft(caster, target) then
			executeEnhancedCraft(caster, target)
			caster:AddNewModifier(caster, ability, "modifier_ultimate_barrier_force_field", {duration = force_field_duration})
		end

		spendCP(caster, ability)
		applyDelayCooldowns(caster, ability)

		caster:AddNewModifier(caster, ability, "modifier_physical_guard", {duration = guard_duration})
	end
end

function ultimate_barrier:GetBehavior()
	local behavior = DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_AOE
	if self:GetCaster():HasModifier("modifier_combat_link_followup_available") then
		behavior = DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
	end
	return behavior
end

function ultimate_barrier:GetAOERadius()
	return self:GetSpecialValueFor("unbalanced_field_radius")
end

function ultimate_barrier:CastFilterResultTarget(target)
	if target:HasModifier("modifier_combat_link_unbalanced") then
		return UF_SUCCESS
	else
		return UF_FAIL_CUSTOM
	end
end

function ultimate_barrier:GetCustomCastErrorTarget(target)
	return "must_target_unbalanced"
end

modifier_ultimate_barrier_force_field = class({})

function modifier_ultimate_barrier_force_field:GetTexture()
	return "millium_ultimate_barrier"
end

if IsServer() then
	function modifier_ultimate_barrier_force_field:OnCreated( kv )
		self:StartIntervalThink(1/30)
		self:GetAbility().force_field_affected_units = {}
	end

	function modifier_ultimate_barrier_force_field:OnIntervalThink()
		local caster = self:GetCaster()
		local ability = self:GetAbility()

		for unit,v in pairs(ability.force_field_affected_units) do
			ability.force_field_affected_units[unit] = false
		end

		local radius = ability:GetSpecialValueFor("unbalanced_field_radius")
		local team = caster:GetTeamNumber()
		local origin = caster:GetAbsOrigin()
		local iTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY
		local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_ANY_ORDER
		local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
		for k,unit in pairs(targets) do
			ability.force_field_affected_units[unit] = true
			unit:AddNewModifier(caster, ability, "modifier_guard_high_priority", {})
		end

		for unit,v in pairs(ability.force_field_affected_units) do
			if not ability.force_field_affected_units[unit] then
				unit:RemoveModifierByName("modifier_guard_high_priority")
			end
		end
	end

	function modifier_ultimate_barrier_force_field:OnDestroy()
		for unit,v in pairs(self:GetAbility().force_field_affected_units) do
			unit:RemoveModifierByName("modifier_guard_high_priority")
		end
		self:GetAbility().force_field_affected_units = nil
	end
end

function modifier_ultimate_barrier_force_field:GetEffectName()
	return "particles/crafts/millium/ultimate_barrier/force_field.vpcf"
end

function modifier_ultimate_barrier_force_field:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_ultimate_barrier_force_field:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ABILITY_START,
			MODIFIER_EVENT_ON_ATTACK_START}
end

function modifier_ultimate_barrier_force_field:OnAbilityStart(params)
	if params.unit == self:GetParent() then
		self:Destroy()
	end
end

function modifier_ultimate_barrier_force_field:OnAttackStart(params)
	if params.attacker == self:GetParent() then
		self:Destroy()
	end
end
require "game_functions"
require "libraries/util"
require "libraries/physics"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target_points[1]
	local target = keys.target

	local radius = ability:GetSpecialValueFor("radius")
	local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100
	local damage_type = ability:GetAbilityDamageType()
	local faint_duration = ability:GetSpecialValueFor("faint_duration")
	local mov_down_duration = ability:GetSpecialValueFor("mov_down_duration")
	local bonus_unbalance = ability:GetSpecialValueFor("bonus_unbalance")
	local flight_time = 1
	local mov_down = ability:GetSpecialValueFor("mov_down")

	spendCP(caster, ability)
	applyDelayCooldowns(caster, ability)

	local enhanced = false
	if validEnhancedCraft(caster, target) then
		executeEnhancedCraft(caster, target)
		damage_scale = ability:GetSpecialValueFor("unbalanced_damage_percent") / 100
		mov_down_duration = ability:GetSpecialValueFor("unbalanced_mov_down_duration")
		enhanced = true
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_megaton_press_untargetable", {})

		Physics:Unit(caster)
		local velocity = (target_point + Vector(0,0,2000) - caster:GetAbsOrigin()) / flight_time
		caster:SetPhysicsVelocity(velocity)
		caster:SetPhysicsAcceleration(Vector(0,0,-20000))
		caster:SetPhysicsFriction(0)
		caster:SetGroundBehavior(PHYSICS_GROUND_NOTHING)
		caster:SetAutoUnstuck(false)
		caster:FollowNavMesh(false)
		caster:SetNavCollisionType(PHYSICS_NAV_NOTHING)
	end

	if caster:HasModifier("modifier_crit") then
		damage_scale = damage_scale * 2
		caster:RemoveModifierByName("modifier_crit")
	end

	local dummy = CreateUnitByName("npc_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
	local particle = ParticleManager:CreateParticle("particles/crafts/millium/megaton_press/lammy_flying.vpcf", PATTACH_ABSORIGIN_FOLLOW, dummy)
	ParticleManager:SetParticleControl(particle, 1, target_point)

	local team = caster:GetTeamNumber()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	Timers:CreateTimer(flight_time, function()
		if enhanced then
			caster:RemoveModifierByName("modifier_megaton_press_untargetable")
			caster:SetPhysicsVelocity(Vector(0,0,0))
			caster:SetPhysicsAcceleration(Vector(0,0,0))
			FindClearSpaceForUnit(caster, target_point, true)
		end

		local targets = FindUnitsInRadius(team, target_point, nil, radius, iTeam, iType, iFlag, iOrder, false)
		for k,unit in pairs(targets) do
			applyEffect(unit, damage_type, function()
				if not enhanced then
					dealScalingDamage(unit, caster, damage_type, damage_scale / #targets, ability, CRAFT_CP_GAIN_FACTOR, enhanced, false, bonus_unbalance)
				else
					dealScalingDamage(unit, caster, damage_type, damage_scale, ability, CRAFT_CP_GAIN_FACTOR, enhanced, false, bonus_unbalance)
				end
				if #targets == 1 or enhanced then unit:AddNewModifier(caster, ability, "modifier_faint", {duration = faint_duration}) end
				if #targets > 1 or enhanced then modifyStat(unit, STAT_MOV_DOWN, mov_down, mov_down_duration) end
			end)
		end

		dummy:RemoveSelf()

		local impact_particle = ParticleManager:CreateParticle("particles/crafts/millium/megaton_press_shockwave.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(impact_particle, 0, target_point)
	end)

	Physics:Unit(dummy)
	local velocity = (target_point - dummy:GetAbsOrigin()) / flight_time + Vector(0,0,2000)
	dummy:SetPhysicsVelocity(velocity)
	dummy:SetPhysicsAcceleration(Vector(0,0,-4750))
	dummy:SetPhysicsFriction(0)
	dummy:SetGroundBehavior(PHYSICS_GROUND_NOTHING)
	dummy:SetAutoUnstuck(false)
	dummy:FollowNavMesh(false)
	dummy:SetNavCollisionType(PHYSICS_NAV_NOTHING)
end
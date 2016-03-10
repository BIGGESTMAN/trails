require "game_functions"
require "arts"
require "projectile_list"

item_spark_arrow = class({})

if IsServer() then
	function item_spark_arrow:OnSpellStart()
		local caster = self:GetCaster()
		local ability = self
		local target_point = self:GetCursorPosition()

		local projectile_speed = 1500
		local range = 1000
		local radius = 125
		local jump_radius = 500
		local max_jumps = 3
		local jump_interval = 0.3
		local seal_duration = ability:GetSpecialValueFor("seal_duration")
		local damage_scale = ability:GetSpecialValueFor("damage_percent") / 100

		if caster:HasModifier("modifier_crit") then
			damage_scale = damage_scale * 2
			caster:RemoveModifierByName("modifier_crit")
		end

		applyArtsDelayCooldowns(caster, ability)

		collisionRules = {
			team = caster:GetTeamNumber(),
			radius = radius,
			iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL,
			iFlag = DOTA_UNIT_TARGET_FLAG_NONE,
			iOrder = FIND_ANY_ORDER
		}
		local vector = target_point - caster:GetAbsOrigin()
		local direction = vector:Normalized()
		ProjectileList:CreateLinearProjectile(caster, caster:GetAbsOrigin(), direction, projectile_speed, range, nil, collisionRules, sparkArrowHit, "particles/arts/wind/spark_arrow/projectile_model1_immortal_lightning.vpcf",
												{ability = ability, damage_scale = damage_scale, jumps = max_jumps, seal_duration = seal_duration, jump_radius = jump_radius, jump_interval = jump_interval, destroy_on_collision = true})

		endCastParticle(caster)
	end

	function sparkArrowHit(caster, target, args, projectile, range, collisionRules, collisionFunction, particle_name, projectile_speed)
		local ability = args.ability
		local damage_scale = args.damage_scale
		local damage_type = DAMAGE_TYPE_MAGICAL
		local seal_duration = args.seal_duration
		local jump_radius = args.jump_radius
		local jump_interval = args.jump_interval

		applyEffect(target, damage_type, function()
			target:AddNewModifier(caster, ability, "modifier_seal", {duration = seal_duration})
			dealScalingDamage(target, caster, damage_type, damage_scale, ability)
		end)

		if args.jumps > 0 then
			Timers:CreateTimer(jump_interval, function()
				args.jumps = args.jumps - 1
				local team = caster:GetTeamNumber()
				local origin = target:GetAbsOrigin()
				local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
				local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
				local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
				local iOrder = FIND_CLOSEST
				local targets = FindUnitsInRadius(team, origin, nil, jump_radius, iTeam, iType, iFlag, iOrder, false)
				local jump_target = targets[2]
				if jump_target then
					local vector = jump_target:GetAbsOrigin() - origin
					local direction = vector:Normalized()
					args.cannot_collide_with = {}
					args.cannot_collide_with[target] = true
					ProjectileList:CreateLinearProjectile(caster, origin, direction, projectile_speed, range, nil, collisionRules, collisionFunction, particle_name, args)
				end
			end)
		end
	end

	function item_spark_arrow:OnAbilityPhaseStart()
		createCastParticle(self:GetCaster())
		return true
	end

	function item_spark_arrow:OnAbilityPhaseInterrupted()
		endCastParticle(self:GetCaster())
	end
end
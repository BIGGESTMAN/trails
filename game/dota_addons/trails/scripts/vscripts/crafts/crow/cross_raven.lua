require "game_functions"
-- require "libraries/projectiles"
require "libraries/physics"
require "libraries/util"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target_points[1]

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_cross_raven_casting", {duration = ability:GetChannelTime()})
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_cross_raven_countdown", {})
	caster.cross_raven_bullets = {}
	caster.cross_raven_max_cp = getCP(caster) == MAX_CP
	caster.cross_raven_target = target_point
	caster.cross_raven_bullet_speed = ability:GetSpecialValueFor("inward_bullet_travel_speed")
	caster.cross_raven_retargets = ability:GetSpecialValueFor("recasts")

	Timers:CreateTimer(0, function()
		if caster:HasModifier("modifier_cross_raven_casting") then
			fireBullet(keys)
			return 2/30
		end
	end)

	spendCP(caster, ability)
	applyDelayCooldowns(caster, ability)
end

function channelFinish(keys)
	local caster = keys.caster
	caster:RemoveModifierByName("modifier_cross_raven_casting")

	caster:SwapAbilities("cross_raven", "cross_raven_retarget", false, true)
end

function channelInterrupted(keys)
	local caster = keys.caster
	fizzleBullets(caster)
end

function fireBullet(keys)
	local caster = keys.caster
	local ability = keys.ability

	local bullet_count = #caster.cross_raven_bullets
	local travel_time = math.min(0.5, ability:GetSpecialValueFor("outward_bullet_travel_time") - bullet_count * (1/30))
	-- local speed = ability:GetSpecialValueFor("bullets_max_radius") / travel_time * RandomFloat(0.8, 1.2)
	-- local travel_time = ability:GetSpecialValueFor("outward_bullet_travel_time") - ability:GetChannelTime()
	-- local speed = (ability:GetSpecialValueFor("bullets_max_radius") / travel_time) * RandomFloat(0.8, 1.2)
	-- local upward_velocity = Vector(0,0,1) * speed / 4

	local angle_increment = 360 / (ability:GetChannelTime() * 30)
	local angle = angle_increment * bullet_count
	local direction = RotatePosition(Vector(0,0,0), QAngle(0,angle,0), Vector(0,1,0))
	
	for i=0,1 do
		if i == 1 then direction = direction * -1 end

		-- local velocity = speed * direction + upward_velocity
		local target_point = ability:GetSpecialValueFor("bullets_max_radius") * 0.8 * direction + Vector(0,0,RandomInt(200,300)) + caster.cross_raven_target + randomPointInCircle(Vector(0,0,0), 50)
		local velocity = (target_point - caster:GetAbsOrigin()) / travel_time

		local bullet = CreateUnitByName("npc_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
		ability:ApplyDataDrivenModifier(caster, bullet, "modifier_cross_raven_bullet", {})
		bullet:SetAbsOrigin(caster:GetAbsOrigin())
		table.insert(caster.cross_raven_bullets, bullet)
		bullet.target_point = target_point

		Physics:Unit(bullet)
		bullet:SetPhysicsVelocity(velocity)
		bullet:SetPhysicsFriction(0)
		bullet:FollowNavMesh(false)
		bullet:SetNavCollisionType(PHYSICS_NAV_NOTHING)
		bullet:SetGroundBehavior(PHYSICS_GROUND_NOTHING)
		bullet:SetAutoUnstuck(false)

		bullet:OnPhysicsFrame(function(unit)
			local distance = (bullet.target_point - bullet:GetAbsOrigin()):Length()
			if distance < 100 then
				bullet:SetPhysicsVelocity(Vector(0,0,0))
				bullet:SetPhysicsAcceleration(Vector(0,0,0))
				bullet:OnPhysicsFrame(nil)
				bullet.target_point = nil
			end
		end)

		local particle = ParticleManager:CreateParticle("particles/crafts/crow/cross_raven/bullet_alt.vpcf", PATTACH_ABSORIGIN_FOLLOW, bullet)
		ParticleManager:SetParticleControlEnt(particle, 0, bullet, PATTACH_ABSORIGIN_FOLLOW, "attach_origin", bullet:GetAbsOrigin(), true)
	end
end

function retarget(keys)
	local caster = keys.caster
	local ability = caster:FindAbilityByName("cross_raven")
	caster.cross_raven_target = keys.target_points[1]
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_cross_raven_countdown", {})

	caster.cross_raven_retargets = caster.cross_raven_retargets - 1
	if caster.cross_raven_retargets == 0 then
		caster:SwapAbilities("cross_raven_retarget", "cross_raven", false, true)
		caster.cross_raven_retargets = nil
	end

	local bullet_count = #caster.cross_raven_bullets / 2

	for k,bullet in pairs(caster.cross_raven_bullets) do
		local angle_increment = 360 / (ability:GetChannelTime() * 30)
		local angle = angle_increment * bullet_count
		local direction = RotatePosition(Vector(0,0,0), QAngle(0,angle,0), Vector(0,1,0))
		if k % 2 == 0 then direction = direction * -1 end
		bullet_count = bullet_count - 1

		local target_point = ability:GetSpecialValueFor("bullets_max_radius") * 0.8 * direction + Vector(0,0,RandomInt(200,300)) + caster.cross_raven_target + randomPointInCircle(Vector(0,0,0), 50)
		local velocity = (target_point - bullet:GetAbsOrigin()):Normalized() * caster.cross_raven_bullet_speed

		bullet:SetPhysicsVelocity(velocity)
		bullet:SetPhysicsAcceleration((target_point - bullet:GetAbsOrigin()):Normalized() * ability:GetSpecialValueFor("inward_bullet_travel_speed_increase"))
		bullet.target_point = target_point
		Timers:RemoveTimer("cross_raven_bullet_impact"..bullet:GetEntityIndex())

		bullet:OnPhysicsFrame(function(unit)
			local distance = (bullet.target_point - bullet:GetAbsOrigin()):Length()
			if distance < 100 then
				bullet:SetPhysicsVelocity(Vector(0,0,0))
				bullet:SetPhysicsAcceleration(Vector(0,0,0))
				bullet:OnPhysicsFrame(nil)
				bullet.target_point = nil
				if not caster:HasModifier("modifier_cross_raven_countdown") and caster.cross_raven_target then
					convergeBullet(caster, bullet)
				end
			end
		end)
	end
end

function triggerBulletsConverge(keys)
	local caster = keys.caster
	local ability = keys.ability

	if caster.cross_raven_bullets and caster.cross_raven_target then
		Timers:CreateTimer(0, function()
			if caster.cross_raven_bullets then
				caster.cross_raven_bullet_speed = caster.cross_raven_bullet_speed + ability:GetSpecialValueFor("inward_bullet_travel_speed_increase") * 1/30
				return 1/30
			end
		end)

		for k,bullet in pairs(caster.cross_raven_bullets) do
			if not bullet.target_point then
				convergeBullet(caster, bullet)
			end
		end
	end
end

function convergeBullet(caster, bullet)
	local ability = caster:FindAbilityByName("cross_raven")
	local inward_speed = caster.cross_raven_bullet_speed

	local vector_to_target = caster.cross_raven_target - bullet:GetAbsOrigin()
	bullet:SetPhysicsVelocity(vector_to_target:Normalized() * inward_speed)
	bullet:SetPhysicsAcceleration(vector_to_target:Normalized() * ability:GetSpecialValueFor("inward_bullet_travel_speed_increase"))
	-- print(vector_to_target:Length() / inward_speed, vector_to_target:Length())
	Timers:CreateTimer("cross_raven_bullet_impact"..bullet:GetEntityIndex(), {
		endTime = vector_to_target:Length() / inward_speed,
		callback = function()
			local impact_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_gyrocopter/gyro_guided_missile_explosion.vpcf", PATTACH_CUSTOMORIGIN, nil)
			ParticleManager:SetParticleControl(impact_particle, 0, randomPointInCircle(caster.cross_raven_target, 150))
			bullet:RemoveModifierByName("modifier_cross_raven_bullet")
			bullet:Kill(nil, nil)
			bullet:RemoveSelf()
		end
	})
end

function bulletImpacted(keys)
	local caster = keys.caster
	local ability = keys.ability

	removeElementFromTable(caster.cross_raven_bullets, keys.target)
	if #caster.cross_raven_bullets == 0 then
		local damage_type = ability:GetAbilityDamageType()
		local radius = ability:GetSpecialValueFor("radius")
		local max_damage_radius = ability:GetSpecialValueFor("max_damage_radius")
		local max_damage_scale = ability:GetSpecialValueFor("max_damage_percent") / 100
		local min_damage_scale = ability:GetSpecialValueFor("min_damage_percent") / 100
		local debuff_duration = ability:GetSpecialValueFor("max_cp_debuff_duration")

		if caster.cross_raven_max_cp then
			local max_damage_scale = ability:GetSpecialValueFor("max_cp_max_damage_percent") / 100
			local min_damage_scale = ability:GetSpecialValueFor("max_cp_min_damage_percent") / 100
		end

		if caster:HasModifier("modifier_crit") then
			max_damage_scale = max_damage_scale * 2
			min_damage_scale = min_damage_scale * 2
			caster:RemoveModifierByName("modifier_crit")
		end

		local team = caster:GetTeamNumber()
		local origin = caster.cross_raven_target
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_ANY_ORDER
		local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
		for k,unit in pairs(targets) do
			applyEffect(unit, damage_type, function()
				local distance = (unit:GetAbsOrigin() - caster.cross_raven_target):Length2D()
				local damage_modifier = 1 - (distance - max_damage_radius) / (radius - max_damage_radius)
				if damage_modifier > 1 then damage_modifier = 1 end
				local damage_scale = min_damage_scale + damage_modifier * (max_damage_scale - min_damage_scale)

				dealScalingDamage(unit, caster, damage_type, damage_scale, ability, SCRAFT_CP_GAIN_FACTOR, false, false, 0)
				if caster.cross_raven_max_cp then
					unit:AddNewModifier(caster, ability, "modifier_nightmare", {duration = debuff_duration})
					if damage_modifier == 1 then
						unit:AddNewModifier(caster, ability, "modifier_deathblow", {duration = debuff_duration})
					end
				end
			end)
		end

		caster.cross_raven_bullets = nil
		caster.cross_raven_max_cp = nil
		caster.cross_raven_target = nil
		caster.cross_raven_bullet_speed = nil
		caster.cross_raven_retargets = nil
		if ability:IsHidden() then caster:SwapAbilities("cross_raven_retarget", "cross_raven", false, true) end
	end
end

function fizzleBullets(caster)
	caster.cross_raven_max_cp = nil
	caster.cross_raven_target = nil
	caster.cross_raven_bullet_speed = nil
	caster.cross_raven_retargets = nil
	caster:RemoveModifierByName("modifier_cross_raven_countdown")
	for k,bullet in pairs(caster.cross_raven_bullets) do
		bullet:RemoveSelf()
	end
	caster.cross_raven_bullets = nil
	if caster:FindAbilityByName("cross_raven"):IsHidden() then caster:SwapAbilities("cross_raven_retarget", "cross_raven", false, true) end
end
require "libraries/util"
require "game_functions"

function setupProjectileList()
	ProjectileList = {}
	ProjectileList.__index = ProjectileList
	ProjectileList.projectiles = {}

	function ProjectileList:AddProjectile(unit)
		self.projectiles[unit] = true
	end

	function ProjectileList:RemoveProjectile(unit)
		self.projectiles[unit] = nil
	end

	function ProjectileList:GetProjectiles()
		for projectile,_ in pairs(self.projectiles) do
			if projectile:IsNull() or not projectile:IsAlive() then
				self.projectiles[projectile] = nil
			end
		end

		return self.projectiles
	end

	function ProjectileList:GetProjectilesInArea(center, radius)
		local projectiles = {}
		for projectile,_ in pairs(self:GetProjectiles()) do
			local distance = (center - projectile:GetAbsOrigin()):Length2D()
			if distance <= radius then
				table.insert(projectiles, projectile)
			end
		end
		return projectiles
	end

	function ProjectileList:FreezeProjectiles()
		for projectile,_ in pairs(self:GetProjectiles()) do
			projectile.frozen = true
		end
	end

	function ProjectileList:UnfreezeProjectiles()
		for projectile,_ in pairs(self:GetProjectiles()) do
			projectile.frozen = false
		end
	end

	function ProjectileList:TrackingProjectileCreated(event)
		local origin = EntIndexToHScript(event.entindex_source_const)
		local target = EntIndexToHScript(event.entindex_target_const)
		local speed = event.move_speed
		local dodgeable = event.dodgeable
		local is_attack = event.is_attack

		-- not sure if these are useful for anything
		local ability = EntIndexToHScript(event.entindex_ability_const)
		local max_impact_time = event.max_impact_time
		local expire_time = event.expire_time

		if is_attack then
			rangedAttackLaunched(origin, target, speed)
			return false
		else
			return true
		end
	end

	function ProjectileList:CreateTrackingProjectile(origin, target, speed, impactFunction, particle_name, other_args)
		other_args = other_args or {}
		particle_name = particle_name or getProjectileModel(origin:GetUnitName())
		impactFunction = impactFunction or function() origin:PerformAttack(target, true, true, true, true, false) end

		local origin_location = origin:GetAttachmentOrigin(origin:ScriptLookupAttachment("attach_attack1"))
		local projectile = CreateUnitByName("npc_dummy_unit", origin_location, false, origin, origin, origin:GetTeamNumber())
		projectile:SetAbsOrigin(origin_location)
		ProjectileList:AddProjectile(projectile)

		local target_location = getTargetHitloc(target)
		local projectile_location = projectile:GetAbsOrigin()
		local direction = (target_location - projectile_location):Normalized()

		local dummy_speed = speed * 0.03
		local arrival_distance = target:GetModelRadius()
		local minimum_arrival_distance = dummy_speed / 2 + 5
		if arrival_distance < minimum_arrival_distance then arrival_distance = minimum_arrival_distance end

		local particle = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, projectile)
		ParticleManager:SetParticleControl(particle, 0, projectile_location)
		ParticleManager:SetParticleControl(particle, 1, target_location)
		ParticleManager:SetParticleControl(particle, 2, Vector(speed,0,0))
		projectile:SetForwardVector(direction)

		Timers:CreateTimer(0, function()
			if not projectile:IsNull() then
				if not projectile.frozen then
					ParticleManager:SetParticleControl(particle, 2, Vector(speed,0,0))
					if not target:IsNull() then
						target_location = getTargetHitloc(target)
						ParticleManager:SetParticleControl(particle, 1, target_location)
					end
					projectile_location = projectile:GetAbsOrigin()
					local distance = (target_location - projectile_location):Length2D()
					direction = (target_location - projectile_location):Normalized()
					projectile:SetForwardVector(direction)

					if distance > arrival_distance then
						projectile:SetAbsOrigin(projectile_location + direction * dummy_speed)
						return 0.03
					else
						if not target:IsNull() and not origin:IsNull() then
							impactFunction(origin, target, speed, other_args)
						end
						ParticleManager:DestroyParticle(particle, false)
						Timers:CreateTimer(3, function()
							projectile:RemoveSelf()
						end)
					end
				else
					ParticleManager:SetParticleControl(particle, 2, Vector(0,0,0))
					return 0.03
				end
			end
		end)
	end

	function ProjectileList:CreateLinearProjectile(caster, origin_location, direction, speed, range, impactFunction, collisionRules, collisionFunction, particle_name, other_args)
		other_args = other_args or {}
		local destroy_on_collision = other_args.destroy_on_collision
		local cannot_collide_with = other_args.cannot_collide_with or {}

		local update_interval = 1/30
		speed = speed * update_interval
		if not other_args.non_flat then
			direction.z = 0
		end

		local projectile = CreateUnitByName("npc_dummy_unit", origin_location, false, caster, caster, caster:GetTeamNumber())
		projectile:SetAbsOrigin(origin_location)
		ProjectileList:AddProjectile(projectile)
		projectile.units_hit = {}

		local distance_traveled = 0
		local projectile_location = projectile:GetAbsOrigin()

		local particle = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, projectile)
		if not other_args.stationary_particle then -- stationary particle = just follows CP 0, doesn't use velocity CP
			ParticleManager:SetParticleControl(particle, 0, projectile_location)
			ParticleManager:SetParticleControl(particle, 1, speed * direction / update_interval)
		end
		projectile:SetForwardVector(direction)

		Timers:CreateTimer(0, function()
			if IsValidEntity(projectile) then
				if distance_traveled < range then
					-- Move projectile
					local distance = range - distance_traveled
					if speed < distance then
						projectile:SetAbsOrigin(projectile:GetAbsOrigin() + direction * speed)
					else
						projectile:SetAbsOrigin(projectile:GetAbsOrigin() + direction * distance)
					end
					distance_traveled = distance_traveled + speed
					if not other_args.non_flat then
						projectile:SetAbsOrigin(GetGroundPosition(projectile:GetAbsOrigin(), projectile)) -- keep projectile on ground, for particle purposes
					end

					-- Check for unit collisions
					if collisionFunction and collisionRules then
						collisionRules["origin"] = projectile:GetAbsOrigin()
						local targets = FindUnitsInRadiusTable(collisionRules)
						for k,unit in pairs(targets) do
							if not cannot_collide_with[unit] and not projectile.units_hit[unit] then
								collisionFunction(caster, unit, other_args, projectile, range, collisionRules, collisionFunction, particle_name, speed / update_interval)
								projectile.units_hit[unit] = true
								if destroy_on_collision then
									if impactFunction then impactFunction(caster, origin_location, direction, speed / update_interval, range, collisionRules, collisionFunction, other_args, projectile.units_hit) end
									projectile:RemoveSelf()
									break
								end
							end
						end
					end
					return update_interval
				else
					if impactFunction then impactFunction(caster, origin_location, direction, speed / update_interval, range, collisionRules, collisionFunction, other_args, projectile.units_hit) end
					projectile:RemoveSelf()
				end
			end
		end)
	end
end
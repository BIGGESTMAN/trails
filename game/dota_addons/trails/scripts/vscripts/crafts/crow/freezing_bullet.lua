require "game_functions"
require "libraries/util"

function abilityPhaseStart(keys)
	local caster = keys.caster
	local ability = keys.ability
end

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target_points[1]
	local target = keys.target

	local radius = ability:GetSpecialValueFor("radius")
	local range = ability:GetSpecialValueFor("range")
	local travel_speed = ability:GetSpecialValueFor("travel_speed")
	local shatter_damage_scale = ability:GetSpecialValueFor("shatter_damage_percent") / 100
	local freeze_duration = ability:GetSpecialValueFor("freeze_duration")

	local enhanced = false
	if validEnhancedCraft(caster, target) then
		caster:RemoveModifierByName("modifier_combat_link_followup_available")
		target:RemoveModifierByName("modifier_combat_link_unbalanced")
		shatter_damage_scale = ability:GetSpecialValueFor("unbalanced_shatter_damage_percent") / 100
		enhanced = true
	end

	modifyCP(caster, getCPCost(ability) * -1)
	applyDelayCooldowns(caster, ability)

	if caster:HasModifier("modifier_crit") then
		shatter_damage_scale = shatter_damage_scale * 2
		caster:RemoveModifierByName("modifier_crit")
	end

	local direction = (target_point - caster:GetAbsOrigin()):Normalized()
	local origin_location = caster:GetAbsOrigin()

	ProjectileList:CreateLinearProjectile(caster, origin_location, direction, travel_speed, range, createFrostTrail, nil, nil, "particles/crafts/crow/freezing_bullet.vpcf", {shatter_damage_scale = shatter_damage_scale, enhanced = enhanced})
end

function createFrostTrail(caster, origin, direction, speed, range, collisionRules, collisionFunction, args)
	local ability = caster:FindAbilityByName("freezing_bullet")
	local endpoint = origin + direction * range
	local wall_formation_delay = ability:GetSpecialValueFor("wall_formation_delay")
	if args.enhanced then wall_formation_delay = 0 end
	local radius = ability:GetSpecialValueFor("trail_width")
	local freeze_duration = ability:GetSpecialValueFor("freeze_duration")
	local damage_type = ability:GetAbilityDamageType()

	local particle = ParticleManager:CreateParticle("particles/crafts/crow/freezing_bullet/frost_trail.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, origin)
	ParticleManager:SetParticleControl(particle, 1, endpoint)

	local time_elapsed = 0
	local update_interval = 1/30
	args.units_frozen = {}

	Timers:CreateTimer(0, function()
		local team = caster:GetTeamNumber()
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
		local iOrder = FIND_ANY_ORDER
		local targets = FindUnitsInLine(team, origin, endpoint, nil, radius, iTeam, iType, iOrder)
		for k,unit in pairs(targets) do
			freezeUnit(caster, args.units_frozen, unit, args.enhanced)
		end
		time_elapsed = time_elapsed + update_interval
		if time_elapsed < wall_formation_delay then
			return update_interval
		else
			ParticleManager:DestroyParticle(particle, false)
			createWall(caster, origin, endpoint, args)
		end
	end)
end

function createWall(caster, origin, endpoint, args)
	local ability = caster:FindAbilityByName("freezing_bullet")
	local freeze_radius = ability:GetSpecialValueFor("wall_freeze_radius")
	local wall_duration = ability:GetSpecialValueFor("wall_duration")
	local freeze_duration = ability:GetSpecialValueFor("freeze_duration")
	local damage_type = ability:GetAbilityDamageType()

	local distance = (endpoint - origin):Length2D()
	local direction = (endpoint - origin):Normalized()
	local wall_segments = distance / 100
	local wall_entities = {}
	local wall_dummies = {}

	for i=1,wall_segments do
		local segment_location = origin + direction * distance * i / wall_segments
		wall_entities[i] = SpawnEntityFromTableSynchronous("point_simple_obstruction", {origin = segment_location})
		wall_dummies[i] = CreateUnitByName("npc_dummy_unit_vulnerable", segment_location, false, nil, caster, caster:GetOpposingTeamNumber())
		wall_dummies[i].freezingBulletWallShatter = shatterWall
	end
	local wall_particle = ParticleManager:CreateParticle("particles/crafts/crow/freezing_bullet/ice_wall.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(wall_particle, 0, origin)
	ParticleManager:SetParticleControl(wall_particle, 1, endpoint)

	if not caster.freezing_bullet_walls then caster.freezing_bullet_walls = {} end
	local wall_table = {entities = wall_entities, dummies = wall_dummies, particle = wall_particle, center = midpoint(origin, endpoint), damage_scale = args.shatter_damage_scale}
	table.insert(caster.freezing_bullet_walls, wall_table)

	local time_elapsed = 0
	local update_interval = 1/30

	Timers:CreateTimer(0, function()
		local team = caster:GetTeamNumber()
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
		local iOrder = FIND_ANY_ORDER
		local targets = FindUnitsInLine(team, origin, endpoint, nil, freeze_radius, iTeam, iType, iOrder)
		for k,unit in pairs(targets) do
			freezeUnit(caster, args.units_frozen, unit, args.enhanced)
		end
		time_elapsed = time_elapsed + update_interval
		if time_elapsed < wall_duration then
			return update_interval
		else
			removeWall(wall_table, false)
		end
	end)
end

function freezeUnit(caster, units_frozen, unit, enhanced)
	local ability = caster:FindAbilityByName("freezing_bullet")
	local freeze_duration = ability:GetSpecialValueFor("freeze_duration")
	local freeze_damage_scale = ability:GetSpecialValueFor("unbalanced_freeze_damage_percent") / 100
	local damage_type = ability:GetAbilityDamageType()

	if not units_frozen[unit] then
		unit:AddNewModifier(caster, ability, "modifier_freeze", {duration = freeze_duration})
		units_frozen[unit] = true
		if enhanced and unit:GetUnitName() ~= "npc_dummy_unit_vulnerable" then
			applyEffect(unit, damage_type, function()
				dealScalingDamage(unit, caster, damage_type, freeze_damage_scale, ability, CRAFT_CP_GAIN_FACTOR)
				increaseUnbalance(caster, unit)
			end)
		end
	end
end

function shatterWall(self, dummy, shattering_unit)
	local caster = dummy:GetOwner()
	local ability = caster:FindAbilityByName("freezing_bullet")
	local range = ability:GetSpecialValueFor("shatter_range")
	local damage_type = ability:GetAbilityDamageType()

	local wall = nil
	for k,caster_wall in pairs(caster.freezing_bullet_walls) do
		if tableContains(caster_wall.dummies, dummy) then
			wall = caster_wall
			break
		end
	end
	local direction = (wall.center - shattering_unit:GetAbsOrigin()):Normalized()
	local damage_scale = wall.damage_scale

	local targets = {}
	for k,entity in pairs(wall.entities) do
		local origin = entity:GetAbsOrigin()
		local end_point = origin + direction * range
		local radius = (800 / 8) / 2 + 10

		local team = caster:GetTeamNumber()
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
		local iOrder = FIND_ANY_ORDER
		local entity_targets = FindUnitsInLine(team, origin, end_point, nil, radius, iTeam, iType, iOrder)
		for k,unit in pairs(entity_targets) do
			if pointIsInFront(unit:GetAbsOrigin(), origin, direction) and not tableContains(targets, unit) then
				table.insert(targets, unit)
			end
		end

		local particle = ParticleManager:CreateParticle("particles/crafts/crow/freezing_bullet/shatter_wind.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(particle, 0, origin)
		ParticleManager:SetParticleControl(particle, 1, end_point)
	end

	removeWall(wall, true)

	for k,unit in pairs(targets) do
		applyEffect(unit, damage_type, function()
			dealScalingDamage(unit, caster, damage_type, damage_scale, ability, CRAFT_CP_GAIN_FACTOR)
			increaseUnbalance(caster, unit)
		end)
	end
end

function removeWall(wall_table, delete_particle_instantly)
	for k,entity in pairs(wall_table.entities) do
		if IsValidEntity(entity) then entity:RemoveSelf() end
	end
	for k,dummy in pairs(wall_table.dummies) do
		if IsValidEntity(dummy) then
			dummy.freezingBulletWallShatter = nil -- prevent horrifying buggy wallshatter chain reactions; probably not necessary anymore
			dummy:ForceKill(false)
		end
	end
	ParticleManager:DestroyParticle(wall_table.particle, delete_particle_instantly)
	wall_table = nil
end
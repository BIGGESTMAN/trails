function unitsInLine(caster, origin, range, radius, direction, require_forward, target_types, target_flags)
	target_types = target_types or DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
	target_flags = target_flags or DOTA_UNIT_TARGET_FLAG_NONE

	local targets = {}

	local team = caster:GetTeamNumber()
	local line_midpoint = origin + direction * range / 2
	local search_radius = (range / 2) + radius
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = target_types
	local iFlag = target_flags
	local iOrder = FIND_CLOSEST

	-- DebugDrawCircle(line_midpoint, Vector(255,0,0), 1, search_radius, true, 2)
	
	local possible_targets = FindUnitsInRadius(team, line_midpoint, nil, search_radius, iTeam, iType, iFlag, iOrder, false)
	for k,possible_target in pairs(possible_targets) do
		-- Calculate distance
		local pathStartPos	= origin * Vector( 1, 1, 0 )
		local pathEndPos	= pathStartPos + direction * range
		local distance = DistancePointSegment(possible_target:GetAbsOrigin() * Vector( 1, 1, 0 ), pathStartPos, pathEndPos )
		local unit_in_line = distance <= radius

		if require_forward then -- Calculate angle
			local direction_towards_origin = (possible_target:GetAbsOrigin() - origin):Normalized()
			local angle = direction:Dot(direction_towards_origin)
			if angle <= 0 then -- If unit isn't in front of origin
				unit_in_line = false
			end
		end

		if distance <= radius and unit_in_line then
			table.insert(targets, possible_target)
		end
	end

	return targets
end

function tableContains(list, element)
    if list == nil then return false end
    for i=1,#list do
        if list[i] == element then
            return true
        end
    end
    return false
end

function DistancePointSegment( point, line_point_1, line_point_2 )
	local length = line_point_2 - line_point_1
	local length_squared = length:Dot( length )
	t = ( point - line_point_1 ):Dot( line_point_2 - line_point_1 ) / length_squared
	if t < 0.0 then
		return ( line_point_1 - point ):Length2D()
	elseif t > 1.0 then
		return ( line_point_2 - point ):Length2D()
	else
		local proj = line_point_1 + t * length
		return ( proj - point ):Length2D()
	end
end

function GetEnemiesInCone(unit, start_radius, end_radius, end_distance, caster_forward, circles, debug, target_flags, vision_duration)
	local DEBUG = debug or false
	local VISION_DURATION = vision_duration or 0
	
	-- Positions
	local fv = caster_forward
	local origin = unit:GetAbsOrigin()

	local start_point = origin + fv * start_radius -- Position to find units with start_radius
	local end_point = origin + fv * (start_radius + end_distance) -- Position to find units with end_radius

	if VISION_DURATION > 0 then
		AddFOWViewer(unit:GetTeamNumber(), start_point, start_radius, VISION_DURATION, false)
		AddFOWViewer(unit:GetTeamNumber(), end_point, end_radius, VISION_DURATION, false)
	end

	if DEBUG then
		DebugDrawCircle(start_point, Vector(255,0,0), 5, start_radius, true, 1)
		DebugDrawCircle(end_point, Vector(255,0,0), 5, end_radius, true, 1)
	end

	local intermediate_circles = {}
	local number_of_intermediate_circles = circles - 2
	for i=1,number_of_intermediate_circles do
		local radius = start_radius + (end_radius - start_radius) / (number_of_intermediate_circles + 1) * i
		local point = origin + fv * (end_distance / (number_of_intermediate_circles + 1) * i + start_radius)
		intermediate_circles[i] = {point = point, radius = radius}

		if VISION_DURATION > 0 then AddFOWViewer(unit:GetTeamNumber(), point, radius, VISION_DURATION, false) end
	end
	
	if DEBUG then
		for k,circle in pairs(intermediate_circles) do 
			DebugDrawCircle(circle.point, Vector(0,255,0), 5, circle.radius, true, 1)
		end
	end

	local cone_units = {}
	-- Find the units
	local team = unit:GetTeamNumber()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = target_flags or DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER

	local start_units = FindUnitsInRadius(team, start_point, nil, start_radius, iTeam, iType, iFlag, iOrder, false)
	local end_units = FindUnitsInRadius(team, end_point, nil, end_radius, iTeam, iType, iFlag, iOrder, false)

	-- Join the tables
	for k,v in pairs(end_units) do
		table.insert(cone_units, v)
	end

	for k,v in pairs(start_units) do
		if not tableContains(cone_units, v) then
			table.insert(cone_units, v)
		end
	end

	for k,circle in pairs(intermediate_circles) do
		local units = FindUnitsInRadius(team, circle.point, nil, circle.radius, iTeam, iType, iFlag, iOrder, false)
		for k,v in pairs(units) do
			if not tableContains(cone_units, v) then
				table.insert(cone_units, v)
			end
		end
	end

	--	DeepPrintTable(cone_units)

	return cone_units
end

function IsValidAlive(unit)
	return IsValidEntity(unit) and unit:IsAlive()
end

function randomIndexOfTable(table, excluded_indices)
	local excluded = excluded_indices or {}

	local indexes = {}
	for k,v in pairs(table) do
		if not tableContains(excluded_indices, k) then
			indexes[#indexes + 1] = k
		end
	end
	
	return indexes[RandomInt(1, #indexes)]
end

function sizeOfTable(table)
	local size = 0
	for k,v in pairs(table) do
		size = size + 1
	end
	return size
end

function copyOfTable(table)
	local new_table = {}
	for k,v in pairs(table) do
		new_table[k] = v
	end
	return new_table
end

function removeElementFromTable(table_arg, element)
	for k,v in pairs(table_arg) do
		if v == element then
			table.remove(table_arg, k)
			break
		end
	end
end

function getNumberOfModifierInstances(unit, modifier_name)
	local count = 0
	local modifiers = unit:GetModifierCount()
	for i=0,modifiers - 1 do
		local modifier = unit:GetModifierNameByIndex(i)
		if modifier == modifier_name then count = count + 1 end
	end
	return count
end

function damageMultiplierForArmor(armor)
	return 1 - 0.06 * armor / (1 + (0.06 * math.abs(armor)))
end

function splitGoldAmongTeam(gold, team_number)
	local players = {}
	for i=0,9 do
		if PlayerResource:IsValidPlayer(i) and PlayerResource:GetTeam(i) == team_number then
			table.insert(players, i)
		end
	end
	for k,playerID in pairs(players) do
		PlayerResource:ModifyGold(playerID, gold / #players, false, DOTA_ModifyGold_AbilityCost)
		PopupGoldGain(PlayerResource:GetSelectedHeroEntity(playerID), gold / #players)
	end
end

function getTargetHitloc(target)
	local target_location = target:GetAbsOrigin()
	local target_attach_hitloc = target:ScriptLookupAttachment("attach_hitloc")
	if target_attach_hitloc ~= 0 then
		target_location = target:GetAttachmentOrigin(target_attach_hitloc)
	else
		target_location.z = target_location.z + target:GetBoundingMaxs().z
	end
	return target_location
end

if not util_unit_keyvalues then util_unit_keyvalues = LoadKeyValues("scripts/vscripts/npc_units.txt") end
if not util_hero_keyvalues then util_hero_keyvalues = LoadKeyValues("scripts/vscripts/npc_heroes.txt") end
if not util_custom_unit_keyvalues then util_custom_unit_keyvalues = LoadKeyValues("scripts/npc/npc_units_custom.txt") end
if not util_custom_hero_keyvalues then util_custom_hero_keyvalues = LoadKeyValues("scripts/npc/npc_heroes_custom.txt") end
function getProjectileModel(unit_name)
	local particle_name = nil

	local unit_kvs = util_unit_keyvalues[unit_name]
	if not unit_kvs then unit_kvs = util_hero_keyvalues[unit_name] end
	if not unit_kvs then unit_kvs = util_custom_unit_keyvalues[unit_name] end
	particle_name = unit_kvs["ProjectileModel"]
	if not particle_name then
		for k,v in pairs(util_custom_hero_keyvalues) do
			if v["override_hero"] == unit_name then
				particle_name = v["ProjectileModel"]
			end
		end
	end
	return particle_name
end

function FindUnitsInRadiusTable(table)
	return FindUnitsInRadius(table["team"], table["origin"], nil, table["radius"], table["iTeam"], table["iType"], table["iFlag"], table["iOrder"], false)
end

function randomPointInCircle(origin, radius)
    t = 2*math.pi*RandomFloat(0,radius)
    u = RandomFloat(0, radius)+RandomFloat(0, radius)
    if u > radius then u = radius * 2 - u end
    return Vector(u*math.cos(t), u*math.sin(t),0) + origin
end

function findFirstUnitInLine(caster, origin, endpoint, width, target_team, target_type)
	local team = caster:GetTeamNumber()
	local iTeam = target_team or DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = target_type or DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
	local iOrder = FIND_CLOSEST
	local targets = FindUnitsInLine(team, origin, endpoint, nil, width, iTeam, iType, iOrder)
	return targets[1]
end

function pointIsBetweenPoints(point, comparison_point_1, comparison_point_2)
	local origin = comparison_point_1 + (comparison_point_2 - comparison_point_1) / 2
	local radius = (comparison_point_1 - comparison_point_2):Length2D() / 2
	local distance = (point - origin):Length2D()
	return distance <= radius
end
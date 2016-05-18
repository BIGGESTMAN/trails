require "libraries/util"
require "combat_links"
require "game_functions"
require "master_quartz"
require "gamemodes/modifier_boss_vulnerable"
require "gamemodes/modifier_boss_hp_tracker"
require "gamemodes/modifier_boss_out_of_combat_regen"
require "gamemodes/reward_modifiers"
require "gamemodes/cp_rewards"

LinkLuaModifier("modifier_boss_vulnerable", "gamemodes/modifier_boss_vulnerable.lua", LUA_MODIFIER_MOTION_NONE)

PATHS_COUNT = 4
GROUPS_PER_PATH = 2

SHOPPING = 0
EXPLORING = 1
ENCOUNTER = 2

RESULT_DEFEAT = 0
RESULT_VICTORY = 1

ENCOUNTER_END_DELAY = 5
ARENA_TRIGGER_RANGE = 400

TIME_BETWEEN_CP_ORB_SPAWNS = 15
CP_ORBS_PER_SPAWN = 3
CP_PER_ORB = 15
CP_ORB_DURATION = 7
ORB_PICKUP_RANGE = 125

STARTING_GOLD = 500
DEBUG_HEROES_START_WITH_ALL_ABILITIES = false

if Gamemode_Boss == nil then
	Gamemode_Boss = class({})
	Gamemode_Boss.__index = Gamemode_Boss
end

function Gamemode_Boss:Initialize()
	-- local base_vision = Vision(DOTA_TEAM_GOODGUYS)
	-- base_vision:Add(Vector(0, 0, 0), 1400)

	CustomGameEventManager:RegisterListener("path_button_pressed", WrapMemberMethod(self.OnPathButtonPressed, self))
	self.state = SHOPPING
	self.current_path_progress = 0
	self.paths_completed = {}

	CPRewards:Initialize()
end

function Gamemode_Boss:OnPathButtonPressed(eventSourceIndex, args)
	local path = args.pathNumber
	if not self.currently_on_path then
		self.state = EXPLORING
		self.currently_on_path = path
		CustomGameEventManager:Send_ServerToAllClients("path_start", {})
		CustomGameEventManager:Send_ServerToAllClients("infotext_game_starting", {})
		self:RemovePathWall(path)
	end
end

function Gamemode_Boss:RemovePathWall(path_number)
	ParticleManager:DestroyParticle(self.path_walls[path_number].particle, false)
	for k,entity in pairs(self.path_walls[path_number].entities) do
		entity:RemoveSelf()
	end
	self.path_walls[path_number] = nil
end

function Gamemode_Boss:SetupPaths()
	local enemy_group_kv = LoadKeyValues("scripts/kv/enemygroups.txt")
	local bosses_kv = LoadKeyValues("scripts/kv/bosses.txt")
	local assigned_bosses = {}
	local assigned_crafts = {}
	self.paths = {}
	for i=1, PATHS_COUNT do
		local path_groups = {}
		for i=1, GROUPS_PER_PATH do
			path_groups[i] = self:GetRandomEnemyGroup(enemy_group_kv)
		end
		path_groups[GROUPS_PER_PATH + 1] = self:GetRandomUnassignedBoss(bosses_kv, assigned_bosses)
		local new_path = {groups = path_groups, rewards = self:GetRandomUnassignedCrafts(assigned_crafts)}
		-- print("Path "..i..": ")
		-- DeepPrintTable(new_path)
		table.insert(self.paths, new_path)
	end

	self:CreatePathWalls()
end

function Gamemode_Boss:CreatePathWalls()
	self.path_walls = {}
	for path=1, PATHS_COUNT do
		self.path_walls[path] = {}
		local wall_start = Entities:FindByName(nil, "path_"..path.."_wall_1_start"):GetAbsOrigin()
		local wall_end = Entities:FindByName(nil, "path_"..path.."_wall_1_end"):GetAbsOrigin()
		local distance = (wall_end - wall_start):Length2D()
		local direction = (wall_end - wall_start):Normalized()
		local wall_segments = distance / 40
		self.path_walls[path].entities = {}

		for i=1,wall_segments do
			local segment_location = wall_start + direction * distance * i / wall_segments
			self.path_walls[path].entities[i] = SpawnEntityFromTableSynchronous("point_simple_obstruction", {origin = segment_location})
		end

		self.path_walls[path].particle = ParticleManager:CreateParticle("particles/bosses/path_barrier.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(self.path_walls[path].particle, 0, wall_start)
		ParticleManager:SetParticleControl(self.path_walls[path].particle, 1, wall_end)
	end
end

function Gamemode_Boss:GetRandomEnemyGroup(kv)
	local group_kv = kv[randomIndexOfTable(kv)]
	while group_kv["disabled"] == 1 do
		group_kv = kv[randomIndexOfTable(kv)]
	end

	group_kv = copyOfTable(group_kv)
	group_kv.mobs = {}
	for k,v in pairs(group_kv) do
		if k:find("trailsadventure") then
			group_kv.mobs[k] = v
			group_kv[k] = nil
		end
	end

	return group_kv
end

function Gamemode_Boss:GetRandomUnassignedBoss(kv, assigned_bosses)
	local unassigned_bosses = {}
	for k,v in pairs(kv) do
		if not assigned_bosses[k] and v["disabled"] ~= 1 then
			unassigned_bosses[k] = v
		end
	end

	local boss_kv = nil
	local index = nil
	if #unassigned_bosses > 0 then
		index = randomIndexOfTable(unassigned_bosses)
		boss_kv = unassigned_bosses[index]
	else
		boss_kv = kv[randomIndexOfTable(kv)]
		while boss_kv["disabled"] == 1 do
			boss_kv = kv[randomIndexOfTable(kv)]
		end
	end
	if index then assigned_bosses[index] = true end

	boss_kv = copyOfTable(boss_kv)
	for pathnumber,version in pairs(boss_kv) do
		if pathnumber ~= "boss" then
			version.mobs = {}
			for k,v in pairs(version) do
				if k:find("trailsadventure") then
					version.mobs[k] = v
					version[k] = nil
				end
			end
		end
	end
	return boss_kv
end

function Gamemode_Boss:GetRandomUnassignedCrafts(assigned_crafts)
	local heroes = getAllHeroes()
	local rewards = {}
	for k,hero in pairs(heroes) do
		local unassigned_crafts = {}
		for k,ability in pairs(getAllActiveAbilities(hero)) do
			if ability:GetLevel() == 0 and ability:GetAbilityType() ~= 1 and not assigned_crafts[ability] then
				table.insert(unassigned_crafts, ability)
			end
		end

		if #unassigned_crafts > 0 then
			local reward_ability = unassigned_crafts[RandomInt(1, #unassigned_crafts)]
			assigned_crafts[reward_ability] = true
			rewards[hero] = reward_ability:GetAbilityName()
		end
	end
	return rewards
end

function Gamemode_Boss:initializeStats(hero)
end

function Gamemode_Boss:OnEntityHurt(keys)
end

function Gamemode_Boss:OnHeroInGame(hero)
	if not DEBUG_HEROES_START_WITH_ALL_ABILITIES then
		local starting_craft = hero:GetAbilityByIndex(0)
		local s_craft = hero:GetAbilityByIndex(4)
		if starting_craft then self:HeroLearnAbility(starting_craft) end
		if s_craft then self:HeroLearnAbility(s_craft) end
	else
		for k,ability in pairs(getAllAbilities(hero)) do
			self:HeroLearnAbility(ability)
		end
	end

	hero:ModifyGold(STARTING_GOLD, true, 17)

	if GameMode:HaveAllPlayersPicked() then
		self:BeginGamemode()
	end
end

function Gamemode_Boss:HeroLearnAbility(ability)
	local activated = ability:IsActivated()
	ability:SetActivated(true)
	ability:SetLevel(ability:GetMaxLevel())
	ability:SetActivated(activated)
end

function Gamemode_Boss:BeginGamemode()
	self.currently_on_path = nil
	self:SetupPaths()
	CustomGameEventManager:Send_ServerToAllClients("path_choice_window_start", {path_rewards = self:GetCraftRewards(), path_count = PATHS_COUNT, paths_completed = self.paths_completed})
	self:CheckForArenaTrigger()
	self:ApplyRegenBuff()
	Music:SwitchMusic(MUSIC_TYPE_EXPLORING)
end

function Gamemode_Boss:ApplyRegenBuff()
	for k,hero in pairs(getAllHeroes()) do
		hero:AddNewModifier(hero, nil, "modifier_boss_out_of_combat_regen", {})
	end
end

function Gamemode_Boss:RemoveRegenBuff()
	for k,hero in pairs(getAllHeroes()) do
		hero:RemoveModifierByName("modifier_boss_out_of_combat_regen")
	end
end

function Gamemode_Boss:CheckForArenaTrigger()
	Timers:CreateTimer(0, function()
		if self.state == EXPLORING and self:HeroInRangeOfArena() then
			self:StartEncounter()
		end
		return 1/4
	end)
end

function Gamemode_Boss:HeroInRangeOfArena()
	return #self:HeroesInRangeOfPoint(self:GetNextArenaPoint(), ARENA_TRIGGER_RANGE) > 0
end

function Gamemode_Boss:ClosestHeroToPoint(point, max_range)
	local heroes = self:HeroesInRangeOfPoint(point, max_range)
	local closest_hero = nil
	for k,hero in pairs(heroes) do
		if closest_hero == nil or distanceBetween(hero:GetAbsOrigin(), point) < distanceBetween(closest_hero:GetAbsOrigin(), point) then
			closest_hero = hero
		end
	end
	return closest_hero
end

function Gamemode_Boss:HeroesInRangeOfPoint(point, range)
	local heroes = {}
	for k,hero in pairs(getAllLivingHeroes()) do
		if distanceBetween(hero:GetAbsOrigin(), point) <= range then
			table.insert(heroes, hero)
		end
	end
	return heroes
end

function Gamemode_Boss:GetNextArenaPoint()
	return Entities:FindByName(nil, "path_"..self.currently_on_path.."_arena_"..self.current_path_progress + 1):GetAbsOrigin()
end

function Gamemode_Boss:GetMainSpawnPoint()
	return Entities:FindByClassname(nil, "info_player_start_goodguys"):GetAbsOrigin()
end

function Gamemode_Boss:StartEncounter()
	self.state = ENCOUNTER
	local arena_center = self:GetNextArenaPoint()
	self:TeleportFarawayHeroes(arena_center)
	local enemy_group = self:GetNextEnemyGroup()
	self.active_enemies = {}
	self:SpawnEnemies(enemy_group.mobs)
	self:CreateArenaWalls(enemy_group.arena_size)
	self.time_encounter_started = GameRules:GetGameTime()
	self:RemoveRegenBuff()
	self:StartForcingUnitsInsideArena()
	self.brave_points = 0

	triggerModifierEventOnAll("encounter_started", {})

	CustomGameEventManager:Send_ServerToAllClients("update_brave_points", {brave_points = self.brave_points})
	CustomGameEventManager:Send_ServerToAllClients("encounter_started", {})
	CPRewards:UpdateCPConditionsWindow()

	if not self.active_boss then
		Music:SwitchMusic(MUSIC_TYPE_COMBAT)
	else
		Music:SwitchMusic(MUSIC_TYPE_BOSS)
	end
end

function Gamemode_Boss:AddBravePoints(cp_gained)
	self.brave_points = self.brave_points + cp_gained
	CustomGameEventManager:Send_ServerToAllClients("update_brave_points", {brave_points = self.brave_points})
end

function Gamemode_Boss:SpendBravePoints(points)
	self.brave_points = self.brave_points - points
	CustomGameEventManager:Send_ServerToAllClients("update_brave_points", {brave_points = self.brave_points})
end

function Gamemode_Boss:StartForcingUnitsInsideArena()
	Timers:CreateTimer("force_units_inside_arena", {
		endTime = 0.1,
		callback = function()
			for k,hero in pairs(getAllHeroes()) do
				if distanceBetween(hero:GetAbsOrigin(), self:GetNextArenaPoint()) > self:GetNextEnemyGroup().arena_size then
					self:ForceUnitInsideArena(hero)
				end
			end
			for k,enemy in pairs(self.active_enemies) do
				if IsValidAlive(enemy) and distanceBetween(enemy:GetAbsOrigin(), self:GetNextArenaPoint()) > self:GetNextEnemyGroup().arena_size then
					self:ForceUnitInsideArena(enemy)
				end
			end
			return 0.1
		end
	})
end

function Gamemode_Boss:ForceUnitInsideArena(unit)
	local direction = (self:GetNextArenaPoint() - unit:GetAbsOrigin()):Normalized()
	local distance = distanceBetween(unit:GetAbsOrigin(), self:GetNextArenaPoint()) - self:GetNextEnemyGroup().arena_size + 150 -- plus a bit of a grace area to make sure units get over the arena walls
	FindClearSpaceForUnit(unit, unit:GetAbsOrigin() + direction * distance, true)
end

function Gamemode_Boss:StopForcingUnitsInsideArena()
	Timers:RemoveTimer("force_units_inside_arena")
end

function Gamemode_Boss:SpawnEnemies(enemy_types)
	for enemy_type,count in pairs(enemy_types) do
		for i=1,count do
			self:SpawnEnemy(enemy_type, self:GetNextArenaPoint())
		end
	end
end

function Gamemode_Boss:SpawnEnemy(unit_name, location)
	-- print("spawning unit: ", unit_name)
	local unit = CreateUnitByName(unit_name, location, true, nil, nil, DOTA_TEAM_BADGUYS)
	unit:AddNewModifier(unit, nil, "modifier_"..unit_name:sub(string.len("trailsadventure_mob_") + 1).."_reward", {})
	unit:AddNewModifier(unit, nil, "modifier_counterhit_passive", {})
	if unit:GetUnitName():find("boss") then
		CustomGameEventManager:Send_ServerToAllClients("boss_begin", {unit_id = unit:GetUnitName()})
		self.active_boss = unit
		unit:AddNewModifier(unit, nil, "modifier_boss_hp_tracker", {})
		self:StartSpawningCPOrbs()
	end
	table.insert(self.active_enemies, unit)
	return unit
end

function Gamemode_Boss:StartSpawningCPOrbs()
	Timers:CreateTimer("spawn_cp_orbs", {
		endTime = TIME_BETWEEN_CP_ORB_SPAWNS,
		callback = function()
			for i=1,CP_ORBS_PER_SPAWN do
				local location = randomPointInCircle(self:GetNextArenaPoint(), self:GetNextEnemyGroup().arena_size)
				self:CreateCPOrb(location)
			end
			return TIME_BETWEEN_CP_ORB_SPAWNS
		end
	})
end

function Gamemode_Boss:CreateCPOrb(location)
	local orb_particle = ParticleManager:CreateParticle("particles/econ/items/outworld_devourer/od_shards_exile/od_shards_exile_prison_top_orb_flare.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(orb_particle, 0, location)

	local update_interval = 1/30
	local time_elapsed = 0
	Timers:CreateTimer(0, function()
		local hero = self:ClosestHeroToPoint(location, ORB_PICKUP_RANGE)
		if hero then
			CPRewards:RewardCP(hero, nil, CP_PER_ORB)
			ParticleManager:DestroyParticle(orb_particle, false)
		else
			time_elapsed = time_elapsed + update_interval
			if time_elapsed < CP_ORB_DURATION then
				return update_interval
			else
				ParticleManager:DestroyParticle(orb_particle, false)
			end
		end
	end)
end

function Gamemode_Boss:StopSpawningCPOrbs()
	Timers:RemoveTimer("spawn_cp_orbs")
end

function Gamemode_Boss:CreateArenaWalls(radius)
	self.active_arena_wall = {}
	self.active_arena_wall.entities = {}
	local center = self:GetNextArenaPoint()
	local perimeter = math.pi * 2 * radius
	local wall_segments = perimeter / 40

	for k,point in pairs(pointsAroundCenter(center, radius, wall_segments)) do
		table.insert(self.active_arena_wall.entities, SpawnEntityFromTableSynchronous("point_simple_obstruction", {origin = point}))
	end

	local particle = ParticleManager:CreateParticle("particles/bosses/arena_barrier.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, center)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius,0,0))
	self.active_arena_wall.particle = particle
end

function Gamemode_Boss:RemoveArenaWalls()
	-- print("[BOSS] Removing Arena Walls")
	ParticleManager:DestroyParticle(self.active_arena_wall.particle, false)
	for k,entity in pairs(self.active_arena_wall.entities) do
		entity:RemoveSelf()
	end
	self.active_arena_wall = nil
end

function Gamemode_Boss:GetNextEnemyGroup()
	local enemy_group = self.paths[self.currently_on_path].groups[self.current_path_progress + 1]

	if not enemy_group.mobs then
		local boss = enemy_group.boss
		enemy_group = enemy_group[tostring(#self.paths_completed + 1)]
		enemy_group.mobs[boss] = 1
	end

	return enemy_group
end

function Gamemode_Boss:GetCraftRewards()
	local rewards = {}
	for k,path in pairs(self.paths) do
		local crafts = {}
		for hero,ability in pairs(path.rewards) do
			-- print(ability, ability.GetAbilityName)
			crafts[hero:entindex()] = ability
		end
		table.insert(rewards, crafts)
	end
	-- DeepPrintTable(rewards)
	return rewards
end

function Gamemode_Boss:OnEntityKilled(keys)
	local unit = EntIndexToHScript(keys.entindex_killed)
	local killer = nil
	if keys.entindex_attacker ~= nil then killer = EntIndexToHScript(keys.entindex_attacker) end

	if self.state == ENCOUNTER then
		if unit:IsRealHero() then
			local living_heroes = 0
			for k,hero in pairs(getAllHeroes()) do
				if hero:IsAlive() or hero.reviving then
					living_heroes = living_heroes + 1
				end
			end

			if living_heroes == 0 then
				-- party died like scrubs? idk
				GameRules:SendCustomMessage("#Party_Wiped", 0, 0)
				self:EndEncounter(RESULT_DEFEAT)
			end
		else
			if killer and killer:IsRealHero() then
				CPRewards:RewardCP(killer, unit)
			end
			if self:GetLivingEnemyCount() == 0 then
				self:EndEncounter(RESULT_VICTORY)
			end
		end
	end
end

function Gamemode_Boss:EndEncounter(result)
	self.state = EXPLORING
	self:RemoveLivingEnemies()
	self:StopSpawningCPOrbs()
	self:StopForcingUnitsInsideArena()
	if self:EnemyGroupIsBoss(self:GetNextEnemyGroup()) then
		CustomGameEventManager:Send_ServerToAllClients("boss_end", {})
	end
	if result == RESULT_VICTORY then
		self:GrantEncounterRewards(self:GetNextEnemyGroup())
		if self.currently_on_path then
			self.current_path_progress = self.current_path_progress + 1
		end
	end
	Timers:CreateTimer(ENCOUNTER_END_DELAY, function()
		self:ReviveDeadHeroes()
		self:RemoveArenaWalls()
		if result == RESULT_DEFEAT then
			self:TeleportHeroesToStart()
		end
		self:ApplyRegenBuff()
	end)

	self.brave_points = 0
	CustomGameEventManager:Send_ServerToAllClients("encounter_ended", {})

	Music:SwitchMusic(MUSIC_TYPE_EXPLORING)
end

function Gamemode_Boss:GrantEncounterRewards(enemy_group)
	local cp = enemy_group.cp_reward
	local gold = enemy_group.gold_reward
	local time = GameRules:GetGameTime() - self.time_encounter_started
	local goal_time = enemy_group.swift_victory_time
	self.time_encounter_started = nil

	CustomGameEventManager:Send_ServerToAllClients("show_encounter_rewards", {gold = gold, cp = cp, time = time, goal_time = goal_time, mechanics_percent = "?"})

	self:GrantGoldToAllHeroes(gold)
	CPRewards:RewardCP(nil, nil, cp)
	if self:EnemyGroupIsBoss(enemy_group) then
		self:RewardCrafts()
		self:EndPath()
	end
end

function Gamemode_Boss:RewardCrafts()
	local crafts = self.paths[self.currently_on_path].rewards
	for k,hero in pairs(getAllHeroes()) do
		hero:FindAbilityByName(crafts[hero]):SetLevel(1)
	end
end

function Gamemode_Boss:EndPath()
	CustomGameEventManager:Send_ServerToAllClients("path_end", {})

	self.paths_completed[self.currently_on_path] = true
	self.currently_on_path = nil
	CustomGameEventManager:Send_ServerToAllClients("path_choice_window_start", {path_rewards = self:GetCraftRewards(), path_count = PATHS_COUNT, paths_completed = self.paths_completed})

	self.state = SHOPPING
	self.current_path_progress = 0
end

function Gamemode_Boss:EnemyGroupIsBoss(enemy_group)
	for mob_name,count in pairs(enemy_group.mobs) do
		if mob_name:find("trailsadventure_mob_boss_") then
			return true
		end
	end
	return false
end

function Gamemode_Boss:GrantGoldToAllHeroes(amount)
	for k,hero in pairs(getAllHeroes()) do
		hero:ModifyGold(amount, true, 17)
	end
end

function Gamemode_Boss:RemoveLivingEnemies()
	for k,unit in pairs(self.active_enemies) do
		if IsValidAlive(unit) then
			unit:ForceKill(false)
		end
	end
	self.active_enemies = nil
	self.active_boss = nil
end

function Gamemode_Boss:ReviveDeadHeroes()
	for k,hero in pairs(getAllHeroes()) do
		if not hero:IsAlive() then
			reviveHero(hero, nil, hero:GetMaxMana())
		end
	end
end

function Gamemode_Boss:TeleportFarawayHeroes(arena_point)
	for k,hero in pairs(getAllHeroes()) do
		if distanceBetween(hero:GetAbsOrigin(), arena_point) > self:GetNextEnemyGroup().arena_size then
			FindClearSpaceForUnit(hero, arena_point, true)
		end
	end
end

function Gamemode_Boss:TeleportHeroesToStart()
	for k,hero in pairs(getAllHeroes()) do
		FindClearSpaceForUnit(hero, self:GetMainSpawnPoint(), true)
	end
end

function Gamemode_Boss:GetLivingEnemyCount()
	local count = 0
	for k,enemy in pairs(self.active_enemies) do
		if IsValidAlive(enemy) then
			count = count + 1
		end
	end
	return count
end









function Gamemode_Boss:CreateFOWViewersForTeam(team)
	local cp = self:GetArenaPoint("center") + Vector(0, 0, 512)

	local v = Vision(team)
	v:Add(cp, 1400)
	v:Add(cp + Vector(256, 0, 0), 1400)
	v:Add(cp + Vector(-256, 0, 0), 1400)

	return v
end

function Gamemode_Boss:CreateFOWViewers()
	self.arena_vision = self:CreateFOWViewersForTeam(DOTA_TEAM_GOODGUYS)
	self.boss_arena_vision = self:CreateFOWViewersForTeam(DOTA_TEAM_BADGUYS)
end

function Gamemode_Boss:RemoveFOWViewers()
	self.arena_vision:RemoveAll()
	self.boss_arena_vision:RemoveAll()
end

function Gamemode_Boss:SlowTeleportToLocation(unit, target_pos)
	local start_fx = ParticleManager:CreateParticle("particles/items2_fx/teleport_start.vpcf", PATTACH_ABSORIGIN, unit)
	ParticleManager:SetParticleControl(start_fx, 0, unit:GetAbsOrigin())
	ParticleManager:SetParticleControl(start_fx, 1, unit:GetAbsOrigin())
	ParticleManager:SetParticleControl(start_fx, 2, Vector(0, 0.5, 1))
	
	local end_fx = ParticleManager:CreateParticle("particles/items2_fx/teleport_end.vpcf", PATTACH_ABSORIGIN, unit)
	ParticleManager:SetParticleControl(end_fx, 0, target_pos)
	ParticleManager:SetParticleControl(end_fx, 1, target_pos)
	ParticleManager:SetParticleControl(end_fx, 2, Vector(0, 0.5, 1))

	unit:EmitSound("Portal.Loop_Disappear")

	Timers:CreateTimer(3, function()
		FindClearSpaceForUnit(unit, target_pos, true)
		unit:StopSound("Portal.Loop_Disappear")
		unit:EmitSound("Portal.Hero_Appear")

		ParticleManager:DestroyParticle(start_fx, false)
		ParticleManager:ReleaseParticleIndex(start_fx)
		ParticleManager:DestroyParticle(end_fx, false)
		ParticleManager:ReleaseParticleIndex(end_fx)
	end)
end
-- BOSSRUSH_NETTABLE = "bossrush"

require "libraries/animations"
require "libraries/util"
require "gamemodes/modifier_boss_vulnerable"
require "combat_links"
require "game_functions"

LinkLuaModifier("modifier_boss_vulnerable", "gamemodes/modifier_boss_vulnerable.lua", LUA_MODIFIER_MOTION_NONE)

PATHS_COUNT = 4
GROUPS_PER_PATH = 2

SHOPPING = 0
EXPLORING = 1
ENCOUNTER = 2

ARENA_TRIGGER_RANGE = 400

if Gamemode_Boss == nil then
	Gamemode_Boss = class({})
end

function Gamemode_Boss:Initialize()
	-- ListenToGameEvent('entity_killed', Dynamic_Wrap(Gamemode_Boss, 'OnUnitKilled'), self)

	-- local base_vision = Vision(DOTA_TEAM_GOODGUYS)
	-- base_vision:Add(Vector(0, 0, 0), 1400)

	-- CustomGameEventManager:RegisterListener("preboss_ready", WrapMemberMethod(self.OnHeroReady, self))
	-- Convars:RegisterCommand("br_force_start", WrapMemberMethod(self.CCmd_ForceStart, self), "Forces the game to start even if not all players have readied up.", FCVAR_CHEAT )
	-- Convars:RegisterCommand("br_test_dmgmeter", WrapMemberMethod(self.CCmd_TestDmgMeter, self), "", FCVAR_CHEAT )
	CustomGameEventManager:RegisterListener("path_button_pressed", WrapMemberMethod(self.OnPathButtonPressed, self))
	self.state = SHOPPING
	self.current_path_progress = 0
end

function Gamemode_Boss:OnPathButtonPressed(eventSourceIndex, args)
	local path = args.pathNumber
	if not self.currently_on_path then
		self.state = EXPLORING
		self.currently_on_path = path
		CustomGameEventManager:Send_ServerToAllClients("path_choice_window_hide", {})
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
		path_groups[GROUPS_PER_PATH + 1] = {group = self:GetRandomUnassignedBoss(bosses_kv, assigned_bosses), cleared = false}
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
		if not assigned_bosses[k] then
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

function Gamemode_Boss:StartRound(round)
	self:StartBoss(0)
end

function Gamemode_Boss:StartBoss(boss_index)
	local arena_id = "lake"
	local unit_id = "npc_dota_boss_troll"

	-- DamageMeter:Reset()

	self.currentArena = arena_id
	-- self:CreateFOWViewers()

	PrecacheUnitByNameAsync(unit_id, function()
		-- Spawn the boss
		local boss_unit = CreateUnitByName(unit_id, self:GetArenaPoint("boss"), true, nil, nil, DOTA_TEAM_BADGUYS)
		-- BossAI:Start(boss_unit)
		self.boss_unit = boss_unit
		for i=0,15 do
			local ability = boss_unit:GetAbilityByIndex(i)
			if ability then 
				ability:SetLevel(1)
			end
		end
		boss_unit.enrage_state = 0

		-- Teleport heroes to the encounter
		-- local tp_target = self:GetArenaPoint("herospawn")

		local hero_idx = 0
		for _,hero in ipairs(getAllHeroes()) do
			-- local hero_tp_target = tp_target + Vector((hero_idx + 0.5 - #getAllHeroes() / 2.0) * 200, 0, 0)

			-- AddFOWViewer(DOTA_TEAM_GOODGUYS, hero_tp_target, 500, 3.1, false)
			-- PlayerResource:SetCameraTarget(hero:GetPlayerID(), hero)
			-- self:SlowTeleportToLocation(hero, hero_tp_target)

			-- Clear cooldowns, too
			-- for i = 0, 5 do
			-- 	local ability = hero:GetAbilityByIndex(i)
			-- 	if ability then
			-- 		ability:EndCooldown()
			-- 	end
			-- end

			hero_idx = hero_idx + 1
		end

		-- Lock camera while teleporting
		-- Timers:CreateTimer(3.1, function()
		-- 	for _,hero in ipairs(HeroList:GetAllHeroes()) do
		-- 		PlayerResource:SetCameraTarget(hero:GetPlayerID(), nil)
		-- 	end

			CustomGameEventManager:Send_ServerToAllClients("boss_begin", { unit_id = boss_unit:GetUnitName() })
		-- 	self.encounterStartTime = GameRules:GetGameTime()
		-- 	self.encounterDeaths = 0
		-- 	self.encounterConsumablesUsed = 0
		-- end)
	end)
end

function Gamemode_Boss:GetArenaPoint(name)
	local ent = Entities:FindByName(nil, self.currentArena .. "_" .. name)
	if ent ~= nil then
		return ent:GetAbsOrigin()
	else
		return Vector(0, 0, 0)
	end
end

function Gamemode_Boss:initializeStats(hero)
end

function Gamemode_Boss:OnEntityHurt(keys)
	local target = EntIndexToHScript(keys.entindex_killed)
	if target == self.boss_unit then
		local health_percent = target:GetHealth() / target:GetMaxHealth() * 100
		CustomGameEventManager:Send_ServerToAllClients("boss_health_changed", {percent = health_percent})
		self:UpdateEnrageZone(health_percent)
	end
end

function Gamemode_Boss:UpdateEnrageZone(health_percent)
	local new_enrage_zone = 4 - math.ceil(health_percent / 25)
	if new_enrage_zone > self.boss_unit.enrage_state then
		self.boss_unit.enrage_state = self.boss_unit.enrage_state + 1
		for i=0,15 do
			local ability = self.boss_unit:GetAbilityByIndex(i)
			if ability then 
				ability:SetLevel(ability:GetLevel() + 1)
			end
		end

		ParticleManager:CreateParticle("particles/bosses/enrage_trigger.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.boss_unit)
	end
end

function Gamemode_Boss:OnEntityKilled(keys)
end

function Gamemode_Boss:MakeBossVulnerable(boss)
	self.boss_unit:AddNewModifier(self.boss_unit, nil, "modifier_boss_vulnerable", {duration = VULNERABILITY_DURATION})
end

function Gamemode_Boss:EnhanceHero(damage_dealt_table)
	StartAnimation(self.boss_unit, {duration=44 / 30, activity=ACT_DOTA_DISABLED, rate=1})

	local highest_hero = nil
	for hero,damage in pairs(damage_dealt_table) do
		if highest_hero == nil or damage > damage_dealt_table[highest_hero] then
			highest_hero = hero
		end
	end

	applyEnhancedState(highest_hero, self.boss_unit)
end

function Gamemode_Boss:OnHeroInGame(hero)
	hero:GetAbilityByIndex(0):SetLevel(1)
	hero:GetAbilityByIndex(4):SetLevel(1)

	if GameMode:HaveAllPlayersPicked() then
		self:BeginGamemode()
	end
end

function Gamemode_Boss:BeginGamemode()
	self.currently_on_path = nil
	self:SetupPaths()
	CustomGameEventManager:Send_ServerToAllClients("path_choice_window_start", {path_rewards = self:GetCraftRewards(), path_count = PATHS_COUNT})
	self:CheckForArenaTrigger()
end

function Gamemode_Boss:CheckForArenaTrigger()
	Timers:CreateTimer(0, function()
		if self.state == EXPLORING and self:HeroInRangeOfArena() then
			self:StartEncounter()
			self:TeleportFarawayHeroes()
		end
		return 1/4
	end)
end

function Gamemode_Boss:HeroInRangeOfArena()
	for k,hero in pairs(getAllHeroes()) do
		if distanceBetween(hero:GetAbsOrigin(), self:GetNextArenaPoint()) <= ARENA_TRIGGER_RANGE then
			return true
		end
	end
	return false
end

function Gamemode_Boss:GetNextArenaPoint()
	return Entities:FindByName(nil, "path_"..self.currently_on_path.."_arena_"..self.current_path_progress + 1):GetAbsOrigin()
end

function Gamemode_Boss:StartEncounter()
	self.state = ENCOUNTER
	local arena_center = self:GetNextArenaPoint()
	local enemy_group = self:GetNextEnemyGroup()
	self:SpawnEnemies(enemy_group.mobs)
	self:CreateArenaWalls(enemy_group.arena_size)
end

function Gamemode_Boss:SpawnEnemies(enemy_types)
	for enemy_type,count in pairs(enemy_types) do
		for i=1,count do
			local unit = CreateUnitByName(enemy_type, self:GetNextArenaPoint(), true, nil, nil, DOTA_TEAM_BADGUYS)
		end
	end
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

function Gamemode_Boss:GetNextEnemyGroup()
	return self.paths[self.currently_on_path].groups[self.current_path_progress + 1]
end

function Gamemode_Boss:TeleportFarawayHeroes()
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

	-- ApplySpecialModifier("modifier_bossrush_teleporting", unit)

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
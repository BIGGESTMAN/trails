-- BOSSRUSH_NETTABLE = "bossrush"

require "libraries/animations"
require "gamemodes/modifier_boss_vulnerable"
require "combat_links"

LinkLuaModifier("modifier_boss_vulnerable", "gamemodes/modifier_boss_vulnerable.lua", LUA_MODIFIER_MOTION_NONE)

VULNERABLE_PROC_THRESHOLD_FACTOR = .1
VULNERABILITY_DURATION = 10

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
end

function Gamemode_Boss:SetRevivesLeft(revives)
	self.revivesLeft = revives
	CustomNetTables:SetTableValue(BOSSRUSH_NETTABLE, "general", { revives = revives })
end

function Gamemode_Boss:CCmd_ForceStart()
	CustomGameEventManager:Send_ServerToAllClients("preboss_all_ready", {})
	self:StartNextBoss()
end

function Gamemode_Boss:CCmd_TestDmgMeter()
	DamageMeter:SimulateTest()
end

function Gamemode_Boss:OnHeroInGame(hero)
	DebugPrint("Hero is in game for the first time: " .. hero:GetUnitName())
	
	-- Starting ability points
	hero:SetAbilityPoints(0)
	for i = 0, 10 do
		local ability = hero:GetAbilityByIndex(i)
		if ability then
			ability:SetLevel(1)
		end
	end

	-- Starting items (note that gold is overridden by custom hero select if enabled)
	hero:SetGold(0, false)
	hero:SetGold(BOSSRUSH_HERO_START_GOLD, true)
	for _,item_id in pairs(BOSSRUSH_HERO_START_ITEMS) do
		hero:AddItem(CreateItem(item_id, hero, hero))
	end

	-- For debugging talents
	-- hero:AddExperience(3500, 0, false, true)

	hero.bossrush_preboss_ready = false
	if GameRules:State_Get() ~= DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		Timers.CreateTimer(0.2, function()
			CustomGameEventManager:Send_ServerToPlayer(hero:GetOwner(), "preboss_start", {})
		end)
	end
end

function Gamemode_Boss:OnGameInProgress()
	for i = 0, PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS) do
		local player = PlayerResource:GetPlayer(PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_GOODGUYS, i))
		CustomGameEventManager:Send_ServerToAllClients("preboss_start", {})
	end
end

function Gamemode_Boss:OnHeroReady(eventSourceIndex, args)
	local player = EntIndexToHScript(eventSourceIndex)
	local hero = player:GetAssignedHero()

	DebugPrint("player is ready")
	hero.bossrush_preboss_ready = true

	if self:AreAllHeroesReady() then
		CustomGameEventManager:Send_ServerToAllClients("preboss_all_ready", {})

		self:StartCountdown(3, "quest_time_bossteleport", function()
			self:StartNextBoss()
		end)
	end
end

function Gamemode_Boss:StartNextBoss()
	self:StartBoss(self.nextWaveIndex)
end

function Gamemode_Boss:StartCountdown(time, title, callback)
	CustomGameEventManager:Send_ServerToAllClients("quest_start_timer", { title = title, time = time })
	Timers:CreateTimer(time, callback)
end

function Gamemode_Boss:AreAllHeroesReady()
	local player_count = PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS)
	for i = 0, player_count - 1 do
		local player = PlayerResource:GetPlayer(i)
		if not CustomHeroSelect:HasSelectedHero(player) then
			DebugPrint("Player " .. i .. " has not selected a hero yet")
			return false
		end
		
		local hero = player:GetAssignedHero()
		if hero.bossrush_preboss_ready == false then
			DebugPrint("Hero " .. hero:GetUnitName() .. " is not ready yet")
			return false
		end
	end

	return true
end

function Gamemode_Boss:Victory()
	CustomGameEventManager:Send_ServerToAllClients("boss_victory", {})

	-- Kill stragglers
	for _,entity in ipairs(Entities:FindAllByClassname("npc_dota_creature")) do
		if entity:IsAlive() then
			entity:ForceKill(false)
		end
	end

	-- Revive dead heroes and apply victory cry buff so they don't die again
	for _,hero in ipairs(HeroList:GetAllHeroes()) do
		if not hero:IsAlive() then
			UTIL_Remove(hero.tombstone)
			hero.tombstone = nil
			hero:RespawnUnit()
		end

		ApplySpecialModifier("modifier_bossrush_victorycry", hero)
	end

	Timers:CreateTimer(1.0, function()
		CustomGameEventManager:Send_ServerToAllClients("announce_large", {
			string_id = "announce_victory"
		})

		Timers:CreateTimer(1.0, function()
			self:GiveVictoryReward()
			DamageMeter:ShowToPlayers()

			Timers:CreateTimer(6.0, function()
				local hero_idx = 0
				local tp_target = Entities:FindByName(nil, "homebase_tp"):GetAbsOrigin()
				for _,hero in ipairs(HeroList:GetAllHeroes()) do
					local hero_tp_target = tp_target + Vector((hero_idx + 0.5 - HeroList:GetHeroCount() / 2.0) * 200, 0, 0)
					PlayerResource:SetCameraTarget(hero:GetPlayerID(), hero)
					SlowTeleportToLocation(hero, hero_tp_target)
					hero_idx = hero_idx + 1
				end

				Timers:CreateTimer(3.1, function()
					for _,hero in ipairs(HeroList:GetAllHeroes()) do
						PlayerResource:SetCameraTarget(hero:GetPlayerID(), nil)
					end

					self.nextWaveIndex = self.nextWaveIndex + 1
					self:BeginPrebossState()
				end)
			end)
		end)
	end)
end

function Gamemode_Boss:RegisterConsumableUsed()
	if self.encounterConsumablesUsed ~= nil then
		self.encounterConsumablesUsed = self.encounterConsumablesUsed + 1
	end
end

function Gamemode_Boss:GiveVictoryReward()
	-- Assess total performance
	local encounterTime = (GameRules:GetGameTime() - self.encounterStartTime)

	local seconds_over_par = math.max(0, encounterTime - tonumber(self.activeBossKvData.par_time))
	local consumables_used = self.encounterConsumablesUsed
	local deaths = self.encounterDeaths

	local shitpoints = math.min(100, seconds_over_par * 1.2 + math.max(0, (consumables_used * 4) - 20) + deaths * 35)

	local cash_reward = math.floor(tonumber(self.activeBossKvData.reward_base) + (1 - (shitpoints / 100)) * tonumber(self.activeBossKvData.reward_extra))
	local xp_reward = math.floor(tonumber(self.activeBossKvData.xp_reward_base) + (1 - (shitpoints / 100)) * tonumber(self.activeBossKvData.xp_reward_extra))

	for _,hero in ipairs(HeroList:GetAllHeroes()) do
		-- Give gold and XP
		hero:ModifyGold(cash_reward, true, 0)
		hero:AddExperience(xp_reward, 0, false, false)

		-- Give soul shard
		-- hero:AddItem(CreateItem("item_bossrush_minor_soul", hero, hero))

		-- Level up
	end

	CustomGameEventManager:Send_ServerToAllClients("victory_reward", {
		rating = (100 - shitpoints),
		time = encounterTime,
		consumables_used = consumables_used,
		deaths = deaths,
		cash_reward = cash_reward,
		xp_reward = xp_reward
	})
end

function Gamemode_Boss:OnUnitKilled(args)
	local unit = EntIndexToHScript(args.entindex_killed)

	if unit == self.boss_unit then
		self:Victory()
	elseif unit:IsRealHero() then
		-- Hero died
		self.encounterDeaths = self.encounterDeaths + 1
	else
		-- DebugPrint("non-boss died")
	end
end

function Gamemode_Boss:_Revive()
	-- Remove surviving bosses and mooks
	for _,entity in ipairs(Entities:FindAllByClassname("npc_dota_creature")) do
		entity:RemoveSelf()
	end
	
	--GameMode:RespawnAndRestoreToCheckpoint()

	for hero_idx, hero in ipairs(HeroList:GetAllHeroes()) do
		UTIL_Remove(hero.tombstone)
		hero.tombstone = nil
		
		local hero_revive_target = Entities:FindByName(nil, "homebase_tp"):GetAbsOrigin() + Vector((hero_idx + 0.5 - HeroList:GetHeroCount() / 2.0) * 200, 0, 0)
		hero:SetRespawnPosition(hero_revive_target)
		hero:RespawnUnit()
		
		PlayerResource:SetCameraTarget(hero:GetPlayerID(), hero)
		
		FindClearSpaceForUnit(hero, hero_revive_target, true)

		Timers.CreateTimer(0.3, function()
			PlayerResource:SetCameraTarget(hero:GetPlayerID(), nil)
		end)
	end

	self:SetRevivesLeft(self.revivesLeft - 1)
	self:BeginPrebossState()
	DamageMeter:ShowToPlayers()
end

function Gamemode_Boss:OnAllHeroesKilled()
	if self.boss_unit then
		self.boss_unit.ai:BecomeIdle()

		CustomGameEventManager:Send_ServerToAllClients("boss_defeat", {})
		CustomGameEventManager:Send_ServerToAllClients("announce_large", {
			string_id = "announce_defeat"
		})

		-- This does not seem to be working
		EmitGlobalSound("DOTAMusic_Defeat_Radiant")

		Timers:CreateTimer(5.0, function()
			if self.revivesLeft > 0 then
				CustomGameEventManager:Send_ServerToAllClients("announce", { string_id = "announce_prepare_respawn" })
				EmitGlobalSound("DOTAMusic_Hero.Respawn")

				self:StartCountdown(5, "quest_time_reviving", function()
					self:_Revive()
				end)
			end
		end)
	end
end

function Gamemode_Boss:GetLivingEnemyCount()
end

function Gamemode_Boss:BeginPrebossState()
	CustomGameEventManager:Send_ServerToAllClients("preboss_start", {})

	for _, hero in pairs(HeroList:GetAllHeroes()) do
		hero.bossrush_preboss_ready = false
	end
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
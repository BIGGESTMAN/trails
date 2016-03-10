print ('[BAREBONES] barebones.lua' )

require "projectile_list"
require "filters"
require "combat_links"
require "game_functions"
require "custom_hero_select"
require "turn_bonuses"
require "round_recap"
require "round_manager"

LinkLuaModifier("modifier_interround_invulnerability", "modifier_interround_invulnerability.lua", LUA_MODIFIER_MOTION_NONE)

imported_model_characters = {}

-- GameRules Variables
ENABLE_HERO_RESPAWN = false              -- Should the heroes automatically respawn on a timer or stay dead until manually respawned
ALLOW_SAME_HERO_SELECTION = true        -- Should we let people select the same hero as each other

HERO_SELECTION_TIME = 1.0              -- How long should we let people select their hero?
PRE_GAME_TIME = 120.0                    -- How long after people select their heroes should the horn blow and the game start?
POST_GAME_TIME = 60.0                   -- How long should we let people look at the scoreboard before closing the server automatically?
TREE_REGROW_TIME = 60.0                 -- How long should it take individual trees to respawn after being cut down/destroyed?

GOLD_TICK_TIME = 0.6                    -- How long should we wait in seconds between gold ticks?

RECOMMENDED_BUILDS_DISABLED = false     -- Should we disable the recommened builds for heroes (Note: this is not working currently I believe)
CAMERA_DISTANCE_OVERRIDE = 1134.0        -- How far out should we allow the camera to go?  1134 is the default in Dota

MINIMAP_ICON_SIZE = 1                   -- What icon size should we use for our heroes?
MINIMAP_CREEP_ICON_SIZE = 1             -- What icon size should we use for creeps?
MINIMAP_RUNE_ICON_SIZE = 1              -- What icon size should we use for runes?

RUNE_SPAWN_TIME = 120                    -- How long in seconds should we wait between rune spawns?
CUSTOM_BUYBACK_COST_ENABLED = false      -- Should we use a custom buyback cost setting?
CUSTOM_BUYBACK_COOLDOWN_ENABLED = false  -- Should we use a custom buyback time?
BUYBACK_ENABLED = false                 -- Should we allow people to buyback when they die?

DISABLE_FOG_OF_WAR_ENTIRELY = false      -- Should we disable fog of war entirely for both teams?
USE_STANDARD_HERO_GOLD_BOUNTY = false    -- Should we give gold for hero kills the same as in Dota, or allow those values to be changed?

USE_CUSTOM_TOP_BAR_VALUES = true        -- Should we do customized top bar values or use the default kill count per team?
TOP_BAR_VISIBLE = true                  -- Should we display the top bar score/count at all?
SHOW_KILLS_ON_TOPBAR = true             -- Should we display kills only on the top bar? (No denies, suicides, kills by neutrals)  Requires USE_CUSTOM_TOP_BAR_VALUES

ENABLE_TOWER_BACKDOOR_PROTECTION = true  -- Should we enable backdoor protection for our towers?
REMOVE_ILLUSIONS_ON_DEATH = false       -- Should we remove all illusions if the main hero dies?
DISABLE_GOLD_SOUNDS = false             -- Should we disable the gold sound when players get gold?

END_GAME_ON_KILLS = false                -- Should the game end after a certain number of kills?
KILLS_TO_END_GAME_FOR_TEAM = 50         -- How many kills for a team should signify an end of game?

USE_CUSTOM_HERO_LEVELS = false           -- Should we allow heroes to have custom levels?
MAX_LEVEL = 1                          -- What level should we let heroes get to?

CHEATY_STUFF = GetMapName() ~= "dota"

MAX_ABILITY_LEVELS = CHEATY_STUFF
STARTING_ITEMS = false
FREEEEEEEE_MONEY = CHEATY_STUFF
UNIVERSAL_SHOP_MODE = false             -- Should the main shop contain Secret Shop items as well as regular items
GOLD_PER_TICK = 0                 		    -- How much gold should players get per tick?
USE_CUSTOM_XP_VALUES = CHEATY_STUFF             -- Should we use custom XP values to level up heroes, or the default Dota numbers?

MUSIC = false

ROUNDS_TO_WIN = 5
ROUND_END_DELAY = 3
ROUND_START_DELAY = 3

BASE_GOLD_PER_ROUND = 500
GOLD_INCREASE_PER_ROUND = 500
SHOPPING_TIME = 60



-- Fill this table up with the required XP per level if you want to change it
if CHEATY_STUFF then
	XP_PER_LEVEL_TABLE = {}
	for i=1,MAX_LEVEL do
		XP_PER_LEVEL_TABLE[i] = i * 100
	end
end

-- Generated from template
if GameMode == nil then
	print ( '[BAREBONES] creating barebones game mode' )
	GameMode = class({})
end

-- This function initializes the game mode and is called before anyone loads into the game
-- It can be used to pre-initialize any values/tables that will be needed later
function GameMode:InitGameMode()
	GameMode = self
	print('[BAREBONES] Starting to load Barebones gamemode...')

	-- Setup rules
	GameRules:SetHeroRespawnEnabled( ENABLE_HERO_RESPAWN )
	GameRules:SetUseUniversalShopMode( UNIVERSAL_SHOP_MODE )
	GameRules:SetSameHeroSelectionEnabled( ALLOW_SAME_HERO_SELECTION )
	GameRules:SetHeroSelectionTime( HERO_SELECTION_TIME )
	if CHEATY_STUFF then
		GameRules:SetPreGameTime(0)
	else
		GameRules:SetPreGameTime(PRE_GAME_TIME)
	end
	GameRules:SetPostGameTime( POST_GAME_TIME )
	GameRules:SetTreeRegrowTime( TREE_REGROW_TIME )
	GameRules:SetUseCustomHeroXPValues ( USE_CUSTOM_XP_VALUES )
	if FREEEEEEEE_MONEY then
		GameRules:SetGoldPerTick(GOLD_PER_TICK)
	else
		GameRules:SetGoldPerTick(1)
	end
	GameRules:SetGoldTickTime(GOLD_TICK_TIME)
	GameRules:SetRuneSpawnTime(RUNE_SPAWN_TIME)
	GameRules:SetUseBaseGoldBountyOnHeroes(USE_STANDARD_HERO_GOLD_BOUNTY)
	GameRules:SetHeroMinimapIconScale( MINIMAP_ICON_SIZE )
	GameRules:SetCreepMinimapIconScale( MINIMAP_CREEP_ICON_SIZE )
	GameRules:SetRuneMinimapIconScale( MINIMAP_RUNE_ICON_SIZE )
	print('[BAREBONES] GameRules set')

	-- Listeners - Event Hooks
	-- All of these events can potentially be fired by the game, though only the uncommented ones have had
	-- Functions supplied for them.
	ListenToGameEvent('dota_player_gained_level', Dynamic_Wrap(GameMode, 'OnPlayerLevelUp'), self)
	ListenToGameEvent('dota_ability_channel_finished', Dynamic_Wrap(GameMode, 'OnAbilityChannelFinished'), self)
	ListenToGameEvent('dota_player_learned_ability', Dynamic_Wrap(GameMode, 'OnPlayerLearnedAbility'), self)
	ListenToGameEvent('entity_killed', Dynamic_Wrap(GameMode, 'OnEntityKilled'), self)
	ListenToGameEvent('player_connect_full', Dynamic_Wrap(GameMode, 'OnConnectFull'), self)
	ListenToGameEvent('player_disconnect', Dynamic_Wrap(GameMode, 'OnDisconnect'), self)
	ListenToGameEvent('dota_item_purchased', Dynamic_Wrap(GameMode, 'OnItemPurchased'), self)
	ListenToGameEvent('dota_item_picked_up', Dynamic_Wrap(GameMode, 'OnItemPickedUp'), self)
	ListenToGameEvent('last_hit', Dynamic_Wrap(GameMode, 'OnLastHit'), self)
	ListenToGameEvent('dota_non_player_used_ability', Dynamic_Wrap(GameMode, 'OnNonPlayerUsedAbility'), self)
	ListenToGameEvent('player_changename', Dynamic_Wrap(GameMode, 'OnPlayerChangedName'), self)
	ListenToGameEvent('dota_rune_activated_server', Dynamic_Wrap(GameMode, 'OnRuneActivated'), self)
	ListenToGameEvent('dota_player_take_tower_damage', Dynamic_Wrap(GameMode, 'OnPlayerTakeTowerDamage'), self)
	ListenToGameEvent('tree_cut', Dynamic_Wrap(GameMode, 'OnTreeCut'), self)
	ListenToGameEvent('entity_hurt', Dynamic_Wrap(GameMode, 'OnEntityHurt'), self)
	ListenToGameEvent('player_connect', Dynamic_Wrap(GameMode, 'PlayerConnect'), self)
	ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap(GameMode, 'OnAbilityUsed'), self)
	ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(GameMode, 'OnGameRulesStateChange'), self)
	ListenToGameEvent('npc_spawned', Dynamic_Wrap(GameMode, 'OnNPCSpawned'), self)
	ListenToGameEvent('dota_player_pick_hero', Dynamic_Wrap(GameMode, 'OnPlayerPickHero'), self)
	ListenToGameEvent('dota_team_kill_credit', Dynamic_Wrap(GameMode, 'OnTeamKillCredit'), self)
	ListenToGameEvent("player_reconnected", Dynamic_Wrap(GameMode, 'OnPlayerReconnect'), self)
	ListenToGameEvent("player_chat", Dynamic_Wrap(GameMode, 'OnPlayerChat'), self)

	-- Change random seed
	local timeTxt = string.gsub(string.gsub(GetSystemTime(), ':', ''), '0','')
	math.randomseed(tonumber(timeTxt))

	-- Initialized tables for tracking state
	self.vUserIds = {}
	self.vSteamIds = {}
	self.vBots = {}
	self.vBroadcasters = {}

	self.vPlayers = {}
	self.vRadiant = {}
	self.vDire = {}

	self.nRadiantKills = 0
	self.nDireKills = 0

	self.bSeenWaitForPlayers = false
	
	CustomHeroSelect:Initialize()

	RoundManager:Initialize()

	-- Commands can be registered for debugging purposes or as functions that can be called by the custom Scaleform UI
	--Convars:RegisterCommand( "command_example", Dynamic_Wrap(dotacraft, 'ExampleConsoleCommand'), "A console command example", 0 )

	print('[BAREBONES] Done loading Barebones gamemode!\n\n')
end

-- This function is called whenever any player sends a chat message to team or All
function GameMode:OnPlayerChat(keys)
	local teamonly = keys.teamonly
	local userID = keys.userid
	local playerID = self.vUserIds[userID]:GetPlayerID()
	local player = PlayerResource:GetPlayer(playerID)
	local hero = player:GetAssignedHero()

	local text = keys.text

	if text == "-die" then
		hero:Kill(nil, hero)
	elseif text == "-win" then
		RoundManager:EndRound(hero:GetTeam())
	elseif text == "-togglemusic" then
		if hero.music_playing == nil then
			self:StartMusicForPlayer(player)
		else
			self:StopMusicForPlayer(player)
		end
	elseif text == "-spawnbonus" then
		Turn_Bonuses:SpawnBonus(RoundManager.current_round)
	elseif text == "-maxcp" then
		modifyCP(hero, 200)
	end
end

mode = nil

-- This function is called 1 to 2 times as the player connects initially but before they
-- have completely connected
function GameMode:PlayerConnect(keys)
	print('[BAREBONES] PlayerConnect')
	DeepPrintTable(keys)

	if keys.bot == 1 then
		-- This user is a Bot, so add it to the bots table
		self.vBots[keys.userid] = 1
	end
end

-- This function is called once when the player fully connects and becomes "Ready" during Loading
function GameMode:OnConnectFull(keys)
	print ('[BAREBONES] OnConnectFull')
	DeepPrintTable(keys)
	GameMode:CaptureGameMode()

	local entIndex = keys.index+1
	-- The Player entity of the joining user
	local ply = EntIndexToHScript(entIndex)

	-- The Player ID of the joining player
	local playerID = ply:GetPlayerID()

	-- Update the user ID table with this user
	self.vUserIds[keys.userid] = ply

	-- Update the Steam ID table
	self.vSteamIds[PlayerResource:GetSteamAccountID(playerID)] = ply

	-- If the player is a broadcaster flag it in the Broadcasters table
	if PlayerResource:IsBroadcaster(playerID) then
		self.vBroadcasters[keys.userid] = 1
		return
	end
end

-- This function is called as the first player loads and sets up the GameMode parameters
function GameMode:CaptureGameMode()
	if mode == nil then
		-- Set GameMode parameters
		mode = GameRules:GetGameModeEntity()
		mode:SetRecommendedItemsDisabled( RECOMMENDED_BUILDS_DISABLED )
		mode:SetCameraDistanceOverride( CAMERA_DISTANCE_OVERRIDE )
		mode:SetCustomBuybackCostEnabled( CUSTOM_BUYBACK_COST_ENABLED )
		mode:SetCustomBuybackCooldownEnabled( CUSTOM_BUYBACK_COOLDOWN_ENABLED )
		mode:SetBuybackEnabled( BUYBACK_ENABLED )
		mode:SetTopBarTeamValuesOverride ( USE_CUSTOM_TOP_BAR_VALUES )
		mode:SetTopBarTeamValuesVisible( TOP_BAR_VISIBLE )
		mode:SetUseCustomHeroLevels ( USE_CUSTOM_HERO_LEVELS )
		mode:SetCustomHeroMaxLevel ( MAX_LEVEL )
		mode:SetCustomXPRequiredToReachNextLevel( XP_PER_LEVEL_TABLE )

		--mode:SetBotThinkingEnabled( USE_STANDARD_DOTA_BOT_THINKING )
		mode:SetTowerBackdoorProtectionEnabled( ENABLE_TOWER_BACKDOOR_PROTECTION )

		mode:SetFogOfWarDisabled(DISABLE_FOG_OF_WAR_ENTIRELY)
		mode:SetGoldSoundDisabled( DISABLE_GOLD_SOUNDS )
		mode:SetRemoveIllusionsOnDeath( REMOVE_ILLUSIONS_ON_DEATH )
		mode:SetDaynightCycleDisabled(true)
		mode:SetStashPurchasingDisabled(true)

		setupProjectileList()

		mode:SetTrackingProjectileFilter(Dynamic_Wrap(ProjectileList, "TrackingProjectileCreated"), self)
		mode:SetDamageFilter(Dynamic_Wrap(Filters, "DamageFilter"), self)
		mode:SetModifierGainedFilter(Dynamic_Wrap(Filters, "ModifierGainedFilter"), self)
		mode:SetModifyGoldFilter(Dynamic_Wrap(Filters, "ModifyGoldFilter"), self)
		mode:SetExecuteOrderFilter(Dynamic_Wrap(Filters, "ExecuteOrderFilter"), self)

		self:OnFirstPlayerLoaded()
	end
end

-- This is an example console command
function GameMode:ExampleConsoleCommand()
	print( '******* Example Console Command ***************' )
	local cmdPlayer = Convars:GetCommandClient()
	if cmdPlayer then
		local playerID = cmdPlayer:GetPlayerID()
		if playerID ~= nil and playerID ~= -1 then
			-- Do something here for the player who called this command
			PlayerResource:ReplaceHeroWith(playerID, "npc_dota_hero_viper", 1000, 1000)
		end
	end
	print( '*********************************************' )
end

--[[
  This function should be used to set up Async precache calls at the beginning of the game.  The Precache() function 
  in addon_game_mode.lua used to and may still sometimes have issues with client's appropriately precaching stuff.
  If this occurs it causes the client to never precache things configured in that block.

  In this function, place all of your PrecacheItemByNameAsync and PrecacheUnitByNameAsync.  These calls will be made
  after all players have loaded in, but before they have selected their heroes. PrecacheItemByNameAsync can also
  be used to precache dynamically-added datadriven abilities instead of items.  PrecacheUnitByNameAsync will 
  precache the precache{} block statement of the unit and all precache{} block statements for every Ability# 
  defined on the unit.

  This function should only be called once.  If you want to/need to precache more items/abilities/units at a later
  time, you can call the functions individually (for example if you want to precache units in a new wave of
  holdout).
]]
function GameMode:PostLoadPrecache()
	print("[BAREBONES] Performing Post-Load precache")

end

--[[
  This function is called once and only once as soon as the first player (almost certain to be the server in local lobbies) loads in.
  It can be used to initialize state that isn't initializeable in InitGameMode() but needs to be done before everyone loads in.
]]
function GameMode:OnFirstPlayerLoaded()
	print("[BAREBONES] First Player has loaded")
end

--[[
  This function is called once and only once after all players have loaded into the game, right as the hero selection time begins.
  It can be used to initialize non-hero player state or adjust the hero selection (i.e. force random etc)
]]
function GameMode:OnAllPlayersLoaded()
	print("[BAREBONES] All Players have loaded into the game")
end

--[[
  This function is called once and only once for every player when they spawn into the game for the first time.  It is also called
  if the player's hero is replaced with a new hero for any reason.  This function is useful for initializing heroes, such as adding
  levels, changing the starting gold, removing/adding abilities, adding physics, etc.

  The hero parameter is the hero entity that just spawned in.
]]

function GameMode:OnHeroInGame(hero)
	print("[BAREBONES] Hero spawned in game for first time -- " .. hero:GetUnitName())

	-- Store a reference to the player handle inside this hero handle.
	hero.player = PlayerResource:GetPlayer(hero:GetPlayerID())
	if not hero.player then return end -- Ignore all this shit if this is an illusion or w/e
	-- Store the player's name inside this hero handle.
	hero.playerName = PlayerResource:GetPlayerName(hero:GetPlayerID())
	-- Store this hero handle in this table.
	table.insert(self.vPlayers, hero)

	Timers:CreateTimer(0.03, function() -- Give illusions a frame to acquire the illusion modifier
		if not hero:IsIllusion() then
			for i=0,15 do
				local ability = hero:GetAbilityByIndex(i)
				if ability then 
					ability:SetLevel(ability:GetMaxLevel())
				end
			end
		end
	end)

	if hero:HasAbility("combat_link") then
		hero:FindAbilityByName("combat_link"):SetLevel(1)
		hero:FindAbilityByName("combat_link"):SetActivated(false)
		hero:FindAbilityByName("cp_tracker"):SetLevel(1)
		modifyCP(hero, 0)
	end

	-- Custom hero select trigger
	if CustomHeroSelect:IsPlaceholderHero(hero) then
		hero:AddNewModifier(hero, nil, "modifier_interround_invulnerability", {})
		CustomHeroSelect:OnHeroInGame(hero)
	else
		if not RoundManager.round_started then -- to make testing easier -- this should always be true in a real game
			hero:AddNewModifier(hero, nil, "modifier_interround_invulnerability", {})
		end
		initializeStats(hero)
	
		-- Turn off music by default
		hero.music_playing = nil
		hero.player:SetMusicStatus(DOTA_MUSIC_STATUS_NONE, 100000)

		-- Setup custom UI stuff
		CustomGameEventManager:Send_ServerToPlayer(hero:GetOwner(), "infotext_start", {})
		self:UpdateStatsDisplay(hero)
		CustomGameEventManager:Send_ServerToPlayer(hero:GetOwner(), "ability_bar_start", {heroIndex = hero:GetEntityIndex(), cpCosts = getAbilityCPCosts(hero)})
		self:UpdateAbilityBars(hero)

		
		Timers:CreateTimer(1/30, function() -- have to wait a frame for GetAssignedHero() to actually work after hero is picked
			if not RoundManager.round_started then
				FindClearSpaceForUnit(hero, RoundManager:GetSpawnPosition(hero, true), true)
				if self:AllPlayersPickedHeroes() then
					RoundManager:BeginRoundStartTimer()
				end
			end
			hero:SetGold(BASE_GOLD_PER_ROUND, true)
			self:AddMasterQuartz(hero)
		end)
	end
end

function GameMode:AddMasterQuartz(hero)
	local quartz_name = getHeroValueForKey(hero, "MasterQuartz")
	local item = CreateItem("item_master_"..quartz_name, hero, hero)
	hero:AddItem(item)
end

function GameMode:AllPlayersPickedHeroes()
	local player_count = PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS) + PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_BADGUYS)
	for i = 0, player_count - 1 do
		local player = PlayerResource:GetPlayer(i)
		if not CustomHeroSelect:HasSelectedHero(player) then
			return false
		end
	end
	return true
end

function GameMode:UpdateStatsDisplay(hero)
	Timers:CreateTimer(0, function()
		local stats = {}
		for k,unit in pairs(getAllHeroes()) do
			stats[unit:GetEntityIndex()] = getStats(unit)
			stats[unit:GetEntityIndex()].mov = unit:GetIdealSpeed()
		end

		CustomGameEventManager:Send_ServerToPlayer(hero:GetOwner(), "stats_display_update", {playerid = hero:GetPlayerID(), unitStats = stats})
		return 1/30
	end)
end

function GameMode:UpdateAbilityBars(hero)
	Timers:CreateTimer(0, function()
		local values = {}
		local units = {hero}
		if hero.combat_linked_to then units[2] = hero.combat_linked_to end

		for k,unit in pairs(units) do
			local hero_unbalance = unit:FindModifierByName("modifier_unbalanced_level"):GetStackCount()
			if unit:HasModifier("modifier_combat_link_unbalanced") then hero_unbalance = 100 end
			values[unit:GetEntityIndex()] = {cp = getCP(unit), unbalance = hero_unbalance}
		end

		CustomGameEventManager:Send_ServerToPlayer(hero:GetOwner(), "resource_bars_update", {unitValues = values})
		return 1/30
	end)
end

function GameMode:OnMusicControlToggled(eventSourceIndex, args)
	local player = EntIndexToHScript(eventSourceIndex)
	local hero = player:GetAssignedHero()

	-- Shoutout to unbelievably stupid hacks, fuck this game
	hero.ignore_music_toggle_click = not hero.ignore_music_toggle_click

	-- print("1")
	if not hero.ignore_music_toggle_click then
		-- print("2")
		if hero.music_playing == nil then
			-- print("3")
			self:StartMusicForPlayer(player)
		else
			-- print("4")
			self:StopMusicForPlayer(player)
		end
	end
end

function GameMode:StartMusicForPlayer(player)
	local hero = player:GetAssignedHero()
	Timers:CreateTimer("music_timer_"..player:GetPlayerID(), {
		callback = function()
			local music_string = "Trails.Dont_Be_Defeated"
			if RoundManager.current_round == 8 then music_string = "Trails.Decisive_Collision" end
			EmitSoundOnClient(music_string, player)
			hero.music_playing = music_string
			return 135
		end
	})
end

function GameMode:StopMusicForPlayer(player)
	local hero = player:GetAssignedHero()
	Timers:RemoveTimer("music_timer_"..player:GetPlayerID())
	player:StopSound(hero.music_playing)
	hero.music_playing = nil
end

function GameMode:StartCountdown(time, title, callback)
	CustomGameEventManager:Send_ServerToAllClients("quest_start_timer", { title = title, time = time })
	Timers:CreateTimer(time, callback)
end

function GameMode:AreAllHeroesReady()
	local player_count = PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS) + PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_BADGUYS)
	for i = 0, player_count - 1 do
		local player = PlayerResource:GetPlayer(i)
		if not CustomHeroSelect:HasSelectedHero(player) then
			print("Player " .. i .. " has not selected a hero yet")
			return false
		end
		
		local hero = player:GetAssignedHero()
		if not hero.round_ready then
			print("Hero " .. hero:GetUnitName() .. " is not ready yet")
			return false
		end
	end

	return true
end

--[[
	This function is called once and only once when the game completely begins (about 0:00 on the clock).  At this point,
	gold will begin to go up in ticks if configured, creeps will spawn, towers will become damageable etc.  This function
	is useful for starting any game logic timers/thinkers, beginning the first round, etc.
]]
function GameMode:OnGameInProgress()
	print("[BAREBONES] The game has officially begun")

	Turn_Bonuses:Initialize()
end

-- Cleanup a player when they leave
function GameMode:OnDisconnect(keys)
	print('[BAREBONES] Player Disconnected ' .. tostring(keys.userid))
	DeepPrintTable(keys)

	local name = keys.name
	local networkid = keys.networkid
	local reason = keys.reason
	local userid = keys.userid
end

-- The overall game state has changed
function GameMode:OnGameRulesStateChange(keys)
	print("[BAREBONES] GameRules State Changed")
	DeepPrintTable(keys)

	local newState = GameRules:State_Get()
	if newState == DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD then
		self.bSeenWaitForPlayers = true
	elseif newState == DOTA_GAMERULES_STATE_INIT then
		Timers:RemoveTimer("alljointimer")
	elseif newState == DOTA_GAMERULES_STATE_HERO_SELECTION then
		local et = 6
		if self.bSeenWaitForPlayers then
			et = .01
		end
		Timers:CreateTimer("alljointimer", {
			useGameTime = true,
			endTime = et,
			callback = function()
				if PlayerResource:HaveAllPlayersJoined() then
					GameMode:PostLoadPrecache()
					GameMode:OnAllPlayersLoaded()
					return
				end
				return 1
			end})
	elseif newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		GameMode:OnGameInProgress()
	end
end

-- An NPC has spawned somewhere in game.  This includes heroes
function GameMode:OnNPCSpawned(keys)
	--print("[BAREBONES] NPC Spawned")
	--DeepPrintTable(keys)
	local npc = EntIndexToHScript(keys.entindex)

	if npc:IsRealHero() and npc.bFirstSpawned == nil then
		npc.bFirstSpawned = true
		GameMode:OnHeroInGame(npc)
	end

	if npc:HasAbility("reflex_dummy_unit") then
		npc:FindAbilityByName("reflex_dummy_unit"):SetLevel(1)
	end

	local imported_model = false
	for k,name in pairs(imported_model_characters) do
		if npc:GetName() == name then
			imported_model = true
			break
		end
	end
	if imported_model then
		print("Removing cosmetics")
		local cosmetics = {}
		local cosmetic = npc:FirstMoveChild()
		while cosmetic ~= nil do
			if cosmetic:GetClassname() == "dota_item_wearable" then
				table.insert(cosmetics, cosmetic)
			end
			cosmetic = cosmetic:NextMovePeer()
		end
		for k,v in pairs(cosmetics) do
			v:RemoveSelf()
		end
	end
end

-- An entity somewhere has been hurt.  This event fires very often with many units so don't do too many expensive
-- operations here
function GameMode:OnEntityHurt(keys)
	--print("[BAREBONES] Entity Hurt")
	--DeepPrintTable(keys)
	if keys.entindex_attacker then local entCause = EntIndexToHScript(keys.entindex_attacker) end
	local entVictim = EntIndexToHScript(keys.entindex_killed)
end

-- An item was picked up off the ground
function GameMode:OnItemPickedUp(keys)
	print ( '[BAREBONES] OnItemPickedUp' )
	DeepPrintTable(keys)

	local heroEntity = EntIndexToHScript(keys.HeroEntityIndex)
	local itemEntity = EntIndexToHScript(keys.ItemEntityIndex)
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local itemname = keys.itemname
end

-- A player has reconnected to the game.  This function can be used to repaint Player-based particles or change
-- state as necessary
function GameMode:OnPlayerReconnect(keys)
	print ( '[BAREBONES] OnPlayerReconnect' )
	DeepPrintTable(keys)
end

-- An item was purchased by a player
function GameMode:OnItemPurchased( keys )
	print ( '[BAREBONES] OnItemPurchased' )
	DeepPrintTable(keys)

	-- The playerID of the hero who is buying something
	local plyID = keys.PlayerID
	if not plyID then return end

	-- The name of the item purchased
	local itemName = keys.itemname

	-- The cost of the item purchased
	local itemcost = keys.itemcost

end

-- An ability was used by a player
function GameMode:OnAbilityUsed(keys)
	print('[BAREBONES] AbilityUsed')
	DeepPrintTable(keys)

	local player = EntIndexToHScript(keys.PlayerID)
	local abilityname = keys.abilityname
end

-- A non-player entity (necro-book, chen creep, etc) used an ability
function GameMode:OnNonPlayerUsedAbility(keys)
	print('[BAREBONES] OnNonPlayerUsedAbility')
	DeepPrintTable(keys)

	local abilityname=  keys.abilityname
end

-- A player changed their name
function GameMode:OnPlayerChangedName(keys)
	print('[BAREBONES] OnPlayerChangedName')
	DeepPrintTable(keys)

	local newName = keys.newname
	local oldName = keys.oldName
end

-- A player leveled up an ability
function GameMode:OnPlayerLearnedAbility( keys)
	print ('[BAREBONES] OnPlayerLearnedAbility')
	DeepPrintTable(keys)

	local player = EntIndexToHScript(keys.player)
	local abilityname = keys.abilityname
end

-- A channelled ability finished by either completing or being interrupted
function GameMode:OnAbilityChannelFinished(keys)
	print ('[BAREBONES] OnAbilityChannelFinished')
	DeepPrintTable(keys)

	local abilityname = keys.abilityname
	local interrupted = keys.interrupted == 1
end

-- A player leveled up
function GameMode:OnPlayerLevelUp(keys)
	-- print ('[BAREBONES] OnPlayerLevelUp')
	-- DeepPrintTable(keys)

	local player = EntIndexToHScript(keys.player)
	local level = keys.level
end

-- A player last hit a creep, a tower, or a hero
function GameMode:OnLastHit(keys)
	print ('[BAREBONES] OnLastHit')
	DeepPrintTable(keys)

	local isFirstBlood = keys.FirstBlood == 1
	local isHeroKill = keys.HeroKill == 1
	local isTowerKill = keys.TowerKill == 1
	local player = PlayerResource:GetPlayer(keys.PlayerID)
end

-- A tree was cut down by tango, quelling blade, etc
function GameMode:OnTreeCut(keys)
	print ('[BAREBONES] OnTreeCut')
	DeepPrintTable(keys)

	local treeX = keys.tree_x
	local treeY = keys.tree_y
end

-- A rune was activated by a player
function GameMode:OnRuneActivated (keys)
	print ('[BAREBONES] OnRuneActivated')
	DeepPrintTable(keys)

	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local rune = keys.rune

end

-- A player took damage from a tower
function GameMode:OnPlayerTakeTowerDamage(keys)
	print ('[BAREBONES] OnPlayerTakeTowerDamage')
	DeepPrintTable(keys)

	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local damage = keys.damage
end

-- A player picked a hero
function GameMode:OnPlayerPickHero(keys)
	print ('[BAREBONES] OnPlayerPickHero')
	DeepPrintTable(keys)

	local heroClass = keys.hero
	local heroEntity = EntIndexToHScript(keys.heroindex)
	local player = EntIndexToHScript(keys.player)
end

-- A player killed another player in a multi-team context
function GameMode:OnTeamKillCredit(keys)
	print ('[BAREBONES] OnTeamKillCredit')
	DeepPrintTable(keys)

	local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
	local victimPlayer = PlayerResource:GetPlayer(keys.victim_userid)
	local numKills = keys.herokills
	local killerTeamNumber = keys.teamnumber
	-- if numKills >= 10 and not CHEATY_STUFF then
	-- 	GameRules:SetGameWinner(killerTeamNumber)
	-- end
end

-- An entity died
function GameMode:OnEntityKilled( keys )
	--print( '[BAREBONES] OnEntityKilled Called' )
	--DeepPrintTable( keys )

	-- The Unit that was Killed
	local killedUnit = EntIndexToHScript( keys.entindex_killed )
	-- The Killing entity
	local killerEntity = nil

	if keys.entindex_attacker ~= nil then
		killerEntity = EntIndexToHScript( keys.entindex_attacker )
	end

	if killedUnit:IsRealHero() then
		local living_heroes = {}
		living_heroes[DOTA_TEAM_GOODGUYS] = 0
		living_heroes[DOTA_TEAM_BADGUYS] = 0
		for i=0, 9 do
			local hero = PlayerResource:GetSelectedHeroEntity(i)
			if hero and hero:IsAlive() then
				living_heroes[hero:GetTeam()] = living_heroes[hero:GetTeam()] + 1
			end
		end


		if living_heroes[DOTA_TEAM_GOODGUYS] == 0 then
			RoundManager:EndRound(DOTA_TEAM_BADGUYS)
		elseif living_heroes[DOTA_TEAM_BADGUYS] == 0 then
			RoundManager:EndRound(DOTA_TEAM_GOODGUYS)
		end
	end
end
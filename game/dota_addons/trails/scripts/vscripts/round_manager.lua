require "round_recap"
require "turn_bonuses"

if not RoundManager then
	RoundManager = {}
	RoundManager.__index = RoundManager
end

function RoundManager:Initialize()
	self.score = {}
	self.score[DOTA_TEAM_GOODGUYS] = 0
	self.score[DOTA_TEAM_BADGUYS] = 0
	self.current_round = 0
	self.round_started = false
	CustomGameEventManager:Send_ServerToAllClients("ready_button_hide", {})
	CustomGameEventManager:RegisterListener("ready_button_pressed", WrapMemberMethod(self.OnReadyButtonPressed, self))
end

function RoundManager:OnReadyButtonPressed(eventSourceIndex, args)
	-- Why the fuck does this function run twice zzzzzzzzzzzzzzzzzzzzzz
	print("OnReadyButtonPressed ---------------------------------------------------------------")
	local player = EntIndexToHScript(eventSourceIndex)
	local hero = player:GetAssignedHero()

	hero.round_ready = true
	if GameMode:AreAllHeroesReady() and not self.round_started then
		CustomGameEventManager:Send_ServerToAllClients("ready_button_all_players_ready", {})
		self:BeginRoundStartTimer(3)
	end
end

function RoundManager:BeginRoundStartTimer(time)
	time = time or SHOPPING_TIME
	print(self.time_until_round_start, time)
	if not self.time_until_round_start or time < self.time_until_round_start then
		self.time_until_round_start = time
		CustomGameEventManager:Send_ServerToAllClients("ready_button_start", {})
		Timers:RemoveTimer("round_start_countdown")
		Timers:CreateTimer("round_start_countdown", {
			endTime = 1,
			callback = function()
				self.time_until_round_start = self.time_until_round_start - 1
				print(self.time_until_round_start)
				CustomGameEventManager:Send_ServerToAllClients("ready_button_update", {time = self.time_until_round_start})
				if self.time_until_round_start <= 0 then
					self.round_started = true
					self:StartRound()
					CustomGameEventManager:Send_ServerToAllClients("infotext_game_starting", {})
					CustomGameEventManager:Send_ServerToAllClients("round_recap_remove", {})
					self.time_until_round_start = nil
				else
					return 1
				end
			end
		})
	end
end

function RoundManager:StartRound()
	for i=0, 9 do
		local hero = PlayerResource:GetSelectedHeroEntity(i)
		if hero then
			hero:RemoveModifierByName("modifier_interround_invulnerability")
			hero.round_ready = nil
			if self.current_round == 0 then
				self:AddStatusBars(hero)
			end
			if self.current_round == 8 and hero.music_playing then
				GameMode:StopMusicForPlayer(PlayerResource:GetPlayer(i))
				GameMode:StartMusicForPlayer(PlayerResource:GetPlayer(i))
			end
			FindClearSpaceForUnit(hero, self:GetSpawnPosition(hero, false), true)
		end
	end
	Turn_Bonuses:StartRound(self.current_round)
	Round_Recap:StartRound()
	CustomGameEventManager:Send_ServerToAllClients("ready_button_hide", {})
end

function RoundManager:AddStatusBars(hero)
	local playerid = hero:GetPlayerOwnerID()
	local hero_index = hero:GetEntityIndex()
	local player = PlayerResource:GetPlayer(playerid)
	CustomGameEventManager:Send_ServerToAllClients("status_bars_start", {player=playerid})
	CustomGameEventManager:Send_ServerToAllClients("unbalance_bars_start", {player=playerid})
	Timers:CreateTimer(function()
		if IsValidEntity(hero) then
			CustomGameEventManager:Send_ServerToAllClients("status_bars_update", {player=playerid, hero=hero_index, cp=getCP(hero)})
			local hero_unbalance = hero:FindModifierByName("modifier_unbalanced_level"):GetStackCount()
			if hero:HasModifier("modifier_combat_link_unbalanced") then hero_unbalance = 100 end
			CustomGameEventManager:Send_ServerToAllClients("unbalance_bars_update", {player=playerid, hero=hero_index, unbalance=hero_unbalance})
		end
		return 1/30
	end)
end

function RoundManager:EndRound(winning_team)
	GameRules:SendCustomMessage("#Round_Winner_"..winning_team, 0, 0)
	self.score[winning_team] = self.score[winning_team] + 1
	self.current_round = self.current_round + 1
	self.round_started = false
	mode:SetTopBarTeamValue(DOTA_TEAM_GOODGUYS, self.score[DOTA_TEAM_GOODGUYS])
	mode:SetTopBarTeamValue(DOTA_TEAM_BADGUYS, self.score[DOTA_TEAM_BADGUYS])
	Turn_Bonuses:EndRound()

	Timers:CreateTimer(ROUND_END_DELAY, function()
		for i=0, 9 do
			local hero = PlayerResource:GetSelectedHeroEntity(i)
			if hero then
				hero:SetRespawnPosition(RoundManager:GetSpawnPosition(hero, true))
				hero:RespawnHero(false, false, false)

				hero:AddNewModifier(hero, nil, "modifier_interround_invulnerability", {})
				
				if hero:GetTeam() ~= winning_team then
					modifyCP(hero, END_OF_ROUND_LOSER_CP)
				end

				hero:ModifyGold(BASE_GOLD_PER_ROUND + GOLD_INCREASE_PER_ROUND * self.current_round - 1, true, 17)
			end
		end

		Round_Recap:EndRound()
		
		-- check for game win
		if self.score[DOTA_TEAM_GOODGUYS] == ROUNDS_TO_WIN then
			GameRules:SendCustomMessage("Radiant Victory!", 0, 0)
			GameRules:SetSafeToLeave( true )
			GameRules:SetGameWinner( DOTA_TEAM_GOODGUYS )
		elseif self.score[DOTA_TEAM_BADGUYS] == ROUNDS_TO_WIN then
			GameRules:SendCustomMessage("Dire Victory!", 0, 0)
			GameRules:SetSafeToLeave( true )
			GameRules:SetGameWinner( DOTA_TEAM_BADGUYS )
		else
			self:BeginRoundStartTimer()
		end
	end)
end

function RoundManager:GetSpawnPosition(hero, shopping)
	local swapped_spawns = self.current_round % 2 == 1
	local spawn_location = nil
	local team = hero:GetTeam()
	if swapped_spawns then team = hero:GetOpposingTeamNumber() end
	if not shopping then
		if team == DOTA_TEAM_GOODGUYS then
			spawn_location = Entities:FindByClassname(nil, "info_player_start_goodguys"):GetAbsOrigin()
		elseif team == DOTA_TEAM_BADGUYS then
			spawn_location = Entities:FindByClassname(nil, "info_player_start_badguys"):GetAbsOrigin()
		end
	else
		if team == DOTA_TEAM_GOODGUYS then
			spawn_location = Entities:FindByName(nil, "shop_spawn_radiant"):GetAbsOrigin()
		elseif team == DOTA_TEAM_BADGUYS then
			spawn_location = Entities:FindByName(nil, "shop_spawn_dire"):GetAbsOrigin()
		end
	end
	return spawn_location
end
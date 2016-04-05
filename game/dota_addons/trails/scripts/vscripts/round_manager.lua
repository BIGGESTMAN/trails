require "round_recap"
require "game_functions"

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
	if not self.time_until_round_start or time < self.time_until_round_start then
		self.time_until_round_start = time
		CustomGameEventManager:Send_ServerToAllClients("ready_button_start", {})
		Timers:RemoveTimer("round_start_countdown")
		Timers:CreateTimer("round_start_countdown", {
			endTime = 1,
			callback = function()
				self.time_until_round_start = self.time_until_round_start - 1
				CustomGameEventManager:Send_ServerToAllClients("ready_button_update", {time = self.time_until_round_start})
				if self.time_until_round_start <= 0 then
					self:StartRound()
				else
					return 1
				end
			end
		})
	end
end

function RoundManager:StartRound()
	-- for testing/use of -startround
	Timers:RemoveTimer("round_start_countdown")
	
	self.time_until_round_start = nil
	self.round_started = true
	CustomGameEventManager:Send_ServerToAllClients("infotext_game_starting", {})
	CustomGameEventManager:Send_ServerToAllClients("round_recap_remove", {})
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
	triggerModifierEventOnAll("round_started")
	game_mode:StartRound(self.current_round)
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
	self.current_round = self.current_round + 1
	self.round_started = false
	game_mode:EndRound(winning_team)
	GameRules:GetGameModeEntity():SetTopBarTeamValue(DOTA_TEAM_GOODGUYS, self.score[DOTA_TEAM_GOODGUYS])
	GameRules:GetGameModeEntity():SetTopBarTeamValue(DOTA_TEAM_BADGUYS, self.score[DOTA_TEAM_BADGUYS])

	for k,hero in pairs(getAllHeroes()) do
		hero:AddNewModifier(hero, nil, "modifier_postround_stun", {})
	end

	Timers:CreateTimer(ROUND_END_DELAY, function()
		for i=0, 9 do
			local hero = PlayerResource:GetSelectedHeroEntity(i)
			if hero then
				hero:SetRespawnPosition(RoundManager:GetSpawnPosition(hero, true))
				hero:RespawnHero(false, false, false)

				hero:RemoveModifierByName("modifier_postround_stun")
				hero:AddNewModifier(hero, nil, "modifier_interround_invulnerability", {})
				
				-- if hero:GetTeam() ~= winning_team then
				-- 	modifyCP(hero, END_OF_ROUND_LOSER_CP)
				-- end
				modifyCP(hero, getCP(hero) * -1)

				hero:ModifyGold(BASE_GOLD_PER_ROUND + GOLD_INCREASE_PER_ROUND * self.current_round, true, 17)
				self:RemoveTemporaryModifiers(hero)
				upgradeMasterQuartz(hero)
				ParticleManager:CreateParticle("particles/generic_hero_status/hero_levelup.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
			end
		end

		Round_Recap:EndRound()
		
		-- check for game win
		local game_winner = self:GetGameWinner()
		if game_winner == DOTA_TEAM_GOODGUYS then
			GameRules:SendCustomMessage("Radiant Victory!", 0, 0)
			GameRules:SetSafeToLeave( true )
			GameRules:SetGameWinner( DOTA_TEAM_GOODGUYS )
		elseif game_winner == DOTA_TEAM_BADGUYS then
			GameRules:SendCustomMessage("Dire Victory!", 0, 0)
			GameRules:SetSafeToLeave( true )
			GameRules:SetGameWinner( DOTA_TEAM_BADGUYS )
		else
			self:BeginRoundStartTimer()
		end
	end)
end

-- Holy shit this is kinda dangerous but whatever yolo
function RoundManager:RemoveTemporaryModifiers(hero)
	for k,modifier in pairs(hero:FindAllModifiers()) do
		if modifier:GetDuration() ~= -1 and (not modifier.DestroyOnExpire or modifier:DestroyOnExpire()) then
			modifier:Destroy()
		end
	end
end

function RoundManager:GetGameWinner()
	return game_mode:GetGameWinner()
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
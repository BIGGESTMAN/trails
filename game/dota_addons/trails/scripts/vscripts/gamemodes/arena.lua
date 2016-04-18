require "turn_bonuses"
require "round_manager"
require "game_functions"

ROUNDS_TO_WIN = 5

if not Gamemode_Arena then
	Gamemode_Arena = {}
	Gamemode_Arena.__index = Gamemode_Arena
end

function Gamemode_Arena:Initialize()
	Turn_Bonuses:Initialize()
end

function Gamemode_Arena:StartRound(round)
	Turn_Bonuses:StartRound(round)
end

function Gamemode_Arena:EndRound(winning_team)
	Turn_Bonuses:EndRound()
	GameRules:SendCustomMessage("#Round_Winner_"..winning_team, 0, 0)
	RoundManager.score[winning_team] = RoundManager.score[winning_team] + 1
end

function Gamemode_Arena:OnEntityHurt(keys)
end

function Gamemode_Arena:initializeStats(hero)
end

function Gamemode_Arena:GetGameWinner()
	if RoundManager.score[DOTA_TEAM_GOODGUYS] == ROUNDS_TO_WIN then
		return DOTA_TEAM_GOODGUYS
	elseif RoundManager.score[DOTA_TEAM_BADGUYS] == ROUNDS_TO_WIN then
		return DOTA_TEAM_BADGUYS
	else
		return nil
	end
end

function Gamemode_Arena:OnEntityKilled(keys)
	local unit = EntIndexToHScript(keys.entindex_killed)

	if unit:IsRealHero() then
		local living_heroes = {}
		living_heroes[DOTA_TEAM_GOODGUYS] = 0
		living_heroes[DOTA_TEAM_BADGUYS] = 0
		for k,hero in pairs(getAllHeroes()) do
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

function Gamemode_Arena:OnHeroInGame(hero)
	Timers:CreateTimer(0.03, function() -- Give illusions a frame to acquire the illusion modifier
		if not hero:IsIllusion() then
			for k,ability in pairs(getAllAbilities(hero)) do
				ability:SetLevel(ability:GetMaxLevel())
			end
		end
	end)

	if not RoundManager.round_started then -- to make testing easier -- this should always be true in a real game
		hero:AddNewModifier(hero, nil, "modifier_interround_invulnerability", {})
	end

	if not RoundManager.round_started then
		FindClearSpaceForUnit(hero, RoundManager:GetSpawnPosition(hero, true), true)
		if self:HaveAllPlayersPicked() then
			RoundManager:BeginRoundStartTimer()
		end
	end
	hero:SetGold(BASE_GOLD_PER_ROUND, true)
	GameMode:AddMasterQuartz(hero)
end
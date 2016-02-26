if CustomHeroSelect == nil then
	_G.CustomHeroSelect = { initialized = false }
end

CUSTOM_HERO_SELECT_PLACEHOLDER_UNIT_NAME = "npc_dota_hero_wisp"

function CustomHeroSelect:Initialize()
	GameRules:GetGameModeEntity():SetCustomGameForceHero(CUSTOM_HERO_SELECT_PLACEHOLDER_UNIT_NAME)

	Convars:RegisterCommand("dc_herosel", Dynamic_Wrap(CustomHeroSelect, 'CCmd_HeroSelect'), "", FCVAR_CHEAT)

	self.initialized = true
	self.pickedHeroes = {}
	self.pickedHeroes[DOTA_TEAM_GOODGUYS] = {}
	self.pickedHeroes[DOTA_TEAM_BADGUYS] = {}
	self.start_gold = 0
	self.customHeroSelectData = LoadKeyValues("scripts/kv/herolist_custom.txt")
	CustomGameEventManager:RegisterListener("heroselect_pick", WrapMemberMethod(self.OnHeroSelectPickedEvent, self))
end

function CustomHeroSelect:SetStartingGold(gold)
	self.start_gold = gold
end

function CustomHeroSelect:CCmd_HeroSelect(arg)
	local hero = Convars:GetCommandClient():GetAssignedHero()
	GameMode:BeginCustomHeroSelect(hero)
end

function CustomHeroSelect:IsPlaceholderHero(hero)
	return hero:GetUnitName() == CUSTOM_HERO_SELECT_PLACEHOLDER_UNIT_NAME
end

function CustomHeroSelect:HasSelectedHero(player)
	local hero = player:GetAssignedHero()
	if hero == nil or self:IsPlaceholderHero(hero) then
		return false
	end
	return true
end

function CustomHeroSelect:OnHeroInGame(hero)
	if self.initialized and self:IsPlaceholderHero(hero) then
		hero:GetAbilityByIndex(0):SetLevel(1)
		self:StartHeroSelectionFor(hero)
	end
end

function CustomHeroSelect:StartHeroSelectionFor(hero)
	local teamKey = "GoodGuys"
	if hero:GetTeamNumber() == DOTA_TEAM_BADGUYS then
		teamKey = "BadGuys"
	end
	CustomGameEventManager:Send_ServerToPlayer(hero:GetOwner(), "heroselect_start", { team = teamKey })
end

function CustomHeroSelect:OnHeroSelectPickedEvent(source, data)
	local picked_hero_id = data.hero
	local player = EntIndexToHScript(source)

	local hero = player:GetAssignedHero()
	if hero ~= nil and CustomHeroSelect:IsPlaceholderHero(hero) then
		for k,v in pairs(CustomHeroSelect.pickedHeroes) do
			print(k,v)
		end
		print(player:GetTeamNumber(), CustomHeroSelect.pickedHeroes[player:GetTeamNumber()], picked_hero_id)
		if not CustomHeroSelect.pickedHeroes[player:GetTeamNumber()][picked_hero_id] then
			CustomHeroSelect.pickedHeroes[player:GetTeamNumber()][picked_hero_id] = true
			CustomGameEventManager:Send_ServerToTeam(player:GetTeamNumber(), "heroselect_pick_other", { hero_id = picked_hero_id });
			CustomGameEventManager:Send_ServerToPlayer(player, "heroselect_pick_confirm", {})

			PrecacheUnitByNameAsync(picked_hero_id, function()
				local oldHero = player:GetAssignedHero()
				PlayerResource:ReplaceHeroWith(player:GetPlayerID(), picked_hero_id, self.start_gold, 0)
				CustomGameEventManager:Send_ServerToPlayer(player, "heroselect_pick_done", {})
				if IsValidEntity(oldHero) then
					oldHero:RemoveSelf()
				end
			end, player:GetPlayerID())
		end
	end
end

function WrapMemberMethod(method, selfobj)
	return function(...) method(selfobj, ...) end
end
require "game_functions"

if CustomHeroSelect == nil then
	_G.CustomHeroSelect = { initialized = false }
end

CUSTOM_HERO_SELECT_PLACEHOLDER_UNIT_NAME = "npc_dota_hero_wisp"

ALLOW_SAME_HERO_PICKS = true

function CustomHeroSelect:Initialize()
	GameRules:GetGameModeEntity():SetCustomGameForceHero(CUSTOM_HERO_SELECT_PLACEHOLDER_UNIT_NAME)

	Convars:RegisterCommand("dc_herosel", Dynamic_Wrap(CustomHeroSelect, 'CCmd_HeroSelect'), "", FCVAR_CHEAT)

	self.initialized = true
	self.pickedHeroes = {}
	self.pickedHeroes[DOTA_TEAM_GOODGUYS] = {}
	self.pickedHeroes[DOTA_TEAM_BADGUYS] = {}
	self.start_gold = 0
	CustomGameEventManager:RegisterListener("heroselect_pick", WrapMemberMethod(self.OnHeroSelectPickedEvent, self))
	self.heroesData = CustomHeroSelect:GetHeroData()
end

function CustomHeroSelect:GetHeroData()
	local heroes = {}
	local hero_keyvalues = LoadKeyValues("scripts/npc/npc_heroes_custom.txt")
	for name,keyvalues in pairs(hero_keyvalues) do
		name = getDotaHeroName(name)
		heroes[name] = {}
		heroes[name].abilities = {}
		for i=1,16 do
			if keyvalues["Ability"..i] and keyvalues["Ability"..i] ~= "" and keyvalues["Ability"..i] ~= "combat_link" and keyvalues["Ability"..i] ~= "cp_tracker" then
				heroes[name].abilities[i] = keyvalues["Ability"..i]
			else
				break
			end
		end
		heroes[name].str = keyvalues["Str"]
		heroes[name].ats = keyvalues["Ats"]
		heroes[name].health = keyvalues["StatusHealth"]
		heroes[name].mana = keyvalues["StatusMana"]
		heroes[name].masterquartz = keyvalues["MasterQuartz"]
	end
	return heroes
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
	CustomGameEventManager:Send_ServerToPlayer(hero:GetOwner(), "heroselect_start", { heroes = self.heroesData })
end

function CustomHeroSelect:OnHeroSelectPickedEvent(source, data)
	local picked_hero_id = data.hero
	local player = EntIndexToHScript(source)

	local hero = player:GetAssignedHero()
	if hero ~= nil and CustomHeroSelect:IsPlaceholderHero(hero) then
		if not CustomHeroSelect.pickedHeroes[player:GetTeamNumber()][picked_hero_id] or ALLOW_SAME_HERO_PICKS then
			if not ALLOW_SAME_HERO_PICKS then
				CustomHeroSelect.pickedHeroes[player:GetTeamNumber()][picked_hero_id] = true
				CustomGameEventManager:Send_ServerToTeam(player:GetTeamNumber(), "heroselect_pick_other", { hero_id = picked_hero_id });
			end
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
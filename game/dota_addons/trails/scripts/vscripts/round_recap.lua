if not Round_Recap then
	Round_Recap = {}
	Round_Recap.__index = Round_Recap
end

function Round_Recap:Initialize() -- not actually called at present
	print("Initializing round recap")
end

function Round_Recap:StartRound()
	self.heroes = {}
end

function Round_Recap:EndRound()
	print("Round ended")
	DeepPrintTable(self.heroes)
	CustomGameEventManager:Send_ServerToAllClients("round_recap_start", {heroes = self.heroes})
end

function Round_Recap:AddAbilityDamage(hero, ability, damage)
	local ability_name = "basic_attacks"
	hero_index = hero:GetEntityIndex()
	if ability then ability_name = ability:GetAbilityName() end

	if not self.heroes[hero_index] then self.heroes[hero_index] = {name = hero:GetUnitName(), abilities = {}} end
	if not self.heroes[hero_index].abilities[ability_name] then self.heroes[hero_index].abilities[ability_name] = {name = ability_name, damage = 0} end
	self.heroes[hero_index].abilities[ability_name].damage = self.heroes[hero_index].abilities[ability_name].damage + damage
end
require "game_functions"

if not Turn_Bonuses then
	Turn_Bonuses = {}
	Turn_Bonuses.__index = Turn_Bonuses
end

function Turn_Bonuses:Initialize()
	print("Initializing turn bonuses")
	local cp_fountain = Entities:FindByName(nil, "cp_regener")
	self.location = cp_fountain:GetAbsOrigin()

	self.possible_bonuses = {
		self.StatMax, -- +50% to a random stat (str, def, ats, adf, spd, mov) for 10 seconds
		self.Crit,	 -- Next craft, art or basic attack in next 10 seconds deals double damage
		self.HPHeal, -- Heal 50% of max HP
		-- self.EPHeal, -- Heal 50% of max EP
		self.CPHeal, -- +50 CP
		-- self.ZeroArts, -- Next art in next 10 seconds has no cast time and no EP cost
		self.BruteForce, -- Next offensive craft, art or basic attack in next 10 seconds unbalances target(s)
		self.LinkBreak -- Opponents cannot link for 10 seconds
	}
	self.higher_elements_bonuses = {
		self.StatusAttack, -- Next offensive craft, art or basic attack in next 10 seconds inflicts a random status ailment
		self.VanishBlow, -- Next offensive craft, art or basic attack in next 10 seconds banishes target(s)
		self.CPMax -- +200 CP
	}
	-- self.bonus_names = {
	-- 	self.StatMax = "Stat Bonus",
	-- 	self.Crit = "Critical",
	-- 	self.HPHeal = "HP Heal",
	-- 	self.EPHeal = "EP Heal",
	-- 	self.CPHeal = "CP Boost",
	-- 	self.ZeroArts = "Zero-Arts",
	-- 	self.BruteForce = "Brute Force",
	-- 	self.LinkBreak = "Link Break",
	-- 	self.StatusAttack = "Status Attack",
	-- 	self.VanishBlow = "Vanish Blow",
	-- 	self.CPMax = "CP Max",
	-- }

	self.spawn_interval = 15
	self.radius = 300
	self.update_interval = 1/30
	self.higher_elements_chance_per_round = 0

	self.effect_duration = 10
	self.stat_max_percent = 50
	self.hp_heal = 0.5
	self.cp_heal = 50

	self.current_bonus_name = ""
	self.current_bonus_taken = false
	self.next_bonus = nil
	self.time_until_next_bonus = self.spawn_interval

	local particle = ParticleManager:CreateParticle("particles/turn_bonuses/turn_bonus_zone.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, self.location)
end

function Turn_Bonuses:StartRound(round)
	self.next_bonus = self:RandomBonus(round)
	self:UpdateTurnBonusDisplay()
	Timers:CreateTimer("turn_bonuses_spawn", {
		endTime = self.spawn_interval,
		callback = function()
			self:SpawnBonus(round)
			return self.spawn_interval
		end
	})
end

function Turn_Bonuses:SpawnBonus(round)
	print("Spawning turn bonus")

	self.current_bonus_name = self:GetBonusName(bonus)
	self.current_bonus_taken = false
	self.next_bonus = self:RandomBonus(round)
	self.time_until_next_bonus = self.spawn_interval

	self:RemoveBonus()

	self.bonus_particle = ParticleManager:CreateParticle("particles/turn_bonuses/turn_bonus_available.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(self.bonus_particle, 0, self.location)

	Timers:CreateTimer("turn_bonuses_pickup_check", {
		callback = function()
			local iTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY
			local iType = DOTA_UNIT_TARGET_HERO
			local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
			local iOrder = FIND_CLOSEST
			local units = {}
			units[DOTA_TEAM_GOODGUYS] = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, self.location, nil, self.radius, iTeam, iType, iFlag, iOrder, false)
			units[DOTA_TEAM_BADGUYS] = FindUnitsInRadius(DOTA_TEAM_BADGUYS, self.location, nil, self.radius, iTeam, iType, iFlag, iOrder, false)

			if #units[DOTA_TEAM_BADGUYS] == 0 and #units[DOTA_TEAM_GOODGUYS] > 0 then
				self:GrantBonusTo(units[DOTA_TEAM_GOODGUYS][1])
			elseif #units[DOTA_TEAM_GOODGUYS] == 0 and #units[DOTA_TEAM_BADGUYS] > 0 then
				self:GrantBonusTo(units[DOTA_TEAM_BADGUYS][1])
			else
				return self.update_interval
			end
		end
	})
end

function Turn_Bonuses:GrantBonusTo(unit)
	self.next_bonus(self, unit)
	self.current_bonus_taken = true
	self:RemoveBonus()
	local claimed_particle = ParticleManager:CreateParticle("particles/turn_bonuses/turn_bonus_claimed.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(claimed_particle, 0, self.location)
	ParticleManager:SetParticleControlEnt(claimed_particle, 2, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true)
end

function Turn_Bonuses:RandomBonus(round)
	local bonus = nil
	local higher_elements_chance = round * self.higher_elements_chance_per_round
	local higher_elements_bonus = RandomInt(0, 99) < higher_elements_chance
	if not higher_elements_bonus then
		bonus = self.possible_bonuses[RandomInt(1,#self.possible_bonuses)]
	else
		bonus = self.higher_elements_bonuses[RandomInt(1,#self.higher_elements_bonuses)]
	end
	return bonus
end

function Turn_Bonuses:GetBonusName(bonus)
	local name = nil
	if bonus == self.StatMax then
		name = "Stat Bonus"
	elseif bonus == self.Crit then
		name = "Critical"
	elseif bonus == self.HPHeal then
		name = "HP Heal"
	elseif bonus == self.EPHeal then
		name = "EP Heal"
	elseif bonus == self.CPHeal then
		name = "CP Boost"
	elseif bonus == self.ZeroArts then
		name = "Zero-Arts"
	elseif bonus == self.BruteForce then
		name = "Brute Force"
	elseif bonus == self.LinkBreak then
		name = "Link Break"
	elseif bonus == self.StatusAttack then
		name = "Status Attack"
	elseif bonus == self.VanishBlow then
		name = "Vanish Blow"
	elseif bonus == self.CPMax then
		name = "CP Max"
	end
	return name
end

function Turn_Bonuses:RemoveBonus()
	self:UpdateTurnBonusDisplayTaken()
	if self.bonus_particle then
		ParticleManager:DestroyParticle(self.bonus_particle, false)
		self.bonus_particle = nil
	end
end

function Turn_Bonuses:EndRound()
	Timers:RemoveTimer("turn_bonuses_spawn")
	Timers:RemoveTimer("turn_bonuses_pickup_check")
	self:RemoveBonus()
end

function Turn_Bonuses:UpdateTurnBonusDisplay()
	print(self.time_until_next_bonus)
	CustomGameEventManager:Send_ServerToAllClients("turn_bonus_display_update", {current_bonus = self.current_bonus_name, current_bonus_taken = self.current_bonus_taken, next_bonus = self:GetBonusName(self.next_bonus), time_until_next_bonus = self.time_until_next_bonus})
	Timers:RemoveTimer("turn_bonus_display_tick")
	Timers:CreateTimer("turn_bonus_display_tick", {
		endTime = 1,
		callback = function()
			self.time_until_next_bonus = self.time_until_next_bonus - 1
			CustomGameEventManager:Send_ServerToAllClients("turn_bonus_display_tick", {time_until_next_bonus = self.time_until_next_bonus})
			return 1
		end
	})
end

function Turn_Bonuses:UpdateTurnBonusDisplayTaken()
	CustomGameEventManager:Send_ServerToAllClients("turn_bonus_display_update", {current_bonus = self.current_bonus_name, current_bonus_taken = self.current_bonus_taken, next_bonus = self:GetBonusName(self.next_bonus), time_until_next_bonus = self.time_until_next_bonus})
end

function Turn_Bonuses:StatMax(unit)
	local stats = {STAT_STR, STAT_DEF, STAT_ATS, STAT_ADF, STAT_SPD, STAT_MOV}
	local stat = stats[RandomInt(1, 6)]
	modifyStat(unit, stat, self.stat_max_percent, self.effect_duration)
end

function Turn_Bonuses:Crit(unit)
	unit:AddNewModifier(unit, nil, "modifier_crit", {duration = self.effect_duration})
end

function Turn_Bonuses:HPHeal(unit)
	unit:Heal(unit:GetMaxHealth() * self.hp_heal, unit)
end

function Turn_Bonuses:EPHeal(unit)
end

function Turn_Bonuses:CPHeal(unit)
	modifyCP(unit, self.cp_heal)
end

function Turn_Bonuses:BruteForce(unit)
	unit:AddNewModifier(unit, nil, "modifier_brute_force", {duration = self.effect_duration})
end

function Turn_Bonuses:LinkBreak(unit)
	local origin = unit:GetAbsOrigin()
	local radius = 20100
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(unit:GetTeamNumber(), origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
	for k,target in pairs(targets) do
		target:AddNewModifier(unit, nil, "modifier_link_broken", {duration = self.effect_duration})
	end
end

function Turn_Bonuses:StatusAttack(unit)
end

function Turn_Bonuses:VanishBlow(unit)
end

function Turn_Bonuses:CPMax(unit)
end
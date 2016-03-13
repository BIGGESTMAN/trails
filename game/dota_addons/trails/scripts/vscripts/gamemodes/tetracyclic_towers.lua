require "round_manager"
require "game_functions"

ROUND_TIME = 90
ATTACKER_VICTORY_CAPTURE_TIME = 15

LinkLuaModifier("modifier_capture_blocked", "gamemodes/tetracyclic_towers.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_base_vision_buff", "gamemodes/modifier_base_vision_buff.lua", LUA_MODIFIER_MOTION_NONE)

if not Gamemode_Tetracyclic then
	Gamemode_Tetracyclic = {}
	Gamemode_Tetracyclic.__index = Gamemode_Tetracyclic
end

function Gamemode_Tetracyclic:Initialize()
	self.towers = {}
	self.tower_vision_radius = 700
	self.capture_radius = 400
	self.tower_capture_time = 4
	self.damage_capture_delay = 3
	self:CreateTowers()
end

function Gamemode_Tetracyclic:CreateTowers()
	local tower_locations = Entities:FindAllByName("tetracyclic_tower")
	for k,entity in pairs(tower_locations) do
		self.towers[k] = CreateUnitByName("tetracyclic_tower", entity:GetAbsOrigin(), false, nil, nil, DOTA_TEAM_GOODGUYS)
		self.towers[k]:FindAbilityByName("tetracyclic_tower_passive"):SetLevel(1)
		self.towers[k].capture_progress = 0
		self.towers[k].captured_by = {}
		self.towers[k].being_captured_by = nil
	end
end

function Gamemode_Tetracyclic:StartRound(round)
	self:StartRoundTimer(ROUND_TIME)
end

function Gamemode_Tetracyclic:StartRoundTimer(time)
	self.time_out_quest = SpawnEntityFromTableSynchronous( "quest", { name = "QuestName", title = "#RoundTimer" } )
	self.time_out_quest.EndTime = time
	self.time_out_quest_bar = SpawnEntityFromTableSynchronous( "subquest_base", {
			show_progress_bar = true,
			progress_bar_hue_shift = -119
		} )
	self.time_out_quest:AddSubquest( self.time_out_quest_bar )

	-- text on the quest timer at start
	self.time_out_quest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, time )
	self.time_out_quest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, time )

	-- value on the bar
	self.time_out_quest_bar:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, time )
	self.time_out_quest_bar:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, time )

	Timers:CreateTimer("tetracyclic_round_timer", {
		callback = function()
			self.time_out_quest.EndTime = self.time_out_quest.EndTime - 1
			self.time_out_quest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, self.time_out_quest.EndTime )
			self.time_out_quest_bar:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, self.time_out_quest.EndTime )

			-- Finish the quest when the time is up  
			if self.time_out_quest.EndTime == 0 then 
				EmitGlobalSound("Tutorial.Quest.complete_01") -- Part of game_sounds_music_tutorial
				self.time_out_quest:CompleteQuest()
				RoundManager:EndRound(nil)
				return
			else
				return 1 -- Call again every second
			end
		end
	})
end

function Gamemode_Tetracyclic:EndRoundTimer()
	self.time_out_quest:CompleteQuest()
	Timers:RemoveTimer("tetracyclic_round_timer")
end

function Gamemode_Tetracyclic:EndRound(winning_team)
	local defending_team = self:GetDefendingTeam()
	local attacking_team = getOpposingTeam(defending_team)
	for k,tower in pairs(self.towers) do
		if tower.captured_by[attacking_team] then
			tower:SetTeam(attacking_team)
		else
			tower:SetTeam(defending_team)
		end
	end

	if winning_team == attacking_team then -- old defending team, before round switched
		GameRules:SendCustomMessage("#Tetracyclic_Defenders_Win", 0, 0)
	elseif winning_team == defending_team then
		GameRules:SendCustomMessage("#Tetracyclic_Attackers_Win", 0, 0)
		RoundManager.score[winning_team] = RoundManager.score[winning_team] + 1
	else
		GameRules:SendCustomMessage("#Tetracyclic_Defenders_Win_Timeout", 0, 0)
	end

	self:EndRoundTimer()
end

function onTowerThink(keys)
	local update_interval = 1/30
	local tower = keys.target
	local team = tower:GetTeamNumber()

	AddFOWViewer(team, tower:GetAbsOrigin(), Gamemode_Tetracyclic.tower_vision_radius, update_interval, false)

	if Gamemode_Tetracyclic:TowerCapturable(tower) then
		Gamemode_Tetracyclic:CheckForCapturingUnit(tower)
		Gamemode_Tetracyclic:UpdateTowerCaptureProgress(tower, update_interval)
		Gamemode_Tetracyclic:UpdateTowerCaptureParticles(tower)
	end
end

function Gamemode_Tetracyclic:CheckForCapturingUnit(tower)
	local team = tower:GetTeamNumber()
	local origin = tower:GetAbsOrigin()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, origin, nil, self.capture_radius, iTeam, iType, iFlag, iOrder, false)
	local capturing_unit = nil
	for k,unit in pairs(targets) do
		if not unit:HasModifier("modifier_capture_blocked") then
			capturing_unit = unit
			break
		end
	end

	if not tower.being_captured_by then
		if capturing_unit then
			tower.being_captured_by = capturing_unit
		end
	else
		if capturing_unit ~= tower.being_captured_by then
			ParticleManager:DestroyParticle(tower.capturing_particle, false)
			tower.capturing_particle = nil
			tower.being_captured_by = capturing_unit
		end
	end
end

function Gamemode_Tetracyclic:UpdateTowerCaptureProgress(tower, update_interval)
	if tower.being_captured_by then
		tower.capture_progress = tower.capture_progress + update_interval
		if tower.capture_progress >= self.tower_capture_time then
			self:CaptureTower(tower)
		end
	else
		tower.capture_progress = tower.capture_progress - update_interval
		if tower.capture_progress < 0 then tower.capture_progress = 0 end
	end
end

function Gamemode_Tetracyclic:UpdateTowerCaptureParticles(tower)
	local origin = tower:GetAbsOrigin()
	local tower_height = Vector(0,0,400)

	if tower.being_captured_by then
		if not tower.capturing_particle then
			tower.capturing_particle = ParticleManager:CreateParticle("particles/tetracyclic_towers/capture_rope.vpcf", PATTACH_CUSTOMORIGIN, nil)
			ParticleManager:SetParticleControlEnt(tower.capturing_particle, 0, tower.being_captured_by, PATTACH_POINT_FOLLOW, "attach_hitloc", tower.being_captured_by:GetAbsOrigin(), true)
			ParticleManager:SetParticleControl(tower.capturing_particle, 2, origin)
		end
	end

	if tower.capture_progress > 0 then
		if not tower.capture_progress_particle then
			tower.capture_progress_particle = ParticleManager:CreateParticle("particles/tetracyclic_towers/capture_progress_spiral.vpcf", PATTACH_CUSTOMORIGIN, nil)
		end
		local progress_percent = tower.capture_progress / self.tower_capture_time
		ParticleManager:SetParticleControl(tower.capture_progress_particle, 0, origin + progress_percent * tower_height)
		ParticleManager:SetParticleControl(tower.capture_progress_particle, 1, progress_percent * tower_height * -1)
	else
		if tower.capture_progress_particle then
			ParticleManager:DestroyParticle(tower.capture_progress_particle, false)
			tower.capture_progress_particle = nil
		end
	end
end

function Gamemode_Tetracyclic:CaptureTower(tower)
	tower.captured_by[tower:GetOpposingTeamNumber()] = true
	tower.capture_progress = 0
	tower.being_captured_by = nil

	ParticleManager:DestroyParticle(tower.capturing_particle, false)
	ParticleManager:DestroyParticle(tower.capture_progress_particle, false)
	tower.capturing_particle = nil
	tower.capture_progress_particle = nil

	RoundManager:EndRound(tower:GetOpposingTeamNumber())
end

function Gamemode_Tetracyclic:GetGameWinner()
	if RoundManager.score[DOTA_TEAM_GOODGUYS] == #self.towers then
		return DOTA_TEAM_GOODGUYS
	elseif RoundManager.score[DOTA_TEAM_GOODGUYS] == #self.towers then
		return DOTA_TEAM_BADGUYS
	else
		return nil
	end
end

function Gamemode_Tetracyclic:TowerCapturable(tower)
	local defending_team = self:GetDefendingTeam()
	return tower:GetTeamNumber() == defending_team
end

function Gamemode_Tetracyclic:OnEntityHurt(keys)
	local target = EntIndexToHScript(keys.entindex_killed)
	if target:IsRealHero() then
		target:AddNewModifier(target, nil, "modifier_capture_blocked", {duration = self.damage_capture_delay})
	end
end

function Gamemode_Tetracyclic:OnEntityKilled(keys)
	local unit = EntIndexToHScript(keys.entindex_killed)
	local defending_team = self:GetDefendingTeam()
	local attacking_team = getOpposingTeam(defending_team)

	if unit:IsRealHero() then
		local living_heroes = {}
		living_heroes[DOTA_TEAM_GOODGUYS] = 0
		living_heroes[DOTA_TEAM_BADGUYS] = 0
		for k,hero in pairs(getAllHeroes()) do
			if hero and hero:IsAlive() then
				living_heroes[hero:GetTeam()] = living_heroes[hero:GetTeam()] + 1
			end
		end

		if living_heroes[defending_team] == 0 then
			self:EndRoundTimer()
			self:StartRoundTimer(ATTACKER_VICTORY_CAPTURE_TIME)
			GameRules:SendCustomMessage("#Tetracyclic_Attackers_Win_Kills", 0, 0)
		elseif living_heroes[attacking_team] == 0 then
			RoundManager:EndRound(defending_team)
		end
	end
end

function Gamemode_Tetracyclic:initializeStats(hero)
	hero:AddNewModifier(hero, nil, "modifier_base_vision_buff", {})
end

function Gamemode_Tetracyclic:GetDefendingTeam()
	return (RoundManager.current_round % 2) + 2
end

modifier_capture_blocked = class({})

function modifier_capture_blocked:GetTexture()
	return "backdoor_protection"
end

function modifier_capture_blocked:IsDebuff()
	return true
end
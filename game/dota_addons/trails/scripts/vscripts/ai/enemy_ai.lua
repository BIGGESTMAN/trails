require "libraries/util"
require "game_functions"

THINK_INTERVAL = 0.5

if not EnemyAI then EnemyAI = class({}) end

function EnemyAI:DefineAI(unit, setupfunction)
	-- local ai = class({}, nil, EnemyAI)
	local ai = {}
	setmetatable( ai, {__index = EnemyAI} )
	self.__index = self

	ai.unit = unit
	ai.decisionState = "Default",
	unit:SetIdleAcquire(false)
	-- print(ai)
	setupfunction(ai)

	-- print(ai, self, ai.unit, self.unit)
	Timers:CreateTimer(0, function()
		ai.Think(ai)
		return THINK_INTERVAL
	end)

	return ai
end

function EnemyAI:Think()
	-- print(self)
	-- print("[AI] Thinking")
	-- print(IsValidAlive(self.unit), self.unit)
	if not IsValidAlive(self.unit) then
		return
	else
		if self.stateDuration and GameRules:GetGameTime() >= self.stateEnteredTime + self.stateDuration then
			self:EndState()
		else
			-- print(self:GetStateMethod(self.decisionState), self.decisionState)
			self:GetStateMethod(self.decisionState)(self)
		end
		-- return THINK_INTERVAL

		-- if self.state == AI_NORMAL then
		-- 	self:ThinkNormal()
		-- elseif self.state == AI_CAN_CAST then
		-- 	self:ThinkAggressive()
		-- end
		
		-- if self.order ~= nil then
		-- 	ExecuteOrderFromTable(self.order)
		-- end
	end
end

function EnemyAI:EndState()
	-- self.stateDuration = nil
	self:GetStateEndMethod(self.decisionState)()
	self:SwitchState("Default")
end

function EnemyAI:DefaultBehavior()
	local target = self:ClosestEnemyUnit()

	-- print(self.unit:CanEntityBeSeenByMyTeam(target))
	if IsValidEntity(target) and self.unit:CanEntityBeSeenByMyTeam(target) then
		self:OrderAttack(target)
	end
end

function EnemyAI:SwitchState(newState, duration)
	local func = self:GetStateMethod(newState)
	if func then
		self.decisionState = newState
		self.stateEnteredTime = GameRules:GetGameTime()
		self.stateDuration = duration
	else
		print("[AI] Can't switch to state " .. newState .. ", as it doesn't exist")
	end
end

function EnemyAI:GetStateMethod(state)
	return self['State_' .. state]
end

function EnemyAI:GetStateEndMethod(state)
	return self['State_'..state.."_End"]
end

function EnemyAI:ClosestEnemyUnitInRange(range)
	local enemies = FindUnitsInRadius(self.unit:GetTeam(), self.unit:GetAbsOrigin(), nil, range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
	return enemies[1]
end

function EnemyAI:ClosestEnemyUnit()
	return self:ClosestAmong(getAllLivingHeroes())
end

function EnemyAI:ClosestAmong(units)
	local target = nil
	local closestrange = nil

	for _,unit in pairs(units) do
		local distanceToUnit = (self.unit:GetAbsOrigin() - unit:GetOrigin()):Length2D()
		if closestrange == nil or distanceToUnit < closestrange then
			closestrange = distanceToUnit
			target = unit
		end
	end

	return target
end

function EnemyAI:IssueOrder(order)
	-- print("issuing order")
	order.UnitIndex = self.unit:entindex()
	if self.unit:IsChanneling() then order.Queue = 1 end
	-- DeepPrintTable(order)
	ExecuteOrderFromTable(order)
end

function EnemyAI:OrderAttack(target)
	self:IssueOrder({
		OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
		TargetIndex = target:entindex()
	})
end

function EnemyAI:Cast(ability_name)
	local ability = self.unit:FindAbilityByName(ability_name)
	if ability then
		-- print("[AI] Casting " .. ability_name)
		self:IssueOrder({
			OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
			AbilityIndex = ability:entindex(),
		})
	end
end

function EnemyAI:MoveTowards(target)
	self:IssueOrder({
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_TARGET,
		TargetIndex = target:entindex(),
	})
end

function EnemyAI:CanCast(ability_name)
	local ability = self.unit:FindAbilityByName(ability_name)
	return ability ~= nil and ability:IsFullyCastable() and ability:IsCooldownReady()
end

function EnemyAI:RandomizeAbilityCooldown(ability_name)
	local ability = self.unit:FindAbilityByName(ability_name)
	ability:StartCooldown(RandomFloat(0, ability:GetCooldownTime()))
	-- print(ability:GetCooldownTimeRemaining())
end

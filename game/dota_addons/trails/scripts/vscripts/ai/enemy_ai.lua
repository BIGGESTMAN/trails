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
	ai.decisionState = "Default"
	ai.next_cast_time = 0
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
		elseif self:ShouldDoNewAction() then
			-- print(self:GetStateMethod(self.decisionState), self.decisionState)
			self:GetStateMethod(self.decisionState)(self, self.stateArgs)
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
	local endFunction = self:GetStateEndMethod(self.decisionState)
	if endFunction then endFunction() end
	self:SwitchState("Default")
end

function EnemyAI:DefaultBehavior()
	local target = self:ClosestEnemyUnit()

	-- print(self.unit:CanEntityBeSeenByMyTeam(target))
	if IsValidEntity(target) and self.unit:CanEntityBeSeenByMyTeam(target) then
		self:OrderAttack(target)
	end
end

function EnemyAI:SwitchState(newState, duration, args)
	local func = self:GetStateMethod(newState)
	if func then
		self.decisionState = newState
		self.stateEnteredTime = GameRules:GetGameTime()
		self.stateDuration = duration
		self.stateArgs = args
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

function EnemyAI:GetRandomEnemyUnit()
	return getAllLivingHeroes()[RandomInt(1, #getAllLivingHeroes())]
end

function EnemyAI:IssueOrder(order)
	-- print("issuing order")
	order.UnitIndex = self.unit:entindex()
	if self.unit:IsChanneling() then order.Queue = 1 end -- dunno if this is still necessary with shoulddonewaction() check but whatever
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
		print("[AI] Casting " .. ability_name)
		print(ability:GetCooldownTimeRemaining())
		self:IssueOrder({
			OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
			AbilityIndex = ability:entindex(),
		})
	end
end

function EnemyAI:CastAtTarget(ability_name, target)
	local ability = self.unit:FindAbilityByName(ability_name)
	if ability then
		self:IssueOrder({
			OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
			AbilityIndex = ability:entindex(),
			TargetIndex = target:entindex(),
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
	-- print("[AI] Cooldown of "..ability_name.." remaining: ", ability:GetCooldownTimeRemaining())
	return ability ~= nil and self.next_cast_time <= GameRules:GetGameTime() and ability:IsFullyCastable() and ability:IsCooldownReady() and ability:IsActivated()
end

function EnemyAI:RandomizeAbilityCooldown(ability_name)
	local ability = self.unit:FindAbilityByName(ability_name)
	ability:StartCooldown(RandomFloat(0, ability:GetCooldownTime()))
	-- print(ability:GetCooldownTimeRemaining())
end

function EnemyAI:ShouldDoNewAction()
	return not self.unit:IsChanneling() and not self.unit:GetCurrentActiveAbility()
end

function EnemyAI:HealthPercentBelow(threshold)
	return self.unit:GetHealthPercent() <= threshold
end

function EnemyAI:DisableAbilityFor(ability_name, duration)
	local ability = self.unit:FindAbilityByName(ability_name)
	if not duration then
		ability:SetActivated(false)
	else
		ability:SetActivated(false)
		Timers:CreateTimer(duration, function() ability:SetActivated(true) end)
	end
end

function EnemyAI:CanCastNextAbility()
	return self:CanCast(self:GetNextAbility())
end

function EnemyAI:GetNextAbility()
	return self.next_ability
end

function EnemyAI:SetNextAbility(ability_name)
	self.next_ability = ability_name
end

function EnemyAI:SetTimeUntilNextCast(duration)
	self.next_cast_time = GameRules:GetGameTime() + duration
end

function EnemyAI:MoveToAndCastAtTarget(ability_name, target, callback)
	self:SwitchState("Moving_To_And_Casting", nil, {ability_name = ability_name, target = target, callback = callback})
end

function EnemyAI:State_Moving_To_And_Casting(args)
	local ability = self.unit:FindAbilityByName(args.ability_name)
	local target = args.target
	local cast_range = ability:GetCastRange(nil, target)
	if self.unit:GetRangeToUnit(target) < cast_range then
		self:CastAtTarget(args.ability_name, target)
		self:SwitchState("Default")
		if args.callback then args.callback() end
	else
		self:MoveTowards(target)
	end
end
require "libraries/animations"
require "libraries/util"
require "boss_abilities/sunstrike"
require "gamemodes/boss"

CAST_INTERVAL = 15

BOSS_SPELL_RESULT_SUCCESS = 1
BOSS_SPELL_RESULT_FAILURE = 2

if not BossAI then
	_G.BossAI = class({})
end

function BossAI:Start(unit)
	-- levelUpAbilities(unit)

	local update_interval = 1/30

	if not self.boss_states then self.boss_states = {} end
	self.boss_states[unit] = {}
	self.boss_states[unit].aggro_table = {}
	self.boss_states[unit].time_since_cast = CAST_INTERVAL - 5 -- don't cast for first 5 seconds

	self:ActionLoop(unit, update_interval)
end

function BossAI:ActionLoop(boss, update_interval)
	Timers:CreateTimer(0, function()
		self.boss_states[boss].time_since_cast = self.boss_states[boss].time_since_cast + update_interval
		if boss:IsAlive() then
			if self.boss_states[boss].time_since_cast >= CAST_INTERVAL then
				self.boss_states[boss].time_since_cast = self.boss_states[boss].time_since_cast - CAST_INTERVAL
				self:CastRandomSpell(boss)
			else
				local target = self:GetHighestAggroHero(boss) or self:GetNearestHero(boss)
				if target then
					if boss:GetForceAttackTarget() ~= target then
						boss:Stop()
						boss:SetForceAttackTarget(target)
					end
				else
					boss:SetForceAttackTarget(nil)
				end
			end
			return update_interval
		end
	end)
end

function BossAI:GetHighestAggroHero(boss)
	local aggro_table = self.boss_states[boss].aggro_table
	local highest_aggro_hero = nil
	for hero,aggro in pairs(aggro_table) do
		if highest_aggro_hero == nil or (aggro > aggro_table[hero] and hero:IsAlive()) then
			highest_aggro_hero = hero
		end
	end
	return highest_aggro_hero
end

function BossAI:GetNearestHero(boss)
	local nearest_hero = nil
	for k,hero in pairs(getAllLivingHeroes()) do
		if nearest_hero == nil or self:DistanceToUnit(boss, hero) < self:DistanceToUnit(boss, nearest_hero) then
			nearest_hero = hero
		end
	end
	return nearest_hero
end

function BossAI:DistanceToUnit(boss, unit)
	return (boss:GetAbsOrigin() - unit:GetAbsOrigin()):Length2D()
end

function BossAI:CastRandomSpell(boss)
	local ability_index = RandomInt(0, getAbilityCount(boss) - 1)
	-- self:CastSpell(boss, boss:GetAbilityByIndex(ability_index))
	self:CastSpell(boss, boss:FindAbilityByName("boss_betrayal_bolt"))
end

function BossAI:CastSpell(boss, ability, target)
	-- if not target then
		-- DebugPrint("[AI] Casting " .. abilityName)
	
	-- local order = {
	-- 	OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
	-- 	AbilityIndex = ability:entindex(),
	-- 	UnitIndex = boss:entindex(),
	-- }
	-- self:SetOrder(order)

	-- elseif target.x then
	-- 	self:OrderCastAtPoint(abilityName, target)
	-- else
	-- 	self:OrderCastAtTarget(abilityName, target)
	-- end

	ability:SpellStart(boss)
	Timers:CreateTimer(ability:GetCastPoint(), function()
		if IsValidAlive(boss) then
			ability:SpellCast(boss)
		end
	end)
	StartAnimation(boss, {duration=44 / (ability:GetCastPoint() * 30), activity=ACT_DOTA_CAST_ABILITY_2, rate=1})
end

function BossAI:ReportSpellResult(boss, result)
	if result == BOSS_SPELL_RESULT_FAILURE then
		Gamemode_Boss:MakeBossVulnerable(boss)
	end
end

function BossAI:SetOrder(order_table)
	DeepPrintTable(order_table)
	ExecuteOrderFromTable(order_table)
end
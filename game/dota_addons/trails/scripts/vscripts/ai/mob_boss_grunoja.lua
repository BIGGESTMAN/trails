require("ai/enemy_ai")

function Spawn()
	local ai = EnemyAI:DefineAI(thisEntity, function(ai)
		
		-- ai:RandomizeAbilityCooldown("mob_boss_grunoja_ground_smash")
		ai:SetNextAbility("mob_boss_grunoja_ground_smash")

		function ai:State_Default()
			if self:HealthPercentBelow(50) then
				if self:CanCast("mob_boss_grunoja_fists_of_fury") then
					self:MoveToAndCastAtTarget("mob_boss_grunoja_fists_of_fury", self:GetRandomEnemyUnit(), function() 
						self:DisableAbilityFor("mob_boss_grunoja_fists_of_fury", 80)
						self:SetTimeUntilNextCast(8)
					end)
				elseif self:CanCastNextAbility() then
					self:CastNextAbility()
					self:SetTimeUntilNextCast(8)
				else
					return self:DefaultBehavior()
				end
			elseif self:HealthPercentBelow(75) then
				if self:CanCast("mob_boss_grunoja_grove_call") then
					self:Cast("mob_boss_grunoja_grove_call")
					self:DisableAbilityFor("mob_boss_grunoja_grove_call")
					self:SetTimeUntilNextCast(10)
				elseif self:CanCastNextAbility() then
					self:CastNextAbility()
					self:SetTimeUntilNextCast(10)
				else
					return self:DefaultBehavior()
				end
			else
				if self:CanCastNextAbility() then
					self:CastNextAbility()
					self:SetTimeUntilNextCast(10)
				else
					return self:DefaultBehavior()
				end
			end
		end

		function ai:CastNextAbility()
			if self:GetNextAbility() == "mob_boss_grunoja_ground_smash" then
				self:CastAtTarget("mob_boss_grunoja_ground_smash", self:GetRandomEnemyUnit())
				if self:HealthPercentBelow(75) then
					self:SetNextAbility("mob_boss_grunoja_go_bananas")
				end
			elseif self:GetNextAbility() == "mob_boss_grunoja_go_bananas" then
				self:SwitchState("Casting_Go_Bananas", 5)
				self:SetNextAbility("mob_boss_grunoja_ground_smash")
			end
		end

		function ai:State_Casting_Go_Bananas()
			if self:ClosestEnemyUnitInRange(250) then
				self:Cast("mob_boss_grunoja_go_bananas")
				self:SwitchState("Default")
			else
				self:MoveTowards(self:ClosestEnemyUnit())
			end
		end

		function ai:State_Casting_Go_Bananas_End()
			self:Cast("mob_boss_grunoja_go_bananas")
		end
	end)
end

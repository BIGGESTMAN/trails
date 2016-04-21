require("ai/enemy_ai")

function Spawn()
	local ai = EnemyAI:DefineAI(thisEntity, function(ai)
		function ai:State_Default()
			return self:DefaultBehavior()
		end
	end)
end

function Spawn()
	local ai = EnemyAI:DefineAI(thisEntity, function(ai)

		ai:RandomizeAbilityCooldown("mob_gordi_chief_go_ape")
		ai:RandomizeAbilityCooldown("mob_gordi_chief_knuckleduster")
		
		function ai:State_Default()
			if self:CanCast("mob_gordi_chief_go_ape") then
				self:SwitchState("Casting_Go_Ape", 5)
			elseif self:CanCast("mob_gordi_chief_knuckleduster") then
				self:SwitchState("Casting_Knuckleduster")
			end

			return self:DefaultBehavior()
		end

		function ai:State_Casting_Go_Ape()
			if self:ClosestEnemyUnitInRange(250) then
				self:Cast("mob_gordi_chief_go_ape")
				self:SwitchState("Default")
			else
				self:MoveTowards(self:ClosestEnemyUnit())
			end
		end

		function ai:State_Casting_Go_Ape_End()
			self:Cast("mob_gordi_chief_go_ape")
		end

		function ai:State_Casting_Knuckleduster()
			local target = self:ClosestEnemyUnitInRange(150)
			if target then
				self:CastAtTarget("mob_gordi_chief_knuckleduster", target)
				self:SwitchState("Default")
			else
				self:MoveTowards(self:ClosestEnemyUnit())
			end
		end
	end)
end

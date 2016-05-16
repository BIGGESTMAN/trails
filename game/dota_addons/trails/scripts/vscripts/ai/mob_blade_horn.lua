require("ai/enemy_ai")

function Spawn()
	local ai = EnemyAI:DefineAI(thisEntity, function(ai)

		ai:RandomizeAbilityCooldown("mob_blade_horn_gore")
		
		function ai:State_Default()
			if self:CanCast("mob_blade_horn_gore") then
				local target = self:ClosestEnemyUnitInRange(600)
				if target then
					self:CastAtPoint("mob_blade_horn_gore", target:GetAbsOrigin())
				else
					return self:DefaultBehavior()
				end
			else
				return self:DefaultBehavior()
			end
		end
	end)
end

require("ai/enemy_ai")

function Spawn()
	local ai = EnemyAI:DefineAI(thisEntity, function(ai)

	ai.wander_distance = 500
	ai.aggro_distance = 500
		
		function ai:State_Default()
			if distanceBetween(self.unit:GetAbsOrigin(), self.unit.enemy_group.spawn_point) <= self.wander_distance then
				local target = self:ClosestEnemyUnitInRange(self.aggro_distance)
				if target and distanceBetween(self.unit.enemy_group.spawn_point, target:GetAbsOrigin()) <= self.wander_distance then
					self:MoveTowards(target)
				elseif self.unit:IsIdle() then
					self:MoveToLocation(randomPointInCircle(self.unit:GetAbsOrigin(), 150))
				end
			else
				self:MoveToLocation(self.unit.enemy_group.spawn_point)
			end
		end
	end)
end

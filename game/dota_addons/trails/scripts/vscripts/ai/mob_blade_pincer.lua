require("ai/enemy_ai")

function Spawn()
	thisEntity:SetRenderColor(0,255,0) -- this definitely 100% belongs in an ai file
	local ai = EnemyAI:DefineAI(thisEntity, function(ai)

		ai:RandomizeAbilityCooldown("mob_blade_pincer_stridulate")
		ai:RandomizeAbilityCooldown("mob_blade_pincer_pincer_attack")
		
		function ai:State_Default()
			if self:CanCast("mob_blade_pincer_stridulate") then
				self:Cast("mob_blade_pincer_stridulate")
			elseif self:CanCast("mob_blade_pincer_pincer_attack") then
				local target = self:ClosestEnemyUnitInRange(150)
				if target then
					self:CastAtTarget("mob_blade_pincer_pincer_attack", target)
				else
					self:MoveTowards(self:ClosestEnemyUnit())
				end
			else
				return self:DefaultBehavior()
			end
		end
	end)
end

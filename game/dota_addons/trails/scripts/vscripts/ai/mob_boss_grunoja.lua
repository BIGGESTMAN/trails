require("ai/enemy_ai")

function Spawn()
	local ai = EnemyAI:DefineAI(thisEntity, function(ai)
		
		-- ai:RandomizeAbilityCooldown("mob_boss_grunoja_ground_smash")

		function ai:State_Default()
			if self:CanCast("mob_boss_grunoja_ground_smash") then
				self:CastAtTarget("mob_boss_grunoja_ground_smash", self:GetRandomEnemyUnit())
			else
				return self:DefaultBehavior()
			end
		end
	end)
end

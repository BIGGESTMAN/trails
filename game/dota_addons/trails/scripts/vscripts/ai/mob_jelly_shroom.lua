require("ai/enemy_ai")

function Spawn()
	local ai = EnemyAI:DefineAI(thisEntity, function(ai)

		ai:RandomizeAbilityCooldown("mob_jelly_shroom_spores")
		-- print(ai)
		function ai:State_Default()
			if self:CanCast("mob_jelly_shroom_spores") then
				self:SwitchState("Aggressive", 5)
			end

			return self:DefaultBehavior()
		end

		function ai:State_Aggressive()
			if self:ClosestEnemyUnitInRange(200) then
				self:Cast("mob_jelly_shroom_spores")
				self:SwitchState("Default")
			else
				self:MoveTowards(self:ClosestEnemyUnit())
			end
		end

		function ai:State_Aggressive_End()
			self:Cast("mob_jelly_shroom_spores")
		end
	end)

	-- AICore.DefineAI("Mob_Jelly_Shroom", function(ai)
	-- 	function ai:State_Default()
	-- 		print("?")
	-- 		if self:ClosestEnemyUnitInRange(200) and self:TryCasting("mob_jelly_shroom_spores") then
	-- 			return
	-- 		end

	-- 		return self:DefaultBehavior()
	-- 	end
	-- end):Setup(thisEntity)
end

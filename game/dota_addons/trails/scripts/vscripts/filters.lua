require "libraries/util"
require "game_functions"

if not Filters then 
	Filters = {}
	Filters.__index = Filters
end

function Filters:DamageFilter(event)
	return true
end

function Filters:ModifierGainedFilter(event)
	local caster = EntIndexToHScript(event.entindex_caster_const)
	local target = EntIndexToHScript(event.entindex_parent_const)
	return true
end

function Filters:ModifyGoldFilter(event)
	local hero = PlayerResource:GetPlayer(event.player_id_const):GetAssignedHero()
	return true
end

function Filters:ExecuteOrderFilter(event)
	if event.order_type < 100 then
		for k,unit_index in pairs(event.units) do
			if EntIndexToHScript(unit_index):HasModifier("modifier_freeze") then
				local delayed_order = {
					UnitIndex = unit_index,
					OrderType = event.order_type + 100,
					TargetIndex = event.entindex_target,
					AbilityIndex = event.entindex_ability,
					Position = Vector(event.position_x, event.position_y, event.position_z),
					Queue = event.queue
				}
				Timers:CreateTimer(1, function() ExecuteOrderFromTable(delayed_order) end)
				return false
			end
		end
	else
		event.order_type = event.order_type - 100
	end
	return true
end
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
	-- DeepPrintTable(event)
	return event.reason_const == 17 or event.reason_const == DOTA_ModifyGold_PurchaseItem
end

function Filters:ExecuteOrderFilter(event)
	local unit = nil
	if event.units['0'] then unit = EntIndexToHScript(event.units['0']) end
	if event.order_type >= 200 then
		event.order_type = event.order_type - 200
	elseif event.order_type < 100 then
		for k,unit_index in pairs(event.units) do
			if EntIndexToHScript(unit_index):HasModifier("modifier_confuse") then
				return false
			end
			-- if EntIndexToHScript(unit_index):HasModifier("modifier_freeze") then
			-- 	local delayed_order = {
			-- 		UnitIndex = unit_index,
			-- 		OrderType = event.order_type + 100,
			-- 		TargetIndex = event.entindex_target,
			-- 		AbilityIndex = event.entindex_ability,
			-- 		Position = Vector(event.position_x, event.position_y, event.position_z),
			-- 		Queue = event.queue
			-- 	}
			-- 	Timers:CreateTimer(FREEZE_COMMAND_DELAY, function() ExecuteOrderFromTable(delayed_order) end)
			-- 	return false
			-- end
		end
	else
		event.order_type = event.order_type - 100
	end
	if unit:HasModifier("modifier_chaos_trigger_casting") and event.order_type == DOTA_UNIT_ORDER_STOP then
		local target_point = unit:GetAbsOrigin() + unit:GetForwardVector()
		local self_move_order = {
			UnitIndex = event.units['0'],
			OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
			Position = target_point,
		}
		ExecuteOrderFromTable(self_move_order)
		return false
	end
	if unit:HasModifier("modifier_angel_guardian_reviving") and event.order_type == DOTA_UNIT_ORDER_STOP then
		unit:RemoveModifierByName("modifier_angel_guardian_reviving")
	end
	return true
end
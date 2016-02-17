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
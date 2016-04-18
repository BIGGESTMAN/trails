--[[
	Basic Barebones
]]

-- Required files to be visible from anywhere
require( 'libraries/timers' )
require( 'barebones' )

function Precache( context )
	-- NOTE: IT IS RECOMMENDED TO USE A MINIMAL AMOUNT OF LUA PRECACHING, AND A MAXIMAL AMOUNT OF DATADRIVEN PRECACHING.
	-- Precaching guide: https://moddota.com/forums/discussion/119/precache-fixing-and-avoiding-issues

	--[[
	This function is used to precache resources/units/items/abilities that will be needed
	for sure in your game and that cannot or should not be precached asynchronously or 
	after the game loads.

	See GameMode:PostLoadPrecache() in barebones.lua for more information
	]]

	print("[BAREBONES] Performing pre-load precache")

	-- Particles can be precached individually or by folder
	-- It it likely that precaching a single particle system will precache all of its children, but this may not be guaranteed
	PrecacheResource("particle", "particles/general/evade_message.vpcf", context)
	PrecacheResource("particle", "particles/turn_bonuses/turn_bonus_available.vpcf", context)
	PrecacheResource("particle", "particles/turn_bonuses/turn_bonus_claimed.vpcf", context)
	PrecacheResource("particle", "particles/turn_bonuses/turn_bonus_zone.vpcf", context)
	PrecacheResource("particle", "particles/combat_links/link.vpcf", context)
	PrecacheResource("particle_folder", "particles/arts", context)
	PrecacheResource("particle_folder", "particles/master_quartz", context)
	PrecacheResource("particle_folder", "particles/status_effects", context)
	PrecacheResource("particle_folder", "particles/aoe_previews", context)
	PrecacheResource("particle_folder", "particles/tetracyclic_towers", context)
	PrecacheResource("particle_folder", "particles/bosses", context)
	PrecacheResource("particle_folder", "particles/mobs", context)
	PrecacheResource("particle_folder", "particles/msg_fx", context)

	-- Models can also be precached by folder or individually
	-- PrecacheModel should generally used over PrecacheResource for individual models
	PrecacheResource("model_folder", "particles/heroes/antimage", context)
	PrecacheResource("model", "particles/heroes/viper/viper.vmdl", context)
	-- PrecacheModel("models/heroes/viper/viper.vmdl", context)

	-- Sounds can precached here like anything else
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_gyrocopter.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_custom.vsndevts", context)

	-- Entire items can be precached by name
	-- Abilities can also be precached in this way despite the name
	PrecacheItemByNameSync("example_ability", context)
	PrecacheItemByNameSync("item_example_item", context)

	-- Entire heroes (sound effects/voice/models/particles) can be precached with PrecacheUnitByNameSync
	-- Custom units from npc_units_custom.txt can also have all of their abilities and precache{} blocks precached in this way
	PrecacheUnitByNameSync("npc_dota_hero_ancient_apparition", context)
	PrecacheUnitByNameSync("npc_dota_hero_enigma", context)
end

-- Create the game mode when we activate
function Activate()
	GameRules:SetCustomGameSetupAutoLaunchDelay(0)

	GameRules.GameMode = GameMode()
	GameRules.GameMode:InitGameMode()
end
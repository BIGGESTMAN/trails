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
	PrecacheResource("particle_folder", "particles/test_particle", context)

	-- Models can also be precached by folder or individually
	-- PrecacheModel should generally used over PrecacheResource for individual models
	PrecacheResource("model_folder", "particles/heroes/antimage", context)
	PrecacheResource("model", "particles/heroes/viper/viper.vmdl", context)
	PrecacheModel("models/heroes/viper/viper.vmdl", context)
	PrecacheModel("models/reimu/reimu_reference.vmdl", context)

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

	-- ListenToGameEvent("dota_item_purchase", updateAghsAbilities, nil)
	-- ListenToGameEvent("dota_item_picked_up", updateAghsAbilities, nil)
	-- ListenToGameEvent("dota_inventory_player_got_item", test, nil)
	-- ListenToGameEvent("dota_inventory_item_added", test, nil)
	-- ListenToGameEvent("dota_inventory_item_changed", test, nil)
end

function updateAghsAbilities(eventInfo)
	print("item purchased or picked up")
	for k,v in pairs(eventInfo) do
		print(k,v)
	end
	if eventInfo.itemname == "item_ultimate_scepter" then
		local hero = EntIndexToHScript(eventInfo.HeroEntityIndex)
		if hero:GetName() == "npc_dota_hero_skywrath_mage" then
			hero:FindAbilityByName("peerless_wind_god"):ApplyDataDrivenModifier(hero, hero, "modifier_peerless_wind_god_learned", {})
		elseif hero:GetName() == "npc_dota_hero_rubick" then
			hero:FindAbilityByName("double_spark"):ApplyDataDrivenModifier(hero, hero, "modifier_double_spark_learned", {})
		end
	end
end

function test(eventInfo)
	print("dota_inventory_item_added")
	for k,v in pairs(eventInfo) do
		print(k,v)
	end
end
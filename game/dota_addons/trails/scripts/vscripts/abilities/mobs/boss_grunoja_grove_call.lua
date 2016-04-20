require "game_functions"
require "libraries/util"
require "aoe_previews"
require "gamemodes/boss"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability

	local unit = Gamemode_Boss:SpawnEnemy("trailsadventure_mob_gordi_chief", Gamemode_Boss:GetNextArenaPoint())

	local particle = ParticleManager:CreateParticle("particles/mobs/boss_grunoja_grove_call/dust_cloud.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
end
if not Music then
	Music = class({})
end

MUSIC_TYPE_EXPLORING = "Trails.Path_Of_Spirits"
MUSIC_TYPE_COMBAT = "Trails.Glint_Of_Cold_Steel"
MUSIC_TYPE_BOSS = "Trails.Eliminate_Crisis"
MUSIC_LENGTHS = {}
MUSIC_LENGTHS[MUSIC_TYPE_EXPLORING] = 188
MUSIC_LENGTHS[MUSIC_TYPE_COMBAT] = 148
MUSIC_LENGTHS[MUSIC_TYPE_BOSS] = 216

function Music:InitializeFor(hero)
	hero.music_playing = ""
	hero:GetPlayerOwner():SetMusicStatus(DOTA_MUSIC_STATUS_NONE, 100000)
end

function Music:SwitchMusic(music_type)
	self.current_music = music_type
	for k,hero in pairs(getAllHeroes()) do
		if hero.music_playing then
			local player = hero:GetPlayerOwner()
			self:StopMusicForPlayer(player)
			self:StartMusicForPlayer(player)
		end
	end
end

function Music:StartMusicForPlayer(player)
	local hero = player:GetAssignedHero()
	Timers:CreateTimer("music_timer_"..player:GetPlayerID(), {
		callback = function()
			local music_string = self.current_music
			EmitSoundOnClient(music_string, player)
			hero.music_playing = music_string
			return MUSIC_LENGTHS[self.current_music]
		end
	})
end

function Music:StopMusicForPlayer(player)
	local hero = player:GetAssignedHero()
	Timers:RemoveTimer("music_timer_"..player:GetPlayerID())
	player:StopSound(hero.music_playing)
	hero.music_playing = nil
end
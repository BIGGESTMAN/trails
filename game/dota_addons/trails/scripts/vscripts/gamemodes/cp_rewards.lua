if not CPRewards then
	CPRewards = class({})
end

BASE_CP_REWARD = 10

function CPRewards:RewardCP(recipient, enemy, cp)
	if cp ~= 0 then
		cp = cp or BASE_CP_REWARD
		if recipient then
			local particle = ParticleManager:CreateParticle("particles/bosses/cp_reward_rays.vpcf", PATTACH_ABSORIGIN_FOLLOW, recipient)
			ParticleManager:SetParticleControlEnt(particle, 1, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)

			modifyCP(recipient, cp)
		else
			for k,hero in pairs(getAllLivingHeroes()) do
				self:RewardCP(hero, enemy)
			end
		end
		EmitSoundOn("Trails.Unbalanced", enemy)
	end
end
if not CPRewards then
	CPRewards = class({})
end

BASE_CP_REWARD = 10

function CPRewards:RewardCP(recipient, enemy)
	local particle = ParticleManager:CreateParticle("particles/bosses/cp_reward_rays.vpcf", PATTACH_ABSORIGIN_FOLLOW, recipient)
	ParticleManager:SetParticleControlEnt(particle, 1, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)

	modifyCP(recipient, BASE_CP_REWARD)
end
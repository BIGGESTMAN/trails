if not AOEPreviews then
	AOEPreviews = class({})
end

AOE_TYPE_CIRCLE = 0
AOE_TYPE_LINE = 1

function AOEPreviews:Create(aoe_type, params)
	local particle = nil
	local origin = params.origin
	if aoe_type == AOE_TYPE_CIRCLE then
		local attach_type = PATTACH_CUSTOMORIGIN
		if params.follow then attach_type = PATTACH_ABSORIGIN_FOLLOW end

		particle = ParticleManager:CreateParticle("particles/aoe_previews/circle.vpcf", attach_type, params.follow)
		if not params.follow then
			ParticleManager:SetParticleControl(particle, 0, origin)
		end
		ParticleManager:SetParticleControl(particle, 1, Vector(params.radius,0,0))
	end
	return particle

end

function AOEPreviews:Remove(id)
	ParticleManager:DestroyParticle(id, false)
end
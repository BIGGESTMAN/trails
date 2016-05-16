if not AOEPreviews then
	AOEPreviews = class({})
end

AOE_TYPE_CIRCLE = 0
AOE_TYPE_LINE = 1

function AOEPreviews:Create(aoe_type, params)
	local particle = nil
	local origin = params.origin

	local attach_type = PATTACH_CUSTOMORIGIN
	if params.follow then attach_type = PATTACH_ABSORIGIN_FOLLOW end
	if aoe_type == AOE_TYPE_CIRCLE then
		particle = ParticleManager:CreateParticle("particles/aoe_previews/circle.vpcf", attach_type, params.follow)
		if not params.follow then
			ParticleManager:SetParticleControl(particle, 0, origin)
		end
		ParticleManager:SetParticleControl(particle, 1, Vector(params.radius,0,0))
	elseif aoe_type == AOE_TYPE_LINE then
		local left = RotatePosition(Vector(0,0,0), QAngle(0,90,0), params.direction)
		particle = ParticleManager:CreateParticle("particles/aoe_previews/line.vpcf", attach_type, nil)
		ParticleManager:SetParticleControl(particle, 0, origin)
		ParticleManager:SetParticleControl(particle, 1, origin + params.direction * params.range + left * params.radius / 2)
		ParticleManager:SetParticleControl(particle, 2, origin + params.direction * params.range + left * params.radius / -2)
		ParticleManager:SetParticleControl(particle, 3, origin + left * params.radius / 2)
		ParticleManager:SetParticleControl(particle, 4, origin + left * params.radius / -2)
		ParticleManager:SetParticleControlForward(particle, 0, params.direction)

		-- local points = {origin + params.direction * params.range + left * params.radius / 2,
		-- 				origin + params.direction * params.range + left * params.radius / -2,
		-- 				origin + left * params.radius / 2,
		-- 				origin + left * params.radius / -2}
		-- for k,point in pairs(points) do
		-- 	DebugDrawCircle(point, Vector(255,0,0), 0.5, 50, true, 1)
		-- 	print(point)
		-- end
	end
	return particle
end

function AOEPreviews:Remove(id)
	ParticleManager:DestroyParticle(id, false)
end
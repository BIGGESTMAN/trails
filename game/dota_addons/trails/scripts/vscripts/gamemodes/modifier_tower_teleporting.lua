modifier_tower_teleporting = class({})

function modifier_tower_teleporting:CheckState()
	local state = {
	[MODIFIER_STATE_STUNNED] = true,
	}

	return state
end

function modifier_tower_teleporting:GetEffectName()
	return "particles/items2_fx/teleport_start.vpcf"
end

function modifier_tower_teleporting:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_tower_teleporting:GetTexture()
	return "lone_druid_savage_roar"
end

function modifier_tower_teleporting:SetTeleportDestination(destination, color)
	self.teleport_destination = destination
	self:GetParent():SetForwardVector((destination - self:GetParent():GetAbsOrigin()):Normalized())

	self.end_particle = ParticleManager:CreateParticle("particles/items2_fx/teleport_end.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(self.end_particle, 0, destination)
	ParticleManager:SetParticleControl(self.end_particle, 1, destination)
	ParticleManager:SetParticleControl(self.end_particle, 3, destination)
	ParticleManager:SetParticleControl(self.end_particle, 2, color)
end

if IsServer() then
	function modifier_tower_teleporting:OnCreated(kv)
	end

	function modifier_tower_teleporting:OnDestroy()
		local unit = self:GetParent()
		FindClearSpaceForUnit(unit, self.teleport_destination, true)
		ParticleManager:DestroyParticle(self.end_particle, false)
	end
end
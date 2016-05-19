modifier_map_dummy_invulnerability = class({})

function modifier_map_dummy_invulnerability:IsHidden()
	return true
end

function modifier_map_dummy_invulnerability:CheckState()
	local state = {
	[MODIFIER_STATE_INVULNERABLE] = true,
	[MODIFIER_STATE_NO_HEALTH_BAR] = true,
	[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	[MODIFIER_STATE_UNSELECTABLE] = true,
	}

	return state
end

modifier_map_dummy_hidden = class({})

function modifier_map_dummy_hidden:IsHidden()
	return true
end

function modifier_map_dummy_hidden:CheckState()
	local state = {
	[MODIFIER_STATE_STUNNED] = true,
	[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
	[MODIFIER_STATE_OUT_OF_GAME] = true,
	[MODIFIER_STATE_INVISIBLE] = true,
	}

	return state
end

if IsServer() then
	function modifier_map_dummy_hidden:OnCreated()
		self:GetParent():AddNoDraw()
	end

	function modifier_map_dummy_hidden:OnDestroy()
		self:GetParent():RemoveNoDraw()
	end
end
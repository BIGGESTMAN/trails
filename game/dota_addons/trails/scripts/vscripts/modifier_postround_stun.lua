modifier_postround_stun = class({})

function modifier_postround_stun:IsHidden()
	return true
end

function modifier_postround_stun:CheckState()
	local state = {
	[MODIFIER_STATE_STUNNED] = true,
	}

	return state
end
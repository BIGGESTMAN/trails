modifier_gale_slow = class({})

if IsServer() then
	function modifier_gale_slow:OnCreated( kv )
		self.update_interval = 1/30
		self.slow_amount = self:GetAbility():GetSpecialValueFor("unbalanced_slow")
		self.total_duration = self:GetDuration()
		self:StartIntervalThink(self.update_interval)

		local entindexstr = tostring(self:GetParent():entindex())
		CustomNetTables:SetTableValue("gale_slows", entindexstr, {slow = self.slow_amount})
	end

	function modifier_gale_slow:OnIntervalThink()
		self.slow_amount = self.slow_amount - self:GetAbility():GetSpecialValueFor("unbalanced_slow") * self.update_interval / self.total_duration

		local entindexstr = tostring(self:GetParent():entindex())
		CustomNetTables:SetTableValue("gale_slows", entindexstr, {slow = self.slow_amount})
	end
end

function modifier_gale_slow:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_gale_slow:GetModifierMoveSpeedBonus_Percentage()
	if IsServer() then
		return self.slow_amount
	else
		local entindexstr = tostring(self:GetParent ():entindex())
		local nettable = CustomNetTables:GetTableValue("gale_slows", entindexstr)
		return nettable.slow
	end
end
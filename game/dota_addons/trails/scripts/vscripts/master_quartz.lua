require "combat_links"

LINK_ABILITY_COST = 200
LINK_DURATION = 15

MASTER_QUARTZ_EXP_TABLE = {100, 200, 300, 400, -1}

MasterQuartz = class({})

if IsServer() then
	function MasterQuartz:OnSpellStart()
		local caster = self:GetCaster()
		local ability = self
		local target = self:GetCursorTarget()

		formLink(caster, target, LINK_DURATION)
		Gamemode_Boss:SpendBravePoints(LINK_ABILITY_COST)
	end

	function MasterQuartz:CastFilterResultTarget(target)
		if Gamemode_Boss.state == ENCOUNTER and Gamemode_Boss.brave_points >= LINK_ABILITY_COST and self:GetCaster() ~= target and not target.combat_linked_to then
			return UF_SUCCESS
		else
			return UF_FAIL_CUSTOM
		end
	end
end

function MasterQuartz:GetCustomCastErrorTarget(target)
	if self:GetCaster() == target then
		return "#dota_hud_error_cant_cast_on_self"
	elseif target.combat_linked_to then
		return "target_already_linked"
	else
		return "insufficient_brave_points"
	end
end

function MasterQuartz:GainExperience(experience)
	if MASTER_QUARTZ_EXP_TABLE[self:GetLevel()] ~= -1 then
		local caster = self:GetCaster()

		self.exp = self.exp + experience
		if self.exp >= MASTER_QUARTZ_EXP_TABLE[self:GetLevel()] then
			self:LevelUp()
		end
		PopupExpNumbers(caster, experience)

		local new_master_quartz = getMasterQuartz(caster)
		CustomNetTables:SetTableValue("masterquartz_info", tostring(new_master_quartz:entindex()), new_master_quartz:GetNetTableInfo())
	end
end

function MasterQuartz:LevelUp()
	local caster = self:GetCaster()
	local remaining_exp = self.exp - MASTER_QUARTZ_EXP_TABLE[self:GetLevel()]
	local new_quartz = upgradeMasterQuartz(caster)
	new_quartz.exp = remaining_exp
	ParticleManager:CreateParticle("particles/generic_hero_status/hero_levelup.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
end
require "game_functions"

if not CP_Fountain then CP_Fountain = {} end

function CP_Fountain:Initialize()
	local cp_fountain = Entities:FindByName(nil, "cp_regener")
	local fountain_location = cp_fountain:GetAbsOrigin()

	local cp_interval = 1
	local cp_per_second = 5
	local time_to_control = 5
	local update_interval = 1/30
	local radius = 300

	local time_controlled = 0
	local accrued_cp = 0
	local controlled_by = nil
	local particle = ParticleManager:CreateParticle("particles/cp_fountain/cp_fountain.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, fountain_location)
	local active_particle = nil

	Timers:CreateTimer(0, function()
		local iTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY
		local iType = DOTA_UNIT_TARGET_HERO
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_ANY_ORDER
		local units = {}
		units[DOTA_TEAM_GOODGUYS] = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, fountain_location, nil, radius, iTeam, iType, iFlag, iOrder, false)
		units[DOTA_TEAM_BADGUYS] = FindUnitsInRadius(DOTA_TEAM_BADGUYS, fountain_location, nil, radius, iTeam, iType, iFlag, iOrder, false)

		if #units[DOTA_TEAM_BADGUYS] == 0 and #units[DOTA_TEAM_GOODGUYS] > 0 then
			if controlled_by == DOTA_TEAM_BADGUYS then
				time_controlled = 0
				accrued_cp = 0
				if active_particle then
					ParticleManager:DestroyParticle(active_particle, false)
					active_particle = nil
				end
			end
			controlled_by = DOTA_TEAM_GOODGUYS
		elseif #units[DOTA_TEAM_GOODGUYS] == 0 and #units[DOTA_TEAM_BADGUYS] > 0 then
			if controlled_by == DOTA_TEAM_GOODGUYS then
				time_controlled = 0
				accrued_cp = 0
				if active_particle then
					ParticleManager:DestroyParticle(active_particle, false)
					active_particle = nil
				end
			end
			controlled_by = DOTA_TEAM_BADGUYS
		else
			time_controlled = 0
			accrued_cp = 0
			controlled_by = nil
			if active_particle then
				ParticleManager:DestroyParticle(active_particle, false)
				active_particle = nil
			end
		end

		if controlled_by then
			time_controlled = time_controlled + update_interval
			if time_controlled >= time_to_control then
				if not active_particle then
					active_particle = ParticleManager:CreateParticle("particles/cp_fountain/cp_fountain_active.vpcf", PATTACH_CUSTOMORIGIN, nil)
					ParticleManager:SetParticleControl(active_particle, 0, fountain_location)
				end
				accrued_cp = accrued_cp + update_interval * cp_per_second
				if accrued_cp >= 1 then
					for k,unit in pairs(units[controlled_by]) do
						modifyCP(unit, math.floor(accrued_cp))
					end
					accrued_cp = accrued_cp - math.floor(accrued_cp)
				end
			end
		end
		return update_interval
	end)
end
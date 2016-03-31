require "game_functions"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target_points[1]
	local target = keys.target

	local arrow_destination = target_point + Vector(0,0,300)
	local arrow_travel_time = ability:GetSpecialValueFor("arrow_travel_time")
	local range = (arrow_destination - caster:GetAbsOrigin()):Length()
	local travel_speed = range / arrow_travel_time
	local healing = ability:GetSpecialValueFor("healing") / 100
	local bonus_cp = ability:GetSpecialValueFor("bonus_cp")
	local args = {non_flat = true, healing = healing, bonus_cp = bonus_cp}

	spendCP(caster, ability)
	applyDelayCooldowns(caster, ability)

	if validEnhancedCraft(caster, target) then
		executeEnhancedCraft(caster, target)

		args.enhanced = true
	end
	
	if caster:HasModifier("modifier_crit") then
		args.healing = args.healing * 2
		caster:RemoveModifierByName("modifier_crit")
	end

	local direction = (arrow_destination - caster:GetAbsOrigin()):Normalized()
	local origin_location = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_attack1"))

	ProjectileList:CreateLinearProjectile(caster, origin_location, direction, travel_speed, range, blessedArrowExplode, nil, nil, "particles/crafts/alisa/blessed_arrow/arrow.vpcf", args)
end

function blessedArrowExplode(caster, origin_location, direction, speed, range, collisionRules, collisionFunction, other_args)
	local ability = caster:FindAbilityByName("blessed_arrow")
	local healing_percent = other_args.healing
	local bonus_cp = other_args.bonus_cp
	local radius = ability:GetSpecialValueFor("radius")
	local cp_delay = ability:GetSpecialValueFor("cp_delay")
	local target_point = origin_location + direction * range
	local total_healing = 0

	if other_args.enhanced then
		radius = ability:GetSpecialValueFor("unbalanced_radius")
	end

	local team = caster:GetTeamNumber()
	local iTeam = DOTA_UNIT_TARGET_TEAM_BOTH
	local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, target_point, nil, radius, iTeam, iType, iFlag, iOrder, false)
	for k,unit in pairs(targets) do
		if unit:GetTeamNumber() == team then
			local heal = healing_percent * unit:GetHealthDeficit()
			applyHealing(unit, caster, heal)
			total_healing = total_healing + heal
		elseif other_args.enhanced then
			ability:ApplyDataDrivenModifier(caster, unit, "modifier_blessed_arrow_mischievous_blessing", {})
		end
	end

	local explosion_particle = ParticleManager:CreateParticle("particles/crafts/alisa/blessed_arrow/healing_area.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(explosion_particle, 0, target_point)
	ParticleManager:SetParticleControl(explosion_particle, 1, Vector(1,radius,0))

	local cp_particle = ParticleManager:CreateParticle("particles/crafts/alisa/blessed_arrow/cp_restoration.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(cp_particle, 0, GetGroundPosition(target_point, caster))
	ParticleManager:SetParticleControl(cp_particle, 1, Vector(radius,1,radius))
	ParticleManager:SetParticleControl(cp_particle, 14, Vector(radius,radius,0))

	Timers:CreateTimer(cp_delay, function()
		grantCP(caster, target_point, total_healing)
	end)
end

function grantCP(caster, target_point, total_healing)
	local ability = caster:FindAbilityByName("blessed_arrow")
	local radius = ability:GetSpecialValueFor("radius")
	local bonus_cp_percent = ability:GetSpecialValueFor("bonus_cp_per_healing") / 100

	local team = caster:GetTeamNumber()
	local iTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY
	local iType = DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, target_point, nil, radius, iTeam, iType, iFlag, iOrder, false)
	for k,unit in pairs(targets) do
		modifyCP(unit, total_healing * bonus_cp_percent)
	end
end

function mischievousBlessingAttacked(keys)
	local caster = keys.caster
	local ability = keys.ability
	local unit = keys.attacker

	local healing = getStats(caster).ats * ability:GetSpecialValueFor("unbalanced_mischievous_healing_percent") / 100
	local bonus_cp = ability:GetSpecialValueFor("unbalanced_mischievous_bonus_cp")

	applyHealing(unit, caster, healing)
	modifyCP(unit, bonus_cp)
end
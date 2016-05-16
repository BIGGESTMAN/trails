require "game_functions"

-- element_indices = ["F", "E", "W", "I", "T", "S", "M"]
ELEMENT_FIRE = 0
ELEMENT_EARTH = 1
ELEMENT_WATER = 2
ELEMENT_WIND = 3
ELEMENT_TIME = 4
ELEMENT_SPACE = 5
ELEMENT_MIRAGE = 6
CAST_COLORS = {Vector(255,102,102), Vector(255,186,102), Vector(102,115,255), Vector(102,255,153), Vector(158,102,255), Vector(255,223,66), Vector(198,198,198)}

function createCastParticle(caster, ability)
	caster.casting_particle = ParticleManager:CreateParticle("particles/arts/arcus/casting.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(caster.casting_particle, 4, CAST_COLORS[ability:GetSpecialValueFor("element") + 1])
end

function endCastParticle(caster)
	ParticleManager:DestroyParticle(caster.casting_particle, false)
	caster.casting_particle = nil
end

function applyArtsDelayCooldowns(caster, ability)
	ability:EndCooldown()
	inflictArtsDelay(caster, ability:GetCooldown(ability:GetLevel()) * getArtDelayMultiplier(caster, ability))
end

function getArtDelayMultiplier(caster, ability)
	local multiplier = 1
	for k,modifier in pairs(caster:FindAllModifiers()) do
		if modifier.GetArtDelayMultiplier then
			multiplier = multiplier * modifier:GetArtDelayMultiplier(ability:GetSpecialValueFor("element"))
		end
	end
	return multiplier
end

function inflictArtsDelay(unit, amount)
	local amount = amount * (1 - getStats(unit).spd / 100)
	local arts_delayed = {}

	for i=0,5 do
		local art = unit:GetItemInSlot(i)
		if art and not arts_delayed[art:GetAbilityName()] then
			art:StartCooldown(amount + art:GetCooldownTimeRemaining())
			arts_delayed[art:GetAbilityName()] = true
		end
	end
end

-- if not arts_item_keyvalues then arts_item_keyvalues = LoadKeyValues("scripts/npc/npc_items_custom.txt") end
-- function GetInheritedSpecialValueFor(ability, value_name)
-- 	local value = 0
-- 	DeepPrintTable(arts_item_keyvalues["item_"..ability.inherited_art_name]["AbilitySpecial"])
-- 	print(ability.inherited_art_name, value_name, arts_item_keyvalues["item_"..ability.inherited_art_name]["AbilitySpecial"][value_name], arts_item_keyvalues[ability:GetAbilityName()]["AbilitySpecial"][value_name])
-- 	if ability.inherited_art_name and arts_item_keyvalues["item_"..ability.inherited_art_name]["AbilitySpecial"][value_name] then
-- 		value = arts_item_keyvalues["item_"..ability.inherited_art_name]["AbilitySpecial"][value_name]
-- 		print(value_name, value)
-- 	elseif arts_item_keyvalues[ability:GetAbilityName()]["AbilitySpecial"][value_name] then
-- 		value = arts_item_keyvalues[ability:GetAbilityName()]["AbilitySpecial"][value_name]
-- 		print(value_name, value)
-- 	end
-- 	return value
-- end

-- function GetAbilitySpecial(ability_name, value_name)

-- end
require "game_functions"

-- element_indices = ["F", "E", "W", "I", "T", "S", "M"]
ELEMENT_FIRE = 0
ELEMENT_EARTH = 1
ELEMENT_WATER = 2
ELEMENT_WIND = 3
ELEMENT_TIME = 4
ELEMENT_SPACE = 5
ELEMENT_MIRAGE = 6

function createCastParticle(caster)
	caster.casting_particle = ParticleManager:CreateParticle("particles/arts/arcus/casting.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
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
	print(multiplier)
	return multiplier
end

function inflictArtsDelay(unit, amount)
	local amount = amount * (1 - getStats(unit).spd / 100)

	for i=0,5 do
		local art = unit:GetItemInSlot(i)
		if art then
			art:StartCooldown(amount + art:GetCooldownTimeRemaining())
		end
	end
end
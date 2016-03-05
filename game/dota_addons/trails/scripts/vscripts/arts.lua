require "game_functions"

function createCastParticle(caster)
	caster.casting_particle = ParticleManager:CreateParticle("particles/arts/arcus/casting.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
end

function endCastParticle(caster)
	ParticleManager:DestroyParticle(caster.casting_particle, false)
	caster.casting_particle = nil
end

function applyArtsDelayCooldowns(caster, ability)
	ability:EndCooldown()
	inflictArtsDelay(caster, ability:GetCooldown(ability:GetLevel()))
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
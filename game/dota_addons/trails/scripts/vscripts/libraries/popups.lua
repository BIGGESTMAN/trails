POPUP_SYMBOL_PRE_PLUS = 0
POPUP_SYMBOL_PRE_MINUS = 1
POPUP_SYMBOL_PRE_SADFACE = 2
POPUP_SYMBOL_PRE_BROKENARROW = 3
POPUP_SYMBOL_PRE_SHADES = 4
POPUP_SYMBOL_PRE_MISS = 5
POPUP_SYMBOL_PRE_EVADE = 6
POPUP_SYMBOL_PRE_DENY = 7
POPUP_SYMBOL_PRE_ARROW = 8

POPUP_SYMBOL_POST_EXCLAMATION = 0
POPUP_SYMBOL_POST_POINTZERO = 1
POPUP_SYMBOL_POST_MEDAL = 2
POPUP_SYMBOL_POST_DROP = 3
POPUP_SYMBOL_POST_LIGHTNING = 4
POPUP_SYMBOL_POST_SKULL = 5
POPUP_SYMBOL_POST_EYE = 6
POPUP_SYMBOL_POST_SHIELD = 7
POPUP_SYMBOL_POST_POINTFIVE = 8

function PopupHealing(target, amount)
	PopupNumbers(target, "particles/msg_fx/msg_heal.vpcf", Vector(0, 255, 0),
		1.0, amount, POPUP_SYMBOL_PRE_PLUS, nil)
end

function PopupDamage(target, amount)
	PopupNumbers(target, "particles/msg_fx/msg_damage.vpcf", Vector(255, 0, 0),
		1.0, amount, nil, POPUP_SYMBOL_POST_DROP)
end

function PopupCriticalDamage(target, amount)
	PopupNumbers(target, "particles/msg_fx/msg_crit.vpcf", Vector(255, 0, 0),
		1.0, amount, nil, POPUP_SYMBOL_POST_LIGHTNING)
end

function PopupDamageOverTime(target, amount)
	PopupNumbers(target, "particles/msg_fx/msg_poison.vpcf", Vector(215, 50, 248),
		1.0, amount, nil, POPUP_SYMBOL_POST_EYE)
end

function PopupDamageBlock(target, amount)
	PopupNumbers(target, "particles/msg_fx/msg_block.vpcf", Vector(255, 255, 255),
		1.0, amount, POPUP_SYMBOL_PRE_MINUS, nil)
end

function PopupGoldGain(target, amount)
	PopupNumbers(target, "particles/msg_fx/msg_gold.vpcf", Vector(255, 200, 33),
		1.0, amount, POPUP_SYMBOL_PRE_PLUS, nil, true)
end

function PopupMiss(target)
	PopupNumbers(target, "particles/msg_fx/msg_miss.vpcf", Vector(255, 0, 0),
		1.0, nil, POPUP_SYMBOL_PRE_MISS, nil)
end

function PopupNumbers(target, pfx, color, lifetime, number, presymbol, postsymbol, forplayer)
	local pidx = nil
	if forplayer then
		pidx = ParticleManager:CreateParticleForPlayer(pfx, PATTACH_ABSORIGIN_FOLLOW, target, target:GetPlayerOwner())
	else
		pidx = ParticleManager:CreateParticle(pfx, PATTACH_ABSORIGIN_FOLLOW, target)
	end

	local digits = 0
	if number ~= nil then
		digits = #tostring(math.floor(number))
	end
	if presymbol ~= nil then
		digits = digits + 1
	end
	if postsymbol ~= nil then
		digits = digits + 1
	end

	ParticleManager:SetParticleControl(pidx, 1, Vector(tonumber(presymbol), tonumber(number), tonumber(postsymbol)))
	ParticleManager:SetParticleControl(pidx, 2, Vector(lifetime, digits, 0))
	ParticleManager:SetParticleControl(pidx, 3, color)
	
	ParticleManager:ReleaseParticleIndex(pidx)
end
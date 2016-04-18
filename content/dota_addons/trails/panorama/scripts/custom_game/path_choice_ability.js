"use strict";

function AbilityShowTooltip()
{
	var abilityImage = $( "#AbilityImage" );
	var abilityName = abilityImage.abilityname
	// If you don't have an entity, you can still show a tooltip that doesn't account for the entity
	$.DispatchEvent( "DOTAShowAbilityTooltip", abilityImage, abilityName );
	
	// If you have an entity index, this will let the tooltip show the correct level / upgrade information
	// $.DispatchEvent( "DOTAShowAbilityTooltipForEntityIndex", abilityButton, abilityName, m_QueryUnit );
}

function AbilityHideTooltip()
{
	var abilityImage = $( "#AbilityImage" );
	$.DispatchEvent( "DOTAHideAbilityTooltip", abilityImage );
}
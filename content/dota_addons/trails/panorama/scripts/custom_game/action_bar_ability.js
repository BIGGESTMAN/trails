"use strict";

var m_Ability = -1;
var m_QueryUnit = -1;
var m_bInLevelUp = false;

function SetAbility( ability, queryUnit, bInLevelUp, cpCost)
{
	var bChanged = ( ability !== m_Ability || queryUnit !== m_QueryUnit );
	m_Ability = ability;
	m_QueryUnit = queryUnit;
	m_bInLevelUp = bInLevelUp;
	
	var canUpgradeRet = Abilities.CanAbilityBeUpgraded( m_Ability );
	var canUpgrade = ( canUpgradeRet == AbilityLearnResult_t.ABILITY_CAN_BE_UPGRADED );
	
	$.GetContextPanel().SetHasClass( "no_ability", ( ability == -1 ) );
	$.GetContextPanel().SetHasClass( "learnable_ability", bInLevelUp && canUpgrade );
	$.GetContextPanel().cpCost = cpCost

	// RebuildAbilityUI();
	UpdateAbility();
}

function AutoUpdateAbility()
{
	UpdateAbility();
	$.Schedule( 1/30, AutoUpdateAbility );
}

function UpdateAbility()
{
	var abilityButton = $( "#AbilityButton" );
	var abilityName = Abilities.GetAbilityName( m_Ability );

	var cpCost = $.GetContextPanel().cpCost
	var isDisabled = !(Abilities.IsActivated(m_Ability))
	var noLevel =( 0 == Abilities.GetLevel( m_Ability ) );
	var isCastable = !Abilities.IsPassive( m_Ability ) && !noLevel;
	var manaCost = Abilities.GetManaCost( m_Ability );
	var hotkey = Abilities.GetKeybind( m_Ability, m_QueryUnit );
	var unitMana = Entities.GetMana( m_QueryUnit );

	$.GetContextPanel().SetHasClass( "EnhancedAvailable", IsEnhancedAvailable())
	$.GetContextPanel().SetHasClass( "no_level", isDisabled );
	$.GetContextPanel().SetHasClass( "is_passive", Abilities.IsPassive(m_Ability) );
	// $.GetContextPanel().SetHasClass( "no_mana_cost", ( 0 == manaCost ) );
	$.GetContextPanel().SetHasClass( "insufficient_mana", ( manaCost > unitMana ) );
	$.GetContextPanel().SetHasClass( "auto_cast_enabled", Abilities.GetAutoCastState(m_Ability) );
	$.GetContextPanel().SetHasClass( "toggle_enabled", Abilities.GetToggleState(m_Ability) );
	$.GetContextPanel().SetHasClass( "is_active", ( m_Ability == Abilities.GetLocalPlayerActiveAbility() ) );

	abilityButton.enabled = ( isCastable || m_bInLevelUp );
	
	$( "#HotkeyText" ).text = hotkey;
	
	$( "#AbilityImage" ).abilityname = abilityName;
	$( "#AbilityImage" ).contextEntityIndex = m_Ability;
	
	$( "#CPCost" ).text = cpCost;
	if (cpCost > 0) {
		$("#CPCost").style.visibility = "visible"
	} else {
		$("#CPCost").style.visibility = "collapse"
	}
	
	if ( Abilities.IsCooldownReady( m_Ability ) )
	{
		$.GetContextPanel().SetHasClass( "cooldown_ready", true );
		$.GetContextPanel().SetHasClass( "in_cooldown", false );
	}
	else
	{
		$.GetContextPanel().SetHasClass( "cooldown_ready", false );
		$.GetContextPanel().SetHasClass( "in_cooldown", true );
		var cooldownLength = Abilities.GetCooldownLength( m_Ability );
		var cooldownRemaining = Abilities.GetCooldownTimeRemaining( m_Ability );
		var cooldownPercent = Math.ceil( 100 * cooldownRemaining / cooldownLength );
		var cooldownText = Math.ceil(cooldownRemaining * 10) / 10;
		if (cooldownRemaining > 1) {
			cooldownText = Math.ceil(cooldownRemaining)
		}
		$( "#CooldownTimer" ).text = cooldownText;
		// $( "#CooldownOverlay" ).style.width = cooldownPercent+"%";
		$( "#CooldownOverlay" ).style.width = "100%";
		$("#CooldownOverlay").style.clip = "radial( 50% 50%, 0deg, " + (-1 * cooldownPercent * 360 / 100) + "deg )"
	}
	
}

function IsEnhancedAvailable()
{
	var enhancedAvailable = false
	var nBuffs = Entities.GetNumBuffs( m_QueryUnit );
	for ( var i = 0; i < nBuffs; ++i )
	{
		var buffSerial = Entities.GetBuff( m_QueryUnit, i );
		var name = Buffs.GetName(m_QueryUnit, buffSerial)
		if (name == "modifier_combat_link_followup_available") {
			enhancedAvailable = true
			break;
		}
	}
	return enhancedAvailable;
}

function AbilityShowTooltip()
{
	var abilityButton = $( "#AbilityButton" );
	var abilityName = Abilities.GetAbilityName( m_Ability );
	// If you don't have an entity, you can still show a tooltip that doesn't account for the entity
	//$.DispatchEvent( "DOTAShowAbilityTooltip", abilityButton, abilityName );
	
	// If you have an entity index, this will let the tooltip show the correct level / upgrade information
	$.DispatchEvent( "DOTAShowAbilityTooltipForEntityIndex", abilityButton, abilityName, m_QueryUnit );
}

function AbilityHideTooltip()
{
	var abilityButton = $( "#AbilityButton" );
	$.DispatchEvent( "DOTAHideAbilityTooltip", abilityButton );
}

function ActivateAbility()
{
	if ( m_bInLevelUp )
	{
		Abilities.AttemptToUpgrade( m_Ability );
		return;
	}
	if ($.GetContextPanel().controllable) {
		Abilities.ExecuteAbility( m_Ability, m_QueryUnit, false );
	}
}

function DoubleClickAbility()
{
	// Handle double-click like a normal click - ExecuteAbility will either double-tap (self cast) or normal toggle as appropriate
	ActivateAbility();
}

function RightClickAbility()
{
	if ( m_bInLevelUp )
		return;

	if ( Abilities.IsAutocast( m_Ability ) )
	{
		Game.PrepareUnitOrders( { OrderType: dotaunitorder_t.DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO, AbilityIndex: m_Ability } );
	}
}

// function RebuildAbilityUI()
// {
// 	var abilityLevelContainer = $( "#AbilityLevelContainer" );
// 	abilityLevelContainer.RemoveAndDeleteChildren();
// 	var currentLevel = Abilities.GetLevel( m_Ability );
// 	for ( var lvl = 0; lvl < Abilities.GetMaxLevel( m_Ability ); lvl++ )
// 	{
// 		var levelPanel = $.CreatePanel( "Panel", abilityLevelContainer, "" );
// 		levelPanel.AddClass( "LevelPanel" );
// 		levelPanel.SetHasClass( "active_level", ( lvl < currentLevel ) );
// 		levelPanel.SetHasClass( "next_level", ( lvl == currentLevel ) );
// 	}
// }

(function()
{
	$.GetContextPanel().SetAbility = SetAbility;
	// GameEvents.Subscribe( "dota_ability_changed", RebuildAbilityUI ); // major rebuild
	AutoUpdateAbility(); // initial update of dynamic state
})();

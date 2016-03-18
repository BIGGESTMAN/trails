"use strict";

var m_BuffPanels = []; // created up to a high-water mark, but reused

function UpdateBuff( buffPanel, queryUnit, buffSerial )
{
	var noBuff = ( buffSerial == -1 );
	buffPanel.SetHasClass( "no_buff", noBuff );
	buffPanel.m_QueryUnit = queryUnit;
	buffPanel.m_BuffSerial = buffSerial;
	if ( noBuff )
	{
		return;
	}
	
	var nNumStacks = Buffs.GetStackCount( queryUnit, buffSerial );
	buffPanel.SetHasClass( "is_debuff", Buffs.IsDebuff( queryUnit, buffSerial ) );
	buffPanel.SetHasClass( "has_stacks", ( nNumStacks > 0 ) );

	var stackCount = buffPanel.FindChildInLayoutFile( "StackCount" );
	var itemImage = buffPanel.FindChildInLayoutFile( "ItemImage" );
	var abilityImage = buffPanel.FindChildInLayoutFile( "AbilityImage" );
	if ( stackCount )
	{
		stackCount.text = nNumStacks;
	}
	
	var buffTexture = Buffs.GetTexture( queryUnit, buffSerial );
	// $.Msg(buffTexture)

	if ( itemImage ) itemImage.itemname = "";
	buffPanel.SetHasClass( "item_buff", false );
	buffPanel.SetHasClass( "ability_buff", true );
	var itemIdx = buffTexture.indexOf( "item_" );
	if ( itemIdx === -1 )
	{
		if ( abilityImage ) abilityImage.style.backgroundImage = "url('file://{resources}/images/spellicons/" + buffTexture + ".png')";
		abilityImage.style.backgroundSize = "100% 100%"
	}
	else
	{
		if ( abilityImage ) abilityImage.style.backgroundImage = "url('file://{resources}/images/items/" + buffTexture.substr(5) + ".png')";
		abilityImage.style.backgroundSize = "auto 100%"
	}

	var totalDuration = Buffs.GetDuration(queryUnit, buffSerial)
	var durationRemaining = Buffs.GetRemainingTime(queryUnit, buffSerial)
	var cooldownOverlay = buffPanel.Children()[0].Children()[0].Children()[2]

	if (totalDuration == -1) {
		cooldownOverlay.SetHasClass("limited_duration", false)
	}
	else
	{
		cooldownOverlay.SetHasClass("limited_duration", true)
		var durationPercent = Math.ceil(100 * durationRemaining / totalDuration)
		cooldownOverlay.style.clip = "radial( 50% 50%, 0deg, " + (360 - durationPercent * 360 / 100) + "deg )"
	}
}

function UpdateBuffs()
{
	var buffsListPanel = $( "#buffs_list" );
	if ( !buffsListPanel )
		return;

	// var queryUnit = Players.GetLocalPlayerPortraitUnit();
	var queryUnit = $.GetContextPanel().heroIndex
	
	var nBuffs = Entities.GetNumBuffs( queryUnit );
	
	// update all the panels
	var nUsedPanels = 0;
	for ( var i = 0; i < nBuffs; ++i )
	{
		var buffSerial = Entities.GetBuff( queryUnit, i );
		if ( buffSerial == -1 )
			continue;

		if ( Buffs.IsHidden( queryUnit, buffSerial ) )
			continue;
		
		if ( nUsedPanels >= m_BuffPanels.length )
		{
			// create a new panel
			var buffPanel = $.CreatePanel( "Panel", buffsListPanel, "" );
			buffPanel.BLoadLayout( "file://{resources}/layout/custom_game/buff_list_buff.xml", false, false );
			m_BuffPanels.push( buffPanel );
		}

		// update the panel for the current unit / buff
		var buffPanel = m_BuffPanels[ nUsedPanels ];
		UpdateBuff( buffPanel, queryUnit, buffSerial );
		
		nUsedPanels++;
	}

	// clear any remaining panels
	for ( var i = nUsedPanels; i < m_BuffPanels.length; ++i )
	{
		var buffPanel = m_BuffPanels[ i ];
		UpdateBuff( buffPanel, -1, -1 );
	}
}

function AutoUpdateBuffs()
{
	UpdateBuffs();
	$.Schedule( 1/30, AutoUpdateBuffs );
}

(function()
{
	GameEvents.Subscribe( "dota_player_update_selected_unit", UpdateBuffs );
	GameEvents.Subscribe( "dota_player_update_query_unit", UpdateBuffs );
	
	AutoUpdateBuffs(); // initial update of dynamic state
})();


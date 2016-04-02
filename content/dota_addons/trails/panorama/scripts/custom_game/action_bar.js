"use strict";

var m_AbilityPanels = []; // created up to a high-water mark, but reused when selection changes

function OnHeroPortraitClicked()
{
	GameUI.SelectUnit($("#HeroPortraitWindow").heroIndex, false)
}

function OnHeroPortraitDoubleClicked()
{
	// GameUI.SelectUnit($("#HeroPortraitWindow").heroIndex, false)
	// GameUI.SetCameraLookAtPositionHeightOffset( lookAtHeight + offHeight );
}

function UpdateAbilityList(msg)
{
	var abilityListPanel = $( "#ability_list" );
	if ( !abilityListPanel )
		return;

	var queryUnit = $.GetContextPanel().heroIndex
	if (!queryUnit)
		return;

	// update all the panels
	var nUsedPanels = 0;
	for ( var i = 0; i < Entities.GetAbilityCount( queryUnit ); ++i )
	{
		var ability = Entities.GetAbility( queryUnit, i );
		if ( ability == -1 )
			continue;

		if ( !Abilities.IsDisplayedAbility(ability) )
			continue;
		
		if ( nUsedPanels >= m_AbilityPanels.length )
		{
			// create a new panel
			var abilityPanel = $.CreatePanel( "Panel", abilityListPanel, "" );
			abilityPanel.BLoadLayout( "file://{resources}/layout/custom_game/action_bar_ability.xml", false, false );
			m_AbilityPanels.push( abilityPanel );
			abilityPanel.controllable = Entities.IsControllableByPlayer(queryUnit, Players.GetLocalPlayer())
		}

		// update the panel for the current unit / ability
		var abilityPanel = m_AbilityPanels[ nUsedPanels ];
		abilityPanel.SetAbility( ability, queryUnit, Game.IsInAbilityLearnMode(), $.GetContextPanel().cpCosts[i] );
		
		nUsedPanels++;
	}

	// clear any remaining panels
	for ( var i = nUsedPanels; i < m_AbilityPanels.length; ++i )
	{
		var abilityPanel = m_AbilityPanels[ i ];
		abilityPanel.SetAbility( -1, -1, false );
	}

	var heroPortraitWindow = $("#HeroPortraitWindow")
	heroPortraitWindow.heroIndex = queryUnit
	var heroInternalName = Entities.GetUnitName(queryUnit)
	$("#HeroPortraitName").text = $.Localize(Entities.GetUnitName(queryUnit))
	$("#HeroPortrait").style.backgroundImage = "url('file://{resources}/images/heroes/portrait_" + heroInternalName + ".png')";
	if ($.GetContextPanel().ownerIndex !== undefined) {
		$("#PlayerName").text = Players.GetPlayerName($.GetContextPanel().ownerIndex)
		$("#PlayerName").style.color = "#" + RGBAPlayerColor($.GetContextPanel().ownerIndex)
	}

	var statsDisplay = $("#StatsDisplay")
	statsDisplay.BLoadLayout("file://{resources}/layout/custom_game/stats_display.xml", false, false);
	statsDisplay.heroIndex = queryUnit

	var buffList = $("#BuffList")
	buffList.BLoadLayout("file://{resources}/layout/custom_game/buff_list.xml", false, false);
	buffList.heroIndex = queryUnit
}

function OnCPCostsUpdate(data) {
	if ($.GetContextPanel().style.visibility == "visible") {
		var cpCosts = data.cpCosts
		var heroIndex = $.GetContextPanel().heroIndex

		for ( var i = 0; i < Entities.GetAbilityCount( heroIndex ); ++i )
		{
			var ability = Entities.GetAbility( heroIndex, i );
			if ( ability == -1 )
				continue;

			if ( !Abilities.IsDisplayedAbility(ability) )
				continue;

			$("#ability_list").Children()[i].cpCost = Math.floor(cpCosts[heroIndex][ability])
		}
	}
}

function RGBAPlayerColor(id) {
	var abgr = Players.GetPlayerColor(id).toString(16)
	var rgba = abgr.substring(6,8) + abgr.substring(4,6) + abgr.substring(2,4) + abgr.substring(0,2)
	return rgba
}

(function()
{
    // $.RegisterForUnhandledEvent( "DOTAAbility_LearnModeToggled", OnAbilityLearnModeToggled);

	GameEvents.Subscribe( "dota_portrait_ability_layout_changed", UpdateAbilityList );
	GameEvents.Subscribe( "dota_player_update_selected_unit", UpdateAbilityList );
	GameEvents.Subscribe( "dota_player_update_query_unit", UpdateAbilityList );
	GameEvents.Subscribe( "dota_ability_changed", UpdateAbilityList );
	GameEvents.Subscribe( "dota_hero_ability_points_changed", UpdateAbilityList );
	GameEvents.Subscribe( "ally_ability_bar_start", UpdateAbilityList );

	GameEvents.Subscribe("cp_costs_update", OnCPCostsUpdate);
	
	UpdateAbilityList(); // initial update
})();


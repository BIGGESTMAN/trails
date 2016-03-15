"use strict";

var m_AbilityPanels = []; // created up to a high-water mark, but reused when selection changes

function OnHeroPortraitClicked()
{
	// if ( Game.IsInAbilityLearnMode() )
	// {
	// 	Game.EndAbilityLearnMode();
	// }
	// else
	// {
	// 	Game.EnterAbilityLearnMode();
	// }
	GameUI.SelectUnit($("#HeroPortraitWindow").heroIndex, false)
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

	var statsDisplay = $("#StatsDisplay")
	statsDisplay.BLoadLayout("file://{resources}/layout/custom_game/stats_display.xml", false, false);
	statsDisplay.heroIndex = queryUnit

	var buffList = $("#BuffList")
	buffList.BLoadLayout("file://{resources}/layout/custom_game/buff_list.xml", false, false);
	buffList.heroIndex = queryUnit
}

function OnResourceBarsUpdate(data) {
	var unitValues = data.unitValues
	var heroIndex = $.GetContextPanel().heroIndex
	var container = $("#ResourceBarContainer")
	var healthBar = $("#HealthBar")
	var manaBar = $("#ManaBar")
	var cpBarBackground = $("#ResourceBarContainer").Children()[2]
	var cpBar = $("#CPBar")
	var overfullCPBar = $("#OverfullCPBar")
	var unbalanceBar = $("#UnbalanceBar")

	var healthPercent = Entities.GetHealthPercent(heroIndex)
	var manaPercent = Entities.GetMana(heroIndex) / Entities.GetMaxMana(heroIndex) * 100
	healthBar.style.height = healthPercent + "%"
	if (manaPercent) {
		manaBar.style.height = manaPercent + "%"
	}

	var second_cp_bar_full = Math.max(unitValues[heroIndex].cp - 100, 0)
	var first_cp_bar_full = Math.min(unitValues[heroIndex].cp, 100)
	// $.Msg(cpBarBackground)
	if (second_cp_bar_full > 0) {
		first_cp_bar_full = 100 - second_cp_bar_full
		cpBar.style.position = "0px -" + second_cp_bar_full + "% 0px"
	}
	else {
		cpBar.style.position = "0px 0px 0px" 
	}
	cpBar.style.height = first_cp_bar_full + "%"
	overfullCPBar.style.height = second_cp_bar_full + "%"

	unbalanceBar.style.height = unitValues[heroIndex].unbalance + "%"
	if (unitValues[heroIndex].unbalance == 100) {
		unbalanceBar.style["background-color"] = "gradient( radial, 50% 50%, 0% 0%, 80% 80%, from( #FF3232 ), to( #FFB5B5 ) )";
	}
	else {
		unbalanceBar.style["background-color"] = "gradient( linear, 0% 0%, 100% 0%, from( #FF9933 ), to( #FFB775 ) )";
	}
}

function OnCPCostsUpdate(data) {
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
		// $.Msg(heroIndex, ", ", ability, ", ", cpCosts[heroIndex][ability])
	}
}

(function()
{
    // $.RegisterForUnhandledEvent( "DOTAAbility_LearnModeToggled", OnAbilityLearnModeToggled);

	GameEvents.Subscribe( "dota_portrait_ability_layout_changed", UpdateAbilityList );
	GameEvents.Subscribe( "dota_player_update_selected_unit", UpdateAbilityList );
	GameEvents.Subscribe( "dota_player_update_query_unit", UpdateAbilityList );
	GameEvents.Subscribe( "dota_ability_changed", UpdateAbilityList );
	GameEvents.Subscribe( "dota_hero_ability_points_changed", UpdateAbilityList );

	GameEvents.Subscribe("resource_bars_update", OnResourceBarsUpdate);
	GameEvents.Subscribe("cp_costs_update", OnCPCostsUpdate);
	
	UpdateAbilityList(); // initial update
})();


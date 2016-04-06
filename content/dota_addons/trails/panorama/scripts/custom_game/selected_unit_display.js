"use strict";

function OnAbilityBarStart(msg)
{
	GameUI.SelectUnit(Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer()), false)

	$.GetContextPanel().SetHasClass("NonSelf", true);
	
	$("#ActionBar").BLoadLayout("file://{resources}/layout/custom_game/action_bar.xml", false, false );
	$("#ActionBar").cpCosts = msg.cpCosts

	$("#StatusBar").BLoadLayout("file://{resources}/layout/custom_game/ui_resource_bars.xml", false, false );
	$("#StatusBar").SetHasClass("Lower", false);
	$("#StatusBar").SetHasClass("Upper", false);
	UpdateUnit()
}

function UpdateUnit()
{	
	$.GetContextPanel().style.visibility = "collapse"
	$("#ActionBar").ownerIndex = undefined
	$("#ActionBar").heroIndex = null

	var own_hero = Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer())
	var linked_ally = CustomNetTables.GetTableValue("combat_links", own_hero)["link_target"]

	if (own_hero != Players.GetLocalPlayerPortraitUnit() && Players.GetLocalPlayerPortraitUnit() != linked_ally) {
		$("#ActionBar").heroIndex = Players.GetLocalPlayerPortraitUnit()
		$("#StatusBar").heroIndex = Players.GetLocalPlayerPortraitUnit()
		$.GetContextPanel().style.visibility = "visible"
	}
}

(function()
{
	GameEvents.Subscribe( "dota_player_update_selected_unit", UpdateUnit );
	GameEvents.Subscribe( "dota_player_update_query_unit", UpdateUnit );
	GameEvents.Subscribe( "ability_bar_start", OnAbilityBarStart );
	GameEvents.Subscribe( "link_formed_or_broken", UpdateUnit );
})();


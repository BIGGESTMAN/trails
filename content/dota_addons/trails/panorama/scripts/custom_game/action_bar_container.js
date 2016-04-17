"use strict";

function OnAbilityBarStart(msg)
{
	GameUI.SetRenderBottomInsetOverride(0)

	$("#SelfActionBar").BLoadLayout("file://{resources}/layout/custom_game/action_bar.xml", false, false );
	$("#SelfActionBar").cpCosts = msg.cpCosts
	$("#SelfActionBar").heroIndex = msg.heroIndex

	$("#SelfStatusBar").BLoadLayout("file://{resources}/layout/custom_game/ui_resource_bars.xml", false, false );
	$("#SelfStatusBar").heroIndex = msg.heroIndex
	$("#SelfStatusBar").SetHasClass("Lower", false);
	$("#SelfStatusBar").SetHasClass("Upper", false);


	$("#AllyActionBar").BLoadLayout("file://{resources}/layout/custom_game/action_bar.xml", false, false );
	$("#AllyActionBar").style.visibility = "collapse"
	$("#AllyActionBar").SetHasClass("Upper", true)

	$("#AllyStatusBar").BLoadLayout("file://{resources}/layout/custom_game/ui_resource_bars.xml", false, false );
	$("#AllyStatusBar").style.visibility = "collapse"
	$("#AllyStatusBar").SetHasClass("Upper", true);
	$("#AllyStatusBar").SetHasClass("Lower", false);

	var pvp_mode = CustomNetTables.GetTableValue("gamemode", 0)["pvp_ui_enabled"]
	if (parseInt(pvp_mode) === 0) {
		$("#SelfStatusBar").SetHasClass("PvE", true);
		$("#AllyStatusBar").SetHasClass("PvE", true);
	}
}

function OnAllyAbilityBarStart(msg)
{
	$("#AllyActionBar").style.visibility = "visible"
	$("#AllyActionBar").heroIndex = msg.heroIndex
	$("#AllyActionBar").cpCosts = msg.cpCosts

	$("#AllyStatusBar").style.visibility = "visible"
	$("#AllyStatusBar").heroIndex = msg.heroIndex

	$("#SelfStatusBar").SetHasClass("Lower", true);
}

function OnAllyAbilityBarRemove(msg)
{
	$("#AllyActionBar").style.visibility = "collapse"
	$("#AllyActionBar").heroIndex = null

	$("#AllyStatusBar").style.visibility = "collapse"
	$("#AllyStatusBar").heroIndex = null

	$("#SelfStatusBar").SetHasClass("Lower", false);
}

(function()
{
	GameEvents.Subscribe( "ability_bar_start", OnAbilityBarStart );
	GameEvents.Subscribe( "ally_ability_bar_start", OnAllyAbilityBarStart );
	GameEvents.Subscribe( "ally_ability_bar_remove", OnAllyAbilityBarRemove );
})();


"use strict";

function OnAbilityBarStart(msg)
{
	GameUI.SetRenderBottomInsetOverride(0)

	$("#SelfActionBar").BLoadLayout("file://{resources}/layout/custom_game/action_bar.xml", false, false );
	$("#SelfActionBar").cpCosts = msg.cpCosts
	$("#SelfActionBar").heroIndex = msg.heroIndex
	$("#SelfActionBar").ownerIndex = msg.ownerIndex

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
}

function OnAllyAbilityBarStart(msg)
{
	$("#AllyActionBar").style.visibility = "visible"
	$("#AllyActionBar").heroIndex = msg.heroIndex
	$("#AllyActionBar").cpCosts = msg.cpCosts
	$("#AllyActionBar").ownerIndex = msg.ownerIndex

	$("#AllyStatusBar").style.visibility = "visible"
	$("#AllyStatusBar").heroIndex = msg.heroIndex

	$("#SelfStatusBar").SetHasClass("Lower", true);
}

function OnAllyAbilityBarRemove(msg)
{
	$("#AllyActionBar").style.visibility = "collapse"
	$("#AllyActionBar").ownerIndex = undefined
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


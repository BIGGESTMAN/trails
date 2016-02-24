"use strict";

function OnAbilityBarStart(msg)
{
	var mainAbilityList = $.CreatePanel("Panel", $.GetContextPanel(), "");
	mainAbilityList.heroIndex = msg.heroIndex
	mainAbilityList.BLoadLayout("file://{resources}/layout/custom_game/action_bar.xml", false, false );
	mainAbilityList.style.position = "0px 160px 0px"
	mainAbilityList.cpCosts = msg.cpCosts

	GameUI.SetRenderBottomInsetOverride(0)
}

function OnAllyAbilityBarStart(msg)
{
	var allyAbilityList = $.CreatePanel("Panel", $.GetContextPanel(), "");
	allyAbilityList.heroIndex = msg.heroIndex
	allyAbilityList.BLoadLayout("file://{resources}/layout/custom_game/action_bar.xml", false, false );
	allyAbilityList.cpCosts = msg.cpCosts
}

function OnAllyAbilityBarRemove(msg)
{
	$.GetContextPanel().Children()[1].DeleteAsync(1)
}

(function()
{
	GameEvents.Subscribe( "ability_bar_start", OnAbilityBarStart );
	GameEvents.Subscribe( "ally_ability_bar_start", OnAllyAbilityBarStart );
	GameEvents.Subscribe( "ally_ability_bar_remove", OnAllyAbilityBarRemove );
})();


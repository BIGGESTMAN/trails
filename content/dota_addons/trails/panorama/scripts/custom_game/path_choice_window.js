"use strict";

function OnPathChoiceWindowStart(data) {
	$.GetContextPanel().SetHasClass("Visible", true);
	for ( var i in data.path_rewards ) {
		$("#Path" + i + "RewardIconsContainer").RemoveAndDeleteChildren()
		for (var heroIndex in data.path_rewards[i]) {
			var abilityName = data.path_rewards[i][heroIndex]
			CreateAbilityPanel(abilityName, heroIndex, $("#Path" + i + "RewardIconsContainer"));
		}
		$("#Button" + (i)).SetHasClass("Active", i != 4)
		$("#Button" + (i)).enabled = i != 4
		// $("#Button" + i).SetHasClass("ButtonBevel", i in data.towersOwned)
		// $("#Button" + i).SetHasClass("Dark", !(i in data.towersOwned))
	}
}

function CreateAbilityPanel(abilityName, heroIndex, parent) {
	var icon = $.CreatePanel("Panel", parent, abilityName);
	// icon.BLoadLayout("file://{resources}/layout/custom_game/stats_display.xml", false, false);
	icon.BLoadLayout("file://{resources}/layout/custom_game/path_choice_ability.xml", false, false);
	icon.FindChild("AbilityImage").abilityname = abilityName;

	var heroOwner = parseInt(CustomNetTables.GetTableValue("hero_owners", heroIndex)["owner"])
	var playerColor = "#" + RGBAPlayerColor(heroOwner)
	icon.style["box-shadow"] = "fill " + playerColor + " -1px -1px 8px 3px;"
	// icon.SetAttributeString("ability_name", ability_name);
}

function OnPathChoiceWindowHide(data) {
	$.GetContextPanel().SetHasClass("Visible", false);
}

function OnPathButtonPressed(pathNumber) {
	GameEvents.SendCustomGameEventToServer("path_button_pressed", {pathNumber : pathNumber} )
}

function RGBAPlayerColor(id) {
	var abgr = Players.GetPlayerColor(id).toString(16)
	var rgba = abgr.substring(6,8) + abgr.substring(4,6) + abgr.substring(2,4) + abgr.substring(0,2)
	return rgba
}

(function () {
	GameEvents.Subscribe("path_choice_window_start", OnPathChoiceWindowStart);
	GameEvents.Subscribe("path_choice_window_hide", OnPathChoiceWindowHide);
})();

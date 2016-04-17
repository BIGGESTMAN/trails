"use strict";

function OnStatusBarsStart(data) {
	var pvp_mode = CustomNetTables.GetTableValue("gamemode", 0)["pvp_ui_enabled"]
	if (parseInt(pvp_mode) === 0) {
		$.GetContextPanel().SetHasClass("Disabled", true)
	} else {
		$.GetContextPanel().Children()[data.player].SetHasClass("Visible", true);
	}
}

function OnStatusBarsUpdate(data) {
	if (!$.GetContextPanel().BHasClass("Disabled")) {
		var status_bar = $.GetContextPanel().Children()[data.player]

		var second_bar_full = Math.max(data.cp - 100, 0)
		var first_bar_full = Math.min(data.cp, 100)
		if (second_bar_full > 0) {
			first_bar_full = 100 - second_bar_full
			status_bar.Children()[0].style.position = second_bar_full + "% 0px 0px"
		}
		else {
			status_bar.Children()[0].style.position = "0px 0px 0px" 
		}
		status_bar.Children()[0].style.width = first_bar_full + "%"
		status_bar.Children()[1].style.width = second_bar_full + "%"

		status_bar.style.visibility = "visible"
		if (Players.GetTeam(data.player) != Players.GetTeam(Players.GetLocalPlayer()) && CustomNetTables.GetTableValue("hero_info", Players.GetPlayerHeroEntityIndex(data.player))["visible_to_enemies"] != "true") {
			status_bar.style.visibility = "collapse"
		}
	}
}

function UpdateBarLocations() {
	if (!$.GetContextPanel().BHasClass("Disabled")) {
		var wholeScreen = $.GetContextPanel().GetParent()
		var screenWidth = wholeScreen.actuallayoutwidth
		var screenHeight = wholeScreen.actuallayoutheight
		var scale = 1200 / screenHeight;

		for (var i = 0; i < $.GetContextPanel().Children().length; ++i) {
			var status_bar = $.GetContextPanel().Children()[i]
			var hero_location = Entities.GetAbsOrigin(Players.GetPlayerHeroEntityIndex(i))

			if (hero_location != undefined) {
				var screenX = (Game.WorldToScreenX(hero_location[0], hero_location[1], hero_location[2]) - status_bar.actuallayoutwidth) * scale
				var screenY = (Game.WorldToScreenY(hero_location[0], hero_location[1], hero_location[2])) * scale

				status_bar.style.position = screenX + "px " + screenY + "px 0px";
			}
		}
		$.Schedule( 1/200, UpdateBarLocations );
	}
}

(function () {
	GameEvents.Subscribe("status_bars_start", OnStatusBarsStart);
	GameEvents.Subscribe("status_bars_update", OnStatusBarsUpdate);

	$.Schedule( 1/200, UpdateBarLocations );
})();


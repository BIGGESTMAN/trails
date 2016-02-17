"use strict";

function OnStatusBarsStart(data) {
	$.GetContextPanel().Children()[data.player].SetHasClass("Visible", true);
}

function OnStatusBarsUpdate(data) {
	var hero_location = Entities.GetAbsOrigin(data.hero)
	var screenX = Game.WorldToScreenX(hero_location[0], hero_location[1], hero_location[2]) - 150
	var screenY = Game.WorldToScreenY(hero_location[0], hero_location[1], hero_location[2])
	$.Msg(GameUI.GetCursorPosition(), (screenX + 150) + "," + screenY)
	var status_bar = $.GetContextPanel().Children()[data.player]
	status_bar.style.position = screenX + "px " + screenY + "px 0px";
	var second_bar_full = Math.max(data.cp - 100, 0)
	var first_bar_full = Math.min(data.cp, 100)
	if (second_bar_full > 0) {
		first_bar_full = 100 - second_bar_full
		status_bar.Children()[0].style.position = (150 * second_bar_full / 100) + "px 0px 0px" 
	}
	else {
		status_bar.Children()[0].style.position = "0px 0px 0px" 
	}
	status_bar.Children()[0].style.width = first_bar_full + "%"
	status_bar.Children()[1].style.width = second_bar_full + "%"
}

(function () {
	GameEvents.Subscribe("status_bars_start", OnStatusBarsStart);
	GameEvents.Subscribe("status_bars_update", OnStatusBarsUpdate);
})();


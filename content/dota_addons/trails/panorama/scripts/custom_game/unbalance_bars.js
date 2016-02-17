"use strict";

function OnUnbalanceBarsStart(data) {
	$.GetContextPanel().Children()[data.player].SetHasClass("Visible", true);
}

function OnUnbalanceBarsUpdate(data) {
	var hero_location = Entities.GetAbsOrigin(data.hero)
	var screenX = Game.WorldToScreenX(hero_location[0], hero_location[1], hero_location[2]) - 150
	var screenY = Game.WorldToScreenY(hero_location[0], hero_location[1], hero_location[2]) + 20
	var unbalance_bar = $.GetContextPanel().Children()[data.player]
	unbalance_bar.style.position = screenX + "px " + screenY + "px 0px";
	unbalance_bar.Children()[0].style.width = data.unbalance + "%"
	if (data.unbalance == 100) {
		unbalance_bar.Children()[0].style["background-color"] = "gradient( radial, 50% 50%, 0% 0%, 80% 80%, from( #FF3232 ), to( #FFB5B5 ) )";
	}
	else {
		unbalance_bar.Children()[0].style["background-color"] = "gradient( linear, 0% 0%, 0% 100%, from( #FF9933 ), to( #FFB775 ) )";
	}
}

(function () {
	GameEvents.Subscribe("unbalance_bars_start", OnUnbalanceBarsStart);
	GameEvents.Subscribe("unbalance_bars_update", OnUnbalanceBarsUpdate);
})();


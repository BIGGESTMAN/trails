"use strict";

function OnUnbalanceBarsStart(data) {
	$.GetContextPanel().Children()[data.player].SetHasClass("Visible", true);
}

function OnUnbalanceBarsUpdate(data) {
	var unbalance_bar = $.GetContextPanel().Children()[data.player]
	var hero_location = Entities.GetAbsOrigin(data.hero)

	var wholeScreen = $.GetContextPanel().GetParent()
	var screenWidth = wholeScreen.actuallayoutwidth
	var screenHeight = wholeScreen.actuallayoutheight
	var scale = 1200 / screenHeight;

	var screenX = (Game.WorldToScreenX(hero_location[0], hero_location[1], hero_location[2]) - unbalance_bar.actuallayoutwidth) * scale
	var screenY = (Game.WorldToScreenY(hero_location[0], hero_location[1], hero_location[2])) * scale + 15
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


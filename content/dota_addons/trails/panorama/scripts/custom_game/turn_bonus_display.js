"use strict";

function OnTurnBonusDisplayStart(data) {
	$.GetContextPanel().SetHasClass("Visible", true);
}

function OnTurnBonusDisplayHide(data) {
	$.GetContextPanel().SetHasClass("Visible", false);
}

function OnTurnBonusDisplayUpdate(data) {
	var turn_bonus_display = $.GetContextPanel()

	// var wholeScreen = $.GetContextPanel().GetParent()
	// var screenWidth = wholeScreen.actuallayoutwidth
	// var screenHeight = wholeScreen.actuallayoutheight
	// var scale = 1200 / screenHeight;

	turn_bonus_display.Children()[1].text = data.current_bonus
	turn_bonus_display.Children()[3].text = data.next_bonus
	if (data.current_bonus_taken) {
		$.GetContextPanel().SetHasClass("Active", false)
	}
	else {
		$.GetContextPanel().SetHasClass("Active", true)
		turn_bonus_display.Children()[2].text = "Next Bonus (" + data.time_until_next_bonus + "): "
	}
}

function OnTurnBonusDisplayTick(data) {
	$.GetContextPanel().Children()[2].text = "Next Bonus (" + data.time_until_next_bonus + "): "
}

(function () {
	GameEvents.Subscribe("turn_bonus_display_start", OnTurnBonusDisplayStart);
	GameEvents.Subscribe("turn_bonus_display_update", OnTurnBonusDisplayUpdate);
	GameEvents.Subscribe("turn_bonus_display_tick", OnTurnBonusDisplayTick);
	GameEvents.Subscribe("turn_bonus_display_hide", OnTurnBonusDisplayHide);
})();


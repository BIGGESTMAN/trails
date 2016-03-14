"use strict";

function OnTeleportWindowStart(data) {
	$.Msg(data)
	$.GetContextPanel().SetHasClass("Visible", true);
	for ( var i = 1; i < 5; ++i ) {
		$("#Button" + i).SetHasClass("Active", i in data.towersOwned)
		// $("#Button" + i).SetHasClass("ButtonBevel", i in data.towersOwned)
		$("#Button" + i).enabled = i in data.towersOwned
		// $("#Button" + i).SetHasClass("Dark", !(i in data.towersOwned))
	}
}

function OnTeleportWindowHide(data) {
	$.GetContextPanel().SetHasClass("Visible", false);
}

function OnTeleportWindowUpdate(data) {
	var teleport_window = $.GetContextPanel()

	// teleport_window.Children()[1].text = data.current_bonus
	// teleport_window.Children()[3].text = data.next_bonus
	// if (data.current_bonus_taken) {
	// 	$.GetContextPanel().SetHasClass("Active", false)
	// }
	// else {
	// 	$.GetContextPanel().SetHasClass("Active", true)
	// 	teleport_window.Children()[2].text = "Next Bonus (" + data.time_until_next_bonus + "): "
	// }
}

function OnTeleportButtonPressed(towerIndex) {
	$.Msg(towerIndex)
	GameEvents.SendCustomGameEventToServer("teleport_button_pressed", {towerIndex : towerIndex} )
}

(function () {
	GameEvents.Subscribe("teleport_window_start", OnTeleportWindowStart);
	GameEvents.Subscribe("teleport_window_update", OnTeleportWindowUpdate);
	GameEvents.Subscribe("teleport_window_hide", OnTeleportWindowHide);
})();


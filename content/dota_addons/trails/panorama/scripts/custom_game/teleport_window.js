"use strict";

function OnTeleportWindowStart(data) {
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

function OnTeleportButtonPressed(towerIndex) {
	GameEvents.SendCustomGameEventToServer("teleport_button_pressed", {towerIndex : towerIndex} )
}

(function () {
	GameEvents.Subscribe("teleport_window_start", OnTeleportWindowStart);
	GameEvents.Subscribe("teleport_window_hide", OnTeleportWindowHide);
})();


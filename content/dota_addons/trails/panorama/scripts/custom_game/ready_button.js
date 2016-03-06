"use strict";

function OnReadyButtonStart(msg) {
	$.GetContextPanel().SetHasClass("Visible", true);
	$("#TimeToRoundStartText").text = "Round starting soon..."
}

function OnReadyButtonUpdate(msg) {
	$("#TimeToRoundStartText").text = "Round starting in " + msg.time + "..."
}

function OnReadyButtonHide(msg) {
	$.GetContextPanel().SetHasClass("Visible", false);
	$.GetContextPanel().SetHasClass("ReadiedUp", false);
	$.GetContextPanel().SetHasClass("PlayersReady", false);
}

function OnReadyButtonPlayersReady(msg) {
	$.GetContextPanel().SetHasClass("PlayersReady", true);
}

function OnReadyButtonPressed() {
	$.GetContextPanel().SetHasClass("ReadiedUp", true);
	GameEvents.SendCustomGameEventToServer("ready_button_pressed", {} )
}

(function () {
	GameEvents.Subscribe("ready_button_start", OnReadyButtonStart);
	GameEvents.Subscribe("ready_button_update", OnReadyButtonUpdate);
	GameEvents.Subscribe("ready_button_hide", OnReadyButtonHide);
	GameEvents.Subscribe("ready_button_all_players_ready", OnReadyButtonPlayersReady);
})();


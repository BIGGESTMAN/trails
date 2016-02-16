"use strict";

var seen_tutorials = {}

function OnInfoTextStart(msg) {
	$.GetContextPanel().SetHasClass("ReadiedUp", false);
	$.GetContextPanel().SetHasClass("Visible", true);
}

function OnInfoTextStartSecondary(msg) {
	$.GetContextPanel().SetHasClass("ReadiedUp", false);
	$.GetContextPanel().SetHasClass("Visible", true);
	$("#ReadyButtonText").text = $.Localize("infotext_ok_secondary")
	for (var i in $.GetContextPanel().Children()) {
		if (i < 6) {
			$.GetContextPanel().Children()[i].visible = false
		}
		else if (i == 6) {
			$.GetContextPanel().Children()[i].text = $.Localize("infotext_text_secondary")
		}
	}
}

function OnInfoTextOKClicked() {
	$.GetContextPanel().SetHasClass("ReadiedUp", true);
	GameEvents.SendCustomGameEventToServer("infotext_ok", {} )
}

function OnInfoTextRemove() {
	$.GetContextPanel().SetHasClass("Visible", false);
}

(function () {
	GameEvents.Subscribe("infotext_start", OnInfoTextStart);
	GameEvents.Subscribe("infotext_start_secondary_rounds", OnInfoTextStartSecondary);
	GameEvents.Subscribe("infotext_game_starting", OnInfoTextRemove);
})();


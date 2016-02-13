"use strict";

var seen_tutorials = {}

function OnInfoTextStart(msg) {
	$.GetContextPanel().SetHasClass("ReadiedUp", false);
	$.GetContextPanel().SetHasClass("Visible", true);
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
	GameEvents.Subscribe("infotext_remove_window", OnInfoTextRemove);
})();


"use strict";

var seen_tutorials = {}

function OnPreBossStart(msg) {
	$.GetContextPanel().SetHasClass("ReadiedUp", false);
	$.GetContextPanel().SetHasClass("Visible", true);
}

function OnPreBossReadyClicked() {
	$.GetContextPanel().SetHasClass("ReadiedUp", true);
	GameEvents.SendCustomGameEventToServer("preboss_ready", {} )
}

function OnPreBossAllReady() {
	$.GetContextPanel().SetHasClass("Visible", false);
}

(function () {
	GameEvents.Subscribe("preboss_start", OnPreBossStart);
	GameEvents.Subscribe("preboss_all_ready", OnPreBossAllReady);
})();


"use strict";

var seen_tutorials = {}

function OnInfoTextStart(msg) {
	$("#InfoTextWindow").SetHasClass("ReadiedUp", false);
	$("#InfoTextWindow").SetHasClass("Visible", true);

	var map_name = Game.GetMapInfo()["map_display_name"]
	if (map_name === "liberl_boss") {
		$("#Gamemode_Header").text = $.Localize("infotext_gamemode_boss_header")
		$("#Gamemode_Text").text = $.Localize("infotext_gamemode_boss_text")
	} else {
		$("#Gamemode_Header").text = $.Localize("infotext_gamemode_towers_header")
		$("#Gamemode_Text").text = $.Localize("infotext_gamemode_towers_text")
	}
}

function OnInfoTextStartSecondary(msg) {
	$("#InfoTextWindow").SetHasClass("ReadiedUp", false);
	$("#InfoTextWindow").SetHasClass("Visible", true);
	$("#ReadyButtonText").text = $.Localize("infotext_ok_secondary")
	for (var i in $("#InfoTextWindow").Children()) {
		if (i < 6) {
			$("#InfoTextWindow").Children()[i].visible = false
		}
		else if (i == 6) {
			$("#InfoTextWindow").Children()[i].text = $.Localize("infotext_text_secondary")
		}
	}
}

function OnInfoTextOKClicked() {
	$("#InfoTextWindow").SetHasClass("ReadiedUp", true);
	$.Msg("OnInfoTextOKClicked --------------")
	GameEvents.SendCustomGameEventToServer("infotext_ok", {} )
}

function OnInfoTextRemove() {
	$.GetContextPanel().SetHasClass("Hidden", true);
	$("#InfoTextWindow").SetHasClass("GameStarted", true)
	$("#InfoTextWindow").SetHasClass("ReadiedUp", false)
	$("#SlideButtonText").text = ">>"
}

function OnInfoTextWindowToggled() {
	var currently_hidden = $.GetContextPanel().BHasClass("Hidden") 
	$.GetContextPanel().SetHasClass("Hidden", !currently_hidden);
	if (currently_hidden) {
		$("#SlideButtonText").text = "<<"
	}
	else {
		$("#SlideButtonText").text = ">>"
	}
}

function OnInfoTextPageChanged() {
	var currently_trailspedia = $.GetContextPanel().BHasClass("TrailspediaActive") 
	$.GetContextPanel().SetHasClass("TrailspediaActive", !currently_trailspedia);
	if (currently_trailspedia) {
		$("#PageToggleText").text = "Status Effects"
	}
	else {
		$("#PageToggleText").text = "General Info"
	}
}

(function () {
	GameEvents.Subscribe("infotext_start", OnInfoTextStart);
	GameEvents.Subscribe("infotext_start_secondary_rounds", OnInfoTextStartSecondary);
	GameEvents.Subscribe("infotext_game_starting", OnInfoTextRemove);
})();


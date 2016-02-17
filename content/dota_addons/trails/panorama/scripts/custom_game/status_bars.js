"use strict";

// function OnInfoTextStart(msg) {
// 	$.GetContextPanel().SetHasClass("ReadiedUp", false);
// 	$.GetContextPanel().SetHasClass("Visible", true);
// }

// function OnInfoTextStartSecondary(msg) {
// 	$.GetContextPanel().SetHasClass("ReadiedUp", false);
// 	$.GetContextPanel().SetHasClass("Visible", true);
// 	$("#ReadyButtonText").text = $.Localize("infotext_ok_secondary")
// 	for (var i in $.GetContextPanel().Children()) {
// 		if (i < 6) {
// 			$.GetContextPanel().Children()[i].visible = false
// 		}
// 		else if (i == 6) {
// 			$.GetContextPanel().Children()[i].text = $.Localize("infotext_text_secondary")
// 		}
// 	}
// }

// function OnInfoTextOKClicked() {
// 	$.GetContextPanel().SetHasClass("ReadiedUp", true);
// 	GameEvents.SendCustomGameEventToServer("infotext_ok", {} )
// }

// function OnInfoTextRemove() {
// 	$.GetContextPanel().SetHasClass("Visible", false);
// }

function OnStatusBarsStart() {
	$.GetContextPanel().SetHasClass("Visible", true);
}

function OnStatusBarsUpdate(data) {
	var hero_location = Entities.GetAbsOrigin(data.hero)
	var screenX = Game.WorldToScreenX(hero_location[0], hero_location[1], hero_location[2]) - 175
	var screenY = Game.WorldToScreenY(hero_location[0], hero_location[1], hero_location[2]) - 25
	// $.Msg(screenX, " ", screenY)
	// $.Msg($.GetContextPanel().Children()[0].style)
	// $.Msg($("#CPBar").style)
	$.GetContextPanel().style.position = screenX + "px " + screenY + "px 0px";
	$.Msg((data.cp / 2) + "%")
	$.GetContextPanel().Children()[0].style.width = (data.cp / 2) + "%"
	// $("#CPBar").width = (data.cp / 200) + "%"
	// $.GetContextPanel().Children()[0].style.x = Number(screenX)
	// $.GetContextPanel().Children()[0].style.y = Number(screenY)
	// $("#CPBar").x = screenX
	// $("#CPBar").y = screenY
}

(function () {
	GameEvents.Subscribe("status_bars_start", OnStatusBarsStart);
	GameEvents.Subscribe("status_bars_update", OnStatusBarsUpdate);
})();


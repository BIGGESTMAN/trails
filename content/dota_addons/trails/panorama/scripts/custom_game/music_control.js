"use strict";

function OnMusicControlStart(msg) {
	var wholeScreen = $.GetContextPanel().GetParent()
	var screenWidth = wholeScreen.actuallayoutwidth
	var screenHeight = wholeScreen.actuallayoutheight
	var scale = screenHeight / 1200;

	// var screenX = 1515 * scale
	// var screenY = 600 * scale
	// $.Msg(screenX,",",screenY)
	// $.GetContextPanel().Children()[0].style.position = screenX + "px " + screenY + "px 0px";
	// $.GetContextPanel().Children()[0].style.width = 180 * scale + "px"
	// $.GetContextPanel().Children()[0].style.height = 48 * scale + "px"

	$.GetContextPanel().SetHasClass("Visible", true);
}

function OnMusicControlToggled() {
	GameEvents.SendCustomGameEventToServer("music_control_toggled", {} )
}

(function () {
	GameEvents.Subscribe("music_control_start", OnMusicControlStart);
})();


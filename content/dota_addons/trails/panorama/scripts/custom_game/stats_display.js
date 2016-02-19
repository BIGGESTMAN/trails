"use strict";

function OnStatsDisplayStart(data) {
	$.GetContextPanel().SetHasClass("Visible", true);
}

function OnStatsDisplayUpdate(data) {
	var stats_display = $.GetContextPanel()

	// var wholeScreen = $.GetContextPanel().GetParent()
	// var screenWidth = wholeScreen.actuallayoutwidth
	// var screenHeight = wholeScreen.actuallayoutheight
	// var scale = 1200 / screenHeight;

	var selectedUnit = null
	var selectedControlledUnits = Players.GetSelectedEntities(data.playerid)
	var selectedUncontrolledUnit = Players.GetQueryUnit(data.playerid)

	if (selectedUncontrolledUnit != -1)
	{
		selectedUnit = selectedUncontrolledUnit
	}
	else
	{
		selectedUnit = selectedControlledUnits[0]
	}

	var stats = data.unitStats[selectedUnit]

	$("#Str").text = "Str: " + stats["str"]
	$("#Def").text = "Def: " + stats["def"]
	$("#Ats").text = "Ats: " + stats["ats"]
	$("#Adf").text = "Adf: " + stats["adf"]
	$("#Spd").text = "Spd: " + stats["spd"]
	$("#Mov").text = "Mov: " + Math.floor(stats["mov"])
}

(function () {
	GameEvents.Subscribe("stats_display_start", OnStatsDisplayStart);
	GameEvents.Subscribe("stats_display_update", OnStatsDisplayUpdate);
})();


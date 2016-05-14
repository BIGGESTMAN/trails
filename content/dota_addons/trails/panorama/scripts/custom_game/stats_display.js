"use strict";

function OnStatsDisplayStart(data) {
	$.GetContextPanel().SetHasClass("Visible", true);
}

function OnStatsDisplayUpdate(data) {
	var stats_display = $.GetContextPanel()
	$("#StrImage").style.backgroundImage = "url('file://{resources}/images/ui/strength_icon.png')";
	$("#DefImage").style.backgroundImage = "url('file://{resources}/images/ui/defense_icon.png')";
	$("#AtsImage").style.backgroundImage = "url('file://{resources}/images/ui/m_strength_icon.png')";
	$("#AdfImage").style.backgroundImage = "url('file://{resources}/images/ui/m_defense_icon.png')";

	// var wholeScreen = $.GetContextPanel().GetParent()
	// var screenWidth = wholeScreen.actuallayoutwidth
	// var screenHeight = wholeScreen.actuallayoutheight
	// var scale = 1200 / screenHeight;

	var selectedUnit = null
	var selectedControlledUnits = Players.GetSelectedEntities(Players.GetLocalPlayer())
	var selectedUncontrolledUnit = Players.GetQueryUnit(Players.GetLocalPlayer())

	if (selectedUncontrolledUnit != -1)
	{
		selectedUnit = selectedUncontrolledUnit
	}
	else
	{
		selectedUnit = selectedControlledUnits[0]
	}

	// var stats = data.unitStats[selectedUnit]
	var stats = data.unitStats[stats_display.heroIndex]

	if (stats) { // else unit is dead i think?
		$("#Str").text = "Str: " + stats["str"]
		$("#Def").text = "Def: " + (stats["def"] - 100)
		$("#Ats").text = "Ats: " + stats["ats"]
		$("#Adf").text = "Adf: " + (stats["adf"] - 100)
		$("#Spd").text = "Spd: " + stats["spd"]
		$("#Mov").text = "Mov: " + Math.floor(stats["mov"])
	}
}

function HideStatsTooltip() {
	$.DispatchEvent( "DOTAHideTextTooltip", $.GetContextPanel() );
}

function ShowStatsTooltip() {
	$.DispatchEvent( "DOTAShowTextTooltip", $.GetContextPanel(), $.Localize("stats_tooltip") );
}

(function () {
	GameEvents.Subscribe("stats_display_start", OnStatsDisplayStart);
	GameEvents.Subscribe("stats_display_update", OnStatsDisplayUpdate);
})();


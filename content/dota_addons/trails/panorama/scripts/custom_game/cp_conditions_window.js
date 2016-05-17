"use strict";

function OnEncounterStart() {
	$.GetContextPanel().SetHasClass("Visible", true);
}

function OnEncounterEnd() {
	$.GetContextPanel().SetHasClass("Visible", false);
}

function OnConditionsUpdate(msg) {
	var container = $("#CPConditionsContainer");
	container.RemoveAndDeleteChildren()
	for (var i in msg.conditions) {
		var condition = msg.conditions[i]
		CreateConditionPanel(condition.description, container, condition.unique, condition.unlocked)
	}
}

function CreateConditionPanel(description, parent, unique, unlocked) {
	var conditionPanel = $.CreatePanel("Panel", parent, "CPConditionPanel_" + description);
	conditionPanel.SetAttributeString("description", description);
	conditionPanel.SetAttributeString("unlocked", unlocked);
	conditionPanel.SetAttributeString("unique", unique);
	conditionPanel.BLoadLayout("file://{resources}/layout/custom_game/cp_condition.xml", false, false);
}

function OnBravePointsUpdate(msg) {
	$("#BravePoints").text = "Brave Points: " + msg.brave_points
}

(function () {
	GameEvents.Subscribe("encounter_started", OnEncounterStart);
	GameEvents.Subscribe("encounter_ended", OnEncounterEnd);
	GameEvents.Subscribe("update_cp_conditions_window", OnConditionsUpdate);
	GameEvents.Subscribe("update_brave_points", OnBravePointsUpdate);
})();


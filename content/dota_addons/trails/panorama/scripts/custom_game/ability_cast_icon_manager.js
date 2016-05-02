"use strict";

var abilityCount = 0;
function OnAbilityCast(msg) {
	var abilityName = msg.abilityName
	var casterIndex = msg.casterIndex
	var parent = $.GetContextPanel()
	abilityCount++;

	var panel = $.CreatePanel("Panel", parent, "AbilityCastIcon_" + abilityCount);
	panel.SetAttributeString("ability_name", abilityName);
	panel.SetAttributeInt("caster_index", casterIndex);
	panel.BLoadLayout("file://{resources}/layout/custom_game/ability_cast_icon.xml", false, false);

	// var screenLocation = GetScreenPositionOfUnit(casterIndex)
	// panel.style.position = screenLocation[0] + "px " + screenLocation[1] + "px 0px"

	panel.SetHasClass("CastAnnounce_Visible", true);
	$.Schedule(2, function() {
		panel.SetHasClass("CastAnnounce_Visible", false);
	});
	panel.DeleteAsync(2.3)
}

(function () {
	GameEvents.Subscribe("ability_cast", OnAbilityCast);
})();
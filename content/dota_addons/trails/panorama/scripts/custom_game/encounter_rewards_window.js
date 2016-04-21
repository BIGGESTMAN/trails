"use strict";

function ShowEncounterRewards(data) {
	$.GetContextPanel().style["transition-duration"] = "0.5s"
	$.GetContextPanel().SetHasClass("Visible", true);
	$("#GoldText").text = "Gold: " + data.gold
	$("#CPText").text = "CP : " + data.cp
	var truncated_time = Math.ceil(data.time * 100) / 100
	$("#TimeTakenText").text = "Time Taken: " + truncated_time + "s (Goal: " + data.goal_time + "s)"
	$("#MechanicsRatingText").text = "Mechanics Rating: " + data.mechanics_percent + "%"

	$.Schedule(10, function() {
		$.GetContextPanel().style["transition-duration"] = "3s"
		$.GetContextPanel().SetHasClass("Visible", false);
	})
}

(function () {
	GameEvents.Subscribe("show_encounter_rewards", ShowEncounterRewards);
})();

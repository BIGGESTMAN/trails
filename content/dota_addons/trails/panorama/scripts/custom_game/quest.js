"use strict";

/*
function OnItemWillSpawn( msg )
{
	$.GetContextPanel().SetHasClass( "item_will_spawn", true );
	$.GetContextPanel().SetHasClass( "item_has_spawned", false );
	GameUI.PingMinimapAtLocation( msg.spawn_location );
	$( "#AlertMessage_Chest" ).html = true;
	$( "#AlertMessage_Delivery" ).html = true;
	$( "#AlertMessage_Chest" ).text = $.Localize( "#Chest" );
	$( "#AlertMessage_Delivery" ).text = $.Localize( "#ItemWillSpawn" );

	$.Schedule( 3, ClearItemSpawnMessage );
}
*/

var timerSchedulerId = -1;

function OnStartCounter(msg) {
	$.GetContextPanel().max_count = msg.max_count;

	$("#QuestCounter").SetHasClass("Visible", true);
	$("#QuestTimer").SetHasClass("Visible", false);
	$("#QuestGeneric").SetHasClass("Visible", false);
	$("#Counter").SetHasClass("Hidden", msg.hide_precise_count == true);

	$("#Text").text = $.Localize(msg.title);
	UpdateCounter(0);

	timerSchedulerId = -1;
}

function UpdateCounter(current_count) {
	var counter = $("#Counter");
	var max_count = $.GetContextPanel().max_count;
	counter.SetDialogVariableInt("count", current_count);
	counter.SetDialogVariableInt("max", max_count);
	if (max_count > 0) {
		$("#Progress_Fill").style.width = ((current_count * 100) / max_count) + "%;";
	}
}

function OnUpdateCounter(msg) {
	UpdateCounter(Number(msg.count));
}

function OnStartTimer(msg) {
	$.GetContextPanel().time_left = Number(msg.time) + 1;

	$("#QuestCounter").SetHasClass("Visible", false);
	$("#QuestTimer").SetHasClass("Visible", true);
	$("#QuestGeneric").SetHasClass("Visible", false);

	$("#TimerText").SetDialogVariable("title", $.Localize(msg.title));
	
	UpdateTimer(0);
	timerSchedulerId = timerSchedulerId + 1;
	TimerTick(timerSchedulerId);
}

function TimerTick(id) {
	if (timerSchedulerId == id) {
		var time = --$.GetContextPanel().time_left;

		if (time > 0) {
			UpdateTimer(time);
			$.Schedule(1.0, function() { TimerTick(id) });
		}
		else {
			$("#QuestTimer").SetHasClass("Visible", false);
		}
	}
}

function UpdateTimer(time) {
	$("#TimerText").SetDialogVariableInt("time", time);
}

function OnStartGeneric(msg) {
	$("#QuestCounter").SetHasClass("Visible", false);
	$("#QuestTimer").SetHasClass("Visible", false);
	$("#QuestGeneric").SetHasClass("Visible", true);

	$("#GenericText").text = $.Localize(msg.title);

	timerSchedulerId = -1;
}

function OnEnd(msg) {
	$("#QuestCounter").SetHasClass("Visible", false);
	$("#QuestTimer").SetHasClass("Visible", false);
	$("#QuestGeneric").SetHasClass("Visible", false);
	timerSchedulerId = -1;
}

(function () {
	GameEvents.Subscribe("quest_start_generic", OnStartGeneric);
	GameEvents.Subscribe("quest_start_counter", OnStartCounter);
	GameEvents.Subscribe("quest_update_counter", OnUpdateCounter);
	GameEvents.Subscribe("quest_start_timer", OnStartTimer);
	GameEvents.Subscribe("quest_end", OnEnd);


})();


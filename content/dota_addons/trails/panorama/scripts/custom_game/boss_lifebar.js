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

function OnBossBegin(msg) {
	$.GetContextPanel().SetHasClass("MakeVisible", true);

	$("#Lifebar_Name_Text").text = $.Localize("#"+msg.unit_id);
	SetBossLifebarPercent(100);
}

function OnBossVictory(msg) {
	$.GetContextPanel().SetHasClass("MakeVisible", false);
}


function OnBossDefeat(msg) {
	$.GetContextPanel().SetHasClass("MakeVisible", false);
}


function OnBossHealthChanged(msg) {
	SetBossLifebarPercent(msg.percent.toFixed(1));
}

var spells_announced = 0;
function OnBossCastAbility(msg) {
	var parent = $("#Lifebar_Container_CastAnnounce");
	var child = $.CreatePanel("Panel", parent, "SpellAnnounce_" + spells_announced);
	child.SetAttributeString("ability_name", msg.ability_name);
	child.BLoadLayout("file://{resources}/layout/custom_game/bossrush_boss_cast_announcer.xml", false, false)
	spells_announced++;

	child.SetHasClass("CastAnnounce_Visible", true);
	$.Schedule(2, function() {
		child.SetHasClass("CastAnnounce_Visible", false);
	});
	child.DeleteAsync(2.3)
}

function SetBossLifebarPercent(percent) {
	$("#Lifebar_Text").text = (percent+"%");
	$("#Lifebar_Fill").style.width = (percent+"%;");
}

function OnBossVulnerabilityChanged(msg) {
	$.GetContextPanel().SetHasClass("Vulnerable", 1 === parseInt(msg.vulnerable))
	if (msg.threshold_percent != null) {
		var life_percent = parseFloat($("#Lifebar_Fill").style.width.substr(0, $("#Lifebar_Fill").style.width.indexOf('%')))
		$("#VulnerabilityThresholdBar").style.width = (life_percent - msg.threshold_percent) + "%"
	}
}

function OnBossVulnerabilityTimeUpdate(msg) {
	$("#VulnerabilityDurationBarFill").style.width = (msg.percent + "%");
}

(function () {
	GameEvents.Subscribe("boss_begin", OnBossBegin);
	GameEvents.Subscribe("boss_health_changed", OnBossHealthChanged);
	GameEvents.Subscribe("boss_vulnerability_changed", OnBossVulnerabilityChanged);
	GameEvents.Subscribe("boss_update_vulnerability_time_remaining", OnBossVulnerabilityTimeUpdate);

	GameEvents.Subscribe("boss_cast", OnBossCastAbility);
	GameEvents.Subscribe("boss_victory", OnBossVictory);
	GameEvents.Subscribe("boss_defeat", OnBossDefeat);
})();

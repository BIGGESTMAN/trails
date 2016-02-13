"use strict";

function OnStart(msg) {
	//$.GetContextPanel().max_count = msg.max_count;
}

function OnHeroCardClicked() {
	var id = $.GetContextPanel().id;
	$.GetContextPanel().onHeroCardClicked($.GetContextPanel(), id);
}

function OnOtherPicked(msg) {
	var id = $.GetContextPanel().id;
	if (msg.hero_id == id) {
		$.GetContextPanel().SetHasClass("Disabled", true);
	}
}

(function () {
	var heroid = $.GetContextPanel().id;

	//$("#Portrait").style.backgroundImage = "url('file://{resources}/videos/heroes/" + heroid + ".webm')";
	$("#Portrait").style.backgroundImage = "url('file://{resources}/images/heroes/" + heroid + ".png')";
	$("#Name").text = $.Localize(heroid);

/*
	var skills = [ "dazzle_poison_touch", "warlock_upheaval", "riki_backstab" ];
	var skillsContainer = $("#Skills");
	skillsContainer.RemoveAndDeleteChildren()
	for (var i in skills) {
		var icon = $.CreatePanel("Button", skillsContainer, false, false);
		icon.SetAttributeString("ability_name", skills[i]);
		icon.BLoadLayout("file://{resources}/layout/custom_game/hero_select_skill.xml", false, false);
	}
	*/


	GameEvents.Subscribe("heroselect_pick_other", OnOtherPicked);
})();



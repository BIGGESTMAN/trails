"use strict";

function OnRoundRecapStart(msg) {
	$.Msg("OnRoundRecapStart")
	$.GetContextPanel().SetHasClass("ReadiedUp", false);
	$.GetContextPanel().SetHasClass("Visible", true);

	var heroesContainer = $("#heroes_list");
	// $.Msg(msg)
	heroesContainer.RemoveAndDeleteChildren()
	for (var i in msg.heroes) {
		$.Msg(msg.heroes)
		CreateHeroPanel(msg.heroes[i], heroesContainer)
	}
}

function CreateHeroPanel(hero, parent) {
	var hero_name = hero.name;

	var heroPanel = $.CreatePanel("Panel", parent, hero_name);
	heroPanel.SetAttributeString("hero_name", hero_name);
	$.Msg("Player Index: ", hero.player)
	heroPanel.SetAttributeInt("player_index", hero.player)
	heroPanel.BLoadLayout("file://{resources}/layout/custom_game/round_recap_hero.xml", false, false);

	for (var i in hero.abilities) {
		CreateAbilityPanel(hero.abilities[i], heroPanel)
	}
}

function CreateAbilityPanel(ability, parent) {
	var ability_name = ability.name;

	var icon = $.CreatePanel("Panel", parent, ability_name);
	icon.SetAttributeString("ability_name", ability_name);
	icon.SetAttributeInt("damage", ability.damage);
	icon.BLoadLayout("file://{resources}/layout/custom_game/round_recap_skill.xml", false, false);
}

function OnRoundRecapReadyClicked() {
	$.GetContextPanel().SetHasClass("ReadiedUp", true);
	GameEvents.SendCustomGameEventToServer("round_recap_ready", {} )
}

function OnRoundRecapRemove() {
	$.GetContextPanel().SetHasClass("Visible", false);
}

(function () {
	GameEvents.Subscribe("round_recap_start", OnRoundRecapStart);
	GameEvents.Subscribe("round_recap_remove", OnRoundRecapRemove);
})();


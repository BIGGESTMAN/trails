"use strict";

function OnRoundRecapStart(msg) {
	$.GetContextPanel().SetHasClass("ReadiedUp", false);
	$.GetContextPanel().SetHasClass("Visible", true);

	var heroesContainer = $("#heroes_list");
	heroesContainer.RemoveAndDeleteChildren()
	for (var i in msg.heroes) {
		CreateHeroPanel(msg.heroes[i], heroesContainer)
	}
}

function CreateHeroPanel(hero, parent) {
	var hero_name = hero.name;

	var heroPanel = $.CreatePanel("Panel", parent, hero_name);
	heroPanel.SetAttributeString("hero_name", hero_name);
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
	var abilityTexture = Abilities.GetAbilityTextureName(ability.index)
	icon.SetAttributeString("ability_texture_name", abilityTexture);
	icon.SetAttributeInt("damage", ability.damage);
	icon.BLoadLayout("file://{resources}/layout/custom_game/round_recap_skill.xml", false, false);
}

function OnRoundRecapRemove() {
	$.GetContextPanel().SetHasClass("Visible", false);
}

(function () {
	GameEvents.Subscribe("round_recap_start", OnRoundRecapStart);
	GameEvents.Subscribe("round_recap_remove", OnRoundRecapRemove);
})();


"use strict";



var ALL_HEROES = {
	"npc_dota_hero_ember_spirit": [
		"autumn_leaf_cutter",
		"motivate",
		"arc_slash",
		"gale",
		"azure_flame_slash"
	],
	"npc_dota_hero_windrunner": [
		"flamberge",
		"blessed_arrow",
		"molten_rain"
	]
}

var teamId;
var selectedHeroCard = null;
var pickedHeroes = {}


function OnHeroCardClicked(panel, id) {
	
	SelectHero(id);
}

function OnStart(msg) {
	var container = $("#HeroListContainer");
	container.RemoveAndDeleteChildren()

	teamId = msg.team;

	var firstHero = undefined
	for (var i in ALL_HEROES) {
		var card = $.CreatePanel("Panel", container, i);
		card.BLoadLayout("file://{resources}/layout/custom_game/hero_select_card.xml", false, false);
		card.onHeroCardClicked = OnHeroCardClicked;

		if (!firstHero) {
			firstHero = i;
		}
	}

	SelectHero(firstHero);
}

function OnPickSuccess(msg) {
	$.GetContextPanel().DeleteAsync(0);
}

function OnPickConfirmed(msg) {
	$("#PickLoading").style.opacity = "1.0";
	$("#PickButton").enabled = false;
	$("#PickButton").style.opacity = "0.0";
}

function OnOtherPicked(msg) {
	pickedHeroes[msg.hero_id] = true;
	if (selectedHeroCard) {
		$("#PickButton").enabled = (pickedHeroes[selectedHeroCard.id] != true);
	}
}

function CreateAbilityPanel(ability, parent) {
	var ability_name = ability;
	var is_ultimate = 0;
	if (ability[0] == '*') {
		ability_name = ability.substring(1);
		is_ultimate = 1;
	}

	var icon = $.CreatePanel("Panel", parent, ability_name);
	icon.SetAttributeString("ability_name", ability_name);
	icon.SetAttributeInt("ultimate", is_ultimate);
	icon.BLoadLayout("file://{resources}/layout/custom_game/hero_select_skill.xml", false, false);
}

function OnPickButtonClicked() {
	GameEvents.SendCustomGameEventToServer("heroselect_pick", { "hero": selectedHeroCard.id } );
}

function SelectHero(hero_id) {
	// $.Msg(hero_id);
	//$("#Figure").unit = hero_id; //.SetAttributeString("unit", hero_id);

	/*var fig = $.CreatePanel("DOTAScenePanel", $.GetContextPanel(), "figure_" + hero_id, false);
	fig.SetAttributeString("unit", hero_id);
	fig.style.width = "500px";
	fig.style.height= "500px";*/
	var figureContainer = $("#HeroFigureContainer");
	figureContainer.RemoveAndDeleteChildren()
	var figure = $.CreatePanel("Panel", figureContainer, "figure_" + hero_id);
	figure.LoadLayoutFromStringAsync("<root><styles></styles><scripts></scripts><Panel><DOTAScenePanel style=\"width:100%;height:100%;\" unit=\"" + hero_id + "\" /></Panel></root>", false, false);

	$("#HeroName").text = $.Localize(hero_id);
	$("#HeroDescription").text = $.Localize(hero_id + "_Lore");
	$("#PickButtonLabel").SetDialogVariable("name", $.Localize(hero_id));

	var skills = ALL_HEROES[hero_id];
	var skillsContainer = $("#HeroAbilityContainer");
	// var passiveContainer = $("#HeroPassiveAbilityContainer");
	var scraftContainer = $("#HeroScraftAbilityContainer");
	skillsContainer.RemoveAndDeleteChildren()
	scraftContainer.RemoveAndDeleteChildren()
	// passiveContainer.RemoveAndDeleteChildren()

	var first = true;
	for (var i in skills)
	{
		// if (i == 0)
		// {
		// 	CreateAbilityPanel(skills[i], passiveContainer);
		// }
		/*else*/ if (i == 4)
		{
			CreateAbilityPanel(skills[i], scraftContainer);
		}
		else
		{
			CreateAbilityPanel(skills[i], skillsContainer);
		}
	}

	if (selectedHeroCard) {
		selectedHeroCard.SetHasClass("Selected", false);
	}
	selectedHeroCard = $("#" + hero_id);
	selectedHeroCard.SetHasClass("Selected", true);

	$("#PickButton").enabled = (pickedHeroes[hero_id] != true);
}

function CraftsShowTooltip() {
	$("#CraftsTooltip").SetHasClass("Visible", true);
}
function CraftsHideTooltip() {
	$("#CraftsTooltip").SetHasClass("Visible", false);
}
function ScraftShowTooltip() {
	$("#ScraftTooltip").SetHasClass("Visible", true);
}
function ScraftHideTooltip() {
	$("#ScraftTooltip").SetHasClass("Visible", false);
}

(function () {
	GameEvents.Subscribe("heroselect_start", OnStart);
	GameEvents.Subscribe("heroselect_pick_other", OnOtherPicked);
	GameEvents.Subscribe("heroselect_pick_confirm", OnPickConfirmed);
	GameEvents.Subscribe("heroselect_pick_done", OnPickSuccess);
	
})();


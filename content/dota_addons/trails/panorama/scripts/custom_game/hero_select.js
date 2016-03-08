"use strict";



var ALL_HEROES;
var selectedHeroCard = null;
var pickedHeroes = {}


function OnHeroCardClicked(panel, id) {
	
	SelectHero(id);
}

function OnStart(msg) {
	var container = $("#HeroListContainer");
	container.RemoveAndDeleteChildren()

	ALL_HEROES = msg.heroes
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

function CreateAbilityPanel(ability_name, parent) {
	var icon = $.CreatePanel("Panel", parent, ability_name);
	icon.SetAttributeString("ability_name", ability_name);
	icon.BLoadLayout("file://{resources}/layout/custom_game/hero_select_skill.xml", false, false);
}

function CreateMasterQuartzPanel(quartz_name, parent) {
	var icon = $.CreatePanel("Panel", parent, quartz_name);
	icon.SetAttributeString("quartz_name", quartz_name);
	icon.BLoadLayout("file://{resources}/layout/custom_game/hero_select_quartz.xml", false, false);
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

	// $("#HeroName").text = $.Localize(hero_id);
	$("#HeroDescription").text = $.Localize(hero_id + "_Lore");
	$("#Str").text = "Strength: " + ALL_HEROES[hero_id].str
	$("#Ats").text = "Arts Strength: " + ALL_HEROES[hero_id].ats
	$("#Health").text = "Health: " + ALL_HEROES[hero_id].health
	$("#Mana").text = "Mana: " + ALL_HEROES[hero_id].mana
	$("#PickButtonLabel").SetDialogVariable("name", $.Localize(hero_id));

	var skills = ALL_HEROES[hero_id].abilities;
	var skillsContainer = $("#HeroAbilityContainer");
	var scraftContainer = $("#HeroScraftAbilityContainer");
	var masterQuartzContainer = $("#HeroMasterQuartzContainer");
	skillsContainer.RemoveAndDeleteChildren()
	scraftContainer.RemoveAndDeleteChildren()
	masterQuartzContainer.RemoveAndDeleteChildren()

	var first = true;
	for (var i in skills)
	{
		if (i == 5)
		{
			CreateAbilityPanel(skills[i], scraftContainer);
		}
		else
		{
			CreateAbilityPanel(skills[i], skillsContainer);
		}
	}
	CreateMasterQuartzPanel(ALL_HEROES[hero_id].masterquartz, masterQuartzContainer)

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
function MasterQuartzShowTooltip() {
	$("#MasterQuartzTooltip").SetHasClass("Visible", true);
}
function MasterQuartzHideTooltip() {
	$("#MasterQuartzTooltip").SetHasClass("Visible", false);
}

(function () {
	GameEvents.Subscribe("heroselect_start", OnStart);
	GameEvents.Subscribe("heroselect_pick_other", OnOtherPicked);
	GameEvents.Subscribe("heroselect_pick_confirm", OnPickConfirmed);
	GameEvents.Subscribe("heroselect_pick_done", OnPickSuccess);
	
})();


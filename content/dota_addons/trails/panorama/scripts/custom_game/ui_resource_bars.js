function OnResourceBarsUpdate(data) {
	if ($.GetContextPanel().heroIndex) {
		var unitValues = data.unitValues
		var heroIndex = $.GetContextPanel().heroIndex
		var container = $.GetContextPanel()
		var healthBar = $("#HealthBar")
		var manaBar = $("#ManaBar")
		var cpBarBackground = container.Children()[2]
		var cpBar = $("#CPBar")
		var overfullCPBar = $("#OverfullCPBar")
		var unbalanceBar = $("#UnbalanceBar")

		var healthPercent = Entities.GetHealthPercent(heroIndex)
		var manaPercent = Entities.GetMana(heroIndex) / Entities.GetMaxMana(heroIndex) * 100
		healthBar.style.width = healthPercent + "%"
		manaBar.style.width = manaPercent + "%"
		$("#HealthLabel").text = Entities.GetHealth(heroIndex)
		$("#ManaLabel").text = Entities.GetMana(heroIndex)

		var cp = Math.floor(unitValues[heroIndex].cp)
		var second_cp_bar_full = Math.max(cp - 100, 0)
		var first_cp_bar_full = Math.min(cp, 100)
		if (second_cp_bar_full > 0) {
			first_cp_bar_full = 100 - second_cp_bar_full
			cpBar.style.position = second_cp_bar_full + "% 0px 0px"
		}
		else {
			cpBar.style.position = "0px 0px 0px" 
		}
		cpBar.style.width = first_cp_bar_full + "%"
		overfullCPBar.style.width = second_cp_bar_full + "%"
		$("#CPLabel").text = cp

		unbalanceBar.style.width = unitValues[heroIndex].unbalance + "%"
		if (unitValues[heroIndex].unbalance == 100) {
			unbalanceBar.style["background-color"] = "gradient( radial, 50% 50%, 0% 0%, 80% 80%, from( #FF3232 ), to( #FFB5B5 ) )";
		}
		else {
			unbalanceBar.style["background-color"] = "gradient( linear, 0% 0%, 100% 0%, from( #FF9933 ), to( #FFB775 ) )";
		}
		$("#UnbalanceLabel").text = unitValues[heroIndex].unbalance
	}
}

(function()
{
	GameEvents.Subscribe("resource_bars_update", OnResourceBarsUpdate);
})();
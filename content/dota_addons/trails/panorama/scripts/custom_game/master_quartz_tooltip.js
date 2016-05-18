"use strict";

function setupTooltip() {
	var masterquartz_entindex = $.GetContextPanel().GetAttributeString("masterquartz", "")
	var masterquartz_info = CustomNetTables.GetTableValue("masterquartz_info", masterquartz_entindex)

	$("#Name").text = $.Localize("DOTA_Tooltip_Ability_" + masterquartz_info.name + "_1")

	// var abilities = $.GetContextPanel().GetAttributeString("abilities", "").split(";")
	for ( var i = 0; i < 5; ++i )
	{
		// var abilityIndex = parseInt(abilities[i])
		// if ( abilityIndex == -1 )
		// 	continue;

		var ability = masterquartz_info.abilities[i + 1]
		$("#Ability" + i).SetHasClass("Disabled", !ability.unlocked)
		$("#Ability" + i + "Name").text = $.Localize(ability.name)
		$("#Ability" + i + "Description").text = $.Localize(ability.name + "_desc")
		$("#Ability" + i + "Icon").abilityname = ability.icon

		$("#AbilitySpecialContainer_" + i).RemoveAndDeleteChildren()
		if (ability.unlocked && ability.ability_specials) {
			for (var j=0; j < Object.keys(ability.ability_specials).length; ++j) {
				var abilitySpecialLabel = $.CreatePanel("Label", $("#AbilitySpecialContainer_" + i), "AbilitySpecialLabel_" + i + "_" + j);
				abilitySpecialLabel.AddClass("AbilitySpecial")
				abilitySpecialLabel.SetHasClass("AbilitySpecial", true)

				var percent = false
				var localization_string = $.Localize("DOTA_Tooltip_Ability_" + masterquartz_info.name + "_1_" + ability.ability_specials[j + 1])
				if (localization_string[0] == "%") {
					localization_string = localization_string.substr(1)
					percent = true
				}
				abilitySpecialLabel.html = true
				var text = localization_string + " <font color='#FCB040'>" + Abilities.GetSpecialValueFor(parseInt(masterquartz_entindex), ability.ability_specials[j + 1])
				if (percent) { text = text + "%" }
				text = text + "</font>"
				abilitySpecialLabel.text = text
			}
		}
	}

	var exp_current = Math.floor(masterquartz_info.exp.current)
	var exp_next = masterquartz_info.exp.next_level
	var exp_percent = exp_current / exp_next * 100
	$("#ExpBar").style.width = exp_percent + "%"
	$("#ExpLabel").text = exp_current + " / " + exp_next

	// var a = DumpObjectIndented(masterquartz_info).split('\n')
	// for (var i=0; i<a.length; i++)
	// 	$.Msg(a[i]);
}

function OnMasterQuartzInfoChanged( table_name, key, data ) {
    $.Msg( "Table ", table_name, " changed: '", key, "' = ", data );
    setupTooltip()
}

(function() {
	CustomNetTables.SubscribeNetTableListener( "masterquartz_info", OnMasterQuartzInfoChanged );
})();

function DumpObjectIndented(obj, indent)
{
  var result = "";
  if (indent == null) indent = "";
 
  for (var property in obj)
  {
    var value = obj[property];
    if (typeof value == 'string')
      value = "'" + value + "'";
    else if (typeof value == 'object')
    {
      if (value instanceof Array)
      {
        // Just let JS convert the Array to a string!
        value = "[ " + value + " ]";
      }
      else
      {
        // Recursive dump
        // (replace "  " by "\t" or something else if you prefer)
        var od = DumpObjectIndented(value, indent + "  ");
        // If you like { on the same line as the key
        //value = "{\n" + od + "\n" + indent + "}";
        // If you prefer { and } to be aligned
        value = "\n" + indent + "{\n" + od + "\n" + indent + "}";
      }
    }
    result += indent + "'" + property + "' : " + value + ",\n";
  }
  return result.replace(/,\n$/, "");
}
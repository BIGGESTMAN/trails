"use strict";

(function () {
	var description = $.GetContextPanel().GetAttributeString("description", "")
	var unique = $.GetContextPanel().GetAttributeString("unique", "") === "1"
	var unlocked = $.GetContextPanel().GetAttributeString("unlocked", "") === "1"

	if (!unlocked) {
		description = "???"
	} else {
		description = description + "."
	}
	if (unique) {
		description = "Unique: " + description
	}
	
	$("#Description").text = description
})();
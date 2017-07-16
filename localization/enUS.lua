local addonName, addon = ...
local baseLocale = {
	["Total Crafts: %s x %s"] = "Total Crafts: %s x %s",
	["Expected Crafts: %s"] = "Expected Crafts: %s",
	["Extra Crafts: %s"] = "Extra Crafts: %s",
	["Proc Rate: %s"] = "Proc Rate: %s",
	["Will not be able to compute this craft"] = "Will not be able to compute this craft"
}

addon:RegisterLocale('enUS', baseLocale)

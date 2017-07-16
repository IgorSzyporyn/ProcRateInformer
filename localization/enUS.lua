local addonName, addon = ...
local baseLocale = {
	["Total Crafts: %s x %s"] = "Total Crafts: %s x %s",
	["Current Proc Rate: %s"] = "Current Proc Rate: %s",
	["Historical Proc Rate: %s"] = "Historical Proc Rate: %s",
	["Will not be able to compute this craft"] = "Will not be able to compute this craft"
}

addon:RegisterLocale('enUS', baseLocale)

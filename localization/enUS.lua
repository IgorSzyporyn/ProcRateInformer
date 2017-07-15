local addonName, addon = ...
local baseLocale = {
	["Some Variable: %s"] = "Some Variable: %s"
}

addon:RegisterLocale('enUS', baseLocale)

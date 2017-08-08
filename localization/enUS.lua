local addonName, addon = ...
local baseLocale = {
	["Session report for %s"] = "Session report for %s",
	["Proc Rate: %s (%s crafts + %s procs = %s total)"] = "Proc Rate: %s (%s crafts + %s procs = %s total)",
	["Historical Proc Rate: %s (%s crafts)"] = "Historical Proc Rate: %s (%s crafts)",
	["No procs recorded for your craft of %s"] = "No procs recorded for your craft of %s"
}

addon:RegisterLocale('enUS', baseLocale)

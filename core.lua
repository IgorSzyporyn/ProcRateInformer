--[[-------------------------------------------------------------------------
-- core.lua
--
-- This is a very simple, bare-minimum core for addon development. It provide
-- methods to register events, call initialization functions, and sets up the
-- localization table so it can be used elsewhere. This file is designed to be
-- loaded first, as it has no further dependencies.
--
-- Events registered:
--   * ADDON_LOADED - Watch for saved variables to be loaded, and call the
--       'Initialize' function in response.
--   * PLAYER_LOGIN - Call the 'Enable' method once the major UI elements
--       have been loaded and initialized.
-------------------------------------------------------------------------]]--

local addonName, addon = ...

-- Set global name of addon
_G[addonName] = addon

-- Extract version information from TOC file
addon.version = GetAddOnMetadata(addonName, "Version")
if addon.version == "@project-version" or addon.version == "wowi:version" then
    addon.version = "SCM"
end

--[[-------------------------------------------------------------------------
--  Debug support
-------------------------------------------------------------------------]]--

local EMERGENCY_DEBUG = false
if EMERGENCY_DEBUG then
    local private = {}
    for k,v in pairs(addon) do
        rawset(private, k, v)
        rawset(addon, k, nil)
    end

    setmetatable(addon, {
        __index = function(t, k)
            local value = rawget(private, k)
            if type(value) == "function" then
                print("CALL", addonName .. "." .. tostring(k))
            end
            return value
        end,
        __newindex = function(t, k, v)
            print(addonName, "NEWINDEX", k, v)
            rawset(private, k, v)
        end,
    })
end

--[[-------------------------------------------------------------------------
--  API compatibility support
-------------------------------------------------------------------------]]--

-- Returns true if the API value is true-ish (handles old 1/nil returns)
function addon:APIIsTrue(val, ...)
	if type(val) == "boolean" then
		return val
	elseif type(val) == "number" then
		return val == 1
	else
		return false
	end
end

--[[-------------------------------------------------------------------------
--  Print/Printf support
-------------------------------------------------------------------------]]--

local printHeader = "|cFF33FF99%s|r: "

function addon:Print(msg, ...)
    msg = printHeader .. msg
    local success, txt = pcall(string.format, msg, addonName, ...)
    if success then
        print(txt)
    else
        error(string.gsub(txt, "'%?'", string.format("'%s'", "Printf")), 3)
    end
end

--[[-------------------------------------------------------------------------
--  Event registration and dispatch
-------------------------------------------------------------------------]]--

addon.eventFrame = CreateFrame("Frame", addonName .. "EventFrame", UIParent)
local eventMap = {}

function addon:RegisterEvent(event, handler)
    assert(eventMap[event] == nil, "Attempt to re-register event: " .. tostring(event))
    eventMap[event] = handler and handler or event
    addon.eventFrame:RegisterEvent(event)
end

function addon:UnregisterEvent(event)
    assert(type(event) == "string", "Invalid argument to 'UnregisterEvent'")
    eventMap[event] = nil
    addon.eventFrame:UnregisterEvent(event)
end

addon.eventFrame:SetScript("OnEvent", function(frame, event, ...)
    local handler = eventMap[event]
    local handler_t = type(handler)
    if handler_t == "function" then
        handler(event, ...)
    elseif handler_t == "string" and addon[handler] then
        addon[handler](addon, event, ...)
    end
end)

--[[-------------------------------------------------------------------------
--  Setup Initialize/Enable support
-------------------------------------------------------------------------]]--

addon:RegisterEvent("PLAYER_LOGIN", "Enable")
addon:RegisterEvent("ADDON_LOADED", function(event, ...)
    if ... == addonName then
        addon:UnregisterEvent("ADDON_LOADED")
        if type(addon["Initialize"]) == "function" then
            addon["Initialize"](addon)
        end

        -- If this addon was loaded-on-demand, trigger 'Enable' as well
        if IsLoggedIn() and type(addon["Enable"]) == "function" then
            addon["Enable"](addon)
        end
    end
end)

--[[-------------------------------------------------------------------------
--  Localization
-------------------------------------------------------------------------]]--

addon.L = addon.L or setmetatable({}, {
    __index = function(t, k)
        rawset(t, k, k)
        return k
    end,
    __newindex = function(t, k, v)
        if v == true then
            rawset(t, k, k)
        else
            rawset(t, k, v)
        end
    end,
})

function addon:RegisterLocale(locale, tbl)
    if locale == "enUS" or locale == GetLocale() then
        for k,v in pairs(tbl) do
            if v == true then
                self.L[k] = k
            elseif type(v) == "string" then
                self.L[k] = v
            else
                self.L[k] = k
            end
        end
    end
end

--[[-------------------------------------------------------------------------
--  Addon 'About' Dialog for Interface Options
--
--  Some of this code was taken from/inspired by tekKonfigAboutPanel
-------------------------------------------------------------------------]]--

local about = CreateFrame("Frame", addonName .. "AboutPanel", InterfaceOptionsFramePanelContainer)
about.name = addonName
about:Hide()

function about.OnShow(frame)
    local fields = {"Version", "Author", "X-Category", "X-License", "X-Email", "X-Website", "X-Credits"}
	local notes = GetAddOnMetadata(addonName, "Notes")

    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")

	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(addonName)

	local subtitle = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	subtitle:SetHeight(32)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	subtitle:SetPoint("RIGHT", about, -32, 0)
	subtitle:SetNonSpaceWrap(true)
	subtitle:SetJustifyH("LEFT")
	subtitle:SetJustifyV("TOP")
	subtitle:SetText(notes)

	local anchor
	for _,field in pairs(fields) do
		local val = GetAddOnMetadata(addonName, field)
		if val then
			local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
			title:SetWidth(75)
			if not anchor then title:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", -2, -8)
			else title:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -6) end
			title:SetJustifyH("RIGHT")
			title:SetText(field:gsub("X%-", ""))

			local detail = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
			detail:SetPoint("LEFT", title, "RIGHT", 4, 0)
			detail:SetPoint("RIGHT", -16, 0)
			detail:SetJustifyH("LEFT")
			detail:SetText(val)

			anchor = title
		end
	end

    -- Clear the OnShow so it only happens once
	frame:SetScript("OnShow", nil)
end

addon.optpanels = addon.optpanels or {}
addon.optpanels.ABOUT = about

about:SetScript("OnShow", about.OnShow)
InterfaceOptions_AddCategory(about)


--[[-------------------------------------------------------------------------
--  Addon Wait function
--
-------------------------------------------------------------------------]]--

local waitTable = {};
local waitFrame = nil;

function addon:Wait(delay, func, ...)
  if(type(delay)~="number" or type(func)~="function") then
    return false;
  end
  if(waitFrame == nil) then
    waitFrame = CreateFrame("Frame","WaitFrame", UIParent);
    waitFrame:SetScript("onUpdate",function (self,elapse)
      local count = #waitTable;
      local i = 1;
      while(i<=count) do
        local waitRecord = tremove(waitTable,i);
        local d = tremove(waitRecord,1);
        local f = tremove(waitRecord,1);
        local p = tremove(waitRecord,1);
        if(d>elapse) then
          tinsert(waitTable,i,{d-elapse,f,p});
          i = i + 1;
        else
          count = count - 1;
          f(unpack(p));
        end
      end
    end);
  end
  tinsert(waitTable,{delay,func,{...}});
  return true;
end
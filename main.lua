--[[-------------------------------------------------------------------
--  ProcRateInformer - Igor Szyporyn Jørgensen
-------------------------------------------------------------------]]--
local hooksecurefunc, select, UnitGUID, tonumber, strfind, math
  = hooksecurefunc, select, UnitGUID, tonumber, strfind, math

local addonName, addon = ...;
local L = addon.L;

local craftingCastIteration = 0;
local craftingCastsForCompletion = 0;
local craftingInProgress = false;
local craftingTableItem = nil;
local craftingYield = 0;
local itemsInBagsPost = 0;
local itemsInBagsPre = 0;

local cachedCrafted = nil;
local cachedExpected = nil;
local cachedHistoricalProcRate = nil;
local cachedHistoricallyExpected = nil;
local cachedItemLink = nil;
local cachedProcRate = nil;
local cachedProcs = nil;

--[[-------------------------------------------------------------------
--  Utility functions
-------------------------------------------------------------------]]--
local function countItems(itemID)
  local c = 0;
  for bag=0,NUM_BAG_SLOTS do
      for slot=1,GetContainerNumSlots(bag) do
          if itemID == GetContainerItemID(bag,slot) then
              c=c+(select(2,GetContainerItemInfo(bag,slot)))
          end
      end
  end
  return c
end

local function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

--[[-------------------------------------------------------------------
--  Print Report functions
-------------------------------------------------------------------]]--
local function printSessionReport(expectedCount, craftedCount, procs, craftedProcRate, historicallyExpected, historicalProcRate, itemLink)
  addon:Print(L["Session report for %s"], itemLink);
  addon:Print(L["Proc Rate: %s (%s crafts + %s procs = %s total)"], round(craftedProcRate, 2), expectedCount, procs, craftedCount);
  addon:Print(L["Historical Proc Rate: %s (%s crafts)"], round(historicalProcRate, 2), historicallyExpected);
end

local function printHistoricalReport()

end


--[[-------------------------------------------------------------------
--  Finalize the craft calculations, emit procs and set historical values
-------------------------------------------------------------------]]--
function addon:FinalizeCraft()

  local recipeID = craftingTableItem.ID;
  local itemID = craftingTableItem.itemID;  

  itemsInBagsPost = countItems(itemID);

  local _, itemLink, _, _, _, _, _, _, _, _, _ = GetItemInfo(itemID);
  local craftedCount = itemsInBagsPost - itemsInBagsPre;
  local expectedCount = craftingCastIteration * craftingYield;
  local procs = craftedCount - expectedCount;
  local historicalProcRate = nil;

  if not ProcRateInformerTable[recipeID].crafted then
    ProcRateInformerTable[recipeID].crafted = craftedCount;
    ProcRateInformerTable[recipeID].expected = expectedCount;
    ProcRateInformerTable[recipeID].procs = procs;
  else
    local newHistoricalCrafted = ProcRateInformerTable[recipeID].crafted + craftedCount;
    local newHistoricalExpected = ProcRateInformerTable[recipeID].expected + expectedCount;
    local newHistoricalProcs = ProcRateInformerTable[recipeID].procs + procs;

    ProcRateInformerTable[recipeID].crafted = newHistoricalCrafted;
    ProcRateInformerTable[recipeID].expected = newHistoricalExpected;
    ProcRateInformerTable[recipeID].procs = newHistoricalProcs;

    historicalProcRate = newHistoricalCrafted / newHistoricalExpected;
  end

  local historicallyCrafted = ProcRateInformerTable[recipeID].crafted;
  local historicallyExpected = ProcRateInformerTable[recipeID].expected;
  local historicalProcs = ProcRateInformerTable[recipeID].procs;

  if procs > 0 then
    local craftedProcRate = craftedCount / expectedCount;

    if historicalProcRate == nil then
      historicalProcRate = craftedProcRate;
    end
 
    cachedCrafted = craftedCount;
    cachedExpected = expectedCount;
    cachedHistoricalProcRate = historicalProcRate;
    cachedHistoricallyExpected = historicallyExpected;
    cachedItemLink = itemLink;
    cachedProcRate = craftedProcRate;
    cachedProcs = procs;

    printSessionReport(expectedCount, craftedCount, procs, craftedProcRate, historicallyExpected, historicalProcRate, itemLink);
  else
    self:Print(L["No procs recorded for your craft of %s"], itemLink);
  end

  self:InitProperties();
end


--[[-------------------------------------------------------------------
--  Cast event handlers (craft start, each successfull cast, cast aborts)
-------------------------------------------------------------------]]--

local function onCraftStart(recipeID, amount)
  craftingTableItem = ProcRateInformerTable[recipeID];

  if craftingTableItem then
    craftingYield = C_TradeSkillUI.GetRecipeNumItemsProduced(recipeID);
    craftingInProgress = true;
    craftingCastIteration = 0;
    craftingCastsForCompletion = amount / craftingYield;
    itemsInBagsPre = countItems(craftingTableItem.itemID);
  end
end

function addon:OnSpellCastSuccess()
  if craftingInProgress then
    craftingCastIteration = craftingCastIteration + 1;
    if craftingCastIteration == craftingCastsForCompletion then
      self:Wait(1.5, function()
        addon:FinalizeCraft();
      end)
    end
  end
end

function addon:OnSpellCastFailed()
  if craftingInProgress then
    self:Wait(1.5, function()
      addon:FinalizeCraft();
    end)
  end
end

function addon:InitProperties()
  craftingCastIteration = 0;
  craftingCastsForCompletion = 0;
  craftingInProgress = false;
  craftingTableItem = nil;
  craftingYield = 0;
  itemsInBagsPost = 0;
  itemsInBagsPre = 0;
end


--[[-------------------------------------------------------------------
--  Initializing methods
-------------------------------------------------------------------]]--
function addon:initGlobals()
  if ProcRateInformerConfig == nil then
    ProcRateInformerConfig = {
      verbose = false
    };
  end

  if ProcRateInformerTable == nil then
    ProcRateInformerTable = {};
  end
end

function addon:InitVersion()
  if ProcRateInformerConfig.version < 0700 then
    ProcRateInformerConfig.version = 0700;
  end
end

function addon:LegacyCleanUp()
  ProcRateInformerHistory = nil;
end

function addon:Enable()
  addon:Print("Version 0.7");
end


--[[-------------------------------------------------------------------
--  Command handler functions.
-------------------------------------------------------------------]]--

--[[-------------------------------------------------------------------
--  Shows last craft repots
-------------------------------------------------------------------]]--
local function showLastReport()
  if cachedExpected then
    printSessionReport(cachedExpected, cachedCrafted, cachedProcs, cachedProcRate, cachedHistoricallyExpected, cachedHistoricalProcRate, cachedItemLink);
  else
    addon:Print(L["No crafting session recorded"]);
  end
end

--[[-------------------------------------------------------------------
--  Shows version
-------------------------------------------------------------------]]--
local function showVersion()
  addon:Print(ProcRateInformerConfig.version);
end

--[[-------------------------------------------------------------------
--  Called to handle commands.
-------------------------------------------------------------------]]--
local function slashCommandHandler(params, editBox)

  local _,_,command,options = string.find(msg,"([%w%p]+)%s*(.*)$");

  if (command) then
  command = string.lower(command);
  end

  if (command == nil or command == "") then
    -- editBox();
  elseif (command == "last") then showLastReport();
  elseif (command == "version") then showVersion();
  end
end


--[[-------------------------------------------------------------------
--  Addon Initialization
-------------------------------------------------------------------]]--
function addon:Initialize()
  self:initGlobals();
  self:InitVersion();
  self:InitProperties();
  self:LegacyCleanUp();

  hooksecurefunc(C_TradeSkillUI, "CraftRecipe", onCraftStart);
  self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "OnSpellCastSuccess");
  self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "OnSpellCastFailed");
  self:RegisterEvent("UNIT_SPELLCAST_FAILED", "OnSpellCastFailed");

  SlashCmdList["PROCRATEINFORMER"] = slashCommandHandler;
  SLASH_PROCRATEINFORMER1 = "/pri";
  SLASH_PROCRATEINFORMER2 = "/procrateinformer";
end
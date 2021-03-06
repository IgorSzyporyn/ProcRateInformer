--[[-------------------------------------------------------------------
--  ProcRateInformer - Igor Szyporyn Jørgensen
-------------------------------------------------------------------]]--
local addonName, addon = ...;
local L = addon.L;

function addon:GetTradeSkillFromCastName(name)
  local recipeIDs = C_TradeSkillUI.GetAllRecipeIDs();
  local tradeSkill = nil;

  for id = 1, #recipeIDs do
    local recipe = C_TradeSkillUI.GetRecipeInfo(recipeIDs[id]);
    if recipe.name == name then
      tradeSkill = recipe;
      break;
    end
  end

  return tradeSkill;
end

function addon:KillCraft()
  self:ResetProperties();

  if ProcRateInformerConfig.verbose then
    self:Print(L["Will not be able to compute this craft"]);
  end
end

function addon:FinalizeCraft()

  local craftCountPost = GetItemCount(self.craftItemID);
  local craftCountCrafted = craftCountPost - self.craftCountPre;
  local craftCountExpected = self.craftIterations * self.craftYield;
  local craftCountExtra = craftCountCrafted - craftCountExpected;
  local itemName, itemLink, _, _, _, _, _, _, _, _, _ = GetItemInfo(self.craftItemID);
  local historicalProcRate = nil;

  if not ProcRateInformerHistory[self.craftItemID] then
    ProcRateInformerHistory[self.craftItemID] = {
      crafted = craftCountCrafted,
      expected = craftCountExpected
    };
  else
    local newHistoricalCrafted = ProcRateInformerHistory[self.craftItemID].crafted + craftCountCrafted;
    local newHistoricalExpected = ProcRateInformerHistory[self.craftItemID].expected + craftCountExpected;
    historicalProcRate = newHistoricalCrafted / newHistoricalExpected;

    ProcRateInformerHistory[self.craftItemID] = {
      crafted = newHistoricalCrafted,
      expected = newHistoricalExpected
    };
  end

  if craftCountExtra > 0 then
    local craftProcRate = craftCountCrafted / craftCountExpected;

    self:Print(L["Total Crafts: %s x %s"], craftCountCrafted, itemLink);
    self:Print(L["Current Proc Rate: %s"], craftProcRate);

    if historicalProcRate then
      self:Print(L["Historical Proc Rate: %s"], historicalProcRate);
    end
  end

  self:ResetProperties();
end

function addon:OnSpellCastStart()
  local castName, _, _, _, _, _, isTradeSkill, _, _ = UnitCastingInfo("player");

  self.failed = false;
  self.crafting = true;

  if isTradeSkill then

    if self.castName ~= nil and self.castName ~= castName then
      self:FinalizeCraft();
    end


    if self.craftIterations == 0 then
      local tradeSkill = self:GetTradeSkillFromCastName(castName);

      if tradeSkill then
        local recipeID = tradeSkill.recipeID;

        self.castName = castName;
        self.craftYield = C_TradeSkillUI.GetRecipeNumItemsProduced(recipeID);
        self.craftItemID = C_TradeSkillUI.GetRecipeItemLink(recipeID):match("item:(%d+):")
        self.craftCountPre = GetItemCount(self.craftItemID);
      else
        self:KillCraft();
      end
    end
  else
    self.crafting = false;
  end
end

local function onSpellCastEnd()
  if not addon.crafting and not addon.failed then
    addon:FinalizeCraft();
  end
end

function addon:OnSpellCastSuccess()
  if self.crafting then
    self.craftIterations = self.craftIterations + 1;
    self.crafting = false;
    self:Wait(1.5, onSpellCastEnd);
  end  
end

function addon:OnSpellCastFailed()
  if self.crafting then
    self.failed = true;
    self:FinalizeCraft();
  end
end

function addon:ResetProperties()
  self.recipeID = nil;
  self.castName = nil;
  self.craftIterations = 0;
  self.craftItemID = nil;
  self.craftYield = 0;
  self.craftCountPre = 0;
  self.crafting = false;
end

function addon:InitConfig()
  if ProcRateInformerConfig == nil then
    ProcRateInformerConfig = {
      verbose = false
    };
  end
end

function addon:InitHistory()
  if ProcRateInformerHistory == nil then
    ProcRateInformerHistory = {};
  end
end

function addon:Enable()
  addon:Print("Version 1.1.0");
end

function addon:Initialize()
  self:InitConfig();
  self:InitHistory();
  self:ResetProperties();

  self:RegisterEvent("UNIT_SPELLCAST_START", "OnSpellCastStart")
  self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "OnSpellCastSuccess")
  self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "OnSpellCastFailed")
  self:RegisterEvent("UNIT_SPELLCAST_FAILED", "OnSpellCastFailed")
end
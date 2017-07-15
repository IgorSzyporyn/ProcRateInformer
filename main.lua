--[[-------------------------------------------------------------------
--  ProcRateInformer - Igor Szyporyn Jørgensen
-------------------------------------------------------------------]]--
local addonName, addon = ...;
local L = addon.L;

function addon:FinalizeCraft()
  local craftCountPost = GetItemCount(self.craftID);
  local craftCountCrafted = craftCountPost - self.craftCountPre;
  local craftCountExpected = self.craftIterations * self.craftYield;
  local craftProcRate = craftCountCrafted / craftCountExpected;

  if craftProcRate > 1 then
    self:Print("Expected yield:  %s", craftCountExpected);
    self:Print("Actual yield:    %s", craftCountCrafted);
    self:Print("Craft Proc Rate: %s", craftProcRate);
  end

  self.ResetProperties();
end

function addon:OnSpellCastStart()
  local name, _, _, _, _, _, isTradeSkill, _, _ = UnitCastingInfo("player");

  if isTradeSkill then
    if self.crafting and self.castName ~= name then
      self.FinalizeCraft();
    end

    if self.craftIterations == 0 then
      local recipeID = self.recipeID;

      self:Print("This is the recipe ID: %s", recipeID);

      self.craftYield = C_TradeSkillUI.GetRecipeNumItemsProduced(recipeID);
      self.craftID = C_TradeSkillUI.GetRecipeItemLink(recipeID):match("item:(%d+):")
      self.craftCountPre = GetItemCount(self.craftID);
      self.castName = name;
      self:Print("Found this many in bags: %", self.craftCountPre);
    end
    
    self.crafting = true;
  end
end

local function onSpellCastSuccess()
  if not addon.crafting then    
    addon:FinalizeCraft();
  end
end

function addon:OnSpellCastSuccess()
  if self.crafting then
    self.craftIterations = self.craftIterations + 1;
    self.crafting = false;
    self:Wait(0.25, onSpellCastSuccess);
  end  
end

function addon:OnSpellCastInterrupted()
  if self.crafting then
    self:FinalizeCraft();
  end
end

function addon:OnSpellCastFailed()
  if self.crafting then
    self:FinalizeCraft();
  end
end

function addon:ResetProperties()
  self.recipeID = nil;
  self.castName = nil;
  self.craftIterations = 0;
  self.craftID = 0;
  self.craftYield = 1;
  self.craftCountPre = 0;
  self.crafting = false;
end

function addon:Enable()
  addon:Print("BETA version - bugs may occur");
end

function addon:Initialize()
  self:ResetProperties();
  self:RegisterEvent("UNIT_SPELLCAST_START", "OnSpellCastStart")
  self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "OnSpellCastSuccess")
  self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "OnSpellCastInterrupted")
  self:RegisterEvent("UNIT_SPELLCAST_FAILED", "OnSpellCastFailed")
end
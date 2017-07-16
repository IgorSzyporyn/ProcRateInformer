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

  if self.verbose then
    self:Print("Will not be able to compute this craft");
  end
end

function addon:FinalizeCraft()

  local craftCountPost = GetItemCount(self.craftItemID);
  local craftCountCrafted = craftCountPost - self.craftCountPre;
  local craftCountExpected = self.craftIterations * self.craftYield;

  --[[
  self:Print("craftCountPre: %s", self.craftCountPre);
  self:Print("craftCountPost: %s", craftCountPost);
  self:Print("craftCountCrafted: %s", craftCountCrafted);
  self:Print("craftCountExpected: %s", craftCountExpected);
  ]]--

  if craftCountCrafted > craftCountExpected then
    local craftProcRate = craftCountCrafted / craftCountExpected;

    self:Print("Expected yield:  %s", craftCountExpected);
    self:Print("Actual yield:    %s", craftCountCrafted);
    self:Print("Craft Proc Rate: %s", craftProcRate);
  end

  self:ResetProperties();
end

function addon:OnSpellCastStart()
  local castName, _, _, _, _, _, isTradeSkill, _, _ = UnitCastingInfo("player");

  self.failed = false;

  if isTradeSkill then

    if self.crafting and self.castName ~= castName then
      self:FinalizeCraft();
    end

    self.crafting = true;

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
    self:Wait(0.35, onSpellCastEnd);
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

function addon:Enable()
  addon:Print("BETA version - bugs may occur");
end

function addon:Initialize()
  self.verbose = true;  
  self:ResetProperties();
  self:RegisterEvent("UNIT_SPELLCAST_START", "OnSpellCastStart")
  self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "OnSpellCastSuccess")
  self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "OnSpellCastFailed")
  self:RegisterEvent("UNIT_SPELLCAST_FAILED", "OnSpellCastFailed")
end
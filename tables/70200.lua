if not ProcRateInformerTable70200 then

  ProcRateInformerTable70200 = {
    {
      ID = 188300,
      name = "Ancient Healing Potion",
      itemID = 127834
    },
    {
      ID = 188303,
      name = "Ancient Mana Potion",
      itemID = 127835
    },
    {
      ID = 188306,
      name = "Ancient Rejuvenation Potion",
      itemID = 127836
    },
    {
      ID = 188309,
      name = "Draught of Magic",
      itemID = 127837
    },
    {
      ID = 188312,
      name = "Sylvan Elixir",
      itemID = 127838
    },
    {
      ID = 188315,
      name = "Avalanche Elixir",
      itemID = 127839
    },
    {
      ID = 188318,
      name = "Skaggldrynk",
      itemID = 127840
    },
    {
      ID = 188321,
      name = "Skystep Potion",
      itemID = 127841
    },
    {
      ID = 188324,
      name = "Infernal Alchemist Stone",
      itemID = 127842
    },
    {
      ID = 188327,
      name = "Potion of Deadly Grace",
      itemID = 127843
    },
    {
      ID = 188330,
      name = "Potion of the Old War",
      itemID = 127844
    },
    {
      ID = 188333,
      name = "Unbending Potion",
      itemID = 127845
    },
    {
      ID = 188336,
      name = "Leytorrent Potion",
      itemID = 127846
    },
    {
      ID = 188339,
      name = "Flask of the Whispered Pact",
      itemID = 127847
    },
    {
      ID = 188342,
      name = "Flask of the Seventh Demon",
      itemID = 127848
    },
    {
      ID = 188345,
      name = "Flask of the Countless Armies",
      itemID = 127849
    },
    {
      ID = 188348,
      name = "Flask of Ten Thousand Scars",
      itemID = 127850
    },
    {
      ID = 188351,
      name = "Spirit Cauldron",
      itemID = 127851
    },
    {
      ID = 229220,
      name = "Potion of Prolonged Power",
      itemID = 142117
    }
  };

  if not ProcRateInformerTable then
    ProcRateInformerTable = {};
  end

  for i = 1, #ProcRateInformerTable70200 do
    local recipe = ProcRateInformerTable70200[i];
    ProcRateInformerTable[recipe.ID] = recipe;
  end
end
swLoot.Defaults.TierDrops = {}
swLoot.Defaults.QuestDrops = {}

swLoot.TierDrops = {
    --Belts
    [40853] = {"Paladin", "Priest", "Warlock"},
    [34854] = {"Warrior", "Hunter", "Shaman"},
    [34855] = {"Rogue", "Mage", "Druid"},
    --Boots
    [34856] = {"Paladin", "Priest", "Warlock"},
    [34857] = {"Warrior", "Hunter", "Shaman"},
    [34858] = {"Rogue", "Mage", "Druid"},
    --Bracers
    [34848] = {"Paladin", "Priest", "Warlock"},
    [34851] = {"Warrior", "Hunter", "Shaman"},
    [34852] = {"Rogue", "Mage", "Druid"},
    --Chestpieces
    [40625] = {"Paladin", "Priest", "Warlock"},
    [40626] = {"Warrior", "Hunter", "Shaman"},
    [40627] = {"Rogue", "Mage", "Druid"},
    [29754] = {"Paladin", "Rogue", "Shaman"},
    [29753] = {"Warrior", "Priest", "Druid"},
    [29755] = {"Hunter", "Mage", "Warlock"},
    [31089] = {"Paladin", "Priest", "Warlock"},
    [31091] = {"Warrior", "Hunter", "Shaman"},
    [31090] = {"Rogue", "Mage", "Druid"},
    [40610] = {"Paladin", "Priest", "Warlock"},
    [40611] = {"Warrior", "Hunter", "Shaman"},
    [40612] = {"Rogue", "Death Knight", "Mage", "Druid"},
    [30236] = {"Paladin", "Rogue", "Shaman"},
    [30237] = {"Warrior", "Priest", "Druid"},
    [30238] = {"Hunter", "Mage", "Warlock"},
    --Gloves
    [40628] = {"Paladin", "Priest", "Warlock"},
    [40629] = {"Warrior", "Hunter", "Shaman"},
    [40630] = {"Rogue", "Death Knight", "Mage", "Druid"},
    [29757] = {"Paladin", "Rogue", "Shaman"},
    [29758] = {"Warrior", "Priest", "Druid"},
    [29756] = {"Hunter", "Mage", "Warlock"},
    [31092] = {"Paladin", "Priest", "Warlock"},
    [31094] = {"Warrior", "Hunter", "Shaman"},
    [31093] = {"Rogue", "Mage", "Druid"},
    [40613] = {"Paladin", "Priest", "Warlock"},
    [40614] = {"Warrior", "Hunter", "Shaman"},
    [40615] = {"Rogue", "Death Knight", "Mage", "Druid"},
    [30239] = {"Paladin", "Rogue", "Shaman"},
    [30240] = {"Warrior", "Priest", "Druid"},
    [30241] = {"Hunter", "Mage", "Warlock"},
    --Helms
    [40631] = {"Paladin", "Priest", "Warlock"},
    [40632] = {"Warrior", "Hunter", "Shaman"},
    [40633] = {"Rogue", "Mage", "Druid"},
    [29760] = {"Paladin", "Rogue", "Shaman"},
    [29761] = {"Warrior", "Priest", "Druid"},
    [29759] = {"Hunter", "Mage", "Warlock"},
    [31097] = {"Paladin", "Priest", "Warlock"},
    [31095] = {"Warrior", "Hunter", "Shaman"},
    [31096] = {"Rogue", "Mage", "Druid"},
    [40616] = {"Paladin", "Priest", "Warlock"},
    [40617] = {"Warrior", "Hunter", "Shaman"},
    [40618] = {"Rogue", "Death Knight", "Mage", "Druid"},
    [30242] = {"Paladin", "Rogue", "Shaman"},
    [30243] = {"Warrior", "Priest", "Druid"},
    [30244] = {"Hunter", "Mage", "Warlock"},
    --Pants
    [29766] = {"Paladin", "Rogue", "Shaman"},
    [29767] = {"Warrior", "Priest", "Druid"},
    [29765] = {"Hunter", "Mage", "Warlock"},
    [31098] = {"Paladin", "Priest", "Warlock"},
    [31100] = {"Warrior", "Hunter", "Shaman"},
    [31099] = {"Rogue", "Mage", "Druid"},
    [40619] = {"Paladin", "Priest", "Warlock"},
    [40620] = {"Warrior", "Hunter", "Shaman"},
    [40621] = {"Rogue", "Death Knight", "Mage", "Druid"},
    [30245] = {"Paladin", "Rogue", "Shaman"},
    [30246] = {"Warrior", "Priest", "Druid"},
    [30247] = {"Hunter", "Mage", "Warlock"},
    [40634] = {"Paladin", "Priest", "Warlock"},
    [40635] = {"Warrior", "Hunter", "Shaman"},
    [40636] = {"Rogue", "Death Knight", "Mage", "Druid"},
    --Shoulders
    [40637] = {"Paladin", "Priest", "Warlock"},
    [40638] = {"Warrior", "Hunter", "Shaman"},
    [40639] = {"Rogue", "Death Knight", "Mage", "Druid"},
    [29763] = {"Paladin", "Rogue", "Shaman"},
    [29764] = {"Warrior", "Priest", "Druid"},
    [29762] = {"Hunter", "Mage", "Warlock"},
    [31101] = {"Paladin", "Priest", "Warlock"},
    [31103] = {"Warrior", "Hunter", "Shaman"},
    [31102] = {"Rogue", "Mage", "Druid"},
    [30248] = {"Paladin", "Rogue", "Shaman"},
    [30249] = {"Warrior", "Priest", "Druid"},
    [30250] = {"Hunter", "Mage", "Warlock"},
    [40622] = {"Paladin", "Priest", "Warlock"},
    [40623] = {"Warrior", "Hunter", "Shaman"},
    [40624] = {"Rogue", "Death Knight", "Mage", "Druid"},
}

swLoot.QuestDrops = {
    [32385] = true, --Magtheridon's Head
    [32405] = true, --Kael'thas 25
}

function swLoot:AddTierDrop(itemID, classes)
    if swLoot.TierDrops[itemID] then return end
    if swLoot.Data.TierDrops[itemID] then return end
    swLoot.Data.TierDrops[itemID] = classes
    swLoot.TierDrops[itemID] = classes
end

function swLoot:RemoveTierDrop(itemID)
    swLoot.Data.TierDrops = nil
    swLoot.TierDrops[itemID] = nil
end

function swLoot:AddQuestDrop(itemID)
    if swLoot.QuestDrops[itemID] then return end
    if swLoot.Data.QuestDrops[itemID] then return end
    swLoot.Data.QuestDrops[itemID] = true
    swLoot.QuestDrops[itemID] = true
end

function swLoot:RemoveQuestDrop(itemID)
    swLoot.Data.QuestDrops = nil
    swLoot.QuestDrops = nil
end

local function AddSets(str)
    local classes = {
        "Warrior",
        "Paladin",
        "Hunter",
        "Rogue",
        "Priest",
        "Death Knight",
        "Shaman",
        "Mage",
        "Warlock",
        "#10",
        "Druid",
    }
    for pieces,c in string.gmatch(str, "pieces:%[(.-)%].-classes:%[(.-)%]") do
        for piece in string.gmatch(pieces, "%d+") do
            swLoot.TierDrops[tonumber(piece)] = classes[tonumber(c)]
        end
    end
end
local t1 = 
    [[
    pieces:[16802,16799,16795,16800,16801,16796,16797,16798],classes:[8]
    pieces:[16864,16861,16865,16863,16866,16867,16868,16862],classes:[1]
    pieces:[16828,16829,16830,16833,16831,16834,16835,16836],classes:[11]
    pieces:[16806,16804,16805,16810,16809,16807,16808,16803],classes:[9]
    pieces:[16851,16849,16850,16845,16848,16852,16846,16847],classes:[3]
    pieces:[16858,16859,16857,16853,16860,16854,16855,16856],classes:[2]
    pieces:[16827,16824,16825,16820,16821,16826,16822,16823],classes:[4]
    pieces:[16838,16837,16840,16841,16844,16839,16842,16843],classes:[7]
    pieces:[16811,16813,16817,16812,16814,16816,16815,16819],classes:[5]
    ]]
local t2 = 
    [[
    pieces:[16959,16966,16964,16963,16962,16961,16965,16960],classes:[1]
    pieces:[16910,16906,16911,16905,16907,16908,16909,16832],classes:[4]
    pieces:[16936,16935,16942,16940,16941,16939,16938,16937],classes:[3]
    pieces:[16952,16951,16958,16955,16956,16954,16957,16953],classes:[2]
    pieces:[16933,16927,16934,16928,16930,16931,16929,16932],classes:[9]
    pieces:[16818,16918,16912,16914,16917,16913,16915,16916],classes:[8]
    pieces:[16903,16898,16904,16897,16900,16899,16901,16902],classes:[11]
    pieces:[16944,16943,16950,16945,16948,16949,16947,16946],classes:[7]
    pieces:[16925,16926,16919,16921,16920,16922,16924,16923],classes:[5]
    ]]
AddSets(t1)
AddSets(t2)
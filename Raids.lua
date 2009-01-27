local Addon = swLoot
if not Addon then return end

local DEBUG = (LibStub("dzjrDebug", true) ~= nil)
local dprint = (DEBUG and print) or function(...) end

local Raid = {}
Raid.__index = Raid

local setmetatable, pairs, tostring, print = setmetatable, pairs, tostring, print
local tinsert = table.insert

function Raid:new(name)
    dprint("Creating new raid [" .. name .. "]")
    local self = setmetatable({}, Raid)
    self.name = name
    self.date = Addon.Timestamp:new()
    self.ids = {}
    self.alts = {}
    self.isPug = false
    self.drops = {awarded = {}, banked = {}, disenchanted = {}}
    return self
end

function deepWrite(self, tbl)
    for i,j in pairs(self) do
        local ii
        if type(i) == "table" then
            local m = getmetatable(i)
            if m and type(m.__savable) == "function" then
                ii = m.__savable(i)
            else
                ii = {}
                deepWrite(i, ii)
            end
        else
            ii = i
        end
        if type(j) == "table" then
            local m = getmetatable(j)
            if m and type(m.__savable) == "function" then
                tbl[ii] = m.__savable(j)
            else
                tbl[ii] = {}
                deepWrite(j, tbl[ii])
            end
        else
            tbl[ii] = j
        end
    end
end

function Raid:writeToSV()
    local tbl = {serializableType = "Raid"}
    deepWrite(self, tbl)
    return setmetatable(tbl, Raid)
end
Raid.__savable = Raid.writeToSV

local function deepRead(tbl)
    for i,j in pairs(tbl) do
        local ii
        if type(i) == "table" then
            ii = i.serializableType and 
                 Addon[i.serializableType]:__loadable(i) or
                 deepRead(i)
        else
            ii = i
        end
        if type(j) == "table" then
            tbl[ii] = j.serializableType and
                      Addon[j.serializableType]:__loadable(j) or
                      deepRead(j)
        else
            tbl[ii] = j
        end
    end
    return tbl
end

function Raid:readFromSV(tbl)
    if tbl.serializableType ~= "Raid" then
        error("Invalid serializer " .. tbl.serializableType)
    end
    local self = deepRead(tbl)
    return setmetatable(self, Raid)
end
Raid.__loadable = Raid.readFromSV

function Raid:Activate()
    dprint("Activating [" .. self:tostring() .. "]")
    for alt, main in pairs(self.alts) do
        Addon.Alts[alt] = main
    end
end

function Raid:Deactivate()
    dprint("Deactivating [" .. self:tostring() .. "]")
    Addon:ResetAlts()
end

function Raid:AssignMain(alt, main)
    dprint("Temporarily assigning " .. main .. " as " .. alt .. "'s main.")
    self.alts[alt] = main
    Addon.Alts[alt] = main
end

Raid.__tostring = function(self)
    return self.name .. " created on " .. self.date
end

local function ListNeeds(drops)
    local used = {}
    for i,item in pairs(drops) do
        if not item.deleted and item.usedNeed then
            used[item.winner.name] = item.winner
        end
    end
    return used
end

function Raid:Print(public)
    local func
    if public then
        func = function(...) Addon:Communicate(...) end
    else
        func = print
    end
    func("Raid: " .. self.name)
    func("Created on: " .. self.date)
    func("Awarded items:")
    for i,j in pairs(self.drops.awarded) do
        if DEBUG or not j.deleted then func("   " .. j) end
    end
    func("Disenchanted items:")
    for i,j in pairs(self.drops.disenchanted) do
        if DEBUG or not j.deleted then func("   " .. j) end
    end
    func("Banked items:")
    for i,j in pairs(self.drops.banked) do
        if DEBUG or not j.deleted then func("   " .. j) end
    end
    func("Used needs:")
    for i,j in pairs(ListNeeds(self.drops.awarded)) do
        func("   " .. j)
    end
end

function Raid:ContainsInstance(id)
    for i in pairs(self.ids) do
        if i == id then return true end
    end
    return false
end

--returns true if self is more recent than other; names, ids, et cetera are ignored
function Raid:CompareTo(other)
    return self.date < other.date
end

function Raid:AwardItem(itemLink, player, useNeed)
    dprint("Awarding " .. itemLink .. " to " .. player .. 
           " [need? " .. tostring(useNeed) .. "]")
    tinsert(self.drops.awarded, Addon.Item:new(itemLink, player, useNeed))
end

function Raid:BankItem(itemLink)
    dprint("Banking " .. itemLink)
    tinsert(self.drops.banked, Addon.Item:new(itemLink))
end

function Raid:DisenchantItem(itemLink)
    dprint("Disenchanting " .. itemLink)
    tinsert(self.drops.disenchanted, Addon.Item:new(itemLink))
end

function Raid:UsedNeed(player)
    player = type(player) == "string" and Addon.Player:new(player) or player
    for i, item in pairs(self.drops.awarded) do
        if not item.deleted and 
           item.winner == player and 
           item.usedNeed then 
           return true
    end
    return false
    end
end

function Raid:FreeNeed(player)
    player = type(player) == "string" and Addon.Player:new(player) or player
    dprint("Freeing " .. player .. "'s need roll.")
    local awarded = self.drops.awarded
    for i, item in pairs(awarded) do
        dprint("   " .. item)
        if item.winner == player and item.usedNeed then
            dprint("   Changing need status of " .. item)
            self:AwardItem(item.item, item.winner, false)
            item.deleted = true
        end
    end
end

Addon.Raid = Raid
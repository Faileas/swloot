local Addon = swLoot
if not Addon then return end

local DEBUG = (LibStub("dzjrDebug", true) ~= nil)
local dprint = (DEBUG and print) or function(...) end

local Raid = {}

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
    self.needs = {}
    return self
end

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

function toString(self)
    return self.name .. " created on " .. self.date
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
    for i,j in pairs(self.needs) do
        func("   " .. j.name)
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
           " [need? " .. useNeed .. "]")
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

Raid.__index = Raid
Raid.__tostring = toString

Addon.Raid = Raid
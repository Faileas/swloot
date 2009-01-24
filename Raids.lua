local Addon = swLoot
if not Addon then return end

local DEBUG = (LibStub("dzjrDebug", true) ~= nil)
local dprint = (DEBUG and print) or function(...) end

local Raid = {}
Raid.__index = Raid

local setmetatable, pairs, tostring = setmetatable, pairs, tostring

function Raid:new(name)
    dprint("Creating new raid [" .. name .. "]")
    local self = setmetatable({}, Raid)
    self.name = name
    local _, month, day, year = CalendarGetDate()
    local hour, minute = GetGameTime()
    self.date = {hour = hour, minute = minute, month = month, day = day, year = year}
    self.ids = {}
    self.alts = {}
    self.isPug = false
    self.drops = {awarded = {}, banked = {}, disenchanted = {}}
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

function Raid:tostring()
    return self.name .. " created on " .. 
           self.date.month .. "/" .. self.date.day .. "/" .. self.date.year .. " " ..
           self.date.hour .. ":" .. self.date.minute
end

function Raid:ContainsInstance(id)
    for i in pairs(self.ids) do
        if i == id then return true end
    end
    return false
end

--returns true if self is more recent than other; names, ids, et cetera are ignored
function Raid:CompareTo(other)
    local lhs, rhs = self.date, other.date
    return (lhs.year > rhs.year) or 
           (lhs.month > rhs.month) or 
           (lhs.day > rhs.day) or 
           (lhs.hour > rhs.hour) or
           (lhs.minute > rhs.minute)
end

Addon.Raid = Raid
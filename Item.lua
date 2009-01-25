local Addon = swLoot
if not Addon then return end

local DEBUG = (LibStub("dzjrDebug", true) ~= nil)
local dprint = (DEBUG and print) or function(...) end

local Item = {}
Item.__index = Item

local setmetatable, pairs, tostring = setmetatable, pairs, tostring

local function DeepCopy(tbl)
    local ret = {}
    for i,j in pairs(tbl) do
        if type(j) == "table" then
            ret[i] = DeepCopy(j)
        else
            ret[i] = j
        end
    end
    return ret
end

function Item:new(item)
    local self = setmetatable({}, item)
    if type(item) == "string" then
        dprint("Creating new item [" .. item .. "]")
        self.item = item
        local _, month, day, year = CalendarGetDate()
        local hour, minute = GetGameTime()
        local localtime = date("*t")
        self.timestamp = {hour = hour, minute = minute, seconds = localtime.sec,
                          month = month, day = day, year = year}
        self.deleted = false
        self.lastChanged = self.timestamp
    else
        dprint("Creating new copy of item [" .. item.item .. "]")
        self = DeepCopy(item)
    end
    return self
end

local function compareTimestames(lhs, rhs)
    return (lhs.year > rhs.year) or 
           (lhs.month > rhs.month) or 
           (lhs.day > rhs.day) or 
           (lhs.hour > rhs.hour) or
           (lhs.minute > rhs.minute) or
           (lhs.second > rhs.second)
end

--returns true if rhs is the same item as self, and has a more recent lastChanged field
--        in this case, self.deleted and self.lastChanged is updated to match rhs
--returns false otherwise, and leaves self unchanged
function Item:ConditionalUpdate(rhs)
    if self.item ~= rhs.item or 
       compareTimestamps(self.timestamp, rhs.timestamp) or
       compareTimestamps(self.lastChanged, rhs.lastChanged) then

        return false
    end
    self.lastChanged = DeepCopy(rhs.lastChanged)
    self.deleted = rhs.deleted
    return true
end

function Item:Touch()
    local _, month, day, year = CalendarGetDate()
    local hour, minute = GetGameTime()
    local localtime = date("*t")
    self.lastChanged = {hour = hour, minute = minute, seconds = localtime.sec,
                        month = month, day = day, year = year}
end

function Item:Delete()
    self.deleted = true
    self:Touch()
end

function Item:Restore()
    self.deleted = false
    self:Touch()
end

function Item:IsQuest(item)
    if not item then item = self.item end
    local t = (select(6, GetItemInfo(item)))
    return t == "Quest"
end

function Item:IsTier(item)
    if not item then item = self.item end
    local link = (select(2, GetItemInfo(item)))
    local id = (select(3, string.find(link, "Hitem:(%d+):")))
    dprint(id)
    return false
end

Addon.Item = Item
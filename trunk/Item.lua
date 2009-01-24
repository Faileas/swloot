local Addon = swLoot
if not Addon then return end

local DEBUG = (LibStub("dzjrDebug", true) ~= nil)
local dprint = (DEBUG and print) or function(...) end

local Item = {}
Item.__index = Item

local setmetatable, pairs, tostring = setmetatable, pairs, tostring

function Item:new(item)
    dprint("Creating new item [" .. item .. "]")
    local self = setmetatable({}, Item)
    self.item = item
    local _, month, day, year = CalendarGetDate()
    local hour, minute = GetGameTime()
    local localtime = date("*t")
    self.timestamp = {hour = hour, minute = minute, seconds = localtime.sec,
                      month = month, day = day, year = year}
    return self
end

Addon.Item = Item
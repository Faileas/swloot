local Addon = swLoot
if not Addon then return end

local Timestamp = {}

function Timestamp:new(copy)
    if not copy then
        local _, month, day, year = CalendarGetDate()
        local hour, minute = GetGameTime()
        local localtime = date("*t")
        self = {hour = hour, minute = minute, seconds = localtime.sec,
                month = month, day = day, year = year}
        return setmetatable(self, Timestamp)
    else
        if getmetatable(copy) ~= Timestamp then
            error("Attempt to copy incompatable type")
        end
        return copy:copy()
    end
end

function Timestamp:copy()
    return setmetatable(
        {hour = self.hour, minute = self.minute, seconds = self.seconds,
         month = self.month, day = self.day, year = self.year}, 
        Timestamp)
end

local function toString(self)
    local ret = self.month .. "/"
    local str = tostring(self.day)
    if str:len() == 1 then
        ret = ret .. "0" .. str
    else
        ret = ret .. str
    end
    ret = ret .. "/" .. self.year .. " " .. self.hour .. ":"
    str = tostring(self.minute)
    if str:len() == 1 then
        ret = ret .. "0" .. str
    else
        ret = ret .. str
    end
    ret = ret .. ":"
    str = tostring(self.seconds)
    if str:len() == 1 then
        ret = ret .. "0" .. str
    else
        ret = ret .. str
    end
    return ret
end

local function concat(lhs, rhs)
    local mL = (getmetatable(lhs) == Timestamp)
    local mR = (getmetatable(rhs) == Timestamp)
    return (mL and tostring(lhs) or lhs) .. (mR and tostring(rhs) or rhs)
end

--implements operator< -- This does *not* consider the seconds field
local function lessThan(self, rhs)
    if self.year < rhs.year then return true end
    if self.year > rhs.year then return false end
    if self.month < rhs.month then return true end
    if self.month > rhs.month then return false end
    if self.day < rhs.day then return true end
    if self.day > rhs.day then return false end
    if self.hour < rhs.hour then return true end
    if self.hour > rhs.hour then return false end
    return self.minute < rhs.minute
end

--implements operator== -- this *does* consider the seconds field
local function equalTo(self, rhs)
    return (self.year == rhs.year) and 
           (self.month == rhs.month) and 
           (self.day == rhs.day) and 
           (self.hour == rhs.hour) and
           (self.minute == rhs.minute) and
           (self.seconds == rhs.seconds)
end

Timestamp.__copy = Timestamp.copy
Timestamp.__concat = concat
Timestamp.__tostring = toString
Timestamp.__lt = lessThan
Timestamp.__eq = equalTo
Timestamp.__index = Timestamp
Addon.Timestamp = Timestamp
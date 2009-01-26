local Addon = swLoot
if not Addon then return end

local DEBUG = (LibStub("dzjrDebug", true) ~= nil)
local dprint = (DEBUG and print) or function(...) end

local Item = {}
Item.__index = Item

local setmetatable, pairs, tostring = setmetatable, pairs, tostring

local ItemLinkPattern = "|c%x+|H.+|h%[.+%]|h|r"
local function ParseItem(str)
    local item = select(3, string.find(str, "^%s*(" .. ItemLinkPattern .. ")%s*$"))
    if item then return item end
    item = select(3, string.find(str, "^%s*%[(.+)%]%s*$")) or str
    item = select(2, GetItemInfo(item))
    if item then return item end
    error("Bad item: " .. str)
    return nil
end

function Item:new(item, winner, usedNeed)
    local self = setmetatable({}, Item)
    if type(item) == "string" or type(item) == "number" then
        dprint("Creating new item [" .. item .. "] " .. 
               "for [" .. tostring(winner) .. "] " ..
               "need? [" .. tostring(usedNeed) .. "]")
        self.item = ParseItem(item)
        self.timestamp = Addon.Timestamp:new()
        self.winner = winner and Addon.Player:new(winner) or nil
        self.usedNeed = usedNeed
    else
        dprint("Creating new copy of item [" .. item .. "]")
        if getmetatable(item) ~= Item then 
            error("Attempt to copy incompatable type") 
        end
        self = item:copy()
    end
    return self
end

function Item:copy()
    local ret = {}
    for i,j in pairs(self) do
        local m = getmetatable(j)
        if m and type(m.__copy) == "function" then
            ret[i] = m.__copy(j)
        else
            ret[i] = j
        end
    end
    return setmetatable(ret, Item)
end
Item.__copy = Item.copy

Item.__tostring = function(self)
    local str = self.deleted and "(d)" or ""
    if self.usedNeed then
        str = str .. "(n)"
    end
    str = str .. self.item
    if self.winner then 
        str = str .. " won by " .. self.winner
    end
    return str
end

Item.__concat = function(lhs, rhs)
    local mL = (getmetatable(lhs) == Item)
    local mR = (getmetatable(rhs) == Item)
    return (mL and tostring(lhs) or lhs) .. (mR and tostring(rhs) or rhs)
end

--Two items are equal if the items they represent are the same, and their timestamps
--  match.  Winner, deleted state, and so forth, are not considered.
Item.__eq = function(lhs, rhs)
    return lhs.item == rhs.item and lhs.timestamp == rhs.timestamp
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
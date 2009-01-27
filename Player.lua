local Addon = swLoot
if not Addon then return end

local DEBUG = (LibStub("dzjrDebug", true) ~= nil)
local dprint = (DEBUG and print) or function(...) end

local Player = {}
Player.__index = Player

function Player:new(name)
    if type(name) == "string" then
        dprint("Creating new player " .. name)
        return setmetatable({name = name}, Player)
    else
        if getmetatable(name) ~= Player then 
            error("Attempt to copy incompatable object")
        end
        dprint("Copying player " .. name)
        return name:copy()
    end
end

function Player:copy()
    return setmetatable({name = self.name}, Player)
end
Player.__copy = Player.copy

function Player:writeToSV()
    return {serializableType = "Player", name = self.name}
end
Player.__savable = Player.writeToSV

function Player:readFromSV(tbl)
    if tbl.serializableType ~= "Player" then
        error("Invalid serializer " .. tbl.serializableType)
    end
    return setmetatable({name = tbl.name}, Player)
end
Player.__loadable = Player.readFromSV

function Player:isMain()
    return self.name == self.main
end

Player.__tostring = function(self)
    if self:isMain() then return self.name end
    return self.name .. " [" .. self.main .. "]"
end

Player.__concat = function(lhs, rhs)
    local mL = (getmetatable(lhs) == Player)
    local mR = (getmetatable(rhs) == Player)
    return (mL and tostring(lhs) or lhs) .. (mR and tostring(rhs) or rhs)
end

Player.__eq = function(lhs, rhs)
    dprint(lhs.main .. " == " .. rhs.main)
    return lhs.main == rhs.main
end

Player.__index = function(t, i)
    if i == "main" then
        return Addon.Alts[t.name]
    else 
        return Player[i]
    end
end
Addon.Player = Player
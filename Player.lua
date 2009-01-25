local Addon = swLoot
if not Addon then return end

local DEBUG = (LibStub("dzjrDebug", true) ~= nil)
local dprint = (DEBUG and print) or function(...) end

local Player = {}
Player.__index = Player

function Player:new(name, player)
    if not player then
        dprint("Creating new player " .. name)
        return setmetatable({name = name}, Player)
    else
        if getmetatable(player) ~= Player then 
            error("Attempt to copy incompatable object")
        end
        dprint("Copying player " .. player)
        return player:copy()
    end
end

function Player:copy()
    return setmetatable({name = self.name}, Player)
end

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
    return lhs.main == rhs.main
end

Player.__index = function(t, i)
    if i == "main" then
        return Addon.Alts[t.name]
    else 
        return Player[i]
    end
end
Player.__copy = Player.copy
Addon.Player = Player
do

local MAJOR, MINOR = "GroupLib-1.0", 1
local GroupLib = LibStub:NewLibrary(MAJOR, MINOR)

if not GroupLib then return end

local GroupLibPrints = GroupLibPrints or {}

function GroupLib.Type()
    if GetNumRaidMembers() > 0 then
        return "raid"
    elseif GetNumPartyMembers() > 0 then
        return "party"
    else
        return "solo"
    end
end

local function Callback(self, callback, arg)
    if type(callback) == "string" then
        self[callback](self, arg)
    else
        callback(arg)
    end
end

function GroupLib.Communicate(self, ...)
    local str = type(self) == "table" and "" or tostring(self) .. " "
    for i = 1, select("#", ...) do
        str = str .. tostring(select(i, ...)) .. " "
    end
    if GetNumRaidMembers() > 0 then
        SendChatMessage(str, "RAID")
    elseif GetNumPartyMembers() > 0 then
        SendChatMessage(str, "PARTY")
    else
        if type(self) ~= "table" or not GroupLibPrints[self] then
            SendChatMessage(str, "SAY")
        else
            Callback(self, GroupLibPrints[self], str)
        end
    end    
end

local function ValidateCallback(self, callback, source, callbackname)
	if type(callback) ~= "string" and type(callback) ~= "function" then 
		error(MAJOR..": " .. source ..": '" .. callbackname .. "' - function or method name expected.", 3)
	end
	if type(callback) == "string" then
		if type(self)~="table" then
			error(MAJOR..": " .. source .. ": 'self' - must be a table.", 3)
		end
		if type(self[callback]) ~= "function" then 
			error(MAJOR..": " .. source .. ": '" .. callbackname .. "' - method not found on target object.", 3)
		end
	end
    return true
end

function GroupLib.SetDefaultComm(self, callback)
    ValidateCallback(self, callback, "SetDefaultComm", "callback")
    GroupLibPrints[self] = callback
end

function GroupLib.Number()
    local num = GetNumRaidMembers()
    if num > 0 then return num end
    num = GetNumPartyMembers()
    if num > 0 then return num + 1 end --GetNumPartyMembers() does not include yourself
    return 1
end

function GroupLib.Members()
    local num = GetNumRaidMembers()
    local i = 0
    if num > 0 then
        return function() 
            i = i + 1
            local name = (GetRaidRosterInfo(i))
            if i <= num then 
                return name, UnitLevel(name), UnitIsConnected(name), UnitIsDeadOrGhost(name)
            else 
                return nil 
            end
        end
    end
    num = GetNumPartyMembers()
    if num > 0 then
        return function()
            i = i + 1
            local name
            if i <= num then 
                --return UnitName("party" .. i) 
                name = "party" .. i
            elseif i == num + 1 then
                --return UnitName("player")
                name = "player"
            else
                return nil 
            end
            return UnitName(name), UnitLevel(name), UnitIsConnected(name), UnitIsDeadOrGhost(name)
        end
    end
    return function()
        i = i + 1
        if i == 1 then 
            return UnitName("player"), UnitLevel("player"), UnitIsConnected("player"), UnitIsDeadOrGhost("player")
        else 
            return nil 
        end
    end
end

GroupLib.embeds = GroupLib.embeds or {}

local mixins = {
	"Communicate",
    "SetDefaultComm"
}

function GroupLib:Embed(target)
	for _,v in pairs(mixins) do
		target[v] = GroupLib[v]
	end    
	self.embeds[target] = true    
	return target
end

for target, v in pairs(GroupLib.embeds) do
	GroupLib:Embed(target)
end

end
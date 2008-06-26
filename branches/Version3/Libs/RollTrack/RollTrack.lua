do

local MAJOR, MINOR = "RollTrack-1.0", 1
local RollTrack = LibStub:NewLibrary(MAJOR, MINOR)

if not RollTrack then return end -- No upgrade needed

local Events = LibStub:GetLibrary("AceEvent-3.0")

local tonumber = tonumber

local function Event(arg1, arg2)
    local start, stop, char, roll, min, max = arg2:find("(%a+) rolls (%d+) %((%d+)-(%d+)%)")
    if start ~= nil then
        Events:SendMessage("RollTrack_Roll", char, tonumber(roll), tonumber(min), tonumber(max))
    end
end

Events.RegisterEvent("RollTrack", "CHAT_MSG_SYSTEM", Event)

RollTrack.embeds = RollTrack.embeds or {}

function RollTrack:Embed(target)
	RollTrack.embeds[target] = true
	return target
end

for target, v in pairs(RollTrack.embeds) do
	RollTrack:Embed(target)
end

end
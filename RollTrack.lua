local RollTrack = LibStub("AceAddon-3.0"):NewAddon("swLootRollTrack", "AceEvent-3.0")

function RollTrack:CHAT_MSG_SYSTEM(arg1, arg2)
    local start, stop, char, roll, min, max = string.find(arg2, "(%a+) rolls (%d+) %((%d+)-(%d+)%)")
    if(start ~= nil) then
      RollTrack:SendMessage("RollTrack_Roll", char, tonumber(roll), tonumber(min), tonumber(max))
    end
end

RollTrack:RegisterEvent("CHAT_MSG_SYSTEM")
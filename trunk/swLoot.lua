local DEBUG = (LibStub("dzjrDebug", true) ~= nil)
local dprint = (DEBUG and print) or function(...) end

local eventFrame = CreateFrame("frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_LOGOUT")

swLootData = {}
swLoot = {
    version = tonumber(strmatch("$Revision$", "%d+")),
    Defaults = {},
    Data = swLootData,
}

local function OnInitialize()
    swLoot.Alts["Aggronaut"] = "Ellone"
    swLoot.Alts["Ellone"] = "Aggronaut"
    dzjr1 = swLoot.Player:new("Raam")
    dzjr2 = swLoot.Player:new("Tankin")
    dzjr3 = swLoot.Player:new("Yozora")
    dzjr4 = swLoot.Player:new("Dagen")
    dzjr5 = swLoot.Player:new("Heteria")
    
    dzjrRaid = swLoot.Raid:new("Deadmines")
    dzjrRaid:AwardItem(872, dzjr3, true)
    dzjrRaid:AwardItem(5443, dzjr2, true)
    dzjrRaid:DisenchantItem(1937)
    dzjrRaid:AwardItem(5195, dzjr5, true)
    dzjrRaid:AwardItem(1156, dzjr4, true)
    dzjrRaid:BankItem(10401)
    dzjrRaid:BankItem(10403)
    dzjrRaid:DisenchantItem(5200)
    dzjrRaid:AwardItem(7230, dzjr1, false)
    dzjrRaid:AwardItem(5198, dzjr5, false)
    dzjrRaid:BankItem(8490)
    dzjrRaid:DisenchantItem(10399)
    
    eventFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
    
    dzjrRaid2 = dzjrRaid:readFromSV(swLootData.raid)
end

local function SaveData()
    swLootData.raid = dzjrRaid:writeToSV()
end

local function OnEvent(self, msg, ...)
    if msg == "PLAYER_ENTERING_WORLD" then
        OnInitialize()
    elseif msg == "PLAYER_LOGOUT" then
        SaveData()
    end
end
eventFrame:SetScript("OnEvent", OnEvent)
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
    swLoot.Alts["Raam"] = "Ellone"
    dzjr1 = swLoot.Player:new("Aggronaut")
    dzjr2 = swLoot.Player:new("Raam")
    dzjr3 = swLoot.Player:new("Faileas")
    
    dzjrRaid = swLoot.Raid:new("Test Raid")
    dzjrRaid:AwardItem("[Frostweave Cloth]", dzjr1, true)
    dzjrRaid:AwardItem("[Mightstone Breastplate]", dzjr1, false)
    dzjrRaid:AwardItem("[Seabone Legplates]", dzjr2, true)
    dprint("****************************************************************************")
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
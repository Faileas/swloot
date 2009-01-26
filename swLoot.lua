local DEBUG = (LibStub("dzjrDebug", true) ~= nil)
local dprint = (DEBUG and print) or function(...) end

local eventFrame = CreateFrame("frame")
eventFrame:RegisterEvent("ADDON_LOADED")

swLoot = {
    version = tonumber(strmatch("$Revision$", "%d+")),
    Defaults = {}
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
end

local function OnEvent(self, msg, ...)
    if msg == "ADDON_LOADED" and select(1, ...) == "swLoot" then
        OnInitialize(self)
    end
end
eventFrame:SetScript("OnEvent", OnEvent)
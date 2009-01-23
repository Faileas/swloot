local ItemLinkPattern = "|c%x+|H.+|h%[.+%]|h|r"
local DEBUG = (LibStub("dzjrDebug", true) ~= nil)
local dprint = (DEBUG and print) or function(...) end

local eventFrame = CreateFrame("frame")
eventFrame:RegisterEvent("ADDON_LOADED")

swLoot = {
    version = tonumber(strmatch("$Revision$", "%d+")),
}

local function OnInitialize()
end

local function OnEvent(self, msg, ...)
    if msg == "ADDON_LOADED" and select(1, ...) == "swLoot" then
        OnInitialize(self)
    end
end
eventFrame:SetScript("OnEvent", OnEvent)
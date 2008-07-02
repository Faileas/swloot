OpenRolls = LibStub("AceAddon-3.0"):NewAddon("OpenRolls", 
    "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "GroupLib-1.0")
OpenRollsData = OpenRollsData or {}

local ItemLinkPattern = "|c%x+|H.+|h%[.+%]|h|r"

local tonumber = tonumber

local function CreateNameFrame()
    local frame = CreateFrame("Frame", "OpenRollsNameFrame", UIParent)
    frame:SetBackdrop({
        bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", 
        tile = true, tileSize = 32, edgeSize = 16, 
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })    
    frame:SetBackdropColor(0,0,0,1)
    frame:SetToplevel(true)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")

    local BankName = CreateFrame("EditBox", "OpenRollsBankName", frame, "InputBoxTemplate")
    BankName:SetAutoFocus(false)
    BankName:SetFontObject(ChatFontNormal)
    BankName:SetTextInsets(0,0,3,3)
    BankName:SetMaxLetters(12)
    BankName:SetPoint("BOTTOMLEFT", LootFrame, "TOPLEFT", 75, -4)
    BankName:SetHeight(20)
    BankName:SetWidth(110)
    BankName:SetScript("OnEnter", function(frame, ...)
        local GameTooltip = GameTooltip
        GameTooltip:SetOwner(frame, "ANCHOR_TOPLEFT")
        GameTooltip:SetText("Name of character to recieve bank loot", 1, 1, 1, 1)
        GameTooltip:Show()
    end)
    BankName:SetScript("OnLeave", function(frame, ...) GameTooltip:Hide() end)
    
    local BankString = frame:CreateFontString("OpenRollsBankString", "OVERLAY", "GameFontNormal")
    BankString:SetPoint("BOTTOMLEFT", BankName, "TOPLEFT")
    BankString:SetPoint("BOTTOMRIGHT", BankName, "TOPRIGHT")
    BankString:SetText("Bank Character")
    
    local ChantName = CreateFrame("EditBox", "OpenRollsChantName", frame, "InputBoxTemplate")
    ChantName:SetAutoFocus(false)
    ChantName:SetFontObject(ChatFontNormal)
    ChantName:SetTextInsets(0,0,3,3)
    ChantName:SetMaxLetters(12)
    ChantName:SetPoint("LEFT", BankName, "RIGHT", 10, 0)
    ChantName:SetHeight(20)
    ChantName:SetWidth(110)
    ChantName:SetScript("OnEnter", function(frame, ...)
        local GameTooltip = GameTooltip
        GameTooltip:SetOwner(frame, "ANCHOR_TOPLEFT")
        GameTooltip:SetText("Name of character to disenchant loot", 1, 1, 1, 1)
        GameTooltip:Show()
    end)
    BankName:SetScript("OnLeave", function(frame, ...) GameTooltip:Hide() end)
    
    local ChantString = frame:CreateFontString("OpenRollsChantString", "OVERLAY", "GameFontNormal")
    ChantString:SetPoint("BOTTOMLEFT", ChantName, "TOPLEFT")
    ChantString:SetPoint("BOTTOMRIGHT", ChantName, "TOPRIGHT")
    ChantString:SetText("Disenchanter")
    
    frame:SetPoint("TOPLEFT", BankString, "TOPLEFT", -13, 8)
    frame:SetPoint("BOTTOMRIGHT", ChantName, "BOTTOMRIGHT", 8, -8)
    
    frame:Hide()
    return {frame = frame, 
            bankString = BankString, bankName = BankName, 
            chantString = ChantString, chantName = ChantName}
end


local NamesFrame = NamesFrame or CreateNameFrame()

function OpenRolls:InitializeSavedVariables()
    if OpenRollsData.ShowSummaryWhenRollsOver == nil then
        OpenRollsData.ShowSummaryWhenRollsOver = true
    end
end

function OpenRolls:OnInitialize()
    OpenRolls:InitializeSavedVariables()
end

local function Roll(item, quantity)
    --SummaryFrame:SetTitle(quantity .. "x" .. item)
    OpenRolls:StartRoll(item, quantity)
    local timer = OpenRolls:ScheduleTimer(function() 
        OpenRolls:EndRoll(item, quantity)
        OpenRolls:UnregisterMessage("RollTrack_Roll")
    end, 30)
    
    OpenRolls:RegisterMessage("RollTrack_Roll", function(msg, char, roll, min, max)
        OpenRolls:AssignRoll(char, roll)
        if OpenRolls:HasEverybodyRolled() then
            OpenRolls:EndRoll(item, quantity)
            OpenRolls:UnregisterMessage("RollTrack_Roll")
            OpenRolls:CancelTimer(timer)
        end
    end)
end

local function CommandLine(str)
    local found, _, item, quantity = str:find("^(" .. ItemLinkPattern ..")%s*(%d*)$")
    if found then
        Roll(item, tonumber(quantity) or 1)
        return
    end
    
    found, _, quantity, item = str:find("^(%d+)%s*x%s*(" .. ItemLinkPattern ..")$")
    if found then
        Roll(item, tonumber(quantity) or 1)
        return
    end
    
    OpenRolls:Print("BAD [[" .. str .. "]]")
end

OpenRolls:RegisterChatCommand("openroll", CommandLine)

--[[function OpenRolls:LOOT_OPENED()
    NamesFrame.frame:Show()
end

function OpenRolls:LOOT_CLOSED()
    NamesFrame.frame:Hide()
end

OpenRolls:RegisterEvent("LOOT_OPENED")
OpenRolls:RegisterEvent("LOOT_CLOSED")]]--
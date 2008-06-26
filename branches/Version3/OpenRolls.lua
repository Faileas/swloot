OpenRolls = LibStub("AceAddon-3.0"):NewAddon("OpenRolls", "AceConsole-3.0", "AceEvent-3.0")

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

local function CreateSummaryFrame()
    local frame = CreateFrame("Frame", "OpenRollsSummaryFrame", UIParent)
    frame:SetBackdrop({
        bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", 
        tile = true, tileSize = 32, edgeSize = 16, 
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })    
    frame:SetBackdropColor(0,0,0,1)
    frame:SetToplevel(true)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse()    
    frame:SetScript("OnMouseDown", function(frame) frame:StartMoving() end)
    frame:SetScript("OnMouseUp", function(frame) frame:StopMovingOrSizing() end)
    frame:SetPoint("CENTER", UIParent, "CENTER")
    frame:SetWidth(500)
    frame:SetHeight(200)
    
    local title = frame:CreateFontString("OpenRollsSummaryTitle", "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -12)
    title:SetPoint("RIGHT", frame, "RIGHT", -6)
    title:SetText("Title")
    
    local rolledColorR, rolledColorG, rolledColorB = 0, 1, 0
    local passedColorR, passedColorG, passedColorB = 0.5, 0.5, 0.5
    local waitingColorR, waitingColorG, waitingColorB = 1, 0, 0
    
    local rolls = {}
    local roll = frame:CreateFontString("OpenRollsSummaryRoll1", "OVERLAY", "GameFontNormal")
    roll:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", -12, -12)
    roll:SetText("xxx")
    roll:SetTextColor(waitingColorR, waitingColorG, waitingColorB)
    rolls[1] = roll
    
    local names = {}
    local name = frame:CreateFontString("OpenRollsSummaryName1", "OVERLAY", "GameFontNormal")
    name:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 6, -12)
    name:SetPoint("RIGHT", roll, "LEFT")
    name:SetText("")
    name:SetTextColor(waitingColorR, waitingColorG, waitingColorB)
    name:SetJustifyH("LEFT")
    names[1] = name
    
    local buffer = CreateFrame("Frame", "OpenRollsSummaryBuffer", frame)
    buffer:SetPoint("TOPLEFT", name, "BOTTOMLEFT")
    buffer:SetPoint("TOPRIGHT", roll, "BOTTOMRIGHT")
    buffer:SetHeight(12)
    
    local close = CreateFrame("Button", "OpenRollsSummaryClose", frame, "UIPanelButtonTemplate")
    close:SetHeight(20)
    close:SetWidth(100)
    --close:SetPoint("CENTER", title, "CENTER")
    close:SetPoint("TOP", buffer, "BOTTOM")
    close:SetText("Close")
    close:SetScript("OnClick", function(frame) 
        frame:GetParent():Hide()
    end)
    
    frame:SetHeight(title:GetTop() - close:GetBottom() + 24)
    
    return {frame = frame, close = close, names = names, title = title,
            rolledR = rolledColorR, rolledG = rolledColorG, rolledB = rolledColorB,
            passedR = passedColorR, passedG = passedColorG, passedB = passedColorB,
            waitingR = waitingColorR, waitingG = waitingColorG, waitingB = waitingColorB
    }
end
local SummaryFrame = SummaryFrame or CreateSummaryFrame()

function SummaryFrame:Show()
    self.frame:Show() 
    self.frame:SetHeight(title:GetTop() - close:GetBottom() + 24)
end

function SummaryFrame:Hide()
    self.frame:Hide() 
end

function SummaryFrame:SetTitle(str) 
    title:SetText(str) 
end

function SummaryFrame:AddRoller(name)
    local count = #self.names
    local currentName = self.names[count]
    local currentRoll = self.rolls[count]
    
    current:SetText(name)
    
    local roll = frame:CreateFontString("OpenRollsSummaryRoll" .. count+1, "OVERLAY", "GameFontNormal")
    roll:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", -12, -12)
    roll:SetText("xxx")
    roll:SetTextColor(waitingColorR, waitingColorG, waitingColorB)
    rolls[1] = roll
    
    local nxt = frame:CreateFontString("OpenRollsSummaryName" .. count+1, "OVERLAY", "GameFontNormal")
    nxt:SetPoint("TOPLEFT", current, "BOTTOMLEFT")
    nxt:SetPoint("RIGHT", roll, "LEFT")
    nxt:SetText("")
    nxt:SetTextColor(waitingColorR, waitingColorG, waitingColorB)
    nxt:SetJustifyH("LEFT")
    names[1] = name
end

local function Roll(item, quantity)
    SummaryFrame:SetTitle(quantity .. "x" .. item)
    SummaryFrame:Show()
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
    SummaryFrame:Show()
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
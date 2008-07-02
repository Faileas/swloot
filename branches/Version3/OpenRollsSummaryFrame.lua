local frame = CreateFrame("frame", "OpenRollsSummaryFrame", UIParent)
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

local group = CreateFrame("frame", "OpenRollsSummaryGroup", frame)
group:SetPoint("LEFT", frame, "LEFT", 12, 0)
group:SetPoint("RIGHT", frame, "RIGHT", -12, 0)
group:SetPoint("TOP", title, "BOTTOM", 0, -12)

local strings = {}
for i = 1, 40 do
    local stringframe = CreateFrame("frame", "OpenRollsSummaryString" .. i, group)
    stringframe:SetPoint("LEFT", group, "LEFT")
    stringframe:SetPoint("RIGHT", group, "RIGHT")
    
    local name = stringframe:CreateFontString("OpenRollsSummaryName" .. i, "OVERLAY", "GameFontNormal")
    name:SetJustifyH("LEFT")
    name:SetPoint("TOPLEFT", stringframe, "TOPLEFT")
    name:SetText("Name " .. i)
    
    local roll = stringframe:CreateFontString("OpenRollsSummaryRoll" .. i, "OVERLAY", "GameFontNormal")
    roll:SetJustifyH("RIGHT")
    roll:SetPoint("TOPRIGHT", stringframe, "TOPRIGHT")
    roll:SetText(i)
    --name:SetPoint("RIGHT", roll, "LEFT", 0)
    
    stringframe:SetHeight(name:GetHeight())
    
    strings[i] = {frame = stringframe, name = name, roll = roll}
end

strings[1].frame:SetPoint("TOP", group, "TOP")
for i = 2, 40 do
    strings[i].frame:SetPoint("TOP", strings[i-1].frame, "BOTTOM")
end

local close = CreateFrame("Button", "OpenRollsSummaryClose", frame, "UIPanelButtonTemplate")
close:SetHeight(20)
close:SetWidth(100)
--close:SetPoint("CENTER", title, "CENTER")
close:SetPoint("TOP", group, "BOTTOM")
close:SetText("Close")
close:SetScript("OnClick", function(frame) 
    frame:GetParent():Hide()
end)

group:SetHeight(strings[1].frame:GetTop() - strings[40].frame:GetBottom())
frame:SetHeight(title:GetTop() - close:GetBottom() + 24)

frame:Hide()

local function RollValue(roll)
    if roll == "Offline" then 
        return -2
    elseif roll == "Waiting..." then
        return -1
    else
        return tonumber(roll)
    end
end

local function Color()
    local str, val
    for i = 1, GetNumRaidMembers() do
        str = strings[i]
        val = RollValue(str.roll:GetText())
        if val == -1 then
            str.name:SetTextColor(0.5, 0.5, 0.5)
            str.roll:SetTextColor(0.5, 0.5, 0.5)
        elseif val == -2 then 
            str.name:SetTextColor(1, 0, 0)
            str.roll:SetTextColor(1, 0, 0)
        else
            str.name:SetTextColor(0, 1, 0)
            str.roll:SetTextColor(0, 1, 0)
        end
    end
end

local function Sort(array)
    local values = {}
    for i, str in pairs(strings) do
        values[i] = RollValue(str.roll:GetText())
    end
    --this code was basically stolen from the wikipedia article on insertion sort
    for i = 2, GetNumRaidMembers() do
        local value = values[i]
        local name = strings[i].name:GetText()
        local roll = strings[i].roll:GetText()
        local j = i - 1
        while j >= 1 and values[j] < value do
            values[j + 1] = values[j]
            strings[j+1].name:SetText(strings[j].name:GetText())
            strings[j+1].roll:SetText(strings[j].roll:GetText())
            j = j-1
        end
        values[j+1] = value
        strings[j+1].name:SetText(name)
        strings[j+1].roll:SetText(roll)
    end
    
    Color()
--[[insertionSort(array A)
    for i = 1 to length[A]-1 do
    begin
        value = A[i]
        j = i-1
        while j >= 0 and A[j] > value do
        begin
            A[j + 1] = A[j]
            j = j-1
        end
        A[j+1] = value
    end]]--
end

function OpenRolls:AssignRoll(name, roll)
    for i = 1, GetNumRaidMembers() do
        if strings[i].name:GetText() == name then
            strings[i].roll:SetText(roll)
        end
    end
    Sort()
end

function OpenRolls:HasEverybodyRolled()
    for i = 1, GetNumRaidMembers() do
        if RollValue(strings[i].roll:GetText()) == -1 then 
            return false
        end
    end
    return true
end

function OpenRolls:PrintWinners(quantity)
    if RollValue(strings[1].roll:GetText()) < 1 then
        OpenRolls:Print("Nobody rolled")
        return
    end
    
    for i = 1, quantity do
        if RollValue(strings[i].roll:GetText()) < 1 then
            return
        end
        OpenRolls:Print(strings[i].name:GetText())
    end
end

function OpenRolls:HideSummary()
    frame:Hide()
end

function OpenRolls:ShowSummary(titl)
    title:SetText(titl)
    local height = 0
    local del = strings[1].name:GetHeight()
    for i = 1, GetNumRaidMembers() do
        local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
        strings[i].name:SetText(name)
        height = height + del
        if online then
            strings[i].name:SetTextColor(0.5, 0.5, 0.5)
            strings[i].roll:SetTextColor(0.5, 0.5, 0.5)
            strings[i].roll:SetText("Waiting...")
        else
            strings[i].name:SetTextColor(1, 0, 0)
            strings[i].roll:SetTextColor(1, 0, 0)
            strings[i].roll:SetText("Offline")
        end
        strings[i].frame:Show()
    end
    for i = GetNumRaidMembers()+1, 40 do
        strings[i].frame:Hide()
    end
    group:SetHeight(height)
    frame:SetHeight(title:GetTop() - close:GetBottom() + 24)
    Sort()
    frame:Show()
end

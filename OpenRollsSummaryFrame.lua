local Group = LibStub("GroupLib-1.0")

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
frame:SetWidth(400)
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
    stringframe:EnableMouse()
    stringframe:SetScript("OnEnter", function(frame, ...)
        local GameTooltip = GameTooltip
        GameTooltip:SetOwner(frame, "ANCHOR_TOPLEFT")
        local n = frame.name:GetText()
        local nr, ng, nb = frame.name:GetTextColor()
        local r = frame.roll:GetText()
        local rr, rg, rb = frame.roll:GetTextColor()
        GameTooltip:AddDoubleLine(n, r, nr, ng, nb, rr, rg, rb)
        for single, func in OpenRolls:SummaryHooks() do
            if single then
                GameTooltip:AddLine(func(n, r))
            else
                GameTooltip:AddDoubleLine(func(n, r))
            end
        end
        GameTooltip:AddLine("This is a single line", 1, 0, 1)
        GameTooltip:Show()
    end)    
    stringframe:SetScript("OnLeave", function(frame, ...) GameTooltip:Hide() end)
    
    local name = stringframe:CreateFontString("OpenRollsSummaryName" .. i, "OVERLAY", "GameFontNormal")
    name:SetJustifyH("LEFT")
    name:SetPoint("TOPLEFT", stringframe, "TOPLEFT")
    name:SetText("Not Yet Filled")
    stringframe.name = name
    
    local roll = stringframe:CreateFontString("OpenRollsSummaryRoll" .. i, "OVERLAY", "GameFontNormal")
    roll:SetJustifyH("RIGHT")
    roll:SetPoint("TOPRIGHT", stringframe, "TOPRIGHT")
    roll:SetText(i)
    stringframe.roll = roll
    
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
    elseif roll == "Passed" then
        return 0
    else
        return tonumber(roll)
    end
end

local function Color()
    local str, val
    for i = 1, Group.Number() do
        str = strings[i]
        val = RollValue(str.roll:GetText())
        if val == -1 or val == 0 then
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
    for i = 2, Group.Number() do
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
    for i = 1, Group.Number() do
        if strings[i].name:GetText() == name then
            if RollValue(strings[i].roll:GetText()) > 0 then return false end
            strings[i].roll:SetText(roll)
            Sort()
            return true
        end
    end
    return false
end

function OpenRolls:HasEverybodyRolled()
    for i = 1, Group.Number() do
        if RollValue(strings[i].roll:GetText()) == -1 then 
            return false
        end
    end
    return true
end

function OpenRolls:PrintWinners(item, quantity)
    OpenRolls:Communicate("Roll over for " .. quantity .. "x" .. item)
    if RollValue(strings[1].roll:GetText()) < 1 then
        OpenRolls:Communicate("   Nobody rolled")
        return
    end
    
    for i = 1, quantity do
        if RollValue(strings[i].roll:GetText()) < 1 then
            return
        end
        OpenRolls:Communicate(strings[i].name:GetText() .. " rolled " .. strings[i].roll:GetText())
    end
end

function OpenRolls:HideSummary()
    frame:Hide()
end

function OpenRolls:StartRoll(item, quantity)
    OpenRolls:Communicate("Open roll for " .. quantity .. "x" .. item)
    OpenRolls:FillSummary("Roll in progress for " .. quantity .. "x" .. item)
    OpenRolls:ShowSummary()
end

function OpenRolls:EndRoll(item, quantity)
    title:SetText("Roll finished for " .. quantity .. "x" .. item)
    for i = 1, Group.Number() do
        if strings[i].roll:GetText() == "Waiting..." then
            strings[i].roll:SetText("Passed")
        end
    end
    OpenRolls:PrintWinners(item, quantity)
    if OpenRollsData.ShowSummaryWhenRollsOver then
        OpenRolls:ShowSummary()
    end
end

function OpenRolls:FillSummary(titl)
    title:SetText(titl)
    local height = 0
    local del = strings[1].name:GetHeight()
    local i = 0
    for name, _, online in Group.Members() do
        i = i + 1
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
    for i = Group.Number()+1, 40 do
        strings[i].frame:Hide()
    end
    group:SetHeight(height)
    frame:SetHeight(title:GetTop() - close:GetBottom() + 24)
    Sort()
end

local summaryHooks = {}

function OpenRolls:AddSummaryHook(name, single, func)
    table.insert(summaryHooks, {name = name, single = single, func = func})
end

function OpenRolls:RemoveSummaryHook(name)
    for i, j in pairs(summaryHooks) do
        if j.name == name then table.remove(summaryHooks, i) return end
    end
end

function OpenRolls:SummaryHooks()
    local i = 0
    return function() 
        i = i + 1
        if i > #summaryHooks then return nil end
        return summaryHooks[i].single, summaryHooks[i].func
    end
end

function OpenRolls:ShowSummary()
    if strings[1].name:GetText() == "Not Yet Filled" then
        OpenRolls:FillSummary("No item")
    end
    frame:Show()
end

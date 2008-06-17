local lootframes = {}

local function CreateLootFrame(i)
    local topframe, icon, need, greed, raid, duration, assignName, assignNeed, assign, ignore

    topframe = CreateFrame("Frame", "swLootFramesTop" .. i, UIParent)
    topframe.slot = i
    topframe:SetBackdrop({
        bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", 
        tile = true, tileSize = 32, edgeSize = 32, 
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    }  )
    topframe:SetBackdropColor(0,0,0,1)
    topframe:SetToplevel(true)
    topframe:SetFrameStrata("FULLSCREEN_DIALOG")
    if #lootframes == 0 then
        topframe:SetPoint("TOPLEFT", LootFrame, "TOPRIGHT")
    else
        topframe:SetPoint("TOPLEFT", lootframes[#lootframes].topframe, "BOTTOMLEFT")
    end
    topframe:SetWidth(278)
    topframe:SetHeight(100)

    icon = CreateFrame("Frame", "swLootFramesIcon" .. i, topframe)
    icon:SetHeight(52)
    icon:SetWidth(52)
    icon:EnableMouse()            
    icon:SetScript("OnLeave", function(frame, ...) GameTooltip:Hide() end)
    icon:SetPoint("TOPLEFT", topframe, "TOPLEFT", 15, -15)
    icon:SetBackdrop({
        bgFile=(GetLootSlotInfo(i)),
        edgeFile=nil,
        tile = false, tileSize = 32, edgeSize = 32, 
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    icon:SetScript("OnEnter", function(frame, ...)
        local GameTooltip = GameTooltip
        GameTooltip:SetOwner(frame, "ANCHOR_TOPLEFT")
        GameTooltip:SetHyperlink(GetLootSlotLink(i))
        GameTooltip:Show()
    end)
    
    name = topframe:CreateFontString("swLootFramesName" .. i, "OVERLAY", "GameFontNormal")
    name:SetPoint("TOPLEFT", icon, "TOPRIGHT")
    name:SetText(GetLootSlotLink(i))
    name:SetPoint("RIGHT", topframe, "RIGHT")
    
    need = CreateFrame("Button","swLootFramesNeed" .. i,topframe,"UIPanelButtonTemplate")
    need:SetPoint("TOPLEFT", name,"BOTTOMLEFT")
    need:SetHeight(20)
    need:SetWidth(100)
    need:SetText("Need")
    need.dummyvariable = 15
    need:SetScript("OnClick", function(frame) 
        local slot = frame:GetParent().slot
        local tbl = frame:GetParent().table
        local itemlink = GetLootSlotLink(slot)
        tbl.assignName:SetText("")
        tbl.assignNeed:SetChecked(false)
        swLoot:StartRoll(itemlink, function(winner, need) 
            tbl.assignName:SetText(winner)
            tbl.assignNeed:SetChecked(need)
        end)
    end)
    
    raid = CreateFrame("Button", "swLootFramesRaid" .. i, topframe, "UIPanelButtonTemplate")
    raid:SetPoint("TOPLEFT", need, "TOPRIGHT")
    raid:SetHeight(20)
    raid:SetWidth(100)
    raid:SetText("Raid Roll")
    raid:SetScript("OnClick", function(frame)
        local candidates = {}
        for i = 1, 40 do
            if GetMasterLootCandidate(i) ~= nil then
                table.insert(candidates, {index = i, name = GetMasterLootCandidate(i)})
            end
        end
        local candidate = math.random(#candidates)
        swLoot:Print("Assigning loot to " .. candidates[dandidate].name)
        GiveMasterLoot(frame:GetParent().slot, candidates[candidate].index)
    end)
    
    duration = CreateFrame("EditBox", "swLootFramesDuration" .. i, topframe, "InputBoxTemplate")
    duration:SetAutoFocus(false)
    duration:SetFontObject(ChatFontNormal)
    duration:SetNumeric()
    duration:SetTextInsets(0,0,3,3)
    duration:SetMaxLetters(2)
    duration:SetPoint("TOPRIGHT", need, "BOTTOMRIGHT")
    duration:SetHeight(20)
    duration:SetWidth(20)
    duration:SetText("5")
    duration:SetScript("OnEnter", function(frame, ...)
        local GameTooltip = GameTooltip
        GameTooltip:SetOwner(frame, "ANCHOR_TOPLEFT")
        GameTooltip:SetText("Duration of a greed roll", 1, 1, 1, 1)
        GameTooltip:Show()
    end)
    duration:SetScript("OnLeave", function(frame, ...) GameTooltip:Hide() end)

    greed = CreateFrame("Button", "swLootFramesGreed" .. i ,topframe,"UIPanelButtonTemplate")
    greed:SetPoint("TOPLEFT", need, "BOTTOMLEFT")
    greed:SetPoint("RIGHT",duration,"LEFT",-5,0)
    greed:SetHeight(20)
    greed:SetText("Greed")
    greed:SetScript("OnClick", function(frame) 
        local parent = frame:GetParent()
        local slot = parent.slot
        local itemlink = GetLootSlotLink(slot)
        local duration = parent.table.duration:GetText()
        if duration == "" then duration = "5" end
        parent.table.assignName:SetText("")
        parent.table.assignNeed:SetChecked(false)
        swLoot:StartGreed(itemlink, duration, function(winner, need) 
            parent.table.assignName:SetText(winner)
            parent.table.assignNeed:SetChecked(need)
        end)
    end)
    
    assignName = CreateFrame("EditBox", "swLootFramesAssignName" .. i, topframe, "InputBoxTemplate")
    assignName:SetAutoFocus(false)
    assignName:SetFontObject(ChatFontNormal)
    assignName:SetTextInsets(0,0,3,3)
    assignName:SetMaxLetters(12)
    assignName:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 5, 0)
    assignName:SetHeight(20)
    assignName:SetWidth(100)
    assignName:SetScript("OnEnter", function(frame, ...)
        local GameTooltip = GameTooltip
        GameTooltip:SetOwner(frame, "ANCHOR_TOPLEFT")
        GameTooltip:SetText("User to assign loot to", 1, 1, 1, 1)
        GameTooltip:Show()
    end)
    assignName:SetScript("OnLeave", function(frame, ...) GameTooltip:Hide() end)
    
    assignNeed = CreateFrame("CheckButton", "swLootFramesAssignNeed" .. i, topframe, "OptionsCheckButtonTemplate")
    assignNeed:SetPoint("TOPLEFT", assignName, "TOPRIGHT", 0, 0)
    assignNeed:SetWidth(20)
    assignNeed:SetHeight(20)
    assignNeed:SetHitRectInsets(0,0,0,0)
    assignNeed:SetScript("OnEnter", function(frame, ...)
        local GameTooltip = GameTooltip
        GameTooltip:SetOwner(frame, "ANCHOR_TOPLEFT")
        GameTooltip:SetText("Use need?", 1, 1, 1, 1)
        GameTooltip:Show()
    end)
    assignNeed:SetScript("OnLeave", function(frame, ...) GameTooltip:Hide() end)
        
    ignore = CreateFrame("Button", "swLootFramesIgnore" .. i, topframe, "UIPanelButtonTemplate")
    ignore:SetPoint("TOPLEFT", raid, "BOTTOMLEFT")
    ignore:SetPoint("RIGHT", raid, "RIGHT")
    ignore:SetHeight(20)
    ignore:SetText("Ignore Item")
    ignore:SetScript("OnClick", function(frame) frame:GetParent():Hide() end)
    
    assign = CreateFrame("Button", "swLootFramesAssign" .. i, topframe, "UIPanelButtonTemplate")
    assign:SetPoint("TOPLEFT", assignNeed, "TOPRIGHT")
    assign:SetPoint("RIGHT", ignore, "RIGHT")
    assign:SetHeight(20)
    assign:SetText("Assign")
    assign:SetScript("OnClick", function(frame)
        local parent = frame:GetParent()
        local slot = parent.slot
        local name = parent.table.assignName:GetText()
        local need = parent.table.assignNeed:GetChecked()
        local item = GetLootSlotLink(slot)
        
        if need == 1 then need = "need" else need = "greed" end
        
        if name ~= "" then
            swLoot:AwardItem(name .. " " .. item .. " " .. need)
        end
    end)
    
    local tbl =  {
        topframe = topframe,
        icon = icon,
        need = need,
        greed = greed,
        raid = raid,
        duration = duration,
        assignName = assignName,
        assignNeed = assignNeed,
        assign = assign
    }
    tbl.topframe.table = tbl
    table.insert(lootframes, tbl)
end

function swLoot:LOOT_OPENED()
    if swLootData.showGUI == 'never' then return end
    if swLootData.showGUI == 'whenML' and (select(2, GetLootMethod())) ~= 0 then return end
    
    lootframes = {}
    local threshold = GetLootThreshold()
    for i = 1, GetNumLootItems() do
        if (select(4, GetLootSlotInfo(i))) >= threshold then
            CreateLootFrame(i)
        end
    end
end

function swLoot:LOOT_CLOSED()
    for _, frame in pairs(lootframes) do
        frame.topframe:Hide()
    end
    lootframes = {}
end

function swLoot:LOOT_SLOT_CLEARED(name, slot)
    local pos = nil
    for i, frame in pairs(lootframes) do
        if frame.topframe.slot == slot then 
            frame.topframe:Hide() 
            pos = i
        end
    end
    if pos ~= nil then table.remove(lootframes, pos) end
end

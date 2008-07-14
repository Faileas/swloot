function swLoot:CreateMessageBox(text, yes, no)
    local box = CreateFrame("Frame", "swLootMessageBox" .. count, UIParent)
    count = count + 1
    
    box:SetBackdrop({
        bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", 
        tile = true, tileSize = 32, edgeSize = 32, 
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })    
    box:SetBackdropColor(0,0,0,1)
    box:SetToplevel(true)
    box:SetFrameStrata("FULLSCREEN_DIALOG")
    box:SetWidth(278)
    box:SetHeight(100)
    box:SetPoint("CENTER", UIParent, "CENTER")
    box:SetMovable(true)
    box:EnableMouse()
    box:SetScript("OnMouseDown", function(frame) frame:StartMoving() end)
    box:SetScript("OnMouseUp", function(frame) frame:StopMovingOrSizing() end)
        
    local cancel = CreateFrame("Button", "swLootMessageBoxCancel" .. count, box,"UIPanelButtonTemplate")
    cancel:SetPoint("BOTTOMRIGHT", box,"BOTTOMRIGHT", -12, 12)
    cancel:SetHeight(20)
    cancel:SetWidth(100)
    cancel:SetText("Cancel")
    cancel:SetScript("OnClick", function(frame) 
        box:Hide()
        no()
    end)
    
    local confirm = CreateFrame("Button", "swLootMessageBoxConfirm" .. count, box,"UIPanelButtonTemplate")
    confirm:SetPoint("BOTTOMLEFT", box,"BOTTOMLEFT", 12, 12)
    confirm:SetHeight(20)
    confirm:SetWidth(100)
    confirm:SetText("Confirm")
    confirm:SetScript("OnClick", function(frame) 
        box:Hide()
        yes()
    end)
    
    local str = box:CreateFontString("swLootMessageBoxString" .. count, "OVERLAY", "GameFontNormal")
    str:SetPoint("TOPLEFT", box, "TOPLEFT", 12, -12)
    --str:SetPoint("BOTTOMRIGHT", cancel, "TOPRIGHT", -12, 12)
    str:SetWidth(box:GetRight() - box:GetLeft() - 24)
    str:SetText(text)
    box:SetHeight(str:GetHeight() + 50)
    
    box:Show()
end

function swLoot:LOOT_OPENED()
    if swLootData.showGUI == 'never' then return end
    if swLootData.showGUI == 'whenML' and (select(2, GetLootMethod())) ~= 0 then return end
end

function swLoot:LOOT_CLOSED()
end

function swLoot:LOOT_SLOT_CLEARED(name, slot)
end

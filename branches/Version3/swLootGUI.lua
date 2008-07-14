local function AttachMouseoverText(frame, text, r, g, b, a)
    frame:EnableMouse()
    frame:SetScript("OnEnter", function(self, ...) 
        local GT = GameTooltip
        GT:SetOwner(self, "ANCHOR_TOPLEFT")
        GT:SetText(text, r, g, b, a)
        GT:Show()
    end)
    frame:SetScript("OnLeave", function(self, ...) GameTooltip:Hide() end)
end

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

local frameCount = 1
local function CreateLootWindow(lootslot, parent)
    local framename = "swLootLootFrame" .. frameCount
    frameCount = frameCount+1
    local self = CreateFrame("frame", framename, parent)
    self.lootSlot = lootslot
    
    self.Release = function(self) 
        self:ClearAllPoints()
        self:Hide()
    end

    self:SetBackdrop({
        bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", 
        tile = true, tileSize = 32, edgeSize = 32, 
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    }  )
    self:SetBackdropColor(0,0,0,1)
    self:SetToplevel(true)
    self:SetFrameStrata("FULLSCREEN_DIALOG")
    self:SetWidth(278)
    self:SetHeight(100)
    
    local icon = CreateFrame("Frame", framename .. "Icon", self)
    icon:SetHeight(52)
    icon:SetWidth(52)
    icon:EnableMouse()
    icon:SetScript("OnLeave", function(frame, ...) GameTooltip:Hide() end)
    icon:SetPoint("TOPLEFT", self, "TOPLEFT", 15, -15)
    icon:SetBackdrop({
        bgFile=(GetLootSlotInfo(lootslot)),
        edgeFile=nil,
        tile = false, tileSize = 32, edgeSize = 32, 
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    icon:SetScript("OnEnter", function(frame, ...)
        local GameTooltip = GameTooltip
        GameTooltip:SetOwner(frame, "ANCHOR_TOPLEFT")
        GameTooltip:SetHyperlink(GetLootSlotLink(lootslot))
        GameTooltip:Show()
    end)
    self.icon = icon
    
    local ignore = CreateFrame("button", framename .. "Ignore", self, "UIPanelCloseButton")
    ignore:SetPoint("TOPRIGHT", self, "TOPRIGHT", -4, -4)
    ignore:SetScript("OnClick", function(frame, ...)
        frame:GetParent():Release()
    end)
    self.ignore = ignore
    
    local name = self:CreateFontString(framename .. "Name", "OVERLAY", "GameFontNormal")
    name:SetJustifyH("CENTER")
    name:SetPoint("TOPLEFT", icon, "TOPRIGHT")
    name:SetText(GetLootSlotLink(lootslot))
    name:SetPoint("RIGHT", ignore, "LEFT", 4, 0)
    self.name = name
    
    local assignName = CreateFrame("EditBox", framename .. "AssignName", self, "InputBoxTemplate")
    assignName:SetAutoFocus(false)
    assignName:SetFontObject(ChatFontNormal)
    assignName:SetTextInsets(0,0,3,3)
    assignName:SetMaxLetters(12)
    assignName:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 5, 0)
    assignName:SetWidth(100)
    assignName:SetHeight(20)
    AttachMouseoverText(assignName, "User to award item to", 1, 1, 1, 1)
    self.assignName = assignName
    
    local assign = CreateFrame("button", framename .. "Assign", self, "UIPanelButtonTemplate")
    assign:SetPoint("TOPLEFT", assignName, "TOPRIGHT")
    assign:SetWidth(100)
    assign:SetHeight(20)
    assign:SetText("Award")
    assign:SetScript("OnClick", function(frame, ...)
        local window = frame:GetParent()
        local player = window.assignName:GetText()
        if player == "" then return end
        if not OpenRolls:DistributeItemByName(player, window.slot) then
            OpenRolls:Print(player .. " not eligible for this item.")
        end
    end)
    self.assign = assign

    return self
end


local frames = {}
local function RepositionLootWindows()
    if #frames == 0 then return end
    frames[1]:ClearAllPoints()
    frames[1]:SetPoint("TOPLEFT", LootFrame, "TOPRIGHT", -66, -4)
    for i = 2, #frames do
        frames[i]:ClearAllPoints()
        frames[i]:SetPoint("TOPLEFT", frames[i-1], "BOTTOMLEFT")
    end
end

function swLoot:LOOT_OPENED()
    if swLootData.showGUI == 'never' then return end
    if swLootData.showGUI == 'whenML' and (select(2, GetLootMethod())) ~= 0 then return end

    frames = {}
    local threshold = GetLootThreshold()
    for i = 1, GetNumLootItems() do
        if (select(4, GetLootSlotInfo(i))) >= threshold then
            local item = CreateLootWindow(i, UIParent)
            table.insert(frames, item)
            item:Show()
        end
    end
    RepositionLootWindows()
end

function swLoot:LOOT_CLOSED()
end

function swLoot:LOOT_SLOT_CLEARED(name, slot)
end

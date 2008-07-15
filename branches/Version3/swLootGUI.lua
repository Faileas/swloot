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
        local parent = frame:GetParent() 
        local slot = parent.lootSlot 
        local name = parent.assignName:GetText()
        local need = parent.internal.useNeed:GetChecked() 
        local item = GetLootSlotLink(slot)  
        if need == 1 then 
            need = "need" 
        else 
            need = "greed" 
        end  
        if name ~= "" then 
            swLoot:AwardItem(name .. " " .. item .. " " .. need) 
        end 
    end)
    self.assign = assign

    return self
end

local internalCount = 1
local function CreateInternalWindow(lootslot, parent)
    local framename = "swLootInternalLootFrame" .. internalCount
    internalCount = internalCount+1
    
    local frame = CreateFrame("frame", framename, parent)
    frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT")
    frame:SetWidth(40)
    frame:SetHeight(100)
    frame.slot = lootslot
    
    local need = CreateFrame("button", framename .. "Need", frame, "UIPanelButtonTemplate")
    need:SetPoint("TOPLEFT", frame, "TOPLEFT")
    need:SetHeight(20)
    need:SetWidth(100)
    need:SetText("Need")
    need:SetScript("OnClick", function(frame, ...)
        local parent = frame:GetParent()
        local slot = parent.slot 
        local itemlink = GetLootSlotLink(slot) 
        parent:SetAssign("")
        parent.useNeed:SetChecked(false) 
        swLoot:StartRoll(itemlink, function(winner, need)  
            parent:SetAssign(winner) 
            parent.useNeed:SetChecked(need) 
        end)
    end)
    frame.need = need
    
    duration = CreateFrame("EditBox", framename .. "Duration", frame, "InputBoxTemplate") 
    duration:SetAutoFocus(false) 
    duration:SetFontObject(ChatFontNormal) 
    duration:SetNumeric() 
    duration:SetTextInsets(0,0,3,3) 
    duration:SetMaxLetters(2) 
    duration:SetPoint("TOPRIGHT", need, "BOTTOMRIGHT") 
    duration:SetHeight(20) 
    duration:SetWidth(20) 
    duration:SetText("5") 
    AttachMouseoverText(duration, "Duration of a greed roll", 1, 1, 1, 1)
    frame.duration = duration
    
    local greed = CreateFrame("button", framename .. "Greed", frame, "UIPanelButtonTemplate")
    greed:SetPoint("TOPLEFT", need, "BOTTOMLEFT") 
    greed:SetPoint("RIGHT", duration, "LEFT", -5, 0) 
    greed:SetHeight(20)
    greed:SetWidth(100)
    greed:SetText("Greed")
    greed:SetScript("OnClick", function(frame, ...)
        local parent = frame:GetParent() 
        local slot = parent.slot 
        local itemlink = GetLootSlotLink(slot) 
        local duration = parent.duration:GetText() 
        if duration == "" then 
            duration = "5" 
        end 
        parent:SetAssign("") 
        parent.useNeed:SetChecked(false) 
        swLoot:StartGreed(itemlink, duration, function(winner, need)
            parent:SetAssign(winner)
            parent.useNeed:SetChecked(need) 
        end)
    end)
    frame.greed = greed

    useNeed = CreateFrame("CheckButton", framename .. "UseNeed", frame, "OptionsCheckButtonTemplate") 
    useNeed:SetPoint("TOPLEFT", need, "BOTTOMRIGHT", 0, 10)
    useNeed:SetWidth(20) 
    useNeed:SetHeight(20) 
    useNeed:SetHitRectInsets(0,0,0,0) 
    AttachMouseoverText(useNeed, "Use need?", 1, 1, 1, 1)
    frame.useNeed = useNeed
    
    frame.AwardToPlayer = function(self, player, item)
        local need = self.useNeed:GetChecked()
        if need == 1 then
            need = "need"
        else
            need = "greed"
        end
        swLoot:AwardItem(player .. " " .. item .. " " .. need)
    end
    
    frame:SetWidth(useNeed:GetRight() - need:GetLeft())
    frame:SetHeight(need:GetTop() - greed:GetBottom())
    
    return frame
end

function swLoot:CreateLootWindow(slot, parent)
    return CreateInternalWindow(slot, parent)
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
            local internal = CreateInternalWindow(i, item)
            internal:ClearAllPoints()
            internal:SetPoint("TOPLEFT", item.name, "BOTTOMLEFT")
            internal.SetAssign = function(f, player)
                item.assignName:SetText(player)
            end
            internal.GetAssign = function(f)
                return item.assignName:GetText()
            end
            item.internal = internal
            table.insert(frames, item)
            item:Show()
        end
    end
    RepositionLootWindows()
end

function swLoot:LOOT_CLOSED()
    for _, f in pairs(frames) do
        f:Release()
    end
end

function swLoot:LOOT_SLOT_CLEARED(name, slot)
    local pos = nil
    for i, frame in pairs(frames) do
        if frame.slot == slot then 
            frame:Release() 
            pos = i
        end
    end
    if pos ~= nil then table.remove(frames, pos) end
    RepositionLootWindows()
end

--TODO: Decide when we can clear the warning flag
--Thoughts: two type of warnings; awarding outside and awarding in wrong instance
--  awarding outside can be reset when you award something inside
--  awarding in the wrong instance can be reset when loot is awarded successfully
--To sum up: Both can be reset when something is looted inside an instance

--TODO: The instanceID code in Award is really dumb
--Thoughts: Once intarweb work look up lua tables and see what functions are available

local ItemLinkPattern = "|c%x+|H.+|h%[.+%]|h|r"
local options = {
    type='group',
    args = { 
        roll = { 
            type = 'text',
            name = 'roll',
            desc = 'Begin a roll',
            usage = '<item>',
            get = false,
            set = "StartRoll",
            validate = "ValidateItemLink"
        },
        
        greed = {
            type = 'text',
            name = 'greed',
            desc = 'Begin a greed roll',
            usage = '<item>',
            get = false,
            set = "StartGreed",
            validate = "ValidateItemLink"
        },
        
        award = {
            type = 'execute',
            name = 'award',
            desc = 'Awards item to last winner',
            func = "Award"
        },
        
        createRaid = {
            type = 'text',
            name = 'createRaid',
            desc = 'Creates a fresh raid',
            usage = '<name>',
            get = false,
            set = "CreateRaid"
        },
        
        currentRaid = {
            type = 'text',
            name = 'currentRaid',
            desc = 'The currently active raid',
            usage = '<name>',
            get = function() return swLootsData.currentRaid end,
            set = function(name) swLootsData.currentRaid = name end,
            validate = function(name) return swLootsData.raids[name] ~= nil end,
        },
        
        deleteRaid = {
            type = 'text',
            name = 'deleteRaid',
            desc = 'Delete a prior raid',
            usage = '<name>',
            get = false,
            set = function(name) swLootsData.raids[name] = nil end
        },
        
        listRaids = {
            type = 'execute',
            name = 'listRaids',
            desc = 'List all known raids',
            func = function() for i,j in pairs(swLootsData.raids) do swLoots:Print(i) end end
        },
        
        summarize = {
            type = 'execute',
            name = 'summarize',
            desc = 'Summarize the active raid',
            func = "SummarizeRaid"
        },
        
        debugText = {
            type = 'execute',
            name = 'ToggleDebug',
            desc = 'Toggles between normal operation, and forcing all output to local chat',
            func = function() swLoots.debug = not swLoots.debug end
        },
        
        synchronize = {
            type = 'text',
            name = 'synchronize',
            desc = 'Synchronize raid data with another swLoot user',
            usage = '<player> <raid>',
            get = false,
            set = "SynchronizeRequest",
            validate = function(str)
                local found, _, raid = string.find(str, "%a+%s+(.+)")
                return not (found == nil or swLootsData.raids[raid] == nil)
            end
        },
        
        addTrusted = {
            type = 'text',
            name = 'addTrustedUser',
            desc = 'Add a user to your trusted list for synchronization purposes',
            usage = '<player>',
            get = false,
            set = function(name) swLootsData.trustedUsers[name] = true end
        },
        
        removeTrusted = {
            type = 'text',
            name = 'removeTrustedUser',
            desc = 'Removes a user from your trusted list',
            usage = '<player>',
            get = false,
            set = function(name) swLootsData.trustedUsers[name] = nil end
        },
        
        awardDirect = {
            type = 'text',
            name = 'awardDirect',
            desc = 'Award an item without regard to the previous roll',
            usage = '<player> <item> <need>',
            get = false,
            set = "AwardItem"
        },
        
        useNeed = {
            type = 'text',
            name = 'useNeed',
            desc = 'Use a character\'s need roll without actually awarding loot.',
            usage = '<player>',
            get = false,
            set = function(name) 
                if swLootsData.currentRaid == nil then self:Print("You are not currently tracking a raid.") end
                swLootsData.raids[swLootsData.currentRaid].usedNeed[name] = true
            end
        },
        
        freeNeed = {
            type = 'text',
            name = 'freeNeed',
            desc = 'Removes a player\'s need roll [so they can roll need again].',
            usage = '<player>',
            get = false,
            set = function(name)
                if swLootsData.currentRaid == nil then self:Print("You are not currently tracking a raid.") end
                swLootsData.raids[swLootsData.currentRaid].usedNeed[name] = nil
            end
        },
        
        renameRaid = {
            type = 'text',
            name = 'renameRaid',
            desc = 'Renames an existing raid',
            usage = '<old raid name> <new raid name>',
            get = false,
            set = function(str)
                local found, _, old, new = string.find(str, "(%a+)%s+(.+)")
                if found == nil then 
                    self:Print("Incorrect usage [<old raid name> <new raid name>]")
                    return
                end
                swLoots:Print("Changing raid [" .. old .. "] to [" .. new .. "]")
                swLootsData.raids[new] = swLootsData.raids[old]
                swLootsData.raids[old] = nil
                if swLootsData.currentRaid == old then swLootsData.currentRaid = new end
            end
        },
        
        disqualifyRoll = {
            type = 'text',
            name = 'disqualifyRoll',
            desc = 'Removes a roller from consideration when they roll out of turn',
            usage = '<player>',
            get = false,
            set = function(str)
                if swLoots.currentRollers[str] == nil then
                    swLoots:Print(str .. " did not roll.")
                    return
                end
                swLoots.currentRollers[str] = -1 -- (-1) prevents him from rolling again if a roll
                                                 -- is in progress
                local msg = str .. " was disqualified. "
                if swLoots.rollInProgress ~= true then 
                    local winner, winnerUnusedNeed = swLoots:DetermineWinner()
                    if winner == nil then
                        msg = msg .. " However, nobody else rolled."
                    elseif winner == winnerUnusedNeed or winnerUnusedNeed == nil then
                        msg = msg .. " The new winner is " .. winner .. "."
                    else
                        msg = msg .. " " .. winner .. " rolled highest, but " .. winnerUnusedNeed
                                  .. " has a need roll remaining."
                    end
                end
                swLoots:Print(msg)
            end
        },
    }
}

swLoots = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceEvent-2.0", "AceComm-2.0")
swLoots.version = 14
swLoots.versionSyncCompatable = 13

swLoots:RegisterChatCommand("/swloot", options)

--swLootsData is the structure that gets saved between sessions.  No new members should be added to 
--it unless you want them to be saved.  Single session data belongs in swLoots
swLootsData = {}

--A table of users trusted to automatically synchronize with.
--If trustedUsers[BillyBob] ~= true, then BillyBob is not a trusted user
swLootsData.trustedUsers = {}

--Basically the number of pieces of loot this account has awarded; used to ensure unique IDs while
--  synchronizing
--WHY ARE YOU NIL
--YOU ARE NOT NIL ANYMORE I FIXED YOU
swLootsData.nextLootID = 0

--The actual loot information.  The index is the raid ID
-- raids[ID].loot is a table of the awarded loot.  The index is made up of the player's name, and a
--                unique number; it isn't actually that important except when merging data
-- raids[ID].loot[ID'].item is the item's name
-- raids[ID].loot[ID'].player is the winner's name

--These fields are not yet used:
-- raids[ID].instances is an array of instance IDs that have been awarded loot
-- raids[ID].date is the date when the raid was started
swLootsData.raids = {}

--These define the acceptable roll range.  Eventually, I should like to make this variable, hense
--their inclusion in the saved data
swLootsData.loRoll = 1
swLootsData.hiRoll = 100
swLootsData.currentRaid = nil

--Used by the aceComm library.  Do not change without a really good reason.
swLoots.commPrefix = "swLoots"

--This is information used by the roll tracker.  
--currentRollers[Player] is the roll made by Player
--currentWinner is the player who won the last successful roll.  Its value is undefined while a
--  roll is taking place.
swLoots.currentRollers = {}
swLoots.currentWinner = nil
swLoots.winnerRolledNeed = false

--Note to self: figure out how constants work.  In particular, does lua support Enums in any way?
swLoots.stateStartNeed = 0
swLoots.stateNeedCount = 1
swLoots.stateEvaluateNeed = 2
swLoots.stateStartGreed = 3
swLoots.stateGreedCount = 4
swLoots.stateEvaluateGreed = 5

--A simple locking mechanism to prevent two rolls from taking place at once.
swLoots.rollInProgress = false

--If true, Communicate always prints to the local chat
swLoots.debug = false

swLoots.warningMultipleRaids = false
swLoots.warningNotInInstance = false

--I'll bet there's a better name for this function.  It locates a raid that matches the isntance ID
--for the instance you're in.
function swLoots:FindRaid()
    currentID = swLoots:GetInstanceID()
    
    for name, raid in pairs(swLootsData.raids) do
        if raid.instances == nil then raid.instances = {} end
        for i, v in ipairs(raid.instances) do
            if v == currentID then return name end
        end
    end
    
    return nil
end

--Returns nil if you are not in an instance; 0 if you are not saved; the instance ID otherwise
--Here's hoping 0 is not a valid instance ID
function swLoots:GetInstanceID()
    inInstance, instanceType = IsInInstance()
    if inInstance ~= 1 or instanceType == "pvp" or instanceType == "arena" then return nil end
    
    local currentInstance = GetRealZoneText()
    local currentID = 0
    
    for index = 1, GetNumSavedInstances() do
        local instance, ID = GetSavedInstanceInfo(index)
        if instance == currentInstance then currentID = ID end
    end
    return currentID
end

function swLoots:OnInitialize()
    self:Print("swLoots successfully initialized.")
    self:SetCommPrefix(swLoots.commPrefix)
    self:RegisterComm(self.commPrefix, "WHISPER", "ReceiveMessage")
    
    self:RegisterEvent("UPDATE_INSTANCE_INFO")
end

function swLoots:UPDATE_INSTANCE_INFO(arg1)
    local inInstance, instanceType = IsInInstance()
--    if inInstance == true then
--    if (inInstance == true) and (instanceType == "raid") then
	numInstances = GetNumSavedInstances()
--	self:Print("You are saved to " .. numInstances .. " instances.")
--	self:Print("You are in " .. GetZoneText() .. ".")
	for instanceIndex = 1, numInstances do
		local name, ID, remaining = GetSavedInstanceInfo(instanceIndex)
--		self:Print("Index " .. instanceIndex .. " is " .. name)
--		self:Print("Index " .. instanceIndex)
		if name == GetZoneText() then
			self:Print("Your " .. name .. " raid ID is: " .. ID)
		end
	end
--    end
end

function swLoots:RecordRoll(char, roll, min, max)
  if (min == swLootsData.loRoll) and (max == swLootsData.hiRoll) then
    if(swLoots.currentRollers[char]) then
      self:Print(char .. " already rolled")
      self:Communicate("THAT'S A FUCKING 50 DKP MINUS " .. char .. "!!!")
    else
      swLoots.currentRollers[char] = roll
    end    
  else
    self:Print(char .. " rolled with a non-standard range [" .. min .. ", " .. max .. "]")
    self:Communicate("THAT'S A FUCKING 50 DKP MINUS " .. char .. "!!!")
  end
end

function swLoots:CHAT_MSG_SYSTEM(arg1)
    local start, stop, char, roll, min, max = string.find(arg1, "(%a+) rolls (%d+) %((%d+)-(%d+)%)")
    if(start ~= nil) then
      swLoots:RecordRoll(char, tonumber(roll), tonumber(min), tonumber(max))
    end
end

function swLoots:StateMachine(state, need, greed)
    if state == swLoots.stateStartNeed then
        swLoots:Communicate("Need rolls for " .. swLoots.currentItem)
        self:ScheduleEvent(function() self:StateMachine(swLoots.stateNeedCount, need, greed) end, 3)
    elseif state == swLoots.stateNeedCount then
        swLoots:Communicate(need)
        if need == 0 then state = swLoots.stateEvaluateNeed end
        self:ScheduleEvent(function() self:StateMachine(state, need-1, greed) end, 1)
    elseif state == swLoots.stateEvaluateNeed then
        local winner, winnerUnusedNeed = swLoots:DetermineWinner()
        if winner ~= nil then
            if winner == winnerUnusedNeed or winnerUnusedNeed == nil then
                swLoots:Communicate(winner .. " won " .. swLoots.currentItem .. " on a need.")
                swLoots.currentWinner = winner
            else
                swLoots:Communicate(winner .. " rolled highest, but " ..
                                    winnerUnusedNeed .. " wins " .. 
                                    swLoots.currentItem .. " on a need.")
                swLoots.currentWinner = winnerUnusedNeed
            end
            swLoots.winnerRolledNeed = true
            swLoots:EndRoll()
        else 
            self:ScheduleEvent(function() self:StateMachine(swLoots.stateStartGreed, nil, greed) end, 3)
        end
    elseif state == swLoots.stateStartGreed then
        swLoots:Communicate("Greed rolls for " .. swLoots.currentItem)
        self:ScheduleEvent(function() self:StateMachine(swLoots.stateGreedCount, nil, greed) end, 3)
    elseif state == swLoots.stateGreedCount then
        swLoots:Communicate(greed)
        if greed == 0 then state = swLoots.stateEvaluateGreed end
        self:ScheduleEvent(function() self:StateMachine(state, nil, greed-1) end, 1)
    elseif state == swLoots.stateEvaluateGreed then
        local winner = swLoots:DetermineWinner()
        if winner ~= nil then
            swLoots:Communicate(winner .. " won " .. swLoots.currentItem .. " on a greed.")
            swLoots.currentWinner = winner
            swLoots.winnerRolledNeed = false
        else 
            swLoots:Communicate("Rolls over; nobody rolled.")
        end
        self:EndRoll()
    else
        self:Print("Something's wrong: " .. state .. " -- " .. greed)
    end
end

function swLoots:StartRoll(item)
    if swLoots.rollInProgress == true then
        self:Print("Another roll is in progress [" .. swLoots.currentItem .. "]; please wait for it to complete.")
        return
    elseif swLootsData.currentRaid == nil then
        self:Print("Please start a raid before rolling for loot")
        PrintRecommendedRaid()
        return
    end
    self:RegisterEvent("CHAT_MSG_SYSTEM")
    swLoots.currentItem = item
    self:ResetLastRoll()
    swLoots.rollInProgress = true
    self:StateMachine(swLoots.stateStartNeed, 10, 5)
end

function swLoots:StartGreed(item)
    if swLoots.rollInProgress == true then
        self:Print("Another roll is in progress [" .. swLoots.currentItem .. "]; please wait for it to complete.")
        return
    elseif swLootsData.currentRaid == nil then
        self:Print("Please start a raid before rolling for loot")
        PrintRecommendedRaid()
        return
    end
    self:RegisterEvent("CHAT_MSG_SYSTEM")
    self.currentItem = item
    self:ResetLastRoll()
    self.rollInProgress = true
    self:StateMachine(swLoots.stateStartGreed, nil, 5)
end

function swLoots:EndRoll()
    self:UnregisterEvent("CHAT_MSG_SYSTEM")
    for k,v in pairs(swLoots.currentRollers) do
      self:Print(k .. " rolled " .. v)
    end
    self.rollInProgress = false
end

function swLoots:DetermineWinner()
    local winner = nil
    local roll = -1
    local winnerUnusedNeed = nil
    local rollUnusedNeed = -1
    for k,v in pairs(swLoots.currentRollers) do
        if v > roll then 
            winner = k 
            roll = v 
        end
        if swLootsData.raids[swLootsData.currentRaid].usedNeed[k] == nil and v > rollUnusedNeed then
            winnerUnusedNeed = k
            rollUnusedNeed = v
        end
    end
    return winner, winnerUnusedNeed
end

--Prints out which raid is associated with the current instance ID
function PrintRecommendedRaid()
    local raidName = swLoots:FindRaid()
    if raidName ~= nil then 
        swLoots:Print("[" .. raidName .. "] is currently tracking this instance.")
    else
        swLoots:Print("No raid is currently tracking this instance.")
    end
end

--Return value is true if you are tracking a safe raid; otherwise, returns false
function swLoots:ValidateTrackedRaid()
    --Things I need to check for:
    --  Are we in an instance?
    --  If so, are we in an instance associated with our raid?
    --  If not, are we in an instance associated with any raid?
    --  If not, are we associated with any instance?
    --I AM FINDING THIS VERY HARD
    --Is that, perhaps, what she said?
    --Indeed, no.  What she said was "put this in a function, dumbass"
    
    --  Are we in an instance?
    local _, type = IsInInstance()
    if type ~= "party" and type ~= "raid" then
        if swLoots.warningNotInInstance == false then
            swLoots:Print("You are no inside an instance; are you sure you are tracking the correct raid?")
            swLoots.warningNotInInstance = true
            return false
        else 
            return true
        end
    end
    
    --  If so, are we in an instance associated with our raid?
    local raidName = swLoots:FindRaid()
    if raidName == swLootsData.currentRaid then 
        return true 
    elseif raidName ~= nil then    
        --  If not, are we in an instance associated with any raid?
        swLoots:Print("[" .. raidName .. "] is currently tracking this instance.")
        return false --I do not intend for this to be something you can circumvent
    end

    --  If not, are we associated with any instance?
    if #(swLootsData.raids[swLootsData.currentRaid].instances) == 0 then return true end
    
    -- We are associated with *an* instance, just not this one.
    if swLoots.warningMultipleRaids == false then
        swLoots:Print("This raid is not associated with this instance.")
        swLoots.warningMultipleRaids = true
        return false
    else
        return true
    end
end

function swLoots:Award()
    if swLoots.currentWinner == nil then
        self:Print("Please use /swloot roll <item> before attempting to award loot")
        return
    end
    
    if swLootsData.currentRaid == nil then
        self:Print("You are not currently tracking a raid; loot distribution disabled.")
        PrintRecommendedRaid()
        return
    end
        
    local myRaid = swLootsData.raids[swLootsData.currentRaid]
    
    if swLoots:ValidateTrackedRaid() == false then return end
        
    --swLootsData.raids[swLootsData.currentRaid].loot[swLoots.currentItem] = swLoots.currentWinner
    local lootID = UnitName("player") .. swLootsData.nextLootID
    myRaid.loot[lootID] = {}
    myRaid.loot[lootID].item = swLoots.currentItem
    myRaid.loot[lootID].winner = swLoots.currentWinner
    
    local msg = swLoots.currentWinner .. " awarded " .. swLoots.currentItem
    if swLoots.winnerRolledNeed == true and myRaid.usedNeed[swLoots.currentWinner] == nil then
        msg = msg .. " using a need"
        myRaid.usedNeed[swLoots.currentWinner] = true
    end
    swLoots:Communicate(msg .. ".")
    swLootsData.nextLootID = swLootsData.nextLootID + 1
    
    --make sure we're associated with this instance
    local instanceID = swLoots:GetInstanceID()
    if instanceID ~= nil and instanceID > 0 then 
        swLoots.warningMultipleRaids = false
        swLoots.warningNotInInstance = false
    end
    local found = false
    for _, id in ipairs(myRaid.instances) do
        if id == instanceID then found = true end
    end
    if found == false then
        table.insert(myRaid.instances, instanceID)
    end
end

function swLoots:AwardItem(str)    
    --[[Potention change -- I'd rather wait to implement until I can test some other bits
    local found, _, player, item, need = string.find(str, "^(%a+) (" .. ItemLinkPattern ..") ?(.*)")
    if found == nil then
        found, _, item, player, need = string.find(str, "^(" .. ItemLinkPattern .. ") (%a+) ?(.*)")
        if found == nil then
            self:Print("Syntax error; awardDirect PlayerName Item [need|greed]")
        end
    end
    if need == nil then need = "greed" end
    
    need = string.lower(need)
    if need ~= "need" and need ~= "greed" then
        self:Print("Syntax error; awardDirect PlayerName Item [need|greed]")
    end
    
    self.currentItem = item
    self.currentWinner = player
    self.winnerRolledNeed = (need == "need")
    self:Award()
    ]]--
    local found,_, player, item, need = string.find(str, "^(%a+) (" .. ItemLinkPattern ..") (.*)")
    if found == nil then 
        found, _, player, item = string.find(str, "^(%a+) (" .. ItemLinkPattern ..")")
        need = "greed"
        if(found == nil) then self:Print("error") return end
    end
    self.currentItem = item
    self.currentWinner = player
    self.winnerRolledNeed = (string.lower(need) == "need")
    self:Award()
end

function swLoots:Communicate(str)
    if (not swLoots.debug) and GetNumRaidMembers() > 0 then
        SendChatMessage(str, "RAID")
    elseif (not swLoots.debug) and GetNumPartyMembers() > 0 then
        SendChatMessage(str, "PARTY")
    else
        self:Print(str)
    end
end

function swLoots:ResetLastRoll()
    swLoots.currentRollers = {}
    swLoots.currentWinner = nil
    swLoots.winnerRolledNeed = false
end

function swLoots:CreateRaid(name)
    if swLootsData.raids[name] ~= nil then 
        self:Print("Raid already exists; please delete or use a unique name")
    else
        swLootsData.raids[name] = {}
        swLootsData.raids[name].loot = {}
        swLootsData.raids[name].usedNeed = {}
        swLootsData.raids[name].instances = {}
        swLootsData.raids[name].date = date("%Y %b %d")
        self:Print("Created raid: " .. name)
    end
end

function swLoots:SummarizeRaid()
    if swLootsData.currentRaid == nil then 
        self:Print("You are not currently tracking a raid.") 
        --TODO: Isn't there a system function that prints this?
        --      For that matter, haven't I got something that replaces this outright?
       	for instanceIndex = 1, numInstances do
            local name, ID, remaining = GetSavedInstanceInfo(instanceIndex)
            if name == GetZoneText() then
                self:Print("  Your " .. name .. " raid ID is: " .. ID)
            end
        end
        return 
    end
    self:Communicate("Currently active raid: " .. swLootsData.currentRaid)
    local myRaid = swLootsData.raids[swLootsData.currentRaid]
    
    if myRaid.date ~= nil then self:Communicate("Created on: " .. myRaid.date) end
    self:Communicate("Awarded gear:")
    --for i,j in pairs(swLootsData.raids[swLootsData.currentRaid].loot) do
    for i,j in pairs(myRaid.loot) do
        --self:Communicate("   " .. i .. " -- " .. j)
        self:Communicate("   " .. j.item .. " -- " .. j.winner)
    end
    self:Communicate(" ")
    self:Communicate("Needs used:")
    --for i,j in pairs(swLootsData.raids[swLootsData.currentRaid].usedNeed) do
    for i,j in pairs(myRaid.usedNeed) do
        self:Communicate("   " .. i)
    end
    self:Communicate(" ")
    self:Communicate("Associated raids:")
    for _, i in ipairs(myRaid.instances) do
        self:Communicate("   " .. i)
    end
end

--I hate that this function exists
--Returns true if val is in table
function swLoots:ExistsInTable(table, val)
    for _, i in pairs(table) do
        if i == val then return true end
    end
    return false
end

swLoots.messageSyncRequest = 1
swLoots.messageSyncDenied = 2
swLoots.messageSyncBounceback = 3
swLoots.messageVersionRequest = 4
swLoots.messageVersionResponse = 5

function swLoots:SynchronizeRequest(str)
    local a,b,name,raid = string.find(str, "(%a+)%s+(.+)")
    if not(self:WhisperMessage(name, swLoots.messageSyncRequest, raid, swLootsData.raids[raid])) then
        self:Print("An error occured while attempting to synchronize data.")
    end
end

function swLoots:WhisperMessage(sender, message, data1, data2, data3)
    return self:SendCommMessage("WHISPER", sender, swLoots.version, message, data1, data2, data3)
end

function swLoots:Synchronize(sender, version, raid, data, bounceback)
    if version < swLoots.versionSyncCompatable then
        self:Print(sender .. " attempted to synchronize with an out of date version of swLoot.")
        self:WhisperMessage(sender, swLoots.messageSyncDenied, "Out of date.")
        return
    end
    if bounceback ~= true and swLootsData.trustedUsers[sender] ~= true then
        self:Print("An untrusted user [" .. sender .. "] has attempted to synchronize data.")
        self:Print("If this was in error, please use the command /swloot addTrustedUser " 
                   .. sender .. " to add this player to your trusted list.")
        self:WhisperMessage(sender, swLoots.messageSyncDenied, "Untrusted user")
        return
    end
    if swLootsData.raids[raid] == nil then
        --we do not know anything about this raid, so just copy his data
        swLootsData.raids[raid] = data
    else
        --we do know about this raid, so merge in loot and usedNeed
        local myRaid = swLootsData.raids[raid]
        --loot first
        for ID, loot in pairs(data.loot) do
            if myRaid.loot[ID] == nil then 
                self:Print("adding " .. loot.item .. " and awarding to " .. loot.winner .. ".")
                myRaid.loot[ID] = {}
                myRaid.loot[ID].item = loot.item
                myRaid.loot[ID].winner = loot.winner
            end
        end
        
        --now needs.  Assumption is that if either person believes a need has been used, then a need
        --has been used.  This means that if a need is revoked but only one player is made aware,
        --then a later synchronization will result in the need being reapplied.
        for player, used in pairs(data.usedNeed) do
            if used == true then myRaid.usedNeed[player] = true end
        end
        
        --associated instances
        --PS: I'm storing instance IDs in a retarded manner.  Why is this?  Beyond my generally
        --    lacking knowledge of LUA and its associated data structures, of course.
        --TODO: Find out if I can use a more intelligent structure...a set would be ideal
        for _, ID in pairs(data.instances) do
            if not swLoots:ExistsInTable(myRaid.instances, ID) then 
                table.insert(myRaid.instances, ID) 
            end
        end
        
        --Now send your data to the other player, so that both raids have the same information
        if bounceback ~= true then
            if not(self:WhisperMessage(sender, swLoots.messageSyncBounceback, raid, myRaid)) then
                self:Print("An error occured while attempting to synchronize data.")
            end
        end
    end
    self:Print("Recieved data from " .. sender .." about raid " .. raid .. ".")
end

function swLoots:ReceiveMessage(prefix, sender, distribution, version, messageType, raid, data)
    if messageType == swLoots.messageSyncRequest then
        swLoots:Synchronize(sender, version, raid, data, false)
    elseif messageType == swLoots.messageSyncDenied then
        self:Print("Your synchronization request was denied by " .. sender .. ".")
        self:Print("Reason given: " .. raid)
    elseif messageType == swLoots.messageSyncBounceback then
        swLoots:Synchronize(sender, version, raid, data, true)
    elseif messageType == swLoots.messageVersionRequest then
        self:WhisperMessage(sender, swLoots.messageVersionResponse)
    elseif messageType == swLoots.messageVersionResponse then
        self:Print(sender .. " is using version " .. version .. ".")
    else
        self:Print("An unknown message type [" .. messageType .. "] recieved by " .. sender .. ".")
        self:Print("Version number " .. version)
    end        
end

function swLoots:ValidateItemLink(item)
    return string.find(item, "^" .. ItemLinkPattern .. "$") ~= nil 
end

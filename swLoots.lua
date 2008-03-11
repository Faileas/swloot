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
        
        synchronize = {
            type = 'text',
            name = 'synchronize',
            desc = 'Synchronize raid data with another swLoot user',
            usage = '<player> <raid>',
            get = false,
            set = "Synchronize",
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
            end
        },
    }
}

swLoots = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceEvent-2.0", "AceComm-2.0")
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
swLootsData.nextLootID = 0

--The actual loot information.  The index is the raid ID
-- raids[ID].loot a table of the awarded loot.  Index is the item's name [not a link], 
--     and the value is the player who won the item
-- raids[ID].usedNeed is a table of people who have used need.  
--     usedNeed[BillyBob] == true indicates BillyBob has used his need; otherwise it is still free

--RETHOUGHTS
-- raids[ID].loot should be indexed by a loot ID.  The loot ID is addon-user's player name
--   concatinated with the nextLootID field.
-- Then there would be raids[ID].loot[ID'].item and raids[ID].loot[ID'].player
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

function swLoots:Award()
    if swLoots.currentWinner == nil then
        self:Print("Please use /swloot roll <item> before attempting to award loot")
        return
    end
    
    if swLootsData.currentRaid == nil then
        self:Print("You are not currently tracking a raid; loot distribution disabled.")
        return
    end
    
    local myRaid = swLootsData.raids[swLootsData.currentRaid]
    --swLootsData.raids[swLootsData.currentRaid].loot[swLoots.currentItem] = swLoots.currentWinner
    local lootID = UnitName("player") .. swLootsData.nextLootID
    myRaid.loot[lootID] = {}
    myRaid.loot[lootID].item = swLoots.currentItem
    myRaid.loot[lootID].winner = swLoots.currentWinner
    
    local msg = swLoots.currentWinner .. " awarded " .. swLoots.currentItem
    if swLoots.winnerRolledNeed == true and 
            --swLootsData.raids[swLootsData.currentRaid].usedNeed[swLoots.currentWinner] == nil then
            myRaid.usedNeed[swLoots.currentWinner] == nil then
        msg = msg .. " using a need"
        --swLootsData.raids[swLootsData.currentRaid].usedNeed[swLoots.currentWinner] = true
        myRaid.usedNeed[swLoots.currentWinner] = true
    end
    swLoots:Communicate(msg .. ".")
    swLootsData.nextLootID = swLootsData.nextLootID + 1
end

function swLoots:AwardItem(str)    
    local found,_, player, item, need = string.find(str, "^(%a+) (" .. ItemLinkPattern ..") (.*)")
    if found == nil then 
        found, _, player, item = string.find(str, "^(%a+) (" .. ItemLinkPattern ..")")
        need = "greed"
        if(found == nil) then self:Print("error") return end
    end
    self.currentItem = item
    self.currentWinner = player
    self.winnerRolledNeed = (need == "need")
    self:Award()
end

function swLoots:Communicate(str)
    if GetNumRaidMembers() > 0 then
        SendChatMessage(str, "RAID")
    elseif GetNumPartyMembers() > 0 then
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
        self:Print("Created raid: " .. name)
    end
end

function swLoots:SummarizeRaid()
    if swLootsData.currentRaid == nil then 
        self:Print("You are not currently tracking a raid.") 
        --TODO: Isn't there a system function that prints this?
       	for instanceIndex = 1, numInstances do
            local name, ID, remaining = GetSavedInstanceInfo(instanceIndex)
            if name == GetZoneText() then
                self:Print("  Your " .. name .. " raid ID is: " .. ID)
            end
        end
        return 
    end
    self:Communicate("Currently active raid: " .. swLootsData.currentRaid)
    self:Communicate("Awarded gear:")
    local myRaid = swLootsData.raids[swLootsData.currentRaid]
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
end

function swLoots:Synchronize(str)
    local a,b,name,raid = string.find(str, "(%a+)%s+(.+)")
    if not(self:SendCommMessage("WHISPER", name, raid, swLootsData.raids[raid])) then
        self:Print("An error occured while attempting to synchronize data.")
    end
end

function swLoots:ReceiveMessage(prefix, sender, distribution, raid, data, bounceback)
    if bounceback ~= true and swLootsData.trustedUsers[sender] ~= true then
        self:Print("An untrusted user [" .. sender .. "] has attempted to synchronize data.")
        self:Print("If this was in error, please use the command /swloot addTrustedUser " .. sender .. " to add this player to your trusted list.")
        return
    end
    if swLootsData.raids[raid] == nil then
        --we do not know anything about this raid, so just copy his data
        swLootsData.raids[raid] = data
    else
        --we do know about this raid, so merge in loot and usedNeed
        local myRaid = swLootsData.raids[raid]
        --loot first
        --[[for item, winner in pairs(data.loot) do
            if myRaid.loot[item] ~= nil then --this item already exists
                if myRaid.loot[item] ~= winner then --but doesn't belong to who we think it does
                    self:Print("Duplicate entry found...ignoring pending implementation of tracking multiple copies of loot")
                end
            else 
                self:Print("Adding " .. item .. " and awarding to " .. winner .. ".")
                for i = 1, #item do
                    self:Print(string.byte(item, i) .. " -- " .. string.char(string.byte(item, i)))
                end
                myRaid.loot[item] = winner
            end
        end--]]
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
        
        --Now send your data to the other player, so that both raids have the same information
        if bounceback ~= true then
            if not(self:SendCommMessage("WHISPER", sender, raid, myRaid, true)) then
                self:Print("An error occured while attempting to synchronize data.")
            end
        end
    end
    self:Print("Recieved data from " .. sender .." about raid " .. raid .. ".")
end

function swLoots:ValidateItemLink(item)
    return string.find(item, "^" .. ItemLinkPattern .. "$") ~= nil 
end

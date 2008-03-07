--[[CONCURRENCY]]--

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
    }
}

swLoots = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceEvent-2.0", "AceComm-2.0")
swLoots:RegisterChatCommand("/swloot", options)

swLootsData = {}
swLootsData.trustedUsers = {}
swLootsData.raids = {}
swLootsData.loRoll = 1
swLootsData.hiRoll = 100
swLootsData.currentRaid = nil

swLoots.commPrefix = "swLoots"
swLootsData.trustedUsers = {}

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

swLootsData.raids = {}

swLootsData.loRoll = 1
swLootsData.hiRoll = 100
swLootsData.currentRaid = nil

function swLoots:OnInitialize()
    self:Print("swLoots successfully initialized.")
    self:SetCommPrefix(swLoots.commPrefix)
    self:RegisterComm(self.commPrefix, "WHISPER", "ReceiveMessage")
    
    self:RegisterEvent("UPDATE_INSTANCE_INFO")
end

function swLoots:UPDATE_INSTANCE_INFO(arg1)
    --TODO: FIGURE OUT IF I STILL WANT THIS FUNCTION TO EXIST
    --It was part of the "guess what instance ID I'm in" code, but I might not want that anymore
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

function swLoots:StateMachineThatDoesntSuck(state, need, greed)
    if state == swLoots.stateStartNeed then
        swLoots:Communicate("Need rolls for " .. swLoots.currentItem)
        self:ScheduleEvent(function() self:StateMachineThatDoesntSuck(swLoots.stateNeedCount, need, greed) end, 3)
    elseif state == swLoots.stateNeedCount then
        swLoots:Communicate(need)
        if need == 0 then state = swLoots.stateEvaluateNeed end
        self:ScheduleEvent(function() self:StateMachineThatDoesntSuck(state, need-1, greed) end, 1)
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
            self:ScheduleEvent(function() self:StateMachineThatDoesntSuck(swLoots.stateStartGreed, nil, greed) end, 3)
        end
    elseif state == swLoots.stateStartGreed then
        swLoots:Communicate("Greed rolls for " .. swLoots.currentItem)
        self:ScheduleEvent(function() self:StateMachineThatDoesntSuck(swLoots.stateGreedCount, nil, greed) end, 3)
    elseif state == swLoots.stateGreedCount then
        swLoots:Communicate(greed)
        if greed == 0 then state = swLoots.stateEvaluateGreed end
        self:ScheduleEvent(function() self:StateMachineThatDoesntSuck(state, nil, greed-1) end, 1)
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

function swLoots:StateMachine(state)
--TODO: Figure out if I was drunk when I wrote this function.  
--      http://www.parashift.com/c++-faq-lite/newbie.html#faq-29.11
    if state == 0 then
        swLoots:Communicate("Need rolls for " .. swLoots.currentItem)
        self:ScheduleEvent(function() self:StateMachine(1) end, 3)
    elseif state < 10 then
        swLoots:Communicate(10-state)
        self:ScheduleEvent(function() self:StateMachine(state + 1) end, 1)
    elseif state == 10 then
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
            self:ScheduleEvent(function() self:StateMachine(11) end, 3)
        end
    elseif state == 11 then
        swLoots:Communicate("Greed rolls for " .. swLoots.currentItem)
        self:ScheduleEvent(function() self:StateMachine(12) end, 3)
    elseif state < 16 then
        swLoots:Communicate(16-state)
        self:ScheduleEvent(function() self:StateMachine(state+1) end, 1)
    else
        local winner = swLoots:DetermineWinner()
        if winner ~= nil then
            swLoots:Communicate(winner .. " won " .. swLoots.currentItem .. " on a greed.")
            swLoots.currentWinner = winner
            swLoots.winnerRolledNeed = false
        else 
            swLoots:Communicate("Rolls over; nobody rolled.")
        end
        self:EndRoll()
    end
end

function swLoots:StartRoll(item)
    if swLootsData.currentRaid == nil then
        self:Print("Please start a raid before rolling for loot")
        return
    end
    self:RegisterEvent("CHAT_MSG_SYSTEM")
    swLoots.currentItem = item
    self:ResetLastRoll()
    --self:StateMachine(0)
    self:StateMachineThatDoesntSuck(swLoots.stateStartNeed, 10, 5)
end

function swLoots:StartGreed(item)
    if swLootsData.currentRaid == nil then
        self:Print("Please start a raid before rolling for loot")
        return
    end
    self:RegisterEvent("CHAT_MSG_SYSTEM")
    self.currentItem = item
    self:ResetLastRoll()
    --self:StateMachine(11)
    self:StateMachineThatDoesntSuck(swLoots.stateStartGreed, nil, 5)
end

function swLoots:EndRoll()
    self:UnregisterEvent("CHAT_MSG_SYSTEM")
    for k,v in pairs(swLoots.currentRollers) do
      self:Print(k .. " rolled " .. v)
    end
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
    
    swLootsData.raids[swLootsData.currentRaid].loot[swLoots.currentItem] = swLoots.currentWinner
    local msg = swLoots.currentWinner .. " awarded " .. swLoots.currentItem
    if swLoots.winnerRolledNeed == true and 
            swLootsData.raids[swLootsData.currentRaid].usedNeed[swLoots.currentWinner] == nil then
        msg = msg .. " using a need"
        swLootsData.raids[swLootsData.currentRaid].usedNeed[swLoots.currentWinner] = true
    end
    swLoots:Communicate(msg .. ".")
end

function swLoots:AwardItem(str)    
    if swLootsData.currentRaid == nil then
        self:Print("You are not currently tracking a raid; loot distribution disabled.")
        return
    end
    
    local found,_, player, item, need = string.find(str, "^(%a+) (" .. ItemLinkPattern ..") (.*)")
    if found == nil then 
        found, _, player, item = string.find(str, "^(%a+) (" .. ItemLinkPattern ..")")
        need = "greed"
        if(found == nil) then self:Print("error") return end
    end
    if need == "need" then 
        swLootsData.raids[swLootsData.currentRaid].usedNeed[player] = true 
    elseif need ~= "greed" then
        self:Print("Unrecognized text following item link")
        return
    end
    swLootsData.raids[swLootsData.currentRaid].loot[item] = player
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
        return 
    end
    self:Communicate("Currently active raid: " .. swLootsData.currentRaid)
    self:Communicate("Awarded gear:")
    for i,j in pairs(swLootsData.raids[swLootsData.currentRaid].loot) do
        self:Communicate("   " .. i .. " -- " .. j)
    end
    self:Communicate(" ")
    self:Communicate("Needs used:")
        for i,j in pairs(swLootsData.raids[swLootsData.currentRaid].usedNeed) do
        self:Communicate("   " .. i)
    end
end

function swLoots:Synchronize(str)
    local a,b,name,raid = string.find(str, "(%a+)%s+(.+)")
    if not(self:SendCommMessage("WHISPER", name, raid, swLootsData.raids[raid])) then
        self:Print("An error occured while attempting to synchronize data.")
    end
end

function swLoots:ReceiveMessage(prefix, sender, distribution, raid, data)
    if swLootsData.trustedUsers[sender] ~= true then
        self:Print("An untrusted user [" .. sender .. "] has attempted to synchronize data.")
        self:Print("If this was in error, please use the command /swloot addTrustedUser " .. sender .. " to add this player to your trusted list.")
        return
    end
    swLootsData.raids[raid] = data
    self:Print("Recieved data from " .. sender .." about raid " .. raid .. ".")
end

function swLoots:ValidateItemLink(item)
    return string.find(item, "^" .. ItemLinkPattern .. "$") ~= nil 
end
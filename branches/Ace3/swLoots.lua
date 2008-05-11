--TODO: The instanceID code in Award is really dumb
--Thoughts: Once intarweb work look up lua tables and see what functions are available

local ItemLinkPattern = "|c%x+|H.+|h%[.+%]|h|r"

local options = {
    name = "swLoot",
    handler = swLoots,
    type = 'group',
    args = {        
        roll = {
            type = "input",
            name = "Roll",
            desc = "Rolls for loot",
            usage = "<item>",
            get = false,
            set = function(info, str) return swLoots:StartRoll(str) end,
            pattern = ItemLinkPattern,
        },
        greed = {
            type = 'input',
            name = 'Greed',
            desc = 'Begin a greed roll',
            usage = '<item>',
            get = false,
            set = function(info, str) return swLoots:StartGreed(str) end,
            pattern = ItemLinkPattern
        },
        
        award = {
            type = 'execute',
            name = 'award',
            desc = 'Awards item to last winner',
            func = function(info) return swLoots:Award() end
        },
        
        summarize = {
            type = 'execute',
            name = 'SummarizeActive',
            desc = 'Summarizes the active raid',
            func = function(info) return swLoots:SummarizeRaid() end
        },
        synchronize = {
            type = 'input',
            name = 'Synchronize',
            desc = 'Synchronize raid data with another swLoot user',
            usage = '<player> <raid>',
            get = false,
            set = function(info, str) return swLoots:SynchronizeRequest(str) end,
            validate = function(info, str)
                local found, _, raid = string.find(str, "%a+%s+(.+)")
                if found == nil then
                    return "Bad input; usage: <player> <raid>"
                elseif swLootsData.raids[raid] == nil then
                    return "Unrecognized raid name"
                else
                    return true
                end
            end            
        },
        version = {
            type = 'input',
            name = 'Version',
            desc = 'Query swLoot version',
            get = false,
            set = function(info, name)
                if name:trim() == "" then
                    swLoots:Print("You are using swLoot version " .. swLoots.version)
                else
                    swLoots:WhisperMessage(name, "CommunicateVersionRequest")
                end
            end
        },
        raid = {
            name = 'Raid',
            desc = 'Functions for raid manipulation',
            type = 'group',
            args = {
                create = {
                    type = 'input',
                    name = 'raidCreate',
                    desc = 'Creates a fresh raid',
                    usage = '<name>',
                    get = false,
                    set = function(info, str) 
                        swLootsData.raids[str] = swLoots:CreateEmptyRaid()
                        swLoots:Print("Created raid: " .. str)
                    end,
                    validate = function(info, str) 
                        if str == "" then return "Enter a name for the new raid" end
                        if swLootsData.raids[str] ~= nil then 
                            return "Raid already exists; please delete or use a unique name"
                        end
                        return true
                    end
                },
                start = {
                    type = 'input',
                    name = 'StartRaid',
                    desc = 'Begins tracking a raid',
                    usage = '<name>',
                    get = false,
                    set = function(info, str)
                        if str:trim() == "" then
                            str = swLootsData.previousRaid
                        end
                        if swLootsData.raids[str] == nil then
                            swLootsData.raids[str] = swLoots:CreateEmptyRaid()
                        end
                        swLootsData.previousRaid = swLootsData.currentRaid
                        swLootsData.currentRaid = str
                        swLoots:Print("Now tracking " .. str)
                    end,
                    validate = function(info, str)
                        if swLootsData.currentRaid ~= nil then
                            return "Please finish tracking your current raid before starting a new one"
                        end
                        if str:trim() == "" and swLootsData.previousRaid == nil then
                            return "Please enter a raid name."
                        end
                        return true
                    end
                },
                stop = {
                    type = 'execute',
                    name = 'StopRaid',
                    desc = 'Stop tracking the current raid',
                    func = function(info)
                        if swLootsData.currentRaid == nil then
                            swLoots:Print("Not currently tracking any raid.")
                        else
                            swLootsData.previousRaid = swLootsData.currentRaid
                            swLootsData.currentRaid = nil
                            swLoots:Print("No longer tracking " .. swLootsData.previousRaid)
                        end
                    end
                },
                delete = {
                    type = 'input',
                    name = 'DeleteRaid',
                    desc = 'Delete a prior raid',
                    usage = '<name>',
                    get = false,
                    set = function(info, name) 
                        swLootsData.raids[name] = nil 
                        swLoots:Print("Deleted raid [" .. name .. "]")
                    end,
                    validate = function(info, name)
                        if swLootsData.raids[name] == nil then
                            return "Raid does not exist."
                        end
                        return true
                    end
                },
                list = {
                    type = 'execute',
                    name = 'ListRaids',
                    desc = 'List all known raids',
                    func = function(info)
                        swLoots:Print("Known raids: ")
                        for i,j in pairs(swLootsData.raids) do
                            swLoots:Print("    " .. i .. " [" .. date("%c", time(j.date)) .. "]")
                        end
                    end
                },
                rename = {
                    type = 'input',
                    name = 'Rename Raid',
                    desc = 'Renames an existing raid',
                    usage = '<old raid name> <new raid name>',
                    get = false,
                    set = function(info, str)
                        local found, _, old, new = string.find(str, "(%a+)%s+(.+)")
                        swLoots:Print("Changing raid [" .. old .. "] to [" .. new .. "]")
                        swLootsData.raids[new] = swLootsData.raids[old]
                        swLootsData.raids[old] = nil
                        if swLootsData.currentRaid == old then swLootsData.currentRaid = new end
                    end,
                    validate = function(info, str)
                        local found, _, old, new = string.find(str, "(%a+)%s+(.+)")
                        if found == nil then 
                            return "Incorrect usage [<old raid name> <new raid name>]"
                        elseif swLootsData[old] == nil then
                            return "Unrecognized raid name"
                        else
                            return true
                        end
                    end
                },
            }
        },
        debug = {
            type = 'group',
            name = 'DebugMenu',
            desc = 'Functions for debugging the addon',
            args = {
                output = {
                    type = 'select',
                    name = 'Output',
                    desc = 'Maximum chat level to print output to',
                    values = {raid = "raid", party = "party", chat = "chat"},
                    get = function(info) return swLoots.debug end,
                    set = function(info, value) swLoots.debug = value swLoots:Print(value) end
                },
                
                verbose = {
                    type = 'toggle',
                    name = 'Verbose output',
                    desc = 'Enables additional information to be printed',
                    get = function(info) return swLoots.verbose end,
                    set = function(info, value) swLoots.verbose = value end
                },
            }
        },
        trusted = {
            type = 'group',
            name = 'Trusted users menu',
            desc = 'Functions for manipulating the list of trusted users',
            args = {
                add = {
                    type = 'input',
                    name = 'Add Trusted User',
                    desc = 'Add a user to your trusted list',
                    usage = '<player>',
                    get = false,
                    set = function(info, name)
                        swLootsData.trustedUsers[string.lower(name)] = true
                        swLoots:Print(name .. " added to trusted user list.")
                    end
                },
                remove = {
                    type = 'input',
                    name = 'Remove Trusted User',
                    desc = 'Removes a user from your trusted list',
                    usage = '<player>',
                    get = false,
                    set = function(info, name)
                        swLootsData.trustedUsers[string.lower(name)] = nil
                        swLoots:Print(name .. " removed from trusted user list.")
                    end
                },
                list = {
                    type = 'execute',
                    name = 'List Trusted Users',
                    desc = 'Lists all users trusted for synchronization',
                    func = function(info)
                        for i,j in pairs(swLootsData.trustedUsers) do
                            swLoots:Print(i)
                        end
                    end
                },
            }
        },
        loot = {
            name = 'Loot manipulation',
            desc = 'Functions that directly manipulate loot distribution',
            type = 'group',
            args = {
                direct = {
                    type = 'input',
                    name = 'Award Direct',
                    desc = 'Award an item without regard to the previous roll',
                    usage = '<player> <item> [need|greed]',
                    get = false,
                    set = function(info, str) return swLoots:AwardItem(str) end
                },                
                need = {
                    type = 'input',
                    name = 'Change needs',
                    desc = 'Change the status of a player\'s need roll.',
                    usage = '<player> [true|false]',
                    get = false,
                    set = function(info, str) 
                        local _, _, player, need = string.find(str, "^(%a+)%s*(%a*)")
                        local myRaid = swLootsData.raids[swLootsData.currentRaid]
                        local myNeed = myRaid.usedNeed[player]
                        if need:trim() == "" then
                            if myNeed == nil then
                                myRaid.usedNeed[player] = {
                                    used = true,
                                    timestamp = swLoots:CreateTimestamp(myRaid)
                                }
                                swLoots:Print(player .. "'s need roll used.")
                            elseif myNeed.used == true then
                                myRaid.usedNeed[player] = {
                                    used = false,
                                    timestamp = swLoots:CreateTimestamp(myRaid)
                                }
                                swLoots:Print(player .. "'s need roll freed.")
                            else
                                myRaid.usedNeed[player] = {
                                    used = true,
                                    timestamp = swLoots:CreateTimestamp(myRaid)
                                }
                                swLoots:Print(player .. "'s need roll used.")
                            end
                        elseif need:lower() == "true" then
                            myRaid.usedNeed[player] = {
                                used = true,
                                timestamp = swLoots:CreateTimestamp(myRaid)
                            }
                            swLoots:Print(player .. "'s need roll used.")
                        elseif need:lower() == "false" then
                            myRaid.usedNeed[player] = {
                                used = false,
                                timestamp = swLoots:CreateTimestamp(myRaid)
                            }
                            swLoots:Print(player .. "'s need roll freed.")
                        else
                            swLoots:Print("Error " .. need)
                        end
                    end,
                    validate = function(info, str)
                        if swLootsData.currentRaid == nil then 
                            return "You are not tracking a raid."
                        end
                        local found, _, player, need = string.find(str, "^(%a+)%s*(%a*)")
                        if not found then return "Usage: <player> [true|false] ***" end
                        if need:trim() == "" or
                           need:lower() == "true" or
                           need:lower() == "false" then return true end
                        return "Usage: <player> [true|false]"
                    end
                },
                disqualify = {
                    type = 'input',
                    name = 'Disqualify Roll',
                    desc = 'Removes a roll from consideration',
                    usage = '<player>',
                    get = false,
                    set = function(info, str)
                        if swLoots.currentRollers[str] == nil then
                            swLoots:Print(str .. " did not roll.")
                            return
                        end
                        swLoots.currentRollers[str] = -1 -- (-1) prevents him from rolling again
                                                         -- if a roll is in progress
                        local msg = str .. " was disqualified. "
                        if swLoots.rollInProgress ~= true then 
                            local winner, winnerUnusedNeed = swLoots:DetermineWinner()
                            if winner == nil then
                                msg = msg .. " However, nobody else rolled."
                            elseif winner == winnerUnusedNeed or winnerUnusedNeed == nil then
                                msg = msg .. " The new winner is " .. winner .. "."
                            else
                                msg = msg .. " " .. winner .. " rolled highest, but "
                                          .. winnerUsedNeed .. " has a need roll remaining."
                            end
                        end
                        swLoots:Print(msg)
                    end
                },
            }
        },
    }
}

swLoots = LibStub("AceAddon-3.0"):NewAddon("swLoot", "AceConsole-3.0", "AceEvent-3.0", 
                                                     "AceComm-3.0", "AceTimer-3.0",
                                                     "AceSerializer-3.0")

swLoots.version = tonumber(strmatch("$Revision$", "%d+"))
swLoots.reqVersion = swLoots.version --Beta release; no talking with old betas

--Used by the aceComm library.  Do not change without a really good reason.
swLoots.commPrefix = "swLootsBeta"

--swLootsData is the structure that gets saved between sessions.  No new members should be added to 
--it unless you want them to be saved.  Single session data belongs in swLoots
swLootsData = {}

--A table of users trusted to automatically synchronize with.
--If trustedUsers[BillyBob] ~= true, then BillyBob is not a trusted user
swLootsData.trustedUsers = {}

--Basically the number of pieces of loot this account has awarded; used to ensure unique IDs while
--  synchronizing
swLootsData.nextLootID = 0

--The actual loot information.  The index is the raid ID
-- raids[ID].loot is a table of the awarded loot.  The index is made up of the player's name, and a
--                unique number; it isn't actually that important except when merging data
-- raids[ID].loot[ID'].item is the item's name
-- raids[ID].loot[ID'].player is the winner's name

--These fields are not yet used:
--  raids[ID].instances is an array of instance IDs that have been awarded loot
--  raids[ID].date is the date when the raid was started
--  raids[ID].offset is the time difference between the local clock and the 
--                   machine that created the raid
swLootsData.raids = {}

--These define the acceptable roll range.  Eventually, I should like to make this variable, hense
--their inclusion in the saved data
swLootsData.loRoll = 1
swLootsData.hiRoll = 100
swLootsData.currentRaid = nil
swLootsData.previousRaid = nil

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

--Indicates whether or not we are currently recording rolls
swLoots.recordingRolls = false

--Maximum level Communicate will print to
swLoots.debug = "raid"
swLoots.verbose = false

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

function swLoots:CreateEmptyRaid()
    local i = {}
    i.loot = {}
    i.usedNeed = {}
    i.instances = {}
    i.date = date("*t")
    i.offset = 0
    return i
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
    LibStub("AceConfig-3.0"):RegisterOptionsTable("swLoot", options, {"swloot"})
      
    self:RegisterComm(self.commPrefix)
    
    local str = swLoots:Serialize("TestFunction")
    self:TestFunction(select(3, self:Deserialize(str)))
    
    if swLootsData.currentRaid ~= nil then
        swLootsData.previousRaid = swLootsData.currentRaid
        swLootsData.currentRaid = nil
    end
    
    self:RegisterEvent("CHAT_MSG_SYSTEM")
    self:RegisterEvent("UPDATE_INSTANCE_INFO")
    self:Print("swLoots successfully initialized.")
    
end

function swLoots:TestFunction(arg1)
    swLoots:Print(arg1)
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
  if not swLoots.recordingRolls then 
    --We're rolling, but not recording rolls; somebody has rolled out of turn
    if swLoots.rollInProgress then
        self:Communicate("Your previous roll was out of turn and was not recorded by swLoots.  " ..
                         "Please roll again at the proper time; if you believe this to be in " ..
                         "error please discuss the situation with the Master Looter.", char)
    end
    return 
  end
  if (min == swLootsData.loRoll) and (max == swLootsData.hiRoll) then
    if(swLoots.currentRollers[char]) then
      self:Print(char .. " already rolled")
      self:Communicate("Roll ignored; Please limit yourself to one roll per item.", char)
    else
      swLoots.currentRollers[char] = roll
    end    
  else
    self:Print(char .. " rolled with a non-standard range [" .. min .. ", " .. max .. "]")
    self:Communicate("Roll ignored; The proper command is /roll " ..
                     swLootsData.loRoll .. "-" .. swLootsData.hiRoll, char)
  end
end

function swLoots:CHAT_MSG_SYSTEM(arg1, arg2)
    local start, stop, char, roll, min, max = string.find(arg2, "(%a+) rolls (%d+) %((%d+)-(%d+)%)")
    if(start ~= nil) then
      swLoots:RecordRoll(char, tonumber(roll), tonumber(min), tonumber(max))
    end
end

function swLoots:StateMachine(state, need, greed)
    if state == swLoots.stateStartNeed then
        self:Communicate("Need rolls for " .. swLoots.currentItem)
        self.recordingRolls = true
        self:ScheduleTimer(function() self:StateMachine(swLoots.stateNeedCount, need, greed) end, 3)
    elseif state == swLoots.stateNeedCount then
        swLoots:Communicate(need)
        if need == 0 then 
            state = self.stateEvaluateNeed 
            self.recordingRolls = false
        end
        self:ScheduleTimer(function() self:StateMachine(state, need-1, greed) end, 1)
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
            self:ScheduleTimer(function() self:StateMachine(swLoots.stateStartGreed, nil, greed) end, 2)
        end
    elseif state == swLoots.stateStartGreed then
        self:Communicate("Greed rolls for " .. swLoots.currentItem)
        self.recordingRolls = true
        self:ScheduleTimer(function() self:StateMachine(swLoots.stateGreedCount, nil, greed) end, 3)
    elseif state == swLoots.stateGreedCount then
        self:Communicate(greed)
        if greed == 0 then 
            state = swLoots.stateEvaluateGreed 
        end
        self:ScheduleTimer(function() self:StateMachine(state, nil, greed-1) end, 1)
    elseif state == swLoots.stateEvaluateGreed then
        self.recordingRolls = false
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
    self.currentItem = item
    self:ResetLastRoll()
    self.rollInProgress = true
    self:StateMachine(swLoots.stateStartGreed, nil, 5)
end

function swLoots:EndRoll()
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
        local myRaid = swLootsData.raids[swLootsData.currentRaid]
        --if swLootsData.raids[swLootsData.currentRaid].usedNeed[k] == nil and v > rollUnusedNeed then
        if (myRaid.usedNeed[k] == nil or myRaid.usedNeed[k].used == false) and v > rollUnusedNeed then
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
            swLoots:Print("You are not inside an instance; are you sure you are tracking the correct raid?")
            swLoots:Print("If so, repeat the last command and this warning will go away.")
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
        swLoots:Print("This raid is not associated with this instance; did you mean to create a new raid?")
        swLoots:Print("If this is the correct raid, repeat the last command and this warning will go away.")
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
    myRaid.loot[lootID].deleted = false
    myRaid.loot[lootID].timestamp = swLoots:CreateTimestamp(myRaid)
    
    local msg = swLoots.currentWinner .. " awarded " .. swLoots.currentItem
    if swLoots.winnerRolledNeed == true and myRaid.usedNeed[swLoots.currentWinner] == nil then
        msg = msg .. " using a need"
        --myRaid.usedNeed[swLoots.currentWinner] = true
        myRaid.usedNeed[swLoots.currentWinner] = {}
        myRaid.usedNeed[swLoots.currentWinner].used = true
        myRaid.usedNeed[swLoots.currentWinner].timestamp = swLoots:CreateTimestamp(myRaid)
    end
    swLoots:Communicate(msg .. ".")
    swLootsData.nextLootID = swLootsData.nextLootID + 1
    
    --make sure we're associated with this instance
    local instanceID = swLoots:GetInstanceID()
    
    --if we're outside/not saved then don't attempt to associate
    if instanceID == nil or instanceID == 0 then return end
    
    swLoots.warningMultipleRaids = false    
    swLoots.warningNotInInstance = false
    
    local found = false
    for _, id in ipairs(myRaid.instances) do
        if id == instanceID then found = true end
    end
    if found == false then
        table.insert(myRaid.instances, instanceID)
    end
end

function swLoots:AwardItem(str)
    local found, _, player, item, need = string.find(str, "^(%a+)%s*(" .. ItemLinkPattern ..")%s*(%a*)")
    if found == nil then
        found, _, item, player, need = string.find(str, "^(" .. ItemLinkPattern .. ")%s*(%a+)%s*(%a*)")
        if found == nil then
            self:Print("Syntax error; awardDirect PlayerName Item [need|greed]")
            return
        end
    end
    if need:trim() == "" then need = "greed" end
    
    need = string.lower(need)
    if need ~= "need" and need ~= "greed" then
        self:Print("Syntax error; awardDirect PlayerName Item [need|greed]")
        return
    end
    
    self.currentItem = item
    self.currentWinner = player
    self.winnerRolledNeed = (need == "need")
    self:Award()
end

function swLoots:Communicate(str, player)
    if player ~= nil then
        SendChatMessage(str, "WHISPER", "Common", player)
    elseif swLoots.debug == "raid" and GetNumRaidMembers() > 0 then
        SendChatMessage(str, "RAID")
    elseif swLoots.debug ~= "chat" and GetNumPartyMembers() > 0 then
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
    
    if myRaid.date ~= nil then self:Communicate("Created on: " .. date("%c", time(myRaid.date))) end
    self:Communicate("Awarded gear:")
    --for i,j in pairs(swLootsData.raids[swLootsData.currentRaid].loot) do
    for i,j in pairs(myRaid.loot) do
        --self:Communicate("   " .. i .. " -- " .. j)
        local timestamp
        if j.timestamp < 0 then
            timestamp = SecondsToTime(-j.timestamp)
        else
            timestamp = SecondsToTime(j.timestamp)
        end
        if j.deleted == false then
            if swLoots.verbose then
                self:Communicate("   " .. j.item .. " -- " .. j.winner .. " [" .. timestamp .. "]")
            else
                self:Communicate("   " .. j.item .. " -- " .. j.winner)
            end
        elseif swLoots.verbose then
            self:Communicate("   [D] " .. j.item .. " -- " .. j.winner .. " [" .. timestamp .. "]")
        end
    end
    self:Communicate(" ")
    self:Communicate("Needs used:")
    --for i,j in pairs(swLootsData.raids[swLootsData.currentRaid].usedNeed) do
    for i,j in pairs(myRaid.usedNeed) do
        if j.used == true then
            if swLoots.verbose then
                local timestamp
                if j.timestamp < 0 then
                    timestamp = SecondsToTime(-j.timestamp)
                else
                    timestamp = SecondsToTime(j.timestamp)
                end
                self:Communicate("   " .. i .. " [" .. timestamp .. "]")
            else
                self:Communicate("   " .. i)
            end
        end
    end
    if swLoots.verbose then
        self:Communicate(" ")
        self:Communicate("Associated raids:")
        for _, i in ipairs(myRaid.instances) do
            self:Communicate("   " .. i)
        end
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

function swLoots:SynchronizeRequest(str)
    local a,b,name,raid = string.find(str, "(%a+)%s+(.+)")
    if not self:WhisperMessage(name, "CommunicateSyncRequest", 
                               self.version, self.reqVersion, raid, swLootsData.raids[raid], time()) then
        self:Print("An error occured while attempting to synchronize data.")
    end
end

function swLoots:OnCommReceived(prefix, message, group, sender)
    self:ParseCommunication(sender, group, select(2, self:Deserialize(message)))
end

function swLoots:ParseCommunication(sender, group, command, ...)
    if self[command] == nil then
        self:Print("An unknown message type [" .. command .. "] recieved by " .. sender .. ".")
        return
    end
    
    self[command](self, sender, group, ...)
end

function swLoots:CommunicateSyncRequest(sender, group, version, reqVersion, raidName, raidData, time)
    if version < swLoots.reqVersion then
        self:Print(sender .. " attempted to synchronize with an out of date version of swLoot.")
        self:WhisperMessage(sender, "CommunicateSyncDenied", "Target version out of date.")
        return
    end
    if swLoots.version < reqVersion then
        self:Print(sender .. " attempted to synchronize with a more recent version of swLoot.")
        self:WhisperMessage(sender, "CommunicateSyncDenied", "Target version more recent.")
        return
    end
    self:Synchronize(sender, raidName, raidData, time, false)
end

function swLoots:CommunicateSyncDenied(sender, group, reason)
        self:Print("Your synchronization request was denied by " .. sender .. ".")
        self:Print("Reason given: " .. reason)
end

function swLoots:CommunicateSyncBounceback(sender, group, raidName, raidData, time)
    self:Synchronize(sender, raidName, raidData, time, true)
end

function swLoots:CommunicateVersionRequest(sender, group)
    self:WhisperMessage(sender, "CommunicateVersionResponse", self.version)
end

function swLoots:CommunicateVersionResponse(sender, group, version)
        self:Print(sender .. " is using version " .. version .. ".")
end

function swLoots:WhisperMessage(sender, message, ...)
    self:SendCommMessage(self.commPrefix, self:Serialize(message, ...), "WHISPER", sender)
    return true --I don't think SendCommMessage has a return value anymore
end

function swLoots:Synchronize(sender, raid, data, timez, bounceback)
    if bounceback ~= true and swLootsData.trustedUsers[string.lower(sender)] ~= true then
        self:Print("An untrusted user [" .. sender .. "] has attempted to synchronize data.")
        self:Print("If this was in error, please use the command /swloot addTrusted " 
                   .. sender .. " to add this player to your trusted list.")
        self:WhisperMessage(sender, "CommunicateSyncDenied", "Untrusted user")
        return
    end
    if swLootsData.raids[raid] == nil then
        --we do not know anything about this raid, so just copy his data
        swLootsData.raids[raid] = data
        
        --calculate an appropriate offset
        --otherOffset = otherTimeWhenCreated - data.time
        --myOffset = myTimeWhenCreated - data.time
        --tmpOffset = myTime - otherTime
        --date.time + otherOffset + tmpOffset = myTimeWhenCreated
        --myOffset = otherOffset + tmpOffset
        swLootsData.raids[raid].offset = data.offset + (time() - timez)
    else
        --we do know about this raid, so merge in loot and usedNeed
        local myRaid = swLootsData.raids[raid]
        --loot first
        for ID, loot in pairs(data.loot) do
            local myLoot = myRaid.loot[ID]
            if myLoot == nil then 
                self:Print("adding " .. loot.item .. " and awarding to " .. loot.winner .. ".")
                myRaid.loot[ID] = {}
                myRaid.loot[ID].item = loot.item
                myRaid.loot[ID].winner = loot.winner
                myRaid.loot[ID].timestamp = loot.timestamp
                myRaid.loot[ID].deleted = loot.deleted
            elseif myLoot.deleted ~= loot.deleted then
                if myLoot.timestamp < loot.timestamp then
                    myLoot.deleted = loot.deleted
                end
            else
                if myLoot.timestamp > loot.timestamp then
                    myLoot.timestamp = loot.timestamp
                end
            end
        end
        
        --now needs.  Assumption is that the more recent timestamp is the accurate one
        for player, need in pairs(data.usedNeed) do
            --need is a table [used, timestamp]
            --  if used and myUsed are different
            --     if myTimestamp > data.timestamp copy over data
            --  otherwise if myTimestamp < data.timestamp copy over timestamp
            local myNeed = myRaid.usedNeed[player]
            if myNeed == nil then
                myRaid.usedNeed[player] = need
            elseif myNeed.used ~= need.used then
                if myNeed.timestamp < need.timestamp then
                    myRaid.usedNeed[player] = need
                end
            elseif myNeed.timestamp > need.timestamp then
                myNeed.timestamp = need.timestamp
            end
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
            if not(self:WhisperMessage(sender, "CommunicateSyncBounceback", raid, myRaid, time())) then
                self:Print("An error occured while attempting to synchronize data.")
            end
        end
    end
    self:Print("Recieved data from " .. sender .." about raid " .. raid .. ".")
end

function swLoots:ValidateItemLink(item)
    return string.find(item, "^" .. ItemLinkPattern .. "$") ~= nil 
end

function swLoots:CreateTimestamp(raid)
    return raid.offset - (time() - time(raid.date))
end
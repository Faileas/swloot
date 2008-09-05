--Pokie pokie
local ItemLinkPattern = "|c%x+|H.+|h%[.+%]|h|r"

local options = {
    name = "swLoot",
    handler = swLoot,
    type = 'group',
    args = {        
        roll = {
            type = "input",
            name = "Roll",
            desc = "Rolls for loot",
            order = 1,
            usage = "<item>",
            get = false,
            set = function(info, str) return swLoot:StartRoll(str) end,
            pattern = ItemLinkPattern,
        },
        greed = {
            type = 'input',
            name = 'Greed Roll',
            desc = 'Begin a greed roll',
            order = 2,
            usage = '<item>',
            get = false,
            set = function(info, str) return swLoot:StartGreed(str) end,
            pattern = ItemLinkPattern
        },
        
        award = {
            type = 'execute',
            name = 'Award Loot',
            desc = 'Awards item to last winner',
            order = 3,
            func = function(info) return swLoot:Award() end
        },
        
        summarize = {
            type = 'execute',
            name = 'SummarizeActive',
            desc = 'Summarizes the active raid',
            order = 4,
            func = function(info) return swLoot:SummarizeRaid() end
        },
        synchronize = {
            type = 'input',
            name = 'Synchronize',
            desc = 'Synchronize raid data with another swLoot user',
            usage = '<player> <raid>',
            order = 5,
            get = false,
            set = function(info, str) return swLoot:SynchronizeRequest(str) end,
            validate = function(info, str)
                local found, _, raid = string.find(str, "%a+%s+(.+)")
                if found == nil then
                    return "Bad input; usage: <player> <raid>"
                elseif swLootData.raids[raid] == nil then
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
            order = 6,
            get = false,
            set = function(info, name)
                if name:trim() == "" then
                    swLoot:Print("You are using swLoot version " .. swLoot.version)
                else
                    swLoot:WhisperMessage(name, "CommunicateVersionRequest")
                end
            end
        },
        config = {
            type = 'group',
            name = 'Config',
            desc = 'Configuration options',
            order = 7,
            args = {
                showGUI = {
                    type = 'select',
                    name = 'Show GUI',
                    desc = 'Specify when to show the loot interface',
                    values = {never = 'never', whenML = 'whenML', always = 'always'},
                    get = function(info) return swLootData.showGUI end,
                    set = function(info, value) 
                        swLootData.showGUI = value
                        swLoot:Print("Show GUI: " .. value)
                    end
                },
            }
        },
        raid = {
            name = 'Raid',
            desc = 'Functions for raid manipulation',
            type = 'group',
            order = 8,
            args = {
                create = {
                    type = 'input',
                    name = 'raidCreate',
                    desc = 'Creates a fresh raid',
                    usage = '<name>',
                    get = false,
                    set = function(info, str) 
                        swLootData.raids[str] = swLoot:CreateEmptyRaid()
                        swLoot:Print("Created raid: " .. str)
                    end,
                    validate = function(info, str) 
                        if str == "" then return "Enter a name for the new raid" end
                        if swLootData.raids[str] ~= nil then 
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
                            str = swLootData.previousRaid
                        end
                        if swLootData.raids[str] == nil then
                            swLootData.raids[str] = swLoot:CreateEmptyRaid()
                        end
                        swLootData.previousRaid = swLootData.currentRaid
                        swLootData.currentRaid = str
                        swLoot:Print("Now tracking " .. str)
                    end,
                    validate = function(info, str)
                        if swLootData.currentRaid ~= nil then
                            return "Please finish tracking your current raid before starting a new one"
                        end
                        if str:trim() == "" and swLootData.previousRaid == nil then
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
                        if swLootData.currentRaid == nil then
                            swLoot:Print("Not currently tracking any raid.")
                        else
                            swLootData.previousRaid = swLootData.currentRaid
                            swLootData.currentRaid = nil
                            swLoot:Print("No longer tracking " .. swLootData.previousRaid)
                            if swLoot.currentWinner ~= nil then
                                swLoot:Print("A previously unawarded roll was discarded.")
                            end
                            swLoot:ResetLastRoll()
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
                        swLootData.raids[name] = nil 
                        swLoot:Print("Deleted raid [" .. name .. "]")
                    end,
                    validate = function(info, name)
                        if swLootData.raids[name] == nil then
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
                        swLoot:Print("Known raids: ")
                        for i,j in pairs(swLootData.raids) do
                            swLoot:Print("    " .. i .. " [" .. date("%c", time(j.date)) .. "]")
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
                        swLoot:Print("Changing raid [" .. old .. "] to [" .. new .. "]")
                        swLootData.raids[new] = swLootData.raids[old]
                        swLootData.raids[old] = nil
                        if swLootData.currentRaid == old then swLootData.currentRaid = new end
                    end,
                    validate = function(info, str)
                        local found, _, old, new = string.find(str, "(%a+)%s+(.+)")
                        if found == nil then 
                            return "Incorrect usage [<old raid name> <new raid name>]"
                        elseif swLootData[old] == nil then
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
            order = 12,
            args = {
                output = {
                    type = 'select',
                    name = 'Output',
                    desc = 'Maximum chat level to print output to',
                    values = {raid = "raid", party = "party", chat = "chat"},
                    get = function(info) return swLoot.debug end,
                    set = function(info, value) swLoot.debug = value swLoot:Print(value) end
                },
                
                verbose = {
                    type = 'toggle',
                    name = 'Verbose output',
                    desc = 'Enables additional information to be printed',
                    get = function(info) return swLoot.verbose end,
                    set = function(info, value) 
                        swLoot:Print("Verbose mode: " .. tostring(value))
                        swLoot.verbose = value 
                    end
                },
                
                summarize = {
                    type = 'execute',
                    name = 'Private Summary',
                    desc = 'Prints a private raid summary',
                    func = function(info) 
                        local olddebug = swLoot.debug
                        swLoot.debug = "chat"
                        swLoot:SummarizeRaid()
                        swLoot.debug = olddebug
                    end
                }
            }
        },
        trusted = {
            type = 'group',
            name = 'Trusted users menu',
            desc = 'Functions for manipulating the list of trusted users',
            order = 11,
            args = {
                add = {
                    type = 'input',
                    name = 'Add Trusted User',
                    desc = 'Add a user to your trusted list',
                    usage = '<player>',
                    get = false,
                    set = function(info, name)
                        swLootData.trustedUsers[string.lower(name)] = true
                        swLoot:Print(name .. " added to trusted user list.")
                    end
                },
                remove = {
                    type = 'input',
                    name = 'Remove Trusted User',
                    desc = 'Removes a user from your trusted list',
                    usage = '<player>',
                    get = false,
                    set = function(info, name)
                        swLootData.trustedUsers[string.lower(name)] = nil
                        swLoot:Print(name .. " removed from trusted user list.")
                    end
                },
                list = {
                    type = 'execute',
                    name = 'List Trusted Users',
                    desc = 'Lists all users trusted for synchronization',
                    func = function(info)
                        for i,j in pairs(swLootData.trustedUsers) do
                            swLoot:Print(i)
                        end
                    end
                },
            }
        },
        loot = {
            name = 'Loot manipulation',
            desc = 'Functions that directly manipulate loot distribution',
            type = 'group',
            order = 9,
            args = {
                direct = {
                    type = 'input',
                    name = 'Award Direct',
                    desc = 'Award an item without regard to the previous roll',
                    usage = '<player> <item> [need|greed]',
                    get = false,
                    set = function(info, str) return swLoot:AwardItem(str) end
                },                
                need = {
                    type = 'input',
                    name = 'Change needs',
                    desc = 'Change the status of a player\'s need roll.',
                    usage = '<player> [true|false]',
                    get = false,
                    set = function(info, str) 
                        local _, _, player, need = string.find(str, "^(%a+)%s*(%a*)")
                        local myRaid = swLootData.raids[swLootData.currentRaid]
                        player = swLoot:FindMain(player)
                        local myNeed = myRaid.usedNeed[player]
                        if need:trim() == "" then
                            if myNeed == nil then
                                myRaid.usedNeed[player] = {
                                    used = true,
                                    timestamp = swLoot:CreateTimestamp(myRaid)
                                }
                                swLoot:Print(player .. "'s need roll used.")
                            elseif myNeed.used == true then
                                myRaid.usedNeed[player] = {
                                    used = false,
                                    timestamp = swLoot:CreateTimestamp(myRaid)
                                }
                                swLoot:Print(player .. "'s need roll freed.")
                            else
                                myRaid.usedNeed[player] = {
                                    used = true,
                                    timestamp = swLoot:CreateTimestamp(myRaid)
                                }
                                swLoot:Print(player .. "'s need roll used.")
                            end
                        elseif need:lower() == "true" then
                            myRaid.usedNeed[player] = {
                                used = true,
                                timestamp = swLoot:CreateTimestamp(myRaid)
                            }
                            swLoot:Print(player .. "'s need roll used.")
                        elseif need:lower() == "false" then
                            myRaid.usedNeed[player] = {
                                used = false,
                                timestamp = swLoot:CreateTimestamp(myRaid)
                            }
                            swLoot:Print(player .. "'s need roll freed.")
                        else
                            swLoot:Print("Error " .. need)
                        end
                    end,
                    validate = function(info, str)
                        if swLootData.currentRaid == nil then 
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
                        if swLoot.currentRollers[str] == nil then
                            swLoot:Print(str .. " did not roll.")
                            return
                        end
                        swLoot.currentRollers[str] = -1 -- (-1) prevents him from rolling again
                                                         -- if a roll is in progress
                        local msg = str .. " was disqualified. "
                        if swLoot.rollInProgress ~= true then 
                            local winner, winnerUnusedNeed = swLoot:DetermineWinner()
                            if winner == nil then
                                msg = msg .. " However, nobody else rolled."
                            elseif winner == winnerUnusedNeed or winnerUnusedNeed == nil then
                                msg = msg .. " The new winner is " .. winner .. "."
                            else
                                msg = msg .. " " .. winner .. " rolled highest, but "
                                          .. winnerUsedNeed .. " has a need roll remaining."
                            end
                        end
                        swLoot:Print(msg)
                    end
                },
            }
        },
        alts = {
            name = 'Alt manipulation',
            desc = 'Functions that associate alts with mains',
            type = 'group',
            order = 10,
            args = {
                list = {
                    name = 'List Alts',
                    desc = 'List the mains for each member of the current party',
                    type = 'execute',
                    func = function(info)
                        local name
                        if GetNumRaidMembers() > 0 then
                            for i = 1, 40 do
                                name = GetRaidRosterInfo(i)
                                if name ~= nil then
                                    swLoot:Print(name .. " --> " .. swLoot:FindMain(name))
                                end
                            end
                        elseif GetNumPartyMembers() > 0 then
                            name = UnitName("player")
                            swLoot:Print(name .. " --> " .. swLoot:FindMain(name))
                            for i = 1, 4 do
                                name = UnitName("party" .. i)
                                if name ~= nil then
                                    swLoot:Print(name .. " --> " .. swLoot:FindMain(name))
                                end
                            end
                        else
                            name = UnitName("player")
                            swLoot:Print(name .. " --> " .. swLoot:FindMain(name))
                        end
                    end
                },
                temp = {
                    type = 'group',
                    name = 'Temporary alts',
                    desc = 'Functions for assigning an alt for a single raid',
                    args = {
                        set = {
                            type = 'input',
                            name = 'Set temporary alt',
                            desc = 'Sets an alt-main association for a single raid',
                            usage = '<alt name> <main name>',
                            get = false,
                            set = function(info, str)
                                if swLootData.currentRaid == nil then
                                    swLoot:Print("You are not currently tracking a raid.")
                                    return
                                end
                                local _, _, alt, main = string.find(str, "^(%a+)%s*(%a+)$")
                                if alt == nil then
                                    swLoot:Print("Unrecognized string [" .. str .."]")
                                end
                                swLootData.raids[swLootData.currentRaid].mains[alt] = main
                            end
                        },
                        clear = {
                            type = 'input',
                            name = 'Clear temporary alt',
                            desc = 'Removes the association between an alt and a main',
                            usage = '<alt name>',
                            get = false,
                            set = function(info, str)
                                if swLootData.currentRaid == nil then
                                    swLoot:Print("You are not currently tracking a raid.")
                                    return
                                end
                                local myRaid = swLootData.raids[swLootData.currentRaid]
                                if myRaid.mains[alt] == nil then
                                    swLoot:Print(alt .. " has not been assigned a main.")
                                    return
                                end
                                myRaid.mains[alt] = nil
                            end
                        }
                    }                    
                },
                permanent = {
                    type = 'group',
                    name = 'Permanent alts',
                    desc = 'Functions for assigning alts across all raids',
                    args = {
                        set = {
                            name = 'Set permanent alt',
                            desc = 'Sets an alt that spans all future raids',
                            type = 'input',
                            usage = '<alt name> <main name>',
                            get = false,
                            set = function(info, str)
                                local _, _, alt, main = string.find(str, "^(%a+)%s*(%a+)$")
                                if alt == nil then
                                    swLoot:Print("Unrecognized string [" .. str .."]")
                                end
                                if swLootData.mains[alt] ~= nil then
                                    swLoot:Print(alt .."'s main changed from " 
                                                     .. swLootData.mains[alt] .. " to " 
                                                     .. main .. ".")
                                else
                                    swLoot:Print(alt .. "'s main set to " .. main .. ".")
                                end
                                swLootData.mains[alt] = main
                            end
                        },
                        clear = {
                            name = 'Clear permanent alt',
                            desc = 'Removes the association between an alt and a main',
                            type = 'input',
                            usage = '<alt name>',
                            get = false,
                            set = function(info, str)
                                if swLootData.mains[alt] == nil then
                                    swLoot:Print(alt .. " has not been assigned a main.")
                                    return
                                end
                                swLoot:Print(alt .. "'s main cleared.")
                                swLootData.mains[alt] = nil
                            end
                        }
                    }
                }
            }
        }
    }
}

swLoot = LibStub("AceAddon-3.0"):NewAddon("swLoot", "AceConsole-3.0", "AceEvent-3.0", 
                                                    "AceComm-3.0", "AceTimer-3.0",
                                                    "AceSerializer-3.0")

swLoot.version = tonumber(strmatch("$Revision$", "%d+"))
swLoot.reqVersion = swLoot.version --old: 34 

--Used by the aceComm library.  Do not change without a really good reason.
swLoot.commPrefix = "swLootBeta"

swLoot.altPattern = "%(Alt%)%s*(%a+)"

--This is information used by the roll tracker.  
--currentRollers[Player] is the roll made by Player
--currentWinner is the player who won the last successful roll.  Its value is undefined while a
--  roll is taking place.
swLoot.currentRollers = {}
swLoot.currentWinner = nil
swLoot.winnerRolledNeed = false

--Note to self: figure out how constants work.  In particular, does lua support Enums in any way?
swLoot.stateStartNeed = 0
swLoot.stateNeedCount = 1
swLoot.stateEvaluateNeed = 2
swLoot.stateStartGreed = 3
swLoot.stateGreedCount = 4
swLoot.stateEvaluateGreed = 5

--A simple locking mechanism to prevent two rolls from taking place at once.
swLoot.rollInProgress = false

--Indicates whether or not we are currently recording rolls
swLoot.recordingRolls = false

--Maximum level Communicate will print to
swLoot.debug = "raid"
swLoot.verbose = false

swLoot.warningMultipleRaids = false
swLoot.warningNotInInstance = false


function swLoot:InitializeSavedVariables()
    --swLootData is the structure that gets saved between sessions.  No new members should be added to 
    --it unless you want them to be saved.  Single session data belongs in swLoot
    if swLootData == nil then swLootData = {} end

    --A table of users trusted to automatically synchronize with.
    --If trustedUsers[BillyBob] ~= true, then BillyBob is not a trusted user
    if swLootData.trustedUsers == nil then swLootData.trustedUsers = {} end

    --Basically the number of pieces of loot this account has awarded; used to ensure unique IDs while
    --  synchronizing
    if swLootData.nextLootID == nil then swLootData.nextLootID = 0 end

    --The actual loot information.  The index is the raid ID
    -- raids[ID].loot is a table of the awarded loot.  The index is made up of the player's name, and a
    --                unique number; it isn't actually that important except when merging data
    -- raids[ID].loot[ID'].item is the item's name
    -- raids[ID].loot[ID'].player is the winner's name
    -- raids[ID].instances is an array of instance IDs that have been awarded loot
    -- raids[ID].date is the date when the raid was started
    -- raids[ID].offset is the time difference between the local clock and the 
    --                  machine that created the raid
    -- raids[ID].mains[Name] is the main that is associated with Name.  All 
    if swLootData.raids == nil then swLootData.raids = {} end

    --These define the acceptable roll range.  Eventually, I should like to make this variable, hense
    --their inclusion in the saved data
    if swLootData.loRoll == nil then swLootData.loRoll = 1 end
    if swLootData.hiRoll == nil then swLootData.hiRoll = 100 end
    --swLootData.currentRaid = nil
    --swLootData.previousRaid = nil

    --The global alt list.  
    if swLootData.mains == nil then swLootData.mains = {} end
    
    --Do we want to see the loot panel?
    if swLootData.showGUI == nil then swLootData.showGUI = 'whenML' end
end

--I'll bet there's a better name for this function.  It locates a raid that matches the isntance ID
--for the instance you're in.
function swLoot:FindRaid()
    currentID = swLoot:GetInstanceID()
    
    for name, raid in pairs(swLootData.raids) do
        if raid.instances == nil then raid.instances = {} end
        for i, v in ipairs(raid.instances) do
            if v == currentID then return name end
        end
    end
    
    return nil
end

function swLoot:CreateEmptyRaid()
    local i = {}
    i.loot = {}
    i.usedNeed = {}
    i.instances = {}
    i.date = date("*t")
    i.offset = 0
    i.mains = {}
    return i
end

--Returns nil if you are not in an instance; 0 if you are not saved; the instance ID otherwise
--Here's hoping 0 is not a valid instance ID
function swLoot:GetInstanceID()
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

function swLoot:OnInitialize()
    LibStub("AceConfig-3.0"):RegisterOptionsTable("swLoot", options, {"swloot"})
      
    self:RegisterComm(self.commPrefix)
    
    swLoot:InitializeSavedVariables()
    
    if swLootData.currentRaid ~= nil then
        swLootData.previousRaid = swLootData.currentRaid
        swLootData.currentRaid = nil
    end
    
    self:RegisterEvent("VARIABLES_LOADED")
    self:RegisterEvent("CHAT_MSG_SYSTEM")
    self:RegisterEvent("UPDATE_INSTANCE_INFO")
    self:Print("swLoot successfully initialized.")
end

function swLoot:VARIABLES_LOADED()
    local OpenRolls = LibStub("AceAddon-3.0"):GetAddon("OpenRolls", true)
    if not OpenRolls then 
        self:RegisterEvent("LOOT_OPENED")
        self:RegisterEvent("LOOT_CLOSED")
        self:RegisterEvent("LOOT_SLOT_CLEARED")
    else
        OpenRolls:RegisterLootWindow(swLoot)
        OpenRolls:AddSummaryHook("swLootUsedNeed", true, function(name, roll)
            if swLootData.currentRaid == nil then return end
            local myRaid = swLootData.raids[swLootData.currentRaid]
            local need = myRaid.usedNeed[swLoot:FindMain(name)]
            local str
            if need == nil or need == false then
                str = name .. " has not used a need roll."
            else
                str = name .. " has used a need roll."
            end
            return str, 1, 1, 1
        end)
    end
end

function swLoot:UPDATE_INSTANCE_INFO(arg1)
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

function swLoot:RecordRoll(char, roll, min, max)
  if not swLoot.recordingRolls then 
    --We're rolling, but not recording rolls; somebody has rolled out of turn
    if swLoot.rollInProgress then
        self:Communicate("Your previous roll was out of turn and was not recorded by swLoot.  " ..
                         "Please roll again at the proper time; if you believe this to be in " ..
                         "error please discuss the situation with the Master Looter.", char)
    end
    return 
  end
  if (min == swLootData.loRoll) and (max == swLootData.hiRoll) then
    if(swLoot.currentRollers[char]) then
      self:Print(char .. " already rolled")
      self:Communicate("Roll ignored; Please limit yourself to one roll per item.", char)
    else
      swLoot.currentRollers[char] = roll
    end    
  else
    self:Print(char .. " rolled with a non-standard range [" .. min .. ", " .. max .. "]")
    self:Communicate("Roll ignored; The proper command is /roll " ..
                     swLootData.loRoll .. "-" .. swLootData.hiRoll, char)
  end
end

function swLoot:CHAT_MSG_SYSTEM(arg1, arg2)
    local start, stop, char, roll, min, max = string.find(arg2, "(%a+) rolls (%d+) %((%d+)-(%d+)%)")
    if(start ~= nil) then
      swLoot:RecordRoll(char, tonumber(roll), tonumber(min), tonumber(max))
    end
end

function swLoot:StateMachine(state, need, greed, callback)
    if state == swLoot.stateStartNeed then
        self:Communicate("Need rolls for " .. swLoot.currentItem)
        self.recordingRolls = true
        self:ScheduleTimer(function() self:StateMachine(swLoot.stateNeedCount, need, greed, callback) end, 3)
    elseif state == swLoot.stateNeedCount then
        swLoot:Communicate(need)
        if need == 0 then 
            state = self.stateEvaluateNeed 
            self.recordingRolls = false
        end
        self:ScheduleTimer(function() self:StateMachine(state, need-1, greed, callback) end, 1)
    elseif state == swLoot.stateEvaluateNeed then
        local winner, winnerUnusedNeed = swLoot:DetermineWinner()
        if winner ~= nil then
            if winner == winnerUnusedNeed or winnerUnusedNeed == nil then
                swLoot:Communicate(winner .. " won " .. swLoot.currentItem .. " on a need.")
                swLoot.currentWinner = winner
            else
                swLoot:Communicate(winner .. " rolled highest, but " ..
                                    winnerUnusedNeed .. " wins " .. 
                                    swLoot.currentItem .. " on a need.")
                swLoot.currentWinner = winnerUnusedNeed
            end
            swLoot.winnerRolledNeed = true
            if callback ~= nil then callback(swLoot.currentWinner, true) end
            swLoot:EndRoll()
        else 
            self:ScheduleTimer(function() self:StateMachine(swLoot.stateStartGreed, nil, greed, callback) end, 2)
        end
    elseif state == swLoot.stateStartGreed then
        self:Communicate("Greed rolls for " .. swLoot.currentItem)
        self.recordingRolls = true
        self:ScheduleTimer(function() self:StateMachine(swLoot.stateGreedCount, nil, greed, callback) end, 3)
    elseif state == swLoot.stateGreedCount then
        self:Communicate(greed)
        if greed == 0 then 
            state = swLoot.stateEvaluateGreed 
        end
        self:ScheduleTimer(function() self:StateMachine(state, nil, greed-1, callback) end, 1)
    elseif state == swLoot.stateEvaluateGreed then
        self.recordingRolls = false
        local winner = swLoot:DetermineWinner()
        if winner ~= nil then
            swLoot:Communicate(winner .. " won " .. swLoot.currentItem .. " on a greed.")
            swLoot.currentWinner = winner
            swLoot.winnerRolledNeed = false
            if callback ~= nil then callback(swLoot.currentWinner, false) end
        else 
            swLoot:Communicate("Rolls over; nobody rolled.")
        end
        self:EndRoll()
    else
        self:Print("Something's wrong: " .. state .. " -- " .. greed)
    end
end

function swLoot:StartRoll(item, callback)
    if swLoot.rollInProgress == true then
        self:Print("Another roll is in progress [" .. swLoot.currentItem .. "]; please wait for it to complete.")
        return
    elseif swLootData.currentRaid == nil then
        self:Print("Please start a raid before rolling for loot")
        PrintRecommendedRaid()
        return
    end
    swLoot.currentItem = item
    self:ResetLastRoll()
    swLoot.rollInProgress = true
    self:StateMachine(swLoot.stateStartNeed, 10, 5, callback)
end

function swLoot:StartGreed(item, duration, callback)
    if duration == nil then duration = 5 end
    if swLoot.rollInProgress == true then
        self:Print("Another roll is in progress [" .. swLoot.currentItem .. "]; please wait for it to complete.")
        return
    elseif swLootData.currentRaid == nil then
        self:Print("Please start a raid before rolling for loot")
        PrintRecommendedRaid()
        return
    end
    self.currentItem = item
    self:ResetLastRoll()
    self.rollInProgress = true
    self:StateMachine(swLoot.stateStartGreed, nil, duration, callback)
end

function swLoot:EndRoll()
    for k,v in pairs(swLoot.currentRollers) do
      self:Print(k .. " rolled " .. v)
    end
    self.rollInProgress = false
end

function swLoot:DetermineWinner()
    local winner = nil
    local roll = -1
    local winnerUnusedNeed = nil
    local rollUnusedNeed = -1
    for k,v in pairs(swLoot.currentRollers) do
        k = swLoot:FindMain(k)
        if v > roll then 
            winner = k 
            roll = v 
        end
        local myRaid = swLootData.raids[swLootData.currentRaid]
        --if swLootData.raids[swLootData.currentRaid].usedNeed[k] == nil and v > rollUnusedNeed then
        if (myRaid.usedNeed[k] == nil or myRaid.usedNeed[k].used == false) and v > rollUnusedNeed then
            winnerUnusedNeed = k
            rollUnusedNeed = v
        end
    end
    return winner, winnerUnusedNeed
end

--Prints out which raid is associated with the current instance ID
function PrintRecommendedRaid()
    local raidName = swLoot:FindRaid()
    if raidName ~= nil then 
        swLoot:Print("[" .. raidName .. "] is currently tracking this instance.")
    else
        swLoot:Print("No raid is currently tracking this instance.")
    end
end

--Return value is true if you are tracking a safe raid; otherwise, returns false
function swLoot:ValidateTrackedRaid()
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
        if swLoot.warningNotInInstance == false then
            swLoot:Print("You are not inside an instance; are you sure you are tracking the correct raid?")
            swLoot:Print("If so, repeat the last command and this warning will go away.")
            swLoot.warningNotInInstance = true
            return false
        else 
            return true
        end
    end
    
    --  If so, are we in an instance associated with our raid?
    local raidName = swLoot:FindRaid()
    if raidName == swLootData.currentRaid then 
        return true 
    elseif raidName ~= nil then    
        --  If not, are we in an instance associated with any raid?
        swLoot:Print("[" .. raidName .. "] is currently tracking this instance.")
        return false --I do not intend for this to be something you can circumvent
    end

    --  If not, are we associated with any instance?
    if #(swLootData.raids[swLootData.currentRaid].instances) == 0 then return true end
    
    -- We are associated with *an* instance, just not this one.
    if swLoot.warningMultipleRaids == false then
        swLoot:Print("This raid is not associated with this instance; did you mean to create a new raid?")
        swLoot:Print("If this is the correct raid, repeat the last command and this warning will go away.")
        swLoot.warningMultipleRaids = true
        return false
    else
        return true
    end
end

function swLoot:Award()
    if swLoot.currentWinner == nil then
        self:Print("Please use /swloot roll <item> before attempting to award loot")
        return
    end
    
    if swLootData.currentRaid == nil then
        self:Print("You are not currently tracking a raid; loot distribution disabled.")
        PrintRecommendedRaid()
        return
    end
        
    local myRaid = swLootData.raids[swLootData.currentRaid]
    
    if swLoot:ValidateTrackedRaid() == false then return end

    swLoot.currentWinner = swLoot:FindMain(swLoot.currentWinner)
    
    --swLootData.raids[swLootData.currentRaid].loot[swLoot.currentItem] = swLoot.currentWinner
    local lootID = UnitName("player") .. swLootData.nextLootID
    myRaid.loot[lootID] = {}
    myRaid.loot[lootID].item = swLoot.currentItem
    myRaid.loot[lootID].winner = swLoot.currentWinner
    myRaid.loot[lootID].deleted = false
    myRaid.loot[lootID].timestamp = swLoot:CreateTimestamp(myRaid)
    
    local msg = swLoot.currentWinner .. " awarded " .. swLoot.currentItem
    if swLoot.winnerRolledNeed == true and myRaid.usedNeed[swLoot.currentWinner] == nil then
        msg = msg .. " using a need"
        --myRaid.usedNeed[swLoot.currentWinner] = true
        myRaid.usedNeed[swLoot.currentWinner] = {}
        myRaid.usedNeed[swLoot.currentWinner].used = true
        myRaid.usedNeed[swLoot.currentWinner].timestamp = swLoot:CreateTimestamp(myRaid)
    end
    swLoot:Communicate(msg .. ".")
    swLootData.nextLootID = swLootData.nextLootID + 1
    
    swLoot:ResetLastRoll()
    
    --make sure we're associated with this instance
    local instanceID = swLoot:GetInstanceID()
    
    --if we're outside/not saved then don't attempt to associate
    if instanceID == nil or instanceID == 0 then return end
    
    swLoot.warningMultipleRaids = false    
    swLoot.warningNotInInstance = false
    
    local found = false
    for _, id in ipairs(myRaid.instances) do
        if id == instanceID then found = true end
    end
    if found == false then
        table.insert(myRaid.instances, instanceID)
    end
end

function swLoot:AwardItem(str)
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

function swLoot:Communicate(str, player)
    if player ~= nil then
        SendChatMessage(str, "WHISPER", "Common", player)
    elseif swLoot.debug == "raid" and GetNumRaidMembers() > 0 then
        SendChatMessage(str, "RAID")
    elseif swLoot.debug ~= "chat" and GetNumPartyMembers() > 0 then
        SendChatMessage(str, "PARTY")
    else
        self:Print(str)
    end
end

function swLoot:ResetLastRoll()
    swLoot.currentRollers = {}
    swLoot.currentWinner = nil
    swLoot.winnerRolledNeed = false
end

function swLoot:SummarizeRaid()
    if swLootData.currentRaid == nil then 
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
    self:Communicate("Currently active raid: " .. swLootData.currentRaid)
    local myRaid = swLootData.raids[swLootData.currentRaid]
    
    if myRaid.date ~= nil then self:Communicate("Created on: " .. date("%c", time(myRaid.date))) end
    self:Communicate("Awarded gear:")
    --for i,j in pairs(swLootData.raids[swLootData.currentRaid].loot) do
    for i,j in pairs(myRaid.loot) do
        if j.deleted == false then
            if swLoot.verbose then
                self:Communicate("   " .. j.item .. " -- " .. j.winner
                                 .. " [" .. date("%c", time(myRaid.date) + j.timestamp) .. "]")
            else
                self:Communicate("   " .. j.item .. " -- " .. j.winner)
            end
        elseif swLoot.verbose then
            self:Communicate("   [D] " .. j.item .. " -- " .. j.winner 
                             .. " [" .. date("%c", time(myRaid.date) + j.timestamp) .. "]")
        end
    end
    self:Communicate(" ")
    self:Communicate("Needs used:")
    --for i,j in pairs(swLootData.raids[swLootData.currentRaid].usedNeed) do
    for i,j in pairs(myRaid.usedNeed) do
        if j.used == true then
            if swLoot.verbose then
                self:Communicate("   " .. i 
                                 .. " [" .. date("%c", time(myRaid.date) + j.timestamp) .. "]")
            else
                self:Communicate("   " .. i)
            end
        end
    end
    if swLoot.verbose then
        self:Communicate(" ")
        self:Communicate("Associated raids:")
        for _, i in ipairs(myRaid.instances) do
            self:Communicate("   " .. i)
        end
    end
end

--I hate that this function exists
--Returns true if val is in table
function swLoot:ExistsInTable(table, val)
    for _, i in pairs(table) do
        if i == val then return true end
    end
    return false
end

function swLoot:SynchronizeRequest(str)
    local a,b,name,raid = string.find(str, "(%a+)%s+(.+)")
    if not self:WhisperMessage(name, "CommunicateSyncRequest", 
                               self.version, self.reqVersion, raid, swLootData.raids[raid], time()) then
        self:Print("An error occured while attempting to synchronize data.")
    end
end

function swLoot:OnCommReceived(prefix, message, group, sender)
    self:ParseCommunication(sender, group, select(2, self:Deserialize(message)))
end

function swLoot:ParseCommunication(sender, group, command, ...)
    if self[command] == nil then
        self:Print("An unknown message type [" .. command .. "] recieved by " .. sender .. ".")
        return
    end
    
    self[command](self, sender, group, ...)
end

function swLoot:CommunicateSyncRequest(sender, group, version, reqVersion, raidName, raidData, time)
    if version < swLoot.reqVersion then
        self:Print(sender .. " attempted to synchronize with an out of date version of swLoot.")
        self:WhisperMessage(sender, "CommunicateSyncDenied", "Target version out of date.")
        return
    end
    if swLoot.version < reqVersion then
        self:Print(sender .. " attempted to synchronize with a more recent version of swLoot.")
        self:WhisperMessage(sender, "CommunicateSyncDenied", "Target version more recent.")
        return
    end
    self:Synchronize(sender, raidName, raidData, time, false)
end

function swLoot:CommunicateSyncDenied(sender, group, reason)
        self:Print("Your synchronization request was denied by " .. sender .. ".")
        self:Print("Reason given: " .. reason)
end

function swLoot:CommunicateSyncBounceback(sender, group, raidName, raidData, time)
    self:Synchronize(sender, raidName, raidData, time, true)
end

function swLoot:CommunicateVersionRequest(sender, group)
    self:WhisperMessage(sender, "CommunicateVersionResponse", self.version)
end

function swLoot:CommunicateVersionResponse(sender, group, version)
        self:Print(sender .. " is using version " .. version .. ".")
end

function swLoot:WhisperMessage(sender, message, ...)
    self:SendCommMessage(self.commPrefix, self:Serialize(message, ...), "WHISPER", sender)
    return true --I don't think SendCommMessage has a return value anymore
end

function swLoot:Synchronize(sender, raid, data, timez, bounceback)
    if bounceback ~= true and swLootData.trustedUsers[string.lower(sender)] ~= true then
        self:Print("An untrusted user [" .. sender .. "] has attempted to synchronize data.")
        self:Print("If this was in error, please use the command /swloot trusted add " 
                   .. sender .. " to add this player to your trusted list.")
        self:WhisperMessage(sender, "CommunicateSyncDenied", "Untrusted user")
        return
    end
    if swLootData.raids[raid] == nil then
        --we do not know anything about this raid, so just copy his data
        swLootData.raids[raid] = data
        
        --calculate an appropriate offset
        --otherOffset = otherTimeWhenCreated - data.time
        --myOffset = myTimeWhenCreated - data.time
        --tmpOffset = myTime - otherTime
        --date.time + otherOffset + tmpOffset = myTimeWhenCreated
        --myOffset = otherOffset + tmpOffset
        swLootData.raids[raid].offset = data.offset + (time() - timez)
    else
        --we do know about this raid, so merge in loot and usedNeed
        local myRaid = swLootData.raids[raid]
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
            if not swLoot:ExistsInTable(myRaid.instances, ID) then 
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

function swLoot:ValidateItemLink(item)
    return string.find(item, "^" .. ItemLinkPattern .. "$") ~= nil 
end

function swLoot:GetGuildIndex(name)
    if not IsInGuild() then return 0 end
    for i = 1, GetNumGuildMembers(true) do
        if GetGuildRosterInfo(i) == name then return i end
    end
    return 0
end

function swLoot:FindMain(name)
    --Check raid mains, then global mains, then officer note
    if swLootData.currentRaid ~= nil then
        local mains = swLootData.raids[swLootData.currentRaid].mains
        if mains ~= nil and mains[name] ~= nil then
            return mains[name]
        end
    end
    
    mains = swLootData.mains
    if mains ~= nil and mains[name] ~= nil then
        return mains[name]
    end   
    
    local guildindex = swLoot:GetGuildIndex(name)
    if guildindex == 0 then return name end
    local note = select(8, GetGuildRosterInfo(guildindex))
    local alt = select(3, string.find(note, swLoot.altPattern))
    if alt == nil then alt = name end
    return alt
end

function swLoot:CreateTimestamp(raid)
    return (time() - time(raid.date)) - raid.offset
end

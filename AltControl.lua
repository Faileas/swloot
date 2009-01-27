local Addon = swLoot
if not Addon then return end
local Data = swLootData

local DEBUG = (LibStub("dzjrDebug", true) ~= nil)
local dprint = (DEBUG and print) or function(...) end

local altPattern = "%([Aa]lt%)%s*(%a+)"

local KnownAlts = {}

--returns the value i such that GetGuildRosterInfo(i) yields 'name', 
--  or 0 if the character is not in the current player's guild
local function GetGuildIndex(name)
    if not IsInGuild() then 
        return 0 
    end 
    for i = 1, GetNumGuildMembers(true) do 
        if GetGuildRosterInfo(i) == name then 
            return i 
        end 
    end 
    return 0 
end

--traces a chain of alts through the officer notes until a main is found, 
--   or a loop is formed.
--Returns the name of the main, or else nil if a loop has been found 
local function TraceAlt(name, trace)
    local index = GetGuildIndex(name)
    local note = select(8, GetGuildRosterInfo(index)) or ""
    local main = KnownAlts[name] or select(3, string.find(note, altPattern))
    if main == nil or main == name then return name end
    if trace[main] then return nil end
    trace[main] = true
    return TraceAlt(main, trace)
end

local function LookupAlt(tbl, name)
    local main = TraceAlt(name, {})
    if not main then
        print("A singular main for '" .. name .."' can not be identified.")
        KnownAlts[name] = name
        main = name
    end
    return main
end

local function AssignAlt(tbl, name, main)
    KnownAlts[name] = main
end

Addon.Alts = setmetatable({}, {__index = LookupAlt,
                               __newindex = AssignAlt})
Addon.Defaults.Alts = {}

function Addon:ResetAlts()
    dprint("Reseting alts")
    KnownAlts = {}
    for alt, main in pairs(Data.Alts) do
        KnownAlts[alt] = main
    end
end
do

local MAJOR, MINOR = "Countdown-1.0", 1
local Countdown = LibStub:NewLibrary(MAJOR, MINOR)

if not Countdown then return end -- No upgrade needed

local Timer = LibStub:GetLibrary("AceTimer-3.0")

local type = type

local ActiveIDs = {}

local function Callback(self, callback, arg)
    if type(callback) == "string" then
        self[callback](self, arg)
    else
        callback(arg)
    end
end

local function Complete(args)
    if not ActiveIDs[args.id] then return end
    ActiveIDs[args.id] = nil
    Callback(args.self, args.completed)
end

local function Tick(args)
    if not ActiveIDs[args.id] then return end
    
    Callback(args.self, args.display, args.duration)
    
    if args.duration == 0 then
        Timer:ScheduleTimer(Complete, args.delay, args)
    else    
        args.duration = args.duration - 1    
        Timer:ScheduleTimer(Tick, 1, args)
    end
end

local count = 0

local function ValidateCallback(self, callback, source, callbackname)
	if type(callback) ~= "string" and type(callback) ~= "function" then 
		error(MAJOR..": " .. source ..": '" .. callbackname .. "' - function or method name expected.", 3)
	end
	if type(callback) == "string" then
		if type(self)~="table" then
			error(MAJOR..": " .. source .. ": 'self' - must be a table.", 3)
		end
		if type(self[callback]) ~= "function" then 
			local error_origin = repeating and "ScheduleRepeatingTimer" or "ScheduleTimer"
			error(MAJOR..": " .. source .. ": '" .. callbackname .. "' - method not found on target object.", 3)
		end
	end
    return true
end

function Countdown.BeginCountdown(self, duration, display, completed, delay)
    count = count + 1
    if delay == nil then delay = 0 end
        
    ActiveIDs[count] = true
    
    ValidateCallback(self, display, "BeginCountdown(duration, display, completed, delay)", "display")
    ValidateCallback(self, completed, "BeginCountdown(duration, display, completed, delay)", "completed")
    
    Timer:ScheduleTimer(Tick, delay, {self = self, duration = duration, display = display, completed = completed, delay = delay, id = count})
    return count
end

function Countdown:CancelCountdown(id)
    if ActiveIDs[id] then ActiveIDs[id] = nil end
end

Countdown.embeds = Countdown.embeds or {}

local mixins = {
	"BeginCountdown",
    "CancelCountdown"
}

function Countdown:Embed(target)
	for _,v in pairs(mixins) do
		target[v] = Countdown[v]
	end    
	self.embeds[target] = true    
	return target
end

for target, v in pairs(Countdown.embeds) do
	Countdown:Embed(target)
end

end
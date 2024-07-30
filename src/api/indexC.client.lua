---- DIRECTORY
local MAINDIR = game.ReplicatedStorage:WaitForChild("SystemHandler");
local PACKAGES = MAINDIR:WaitForChild("packages");
local SETTINGS = MAINDIR:WaitForChild("settings");
---- DEPENDENCIES
local CONFIG = require(SETTINGS:WaitForChild("config"));
local LOG = require(PACKAGES:WaitForChild("LogManager", CONFIG.WaitTime));
---- CODE
local ERROR_IN_SCRIPT = "Error in the script %s at line (%d+): %s";  
local systemsLog = LOG.new(script,CONFIG.LogLevel,CONFIG.SaveLogs);
systemsLog.LivePrint = CONFIG.LiveLog;
systemsLog.ShowLevel = CONFIG.ShowLevel;
systemsLog.Save = false;
LOG.PrintDebug = CONFIG.PrintDebug;
LOG.SaveDebug = false;

local EVENT_NAME = script:GetAttribute("Event");
if (EVENT_NAME) then
    local TRANSMISOR : RemoteEvent = game.ReplicatedStorage:WaitForChild(EVENT_NAME, 10);
    if (TRANSMISOR) then
        TRANSMISOR.OnClientEvent:Connect(function(OBJECT, TARGET)
            local MODULE = require(OBJECT);
            for _, code in pairs(MODULE.Scripts) do
                if (code.Name == TARGET) then
                    xpcall(function()
                        MODULE.Log = LOG.new(OBJECT, CONFIG.LogLevel, CONFIG.SaveLogs, code);
                        MODULE.Log.LivePrint = CONFIG.LiveLog;
                        MODULE.Log.ShowLevel = CONFIG.ShowLevel;
                        MODULE.Log.Save = false;
                        MODULE.Log:add(1,`"{code.Name}" log set`);
                        code.Init();
                    end, function(error)
                        warn(error)
                        systemsLog:add(4, string.format(ERROR_IN_SCRIPT, code.Name, LOG.getCallerInfo(OBJECT), error))
                    end) 
                end
            end  
        end)
    else
        systemsLog:add(4, `The {script:GetFullName()} dosen´t find "{EVENT_NAME}" in game.ReplicatedStorage`)
    end
else
    systemsLog:add(4,`The {script:GetFullName()} dosen´t has the "Event" attribute`)
end
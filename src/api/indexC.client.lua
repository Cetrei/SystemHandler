---- SERVICES
local TextService = game:GetService("TextService")
local TNS = game:GetService("TweenService");
local RNS = game:GetService("RunService");
---- DIRECTORY
local MAINDIR = game.ReplicatedStorage:WaitForChild("SystemHandler");
local PACKAGES = MAINDIR:WaitForChild("packages");
local SETTINGS = MAINDIR:WaitForChild("settings");
---- DEPENDENCIES
local CONFIG = require(SETTINGS:WaitForChild("config"));
local LOG = require(PACKAGES:WaitForChild("LogManager", CONFIG.WaitTime));
local PROMISE = require(PACKAGES:WaitForChild("Promise", CONFIG.WaitTime))
local FIND = require(PACKAGES:WaitForChild("Find",CONFIG.WaitTime));
---- CODE
local ERROR_IN_SCRIPT = "Error in the script %s at line (%d+): %s"; 
local ERROR_IN_GUI_ANIM = "The %s animation throw an error: %s"; 
local ERROR_EXECUTING_EVENT = "Error in the event (%s) -> %s";
local systemsLog = LOG.new(script, CONFIG.LogLevel, CONFIG.SaveLogs);
systemsLog.LivePrint = CONFIG.LiveLog;
systemsLog.ShowLevel = CONFIG.ShowLevel;
systemsLog.Save = false;
LOG.PrintDebug = CONFIG.PrintDebug;
LOG.SaveDebug = false;
FIND.SafeMode = false
FIND.DebugMode = false
FIND.setMethod("Depth First Search")
local EVENT_NAME = script:GetAttribute("Event");
if (EVENT_NAME) then
    systemsLog:add(2, "Event name ready");
    local TRANSMISOR : RemoteEvent = game.ReplicatedStorage:WaitForChild(EVENT_NAME, 10);
    if (TRANSMISOR) then
        systemsLog:add(2, "Transmisor ready");
        TRANSMISOR.OnClientEvent:Connect(function(...)
            local PARAMETERS = {...}
            xpcall(function()
                if (typeof(PARAMETERS[1]) ~= "string") then
                    local OBJECT, TARGET = PARAMETERS[1], PARAMETERS[2]
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
                else
                    local ACTION = PARAMETERS[1];
                    if (ACTION == "SetLoadingScreen") then
                        local LOADINGSCREEN = game.Players.LocalPlayer.PlayerGui:WaitForChild(PARAMETERS[2],5);
                        --GUI objects 
                        local Main = LOADINGSCREEN:waitForChild("Main", 5);
                        local Dots = LOADINGSCREEN:waitForChild("Dots", 5);
                        if (Main) and (Dots) then
                            systemsLog:add(2, "Setting loading screen");
                            --Dots
                            local DotInfo = TweenInfo.new(CONFIG.DotsSpeed, Enum.EasingStyle.Circular, Enum.EasingDirection.In)
                            local function state(SHOW:boolean, DOT:Frame)
                                local anim = TNS:Create(DOT, DotInfo, {Size = SHOW and UDim2.fromScale(1,1) or UDim2.fromScale(0,0)});
                                anim:Play();
                                return anim.Completed:Wait();
                            end
                            task.spawn(function()
                                xpcall(function()
                                    while (Dots.Visible) do
                                        state(true, Dots.Dot1.InsideDot);
                                        state(true, Dots.Dot2.InsideDot);
                                        state(true, Dots.Dot3.InsideDot);

                                        state(false, Dots.Dot1.InsideDot);
                                        state(false, Dots.Dot2.InsideDot);
                                        state(false, Dots.Dot3.InsideDot);
                                    end
                                end, function(errorMSG)
                                    systemsLog:add(3, string.format(ERROR_IN_GUI_ANIM, "Dots", errorMSG))
                                end)
                            end)
                            --Gradient
                            local GradientFrame = Main:WaitForChild("Gradient",5) :: Frame;
                            task.spawn(function()
                                xpcall(function()
                                    local UIGradient = GradientFrame:FindFirstChildWhichIsA("UIGradient");
                                    while (GradientFrame.Visible) do
                                        local dt = RNS.Heartbeat:Wait();
                                        UIGradient.Offset = Vector2.new(UIGradient.Offset.X + (CONFIG.BackgroundSpeed*dt), 0)
                                        if (UIGradient.Offset.X >= 1) then
                                            if (UIGradient.Rotation == 180) then
                                                UIGradient.Rotation = 0;
                                            else
                                                UIGradient.Rotation = 180;
                                            end
                                            UIGradient.Offset = Vector2.new(-1, 0);
                                        end
                                        task.wait(dt)
                                    end
                                end, function(errorMSG)
                                    systemsLog:add(3, string.format(ERROR_IN_GUI_ANIM, "Gradient", errorMSG))
                                end)
                            end)

                            --CHARGING LOGIC
                            --Phase : string
                            local LOADING_BAR = FIND("Fill", LOADINGSCREEN) :: Frame;
                            local PHASE_TEXT = FIND("Phase", LOADINGSCREEN) :: TextLabel;
                            task.spawn(function()
                                PHASE_TEXT
                            end)
                            local systemsList = PARAMETERS[3];
                            local sequence = {
                                {"Waiting Systems", function(PHASE_SIZE)
                                    local SYSTEM_SIZE = PHASE_SIZE/#systemsList;    
                                end}
                            }
                            PROMISE.fold(sequence, function(_, phase, index)
                                local HANDLER_PHASE = MAINDIR:GetAttribute("Phase");
                                local NAME, CALLBACK = phase[1], phase[2]
                                CALLBACK(1/#sequence);
                            end)
                        end
                    end
                end
            end, function(errorMSG)
                systemsLog:add(4, string.format(ERROR_EXECUTING_EVENT, typeof(PARAMETERS[1]) == "string" and PARAMETERS[1] or "Unknown", errorMSG));
            end)
        end)
        systemsLog:add(2, "Transmisor event ready");
    else
        systemsLog:add(4, `The {script:GetFullName()} dosen´t find "{EVENT_NAME}" in game.ReplicatedStorage`)
    end
else
    systemsLog:add(4,`The {script:GetFullName()} dosen´t has the "Event" attribute`)
end
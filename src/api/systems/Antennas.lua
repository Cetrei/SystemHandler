local SYSTEM = {};
SYSTEM.UpdateFrequency = 0;
SYSTEM.Tag = "Antenna";
SYSTEM.Delay = 10;

--------------------------------------------------------------------------------------------------------
local system = {};
system.CGD = true;
system.Log = 0;
system.Scripts = {};
system.Scripts.index = {
    Name = "antenasIndex";
    Side = "server";
    Init = function()
        ---- SERVICES
        local CLS = game:GetService("CollectionService");
        local RNS = game:GetService("RunService");
        ---- CONSTANTS
        local MAINDIR = script.Parent.Parent;
        local PACKAGES = MAINDIR:WaitForChild("packages");
        local SETTINGS = MAINDIR:WaitForChild("settings");
        local ERROR_ANTENA = "%s in %s:%s"
        ---- DEPENDENCIES
        local CONFIG = require(SETTINGS:WaitForChild("config"));
        local CLASS = require(PACKAGES:WaitForChild("Class"), CONFIG.WaitTime);
        ---- CODE
        task.wait(CONFIG.Delay);
        local Antenna = CLASS("Antenna",{
            private = {
                Reference = nil;
                Velocity = nil;
                Spinning  = nil;
            },
            public = {
                Antena = function(self, MODEL: Model, VELOCITY: number)
                    local REFERENCE = MODEL:FindFirstChild("Reference", true);
                    if (typeof(VELOCITY) ~= "number") then
                        VELOCITY = 5;
                    end
                    if (REFERENCE) then
                        self.Reference = REFERENCE;
                        self.Velocity = math.rad(VELOCITY);
                        self.Spinning = true;
                    else
                        system.Log:add(3,string.format(ERROR_ANTENA,`The "Reference" part was not found`, MODEL:GetFullName()), script);
                    end
                end,
                Spin = function(self)
                    local tries = 0;
                    while (self.Spinning) do
                        xpcall(function()
                            local DT = RNS.Heartbeat:Wait();
                            self.Reference.CFrame *= CFrame.Angles(0, self.Velocity * DT, 0);
                            tries = 0;
                        end, function(ERROR)
                            if tries < 10 then
                                tries += 1;
                            else
                                self.Stop();
                                system.Log:add(4,string.format(ERROR_ANTENA,`An error occurred while trying to rotate the antenna`, self.Reference:GetFullName(), ERROR), script);
                            end
                        end)
                        task.wait(SYSTEM.UpdateFrequency);
                    end
                end,
                Stop = function(self)
                    self.Spinning = false;
                end
            }
        })
        ---
        local ANTENNAS = CLS:GetTagged(SYSTEM.Tag);
        for i, antenna in pairs(ANTENNAS) do
            local NewAntenna = Antenna(antenna,antenna:GetAttribute("Velocity"));
            NewAntenna.Spin();
        end
        return true;
    end
}
return system;
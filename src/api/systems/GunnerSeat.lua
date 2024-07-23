local SYSTEM = {};
SYSTEM.Tag = "GunnerSeat";
SYSTEM.GunnerGui = game.StarterGui:WaitForChild("GunnerGui",15);
SYSTEM.Storage = nil;

--------------------------------------------------------------------------------------------------------
---- SERVICES
local CLS = game:GetService("CollectionService");
local PYS = game:GetService("Players");
local Workspace = game:GetService("Workspace")
---- CONSTANTS
local MAINDIR = script.Parent.Parent;
local PACKAGES = MAINDIR:WaitForChild("packages");
local SETTINGS = MAINDIR:WaitForChild("settings");
---- DEPENDENCIES
local CONFIG = require(SETTINGS:WaitForChild("config"));
local CLASS = require(PACKAGES:WaitForChild("Class", CONFIG.WaitTime));
local LOG = require(PACKAGES:WaitForChild("LogManager", CONFIG.WaitTime));
local PROMISE = require(PACKAGES:WaitForChild("Promise", CONFIG.WaitTime));
---- VARIABLES
local ERROR_ADDING_SEATS = "An error occur when trying to load the seats: %s"
local ERROR_ADDING_SEAT = "Can´t add the seat %s to the system: %s"
local ERROR_CALLBACK = "Error executing the callbacks for the seat (%s) event: %s"
local ERROR_COUNT_EXCEDED = "The seat (%s) exced the allowed error amount, disconnecting it from the system"
local system = {};
system.CGD = true;
system.Log = 0 :: LOG.Log;
system.Scripts = {};
---- CODE
local function createFolder(NAME: string, PARENT: Instance)
    local folder = Instance.new("Folder");
    folder.Name = tostring(NAME);
    folder.Parent = PARENT;
    return folder;
end
local GunnerSeat = CLASS("GunnerSeat",{
    private = {
        Seat = 0;
        Player = 0;
        Gui = 0;
        Tools = 0;
        Event = 0;
        Sequence = 0;
        ErrorCount = 5;
    },
    public = {
        GunnerSeat = function(self, SEAT: Instance)
            self.Seat = SEAT;
        end;
        gunnerCam = function(self, ACTIVE: boolean)
            if (ACTIVE) then
                self.Player.CameraMode = Enum.CameraMode.LockFirstPerson;
            else
                self.Player.CameraMode = Enum.CameraMode.Classic;
            end
        end,
        gunnerGui = function(self, ACTIVE: boolean)
            if (SYSTEM.GunnerGui) then
                self.Gui = self.Player.PlayerGui:FindFirstChild(SYSTEM.GunnerGui.Name, true);
                if (ACTIVE) then
                    if (self.Gui ~= 0) then
                        self.Gui.Enabled = false;
                    end
                else
                    if (self.Gui ~= 0) then
                        self.Gui.Enabled = false;
                        self.Gui = 0;
                    end
                end
            end
        end,
        gunnerTools = function(self, ACTIVE: boolean)
            if (SYSTEM.Storage) then
                self.Tools = SYSTEM.Storage:FindFirstChild(self.Player.UserId);
                if (not self.Tools) then
                    self.Tools = createFolder(self.Player.UserId, SYSTEM.Storage);
                    task.wait(0.1)
                    self.gunnerTools(true);
                    return;
                end
                if (ACTIVE) then
                    self.Player.Character.Humanoid:UnequipTools()
                    for _, tool in ipairs(self.Player.Backpack:GetChildren()) do
                        if (tool:IsA("Tool")) then
                            tool.Parent = self.Tools;
                        end
                        task.wait()
                    end
                else
                    for _, tool in ipairs(self.Tools:GetChildren()) do
                        if (tool:IsA("Tool")) then
                            tool.Parent = self.Player.Backpack;
                        end
                        task.wait()
                    end
                end
            end
        end,
        handleOccupantChange = function(self)
            if (self.Sequence == 0) then
                self.Sequence = {self.gunnerCam, self.gunnerGui, self.gunnerTools};
            end
            local OCCUPANT = self.Seat.Occupant
            if (OCCUPANT) then
                self.Player = PYS:GetPlayerFromCharacter(OCCUPANT.Parent);
            end
            PROMISE.fold(self.Sequence, function(_, callback: () -> any, index: number)
                callback(OCCUPANT ~= nil);
            end):catch(function(error)
                system.Log:add(4, string.format(ERROR_CALLBACK, self.Seat:GetFullName(), tostring(error)));
                self.ErrorCount -= 1;
                if (self.ErrorCount <= 0) then
                    self.Event:Disconnect();
                    system.Log:add(5, string.format(ERROR_COUNT_EXCEDED, self.Seat:GetFullName()));
                end
            end)
        end,
        Connect = function(self)
            system.Log:add(0, `Connecting to the occupant event`); 
            if (self.Seat ~= 0) then
                self.Event = self.Seat:GetPropertyChangedSignal("Occupant"):Connect(self.handleOccupantChange);
                system.Log:add(0, `Event Connected`); 
            else
                system.Log:add(3, `Seat not dectected, can´t connect to event`);
            end
        end
    }
})

function addGunnerSeat(SEAT: Instance)
    system.Log:add(2, `Adding {SEAT.Name} to the system`); 
    PROMISE.try(function()
        local SEAT_OBJECT = GunnerSeat(SEAT);
        SEAT_OBJECT:Connect();
    end):catch(function(error)
        system.Log:add(4, string.format(ERROR_ADDING_SEAT, SEAT.Name, error));
    end)
end

system.Scripts.index = {
    Name = "GunnerIndex";
    side = "server";
    init = function()
        local seats = CLS:GetTagged(SYSTEM.Tag);
        if (not SYSTEM.Storage) then
            system.Log:add(2, `System Storage not specified, creating one...`);
            SYSTEM.Storage = createFolder("GunnerSeatStorage", game.ServerStorage);
        end
        ------------------------------------------------------------------------------
        system.Log:add(2, `Getting gunner seats...`); 
        if (#seats > 0) then
            PROMISE.fold(seats,function(_, seat, index)
                if (not seat) then
                    system.Log:add(1, `Seat {index} not found, skipping...`);
                elseif (not seat:IsA("Seat")) and    (not seat:IsA("VehicleSeat")) then
                    system.Log:add(1, `Seat {seat:GetFullName()} is not a seat, skipping...`);
                else
                    addGunnerSeat(seat);
                end
            end):andThen(function()
                system.Log:add(2, "GunnerSeat system loaded");
            end):catch(function(error)
                system.Log:add(4, string.format(ERROR_ADDING_SEATS, tostring(error)));
            end)
        else
            system.Log:add(2, `There is not gunner seats to add to the system`); 
        end
        CLS:GetInstanceAddedSignal(SYSTEM.Tag):Connect(addGunnerSeat);
    end
}

return system;
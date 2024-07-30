local SYSTEM = {};
SYSTEM.Tag = "LockerCG";
SYSTEM.Activation = 2; -- 1 -> ProximityPromt | 2 -> ClickDetector
SYSTEM.MaxLoadouts = 4;
SYSTEM.MenuCursor = "rbxassetid://18657596131";
SYSTEM.ProximityPromt = { -- Set the properties for the proximityPromt if you activation mode is set to this type
    ActionText = "Enter";
    ObjectText = "Locker";
    HoldDuration = 0.5;
    MaxActivationDistance = 20;
    KeyboardKeyCode = Enum.KeyCode.F;
    GamepadKeyCode = Enum.KeyCode.ButtonX;
    -- Problably you only want to changue the settings above
    Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton;
    ClickablePrompt = true;
    RequiresLineOfSight = false;
    Style = Enum.ProximityPromptStyle.Default;
    UiOffset = UDim2.fromOffset(0,0);
}
SYSTEM.ClickDetector = {
    MaxActivationDistance = 32;
    CursorIcon = "";
}
SYSTEM.LockerGui = script:WaitForChild("LockerGui", 15);
SYSTEM.LockerTree = script:WaitForChild("LockerOrganization", 15);
SYSTEM.Templates = script:WaitForChild("Templates", 15);
-------
local TNS = game:GetService("TweenService");
SYSTEM.Animations = {
    LoadoutButton = {
        MouseButton1Click = function(BUTTON: ImageLabel)
            TNS:Create(BUTTON.Bar, TweenInfo.new(0.2, Enum.EasingStyle.Bounce, Enum.EasingDirection.InOut, 2), {BackgroundTransparency = 0}):Play();
            BUTTON.ImageTransparency = 0.4;
        end,
        MouseEnter = function(BUTTON: ImageLabel)
            TNS:Create(BUTTON, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {ImageTransparency = 0.2}):Play();
        end,
        MouseLeave = function(BUTTON: ImageLabel)
            TNS:Create(BUTTON, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {ImageTransparency = 0.4}):Play();
        end
    }
}
--------------------------------------------------------------------------------------------------------
local system = {};
system.CGD = true;
system.Log = 0;
system.Scripts = {};
system.Scripts.index = {
    Name = "lockerIndex";
    Side = "server";
    Init = function()
        ---- SERVICES
        local CLS = game:GetService("CollectionService");
        ---- CONSTANTS
        local MAINDIR = script.Parent.Parent;
        local PACKAGES = MAINDIR:WaitForChild("packages");
        local SETTINGS = MAINDIR:WaitForChild("settings");
                local ERROR_LOADING_LOCKERS = "An error occur when trying to load the lockers: %s";
        local ERROR_ADDING_LOCKER = "Can´t add the locker %s to the system: %s";
        ---- DEPENDENCIES
        local CONFIG = require(SETTINGS:WaitForChild("config"));
        local PROMISE = require(PACKAGES:WaitForChild("Promise"), CONFIG.WaitTime)
        local CLASS = require(PACKAGES:WaitForChild("Class"), CONFIG.WaitTime);
        ---- VARIABLES
        local transmisorEventC = nil;
        ---- CODE
        system.Log:add(2, `Locker server side ready`);
        local Locker = CLASS("Locker", {
            private = {
                Locker = 0;
                Activator = 0;
                ActivatorEvent = 0;
                Transmisor = 0;
                Connection = 0;
            },
            public = {
                Locker = function(self, LOCKER: Model)
                    self.Locker = LOCKER;
                    self.Locker.PrimaryPart = LOCKER.Trigger;
                    self.Transmisor = transmisorEventC;
                    if (SYSTEM.Activation == 1) then
                        self.Activator = Instance.new("ProximityPrompt", self.Locker.PrimaryPart);
                        self.Activator.Name = "PP";
                        for property, value in pairs(SYSTEM.ProximityPromt) do
                            xpcall(function()
                                self.Activator[property] = value;
                            end, function()
                                system.Log:add(4,`The property called "{property}" for the SYSTEM.ProximityPrompt dosen´t exist`)
                            end)
                        end
                        self.ActivatorEvent = self.Activator.TriggerEnded;
                    elseif (SYSTEM.Activation == 2) then
                        self.Activator = Instance.new("ClickDetector", self.Locker.PrimaryPart);
                        self.Activator.Name = "CD";
                        for property, value in pairs(SYSTEM.ClickDetector) do
                            xpcall(function()
                                self.Activator[property] = value;
                            end, function()
                                system.Log:add(4,`The property called "{property}" for the SYSTEM.ProximityPrompt dosen´t exist`)
                            end)
                        end
                        self.ActivatorEvent = self.Activator.MouseClick;
                    else
                        system.Log:add(4, `The specified system activation dosen´t exist, must be 1 or 2 not -> {SYSTEM.Activation}`);
                    end
                end,
                OpenClose = function(self, PLAYER: Player)
                    if (PLAYER.Character) and (PLAYER.Character:FindFirstChild("Humanoid") and (PLAYER.Character.Humanoid.Health > 0)) then
                        self.Transmisor:FireClient(PLAYER, "OpenClose", self)
                    end
                end,
                Connect = function(self)
                    if (self.ActivatorEvent) then
                        self.Connection = self.ActivatorEvent:Connect(self.OpenClose);
                        system.Log:add(2, `Locker "{self.Locker:GetFullName()}" event set.`);
                    else
                        system.Log:add(3, `Can´t set the Locker event for "{self.Locker:GetFullName()}"`);
                    end
                end
            }
        })


        local function checkTree()
            for i, teamFolder in pairs(SYSTEM.LockerTree:GetChildren()) do
                if (not game.Teams:FindFirstChild(teamFolder.Name)) then
                    return false, `The folder called "{teamFolder.Name}" dosen´t match with a existing team`; 
                else
                    for j, category in pairs(teamFolder:GetChildren()) do
                        local success, result = pcall(function()
                            return SYSTEM.Templates.Categories[category.Name] ~= nil
                        end)
                        if (not success) then
                            return false, `An unespected error occurr when trying to find the category "{category.Name}": {result}`;
                        elseif (result == false) then
                            return false, `The folder called "{category.Name}" dosen´t match with a existing category`;
                        end
                        task.wait()
                    end
                end
            end
            return true;
        end
        local function checkTemplates()
            local dependencies = {
                Accesory = SYSTEM.Templates:FindFirstChild("Accesory");
                CategoryTab = SYSTEM.Templates:FindFirstChild("CategoryTab");
                TeamTab = SYSTEM.Templates:FindFirstChild("TeamTab");
            }
            for name, dependency in pairs(dependencies) do
                if (dependency == nil) then
                    return false, `Missing dependency: {name}, check it´s existence and name in System -> Templates`;
                end
            end
            return true;
        end

        local function addLocker(LOCKER)
            if (not LOCKER:FindFirstChild("Trigger")) then
                system.Log:add(2, `Locker {LOCKER:GetFullName()} is not a locker or is missing the Trigger part, skipping...`);
            else
                system.Log:add(2, `Adding {LOCKER.Name} to the system`); 
                PROMISE.try(function()
                    local LOCKER_OBJECT = Locker(LOCKER);
                    LOCKER_OBJECT:Connect();
                end):catch(function(error)
                    system.Log:add(4, string.format(ERROR_ADDING_LOCKER, LOCKER.Name, error));
                end)
            end
        end

        task.wait(CONFIG.Delay);
        system.Log:add(2, `Cheking dependencies...`); 
        local VALID_GUI = SYSTEM.LockerGui:IsA("ScreenGui");
        local VALID_TEMPLATES, REASON_TEM = checkTemplates(); 
        local VALID_TREE, REASON_TRE = checkTree();
        if (not SYSTEM.LockerGui) then
            CancellReason = `Can´t found the Locker Gui`;
        elseif (not SYSTEM.LockerTree) then
            CancellReason = `Can´t found the Locker Tree`;
        elseif (not SYSTEM.Templates) then
            CancellReason = `Can´t found the Locker Templates`;
        end
        if (not VALID_GUI) then
            CancellReason = `Locker Gui must be a ScreenGui not a: {SYSTEM.LockerGui.ClassName}`;
        elseif (not VALID_TEMPLATES) then
            CancellReason = `Invalid format for the Locker Templates: {REASON_TEM}`;
        elseif (not VALID_TREE) then
            CancellReason = `Invalid format for the Locker Tree: {REASON_TRE}`;
        end
        if (CancellReason) then
            system.Log:add(3, `Can´t execute the system -> {CancellReason}`);
            return
        end
        system.Log:add(2, `Dependencies approved`); 
        transmisorEventC = Instance.new("RemoteEvent", script)
        transmisorEventC.Name = "LockerEvent";
        SYSTEM.LockerGui.Enabled = false;
        if (SYSTEM.LockerGui.Parent ~= game.StarterGui) then
            SYSTEM.LockerGui:Clone().Parent = game.StarterGui;
        end
        --------------------------------------------------------------------------------
        system.Log:add(2, `Getting lockers...`); 
        local LOCKERS = CLS:GetTagged(SYSTEM.Tag);
        if (#LOCKERS > 0) then
            PROMISE.fold(LOCKERS,function(_, locker, index)
                if (not locker) then
                    system.Log:add(1, `Locker {index} not found, skipping...`);
                else
                    addLocker(locker);
                end
            end):andThen(function()
                system.Log:add(2, "Locker system loaded");
            end):catch(function(error)
                system.Log:add(4, string.format(ERROR_LOADING_LOCKERS, tostring(error)));
            end)
        else
            system.Log:add(2, `There is not lockers to add to the system`); 
        end
        CLS:GetInstanceAddedSignal(SYSTEM.Tag):Connect(addLocker);
    end
}

system.Scripts.client = {
    Name = "lockerClient";
    Side = "client";
    Init = function()
        ---- CONSTANTES
        local PLAYER = game.Players.LocalPlayer;
        local GUI = PLAYER.PlayerGui:WaitForChild(SYSTEM.LockerGui.Name) :: ScreenGui;
        local TRANSMISOR = script:WaitForChild("LockerEvent");
        local SELECTED_COLOR = PLAYER.TeamColor or Color3.new(178, 255, 225);
        ---- VARIABLES
        local currentLoadout
        ---- GUI TREE
        local Main = GUI:WaitForChild("Main", 5);
        local Loadouts = Main:WaitForChild("BottomFrame");
        local CharacterPreview = Main:WaitForChild("MiddleFrame"):WaitForChild("Preview");
        local Accesories = Main.MiddleFrame:WaitForChild("Accesories");
        local IndexTabs = Main:WaitForChild("TopFrame"):WaitForChild("Index");
        local SearchTab = Main.TopFrame:WaitForChild("Search");
        --
        system.Log:add(2, `Locker client side ready`);
        local function setAnimations()
            for _, loadout: ImageLabel in pairs(Loadouts:GetChildren()) do
                if (loadout:IsA("ImageLabel")) then
                    loadout.Bar.BackgroundColor3 = 
                    loadout.Button.MouseEnter:Connect(function()
                        if (currentLoadout ~= loadout) then
                            SYSTEM.Animations.LoadoutButton.MouseEnter(loadout);   
                        end
                    end)
                    loadout.Button.MouseLeave:Connect(function()
                        if (currentLoadout ~= loadout) then
                            SYSTEM.Animations.LoadoutButton.MouseLeave(loadout);   
                        end
                    end)
                    loadout.Button.MouseButton1Click:Connect(function()
                        if (currentLoadout ~= loadout) then
                            SYSTEM.Animations.LoadoutButton.MouseButton1Click(loadout);
                            currentLoadout = loadout;
                        end
                    end)
                end
            end
        end
        local function getLoadouts()
            TRANSMISOR:FireServer("getLoadouts", Loadouts, PLAYER);
        end
        local function setGui()
            system.Log:add(2, `Setting GUI...`);
            currentLoadout = Loadouts["1"];
            
            
            system.Log:add(2, `GUI ready`);
        end

        local function handleGui()
            
        end

        setGui();
        local function handleEvent(ACTION: string, LOCKER: table)
            if (ACTION == "OpenClose") then
                GUI.Enabled = not GUI.Enabled
                if (GUI.Enabled) then
                    handleGui();
                end
            end
        end
        --
        TRANSMISOR.OnClientEvent:Connect(handleEvent)
        system.Log:add(2, `Transmisor event ready`);
    end
}

return system;
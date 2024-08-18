local SYSTEM = {};
SYSTEM.Tag = "MenuCGD";
SYSTEM.Activation = 2; -- 1 -> ProximityPromt | 2 -> ClickDetector
SYSTEM.MenuCursor = "rbxassetid://18657596131";
SYSTEM.ProximityPromt = { -- Set the properties for the proximityPromt if you activation mode is set to this type
    ActionText = "Enter";
    ObjectText = "Menu";
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
---- CODE
local system = {};
system.CGD = true;
system.Log = 0;
system.Scripts = {};

system.Scripts.Server = {
    Name = "ShooterMenuServer";
    Side = "server";
    Init = function()
        
    end
}
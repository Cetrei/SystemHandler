local SYSTEM = game.ReplicatedStorage:WaitForChild("SystemHandler");
local CONFIG = require(SYSTEM:WaitForChild("settings"):WaitForChild("config"));
local TRANSMISOR = script.Parent:WaitForChild(CONFIG.TransmisorName, CONFIG.WaitTime)
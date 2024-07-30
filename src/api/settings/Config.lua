local CONFIG = {};
--- CONSOLE LOGS 
CONFIG.LogLevel = Enum.AnalyticsLogLevel.Warning; -- Level of logs to show: Debug, Warning, Error, Fatal
CONFIG.ShowLevel = Enum.AnalyticsLogLevel.Warning -- The level that it´s going to be showed in LiveLogging
CONFIG.SaveLogs = false; -- Save logs to a file
CONFIG.LiveLog = true; -- Get some info of the current execution
CONFIG.PrintDebug = false;
CONFIG.SaveDebug = false;

--- SYSTEM INTEGRITYs
CONFIG.SafeMode = true; -- Apply a extra security layer using Promises and pcall to handler errors in some processes
CONFIG.CheckSystemHandler = true; -- Check the handler's files before loading systems
CONFIG.TypeChecking = true; -- Check if the config variable types match the expected types
CONFIG.WaitTime = 15; -- Time to wait for dependencies
CONFIG.DelayTime = 0; -- If your game is big and dont need to load fast the systems you can add a delay to evade load erros
CONFIG.AllowPlayerSpawn = false;
--- SYSTEMS LOADING
CONFIG.CheckSystemScripts = true; -- Execute the systems scripts but checking if they return errors
CONFIG.KeepInstallationOnFailCheck = false; -- Install the system even if script checks fail
CONFIG.CanCancelExecutions = true; -- Cancel execution if a system script fails
CONFIG.KeepTrack = true; -- Keep track of system scripts after installationg
--- OTHERS
CONFIG.SaveInfoLocally = true; -- Save if a system is enabled or not so you don´t need to remove it from the folder
CONFIG.SaveInfoCrossGame = true; -- As the name says, save your settings for the handler and each system across your games
CONFIG.TransmisorName = "TransmisorSH";
CONFIG.PathSeparator = "/";
CONFIG.OpenGuiButton = Enum.KeyCode.Period; -- Keybind to open the in-game interface
CONFIG.Admins = { -- Users who can open this interface
    "Cetreibogamer"
}

return CONFIG;
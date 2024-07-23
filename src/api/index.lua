--[=[
    @class CGD
    Sigma
]=]
---- SERVICES
local SCS = game:GetService("ScriptContext");
---- DIRECTORY
local MAINDIR = script.Parent;
local PACKAGES = MAINDIR:WaitForChild("packages");
local SETTINGS = MAINDIR:WaitForChild("settings");
---- DEPENDENCIES
local CONFIG = require(SETTINGS:WaitForChild("config"));
local CLASS = require(PACKAGES:WaitForChild("Class"), CONFIG.WaitTime);
local LOG = require(PACKAGES:WaitForChild("LogManager", CONFIG.WaitTime));
local FIND = require(PACKAGES:WaitForChild("Find",CONFIG.WaitTime));
local PROMISE = require(PACKAGES:WaitForChild("Promise", CONFIG.WaitTime));
---- EVENTS
local onError = SCS.Error;
---- VARIABLES 
local systemsList = {};
local systemsLog = LOG.new(script,CONFIG.LogLevel,CONFIG.SaveLogs);
local transmisor = nil;
---- CODE
local ERROR_IN_SCRIPT = "Error in the script %s at line (%d+): %s";  
local ERROR_INITIALIZING = "Error initializing %s: %*";
local ERROR_CANT_INSTALL = "Can´t install system because of %s";
FIND.Separator = CONFIG.PathSeparator;
FIND.SafeMode = CONFIG.SafeMode;
if (CONFIG.LogLevel == Enum.AnalyticsLogLevel.Debug) then
    FIND.DebugMode = true;
end
systemsLog.LivePrint = CONFIG.LiveLog;
systemsLog.ShowLevel = CONFIG.ShowLevel;
systemsLog.Save = CONFIG.SaveLogs;
LOG.PrintDebug = CONFIG.PrintDebug;
LOG.SaveDebug = CONFIG.SaveDebug;

local function getFindValue(RESULT)
    if (typeof(RESULT) == "table") then
        local worked, value = RESULT:await()
        return value;
    end
    return RESULT;
end

local supportSystems = {};
function supportSystems.ACS(SYSTEM:{})
    FIND.setMethod("Depth First Search");
    local debugPrint = getFindValue(FIND("DebugPrint", SYSTEM.Object));
    if (debugPrint) then
        debugPrint.Value = false;
    end
end

game.Players.CharacterAutoLoads = CONFIG.AllowPlayerSpawn
if (not CONFIG.AllowPlayerSpawn) then
    for _, player:Player in pairs(game.Players:GetPlayers()) do
        if (player.Character) then
            player.Character:Destroy();
        end
    end
end

local System = CLASS("System",{
    private = {
        Object = 0;
        Environment = 0;
        Executing = 0;
        CancelReason = 0;
        Directories = {
            Pending = {};
            Checked = {};
            Broken = {};
        };
        Scripts = {
            Pending = {};
            Checked = {};
            Broken = {};
        };
    },
    public = {
        System = function(self, OBJECT: Instance)
            systemsLog:add(1,`Adding system "{OBJECT.Name}" to the handler`);
            self.Object = OBJECT;
            if (OBJECT:IsA("ModuleScript")) then
                systemsLog:add(1,`Main module detected for the system, trying to load it...`);
                local success, module = pcall(function()
                    local MLOADED = require(OBJECT) or OBJECT;
                    return MLOADED;
                end)
                if (success) then
                    systemsLog:add(1,`Main module "{self.Object.Name}" required correctly`);
                    if (module["CGD"]) then
                        self.Environment = "CGD";
                        if (module["Log"]) then
                            module.Log = LOG.new(self.Object, CONFIG.LogLevel, CONFIG.SaveLogs);
                            module.Log.LivePrint = CONFIG.LiveLog;
                            module.Log.ShowLevel = CONFIG.ShowLevel;
                            module.Log.Save = CONFIG.SaveLogs;
                            systemsLog:add(1,`"{self.Object.Name}" log set`);
                        end
                    else
                        self.Environment = "Normal";
                    end
                else
                    self.Environment = "Normal-Damaged";
                    systemsLog:add(3, string.format(ERROR_INITIALIZING, self.Object.Name, module));
                end
            else
                self.Environment = "Normal";
                --COMPATIBILITY SYSTEMS CHECKS
                if (self.Object.Name:lower():match("acs")) then
                    systemsLog:add(1,`ACS system detected, making sub-system operations`);
                    supportSystems.ACS(self);
                end
            end
            self.Executing = false;
            systemsLog:add(1,`{self.Environment} environment detected for the system`);
        end,
        disableScripts = function(self)
            for _, list in pairs(self.Scripts) do
                for _, script in pairs(list) do
                    if (not script:IsA("ModuleScript")) then
                        script.Enabled = false;
                    end
                end
            end
        end,
        handleScriptError = function(self, MESSAGE, TRACEBACK, SCRIPT)
            local partOfSystem = false;
            for _, category in pairs(self.Scripts) do
                if (category[SCRIPT] == SCRIPT) or (category[SCRIPT][1] == SCRIPT) then
                    partOfSystem = true;
                end
            end
            if (partOfSystem) then
                systemsLog:add(4, string.format(ERROR_IN_SCRIPT, SCRIPT:GetFullName(), LOG.getCallerInfo(SCRIPT, TRACEBACK), MESSAGE));
                if (CONFIG.CanCancelExecutions) then
                    if (self.CancelReason ~= 0) then
                        self.CancelReason = `A {SCRIPT.Name} trowed an error`
                    end
                    self.disableScripts();
                    self.Executing = false;
                end
                table.insert(self.Scripts.Broken, {Code = SCRIPT, Reason = MESSAGE.."\n"..TRACEBACK});
                table.remove(self.Scripts.Checked, table.find(self.Scripts.Checked,SCRIPT));
            end
        end,
        getDirectories = function(self)
            self.Directories.Pending = self.Object:GetChildren();
        end,
        checkDirectories = function(self)
            for i = #self.Directories.Pending, 1, -1 do
                local directory = self.Directories.Pending[i]
                local DESTINATION_NAME = directory.Name;
                local dirPath;

                -- ObjectValue Path Check
                dirPath = directory:FindFirstChildWhichIsA("ObjectValue");
                if (dirPath) and (dirPath.Name == "Path") then
                    table.insert(self.Directories.Checked, {dir = directory, path = dirPath.Value});
                    table.remove(self.Directories.Pending, i);
                    continue;
                end
                
                -- Path Specified Check
                FIND.setMethod("Name Based Search");
                dirPath = getFindValue(FIND(DESTINATION_NAME, game));
                if (typeof(dirPath) == "table") then
                    local worked, value = dirPath:await()
                    dirPath = value;
                end
                if (dirPath) then
                    table.insert(self.Directories.Checked, {dir = directory, path = dirPath});
                    table.remove(self.Directories.Pending, i);
                    continue;
                end

                -- Recursive Search
                FIND.setMethod("Depth First Search");
                directory.Name = "Analizing:"..DESTINATION_NAME;
                dirPath = getFindValue(FIND(DESTINATION_NAME, game));
                if (typeof(dirPath) == "table") then
                    local worked, value = dirPath:await()
                    dirPath = value;
                end
                if (dirPath) then
                    local pathName = dirPath:GetFullName();
                    if (CONFIG.PathSeparator ~= ".") then
                        pathName = string.gsub(pathName, CONFIG.PathSeparator, ".");
                    end
                    systemsLog:add(3, `Directory "{DESTINATION_NAME}" found recursivety for {self.Object.Name}, it´s hightly recommended changue the name to {pathName} or create a ObjectValue with it`);
                    directory.Name = DESTINATION_NAME;
                    table.insert(self.Directories.Checked, {dir = directory, path = dirPath});
                else
                    table.insert(self.Directories.Broken, directory);
                end
                table.remove(self.Directories.Pending, i);
                task.wait()
            end

            systemsLog:add(1, `Results:`);
            for i, pendingDir in pairs(self.Directories.Pending) do
                systemsLog:add(1, `{i}|{pendingDir} -> Pending of check`);
            end
            for i, checkedDir in pairs(self.Directories.Checked) do
                systemsLog:add(1, `{i}|{checkedDir.dir} -> it´s a game directory`);
            end
            for i, brokenDir in pairs(self.Directories.Broken) do
                systemsLog:add(1, `{i}|{brokenDir} -> it´s not a game directory`);
            end
            if (#self.Directories.Broken > 0) then
                self.CancelReason = "broken directories";
            end
        end,
        initialiazeDirs = function(self)
            for _, checked in pairs(self.Directories.Checked) do
                local directory = checked.dir;
                local dirPath = checked.path;
                for _, component in pairs(directory:GetChildren()) do
                    component.Parent = dirPath;
                end
            end
        end,
        -----------
        getScripts = function(self)
            if (self.Environment ~= "CGD") then
                for _, object:Instance in pairs(self.Object:GetDescendants()) do
                    if (not table.find(self.Directories.Pending, object)) and (object:IsA("Script") or object:IsA("LocalScript")) then
                        object.Enabled = false;
                        table.insert(self.Scripts.Pending, object);
                        systemsLog:add(1, `{object.Name} added to the script pending list`);
                    end
                end
            else
                local LMODULE = require(self.Object);
                if (not LMODULE["Scripts"]) then
                    systemsLog:add(3, `The system dosen´t have a "{LMODULE}.Scripts" table`);
                elseif (typeof(LMODULE.Scripts) ~= "table") then
                    systemsLog:add(3, `{self.Object.Name}.Scripts must be a table not a {typeof(LMODULE.Scripts)}`);
                elseif (#LMODULE.Scripts> 0) then
                    systemsLog:add(3, `{self.Object.Name}}.Scripts its empity`);
                else
                    systemsLog:add(1,`Scripts for "{self.Object.Name}" detected correctly`);
                    for _, object:Instance in pairs(LMODULE.Scripts) do
                        table.insert(self.Scripts.Pending, object);
                    end
                end
            end
        end,
        checkScripts = function(self)
            local CONECCTION = onError:Connect(self.handleScriptError);
            local limit = 4;
            if (not CONECCTION.Connected) then
                systemsLog:add(4, `Error conecting to the ScriptContext to handle fails, retring...`);
                repeat
                    CONECCTION = onError:Connect(self.handleScriptError);
                    task.wait(0.1)
                    limit -= 1;
                until (CONECCTION.Connected) or (limit <= 0);
                if (not CONECCTION.Connected) then
                    systemsLog:add(5, `Error conecting to the ScriptContext to handle fails, cancelling script checking`);
                    if (not CONFIG.KeepInstallationOnFailCheck) then
                        self.CancelReason = "Cant check system scripts";
                    end
                end
            end
            systemsLog:add(1, `Executing Scripts...`);
            self.executeScripts();
            if (not CONFIG.KeepTrack) then
                CONECCTION:Disconnect();
                systemsLog:add(0, `ScriptError event disconnected`);
            end
            systemsLog:add(1, `Results:`);
            for i, pendingScript in pairs(self.Scripts.Pending) do
                systemsLog:add(1, `{i}| {pendingScript.Name} -> Pending of check`);
            end
            for i, checkedScript in pairs(self.Scripts.Checked) do
                systemsLog:add(1, `{i}| {checkedScript.Name} -> Without errors`);
            end
            for i, brokenScript in pairs(self.Scripts.Broken) do
                systemsLog:add(1, `{i}| {brokenScript.Code.Name} -> {brokenScript.Reason}`);
            end
            if (#self.Scripts.Broken > 0) and (CONFIG.CanCancelExecutions) then
                if (CONFIG.KeepInstallationOnFailCheck) then
                    systemsLog:add(3, `Installation will be kept, but there is some broken scripts.`);
                else
                    self.CancelReason = "Broken scripts"
                end
            end
            return true;
        end,
        executeScripts = function(self)
            if (self.Environment ~= "CGD") then
                for i = #self.Scripts.Pending, 1, -1 do
                    local code = self.Scripts.Pending[i]
                    xpcall(function()
                        code.Enabled = true;
                        table.insert(self.Scripts.Checked, code);
                    end, function(error)
                        table.insert(self.Scripts.Broken, {Code = code; Reason = error});
                    end)
                    table.remove(self.Scripts.Pending, i);
                end
            else
                for i = #self.Scripts.Pending, 1, -1 do
                    local code = self.Scripts.Pending[i]
                    if (not code["side"]) then
                        table.insert(self.Scripts.Broken, {Code = code, Reason = "Execution Side not specified"});
                    elseif (not code["init"]) then
                        table.insert(self.Scripts.Broken, {Code = code, Reason = "The code must have a init function"});
                    else
                        xpcall(function()
                            if (code.side == "server") then
                                return code.init();
                            else
                                transmisor:FireAllClients(code.init);
                            end
                            table.insert(self.Scripts.Checked, code);
                        end, function(error)
                            systemsLog:add(4,string.format(ERROR_IN_SCRIPT, self.Object.Name, LOG.getCallerInfo(self.Object), error));
                            table.insert(self.Scripts.Broken, {Code = code; Reason = error});
                        end)
                    end
                    table.remove(self.Scripts.Pending, i);
                end
            end 
            if (#self.Scripts.Broken > 0) and (CONFIG.CanCancelExecutions) then
                self.CancelReason = "Broken scripts"
            end
        end,
        init = function(self)
            local sequence = {
                {"Getting Directories...", self.getDirectories, self.Environment ~= "CGD"};
                {"Checking Directories...",self.checkDirectories, self.Environment ~= "CGD"};
                {"Placing Directories...", self.initialiazeDirs, self.Environment ~= "CGD"};
                {"Getting Scripts to execute later...", self.getScripts, true};
                {"Checking Scripts...", self.checkScripts, CONFIG.CheckSystemScripts};
                {"Executing Scripts...", self.executeScripts, not CONFIG.CheckSystemScripts}
            }
            if (CONFIG.SafeMode) then
                PROMISE.fold(sequence, function(_, phase, index)
                    if (self.CancelReason ~= 0) then
                        error()
                    end
                    local NAME, CALLBACK, REQUIRED = phase[1], phase[2], phase[3];
                    if (REQUIRED) then
                        systemsLog:add(1, `{NAME}`);
                        CALLBACK()
                    end
                end, 0):andThen(function()
                    self.Executing = true;
                    systemsLog:add(2, `System {self.Object.Name} initialized successfully.`);
                end):catch(function(error)
                    if (self.CancelReason ~= 0) then
                        error = string.format(ERROR_CANT_INSTALL, self.CancelReason);
                    end
                    systemsLog:add(4, `Error initialiazing {self.Object.Name}: {error}`);
                end):await();
            else
                for i, phase in pairs(sequence) do
                    if (self.CancelReason ~= 0) then
                        local ERROR = string.format(ERROR_CANT_INSTALL, self.CancelReason);
                        systemsLog:add(4, `Error initialiazing {self.Object.Name}: {ERROR}`);
                        break;
                    end
                    local NAME, CALLBACK, REQUIRED = phase[1], phase[2], phase[3];
                    if (REQUIRED) then
                        systemsLog:add(1, `{NAME}`);
                        CALLBACK();
                    end
                end
            end
        end
    }
})

local function handlerInit(resolve, reject)
    task.wait(CONFIG.DelayTime);
    local EXECUTOR = script:WaitForChild("indexC",30);
    if (EXECUTOR) then
        local FOLDER = Instance.new("Folder", workspace);
        FOLDER.Name = "SystemHandler";
        FOLDER.Parent = game.Workspace;
        EXECUTOR.Parent = FOLDER;
        transmisor = Instance.new("RemoteEvent", script);
        transmisor.Name = CONFIG.TransmisorName;
        transmisor.Parent = FOLDER;
        systemsLog:add(2, `Client executor ready to start the systems initialization`);
        ------------------------------------------------------------------------------
        PROMISE.fold(MAINDIR.systems:GetChildren(), function(_, child, i)
            local SystemObject = System(child);
            if (SystemObject) and (typeof(SystemObject) == "table") then
                systemsLog:add(2, `Initializing {child.Name}...`)
                if (CONFIG.SafeMode) then
                    SystemObject.init();
                else
                    xpcall(SystemObject.init(), function(error)
                        systemsLog:add(3, string.format(ERROR_INITIALIZING, child.Name, error));
                    end);
                end
            else
                systemsLog:add(3, `Can´t create the system object for "{child}"`);
            end
        end):catch(function(error)
            systemsLog:add(5, string.format(ERROR_INITIALIZING, "the systems", error));
        end):await();
    else
        systemsLog:add(5, `The system dosen´t have a "indexC" script, check the files`);
    end
    systemsLog:add(2, `System Handler tasks finished, the handle will remain active to manage system erros`);
    if (not CONFIG.AllowPlayerSpawn) then
        for _, player:Player in pairs(game.Players:GetPlayers()) do
            player:LoadCharacter()
        end
    end
    return true;
end

return function ()
    if (CONFIG.SafeMode) then
        PROMISE.try(handlerInit):catch(function(error)
            systemsLog:add(5, string.format(ERROR_INITIALIZING, "the System Handler", error));
        end);
    else
        local level, result = handlerInit();
        if (typeof(level) == "number") then
            systemsLog:add(level, result);
        else
            error(result);
        end
    end
end

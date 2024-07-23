export type Log = {
    Origin: Instance,
    Level: Enum.AnalyticsLogLevel,
    ShowLevel: Enum.AnalyticsLogLevel,
    LivePrint: boolean,
    Save: boolean,
    Logs: {},
    Finished: boolean,
    add: (self:Log, LEVEL: Enum.AnalyticsLogLevel, TEXT: string, SUB_ORIGIN: Instance) -> any,
    finish: (self:Log) -> any,
}
-- SERVICES
local DSS = game:GetService("DataStoreService");
local ANS = game:GetService("AnalyticsService");
local RNS = game:GetService("RunService");
-- CONSTANTS
local LOG_DATA_STORE = DSS:GetDataStore("LogDataStore");
local ENVIRONMENT = nil;
if (RNS:IsStudio()) then
    ENVIRONMENT = "STUDIO";
else
    ENVIRONMENT = "SERVER";
end
-- CODE
local LogManager = {};
LogManager.SaveDebug = true;
LogManager.PrintDebug = true;
LogManager.__index = LogManager;
LogManager.Prototype = {};
LogManager.Prototype.__index = LogManager.Prototype;
local fullLog = `\n System handler running at [placeId: {game.PlaceId}, version: {game.PlaceVersion}, creator: {game.CreatorId}, Environment: {ENVIRONMENT}]}`;
local activeLogs = {};

function LogManager.getCallerInfo(ORIGIN: Instance, TRACEBACK)
    local TRACE = TRACEBACK or debug.traceback()
    local line
    for lineOrigin: string in TRACE:gmatch(ORIGIN.Name..":(%d+)") do
        if (not lineOrigin:match(lineOrigin.." function")) then
            line = lineOrigin;
            break;
        end
    end
    return line or "unknown";
end

function LogManager.new(ORIGIN: Instance, LEVEL: Enum.AnalyticsLogLevel, SAVE: boolean)
    local self = setmetatable({}, LogManager.Prototype);
    self.Origin = ORIGIN or "UNKOWN";
    self.Level = LEVEL or Enum.AnalyticsLogLevel.Info;
    self.ShowLevel = self.Level
    self.LivePrint = true;
    self.Save = SAVE or false;
    self.Logs = {};
    self.Finished = false;
    table.insert(self.Logs, `\n Log info [Origin: {self.Origin}, Level: {self.Level.Name}, Saved: {self.Save}] created the {os.clock()}`);
    table.insert(activeLogs, self);
    game:BindToClose(function()
        if (not self.Finished) then
            self:finish();
        end
    end);
    return self :: Log;
end

function LogManager.format(TEXT: string, ORIGIN: Instance, LEVEL: Enum.AnalyticsLogLevel, SUB_ORIGIN: Instance)
    local DT = DateTime.now();
    local DAY, TIME = DT:FormatLocalTime("l", "en-us"), DT:FormatLocalTime("LTS", "en-us");
    local LINE = LogManager.getCallerInfo(ORIGIN,SUB_ORIGIN);
    local LogLevel = nil;
    if (typeof(LEVEL) == "number") then
        LogLevel = Enum.AnalyticsLogLevel:GetEnumItems()[LEVEL+1]
    end
    if (SUB_ORIGIN) then
        return `[{DAY} - {TIME}] [{ORIGIN.Name} - {SUB_ORIGIN.Name}] [{LogLevel.Name}] [{LINE}] - {TEXT}`;
    else
        return `[{DAY} - {TIME}] [{ORIGIN.Name}] [{LogLevel.Name}] [{LINE}] - {TEXT}`;
    end
end

function LogManager.getLog(NAME: string)
    if (LOG_DATA_STORE:GetAsync(NAME)) then
        return LOG_DATA_STORE:GetAsync(NAME);
    else
        warn(`[{script}] - Can´t get log named "{NAME}" because it dosen´t exist`);
        return nil;
    end
end

function LogManager.getLogsList()
    local success, Content = pcall(function()
        return LOG_DATA_STORE:GetAsync("LogList");
    end)
    if (success) then
        return Content or {};
    else
        warn(`[{script}] - Can´t get log list: {Content}`);
        return {};
    end
end

function LogManager.updateLogsList(NEW_LOG)
    local LIST = LogManager.getLogsList();
    if (table.find(LIST, NEW_LOG)) then
        return
    end
    table.insert(LIST, NEW_LOG);
    local success, errorM = pcall(function()
        LOG_DATA_STORE:SetAsync("LogList", LIST);
    end)
    if (not success) then
        warn(`[{script}] - Error updating log list: "{errorM}"`);
    end
end

function LogManager.deleteLog(NAME: string)
    if (LOG_DATA_STORE:GetAsync(NAME)) then
        local success, errorM = pcall(function()
            LOG_DATA_STORE:RemoveAsync(NAME)
        end)
        if (success) then
            warn(`[{script}] - Log deleted "{NAME}"`);
        else
            warn(`[{script}] - Error deleting log "{NAME}": {errorM}`);
        end
    else
        warn(`[{script}] - There it´s not log named "{NAME}" to delete`);
    end

    local LIST = LogManager.getLogsList()
    for i = #LIST, 1, -1 do
        if LIST[i] == NAME then
            table.remove(LIST, i)
            break
        end
    end

    local success, errorM = pcall(function()
        LOG_DATA_STORE:SetAsync("LogList", LIST);
    end)
    if (not success) then
        warn(`[{script}] - Error updating log list after deletion: "{errorM}"`)
    end
end

function LogManager.deleteAllLogs()
    local logsList = LogManager.getLogsList()
    for _, logName in ipairs(logsList) do
        LogManager.deleteLog(logName)
    end
    local success, errorM = pcall(function()
        LOG_DATA_STORE:RemoveAsync("LogList")
        LOG_DATA_STORE:RemoveAsync("latest")
        LOG_DATA_STORE:RemoveAsync("debug")
    end)
    if (success) then
        warn(`[{script}] - Log list deleted`);
    else
        warn(`[{script}] - Error deleting log list: {errorM}`);
    end
end


function LogManager.Prototype:add(LEVEL:Enum.AnalyticsLogLevel, TEXT: string, SUB_ORIGIN: Instance)
    if (LEVEL >= self.Level.Value) then
        local NEW_LOG = LogManager.format(TEXT, self.Origin, LEVEL, SUB_ORIGIN);
        table.insert(self.Logs, NEW_LOG);
        if (self.LivePrint) and (LEVEL >= self.ShowLevel.Value) then
            if (LEVEL > 2) then
                warn(TEXT);
            else
                print(TEXT);
            end
        end
        if (self.Save) then
            ANS:FireLogEvent(self.Origin, self.Level, NEW_LOG, nil, nil);
        end
    end
end

function LogManager.Prototype:finish()
    local CONTENT = table.concat(self.Logs, "\n");
    fullLog ..= "\n"..CONTENT;
    if (self.Save) then
        local DT = DateTime.now()
        local DAY = DT:FormatLocalTime("YYYY-MM-DD", "en-us");
        local LIST = LogManager.getLogsList();
        local INDEX = #LIST + 1
        local NAME = `{DAY}.{INDEX}.{self.Origin.Name}`;
        
        xpcall(function()
            CONTENT ..= "\n";
            LOG_DATA_STORE:SetAsync(NAME, CONTENT);
            LOG_DATA_STORE:SetAsync("latest", CONTENT);
            LogManager.updateLogsList(NAME);
            LogManager.updateLogsList("latest");
        end, function(ERROR)
            CONTENT ..= LogManager.format(ERROR, self.Origin, self.Level).."\n";
        end)
    end
    self.Finished = true;
    table.remove(activeLogs, table.find(activeLogs, self));
    return CONTENT;
end

game:BindToClose(function()
    if (LogManager.SaveDebug) then
        local MAX_WAIT = 5;
        local timeWaited = 0;
        local tickT = 0.1
        repeat
            timeWaited += tickT;
            task.wait(tickT)
        until #activeLogs == 0 or timeWaited >= MAX_WAIT;
        LOG_DATA_STORE:SetAsync("debug", fullLog);
        LogManager.updateLogsList("debug");
    end
    if (LogManager.PrintDebug) then
        print(fullLog);
    end
end)

return LogManager

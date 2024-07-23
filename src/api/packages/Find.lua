export type searchTree = {
    Root: Instance;
    MaxDepth: number;
    MaxChildren: number;
}
export type FindModule = {
    SafeMode: boolean;
    Separator: string;
    DebugMode: boolean;
    setMethod: (
        METHOD: "Find First Child"|
        "Depth First Search"|
        "Depth Boosted Search"|
        "Breadth First Search"|
        "Name Based Search"|
        "Parallel Descendant Search"
    ) -> nil;
    compareMethods: (
        TARGET: string, 
        NUM_TESTS: number,
        TREE: {
            MaxDepth: number;
            MaxChildren: number;
            Root: Instance;
        } | nil,
        WAIT: boolean|nil
    ) -> nil;
}
----PACKAGES
local Promise = require(script.Parent:WaitForChild("Promise"))
----CODE
local Find = {}
Find.__index = Find
Find.__type = "DFS"
Find.SafeMode = false;
Find.Separator = ".";
Find.DebugMode = true;
Find.prototype = {}

---SEARCHING METHODS
--FindFirstChild | The classic roblox search, implemented to make posible handle it in SafeMode
function Find.prototype.FFC(TARGET: string, ROOT: Instance)
    return ROOT:FindFirstChild(TARGET,true);
end
--Parallel Depth Sort
function Find.prototype.PDS(TARGET: string, ROOT: Instance)
    local result = nil;
    local tasks = {};
    
    local function search(child)
        if (result) then
            return;
        end
        result = Find.prototype.FFC(TARGET,child); -- FindFirstChild recursive uses Depth-First Search so this works
    end

    for _, child in ipairs(ROOT:GetChildren()) do
        table.insert(tasks, task.spawn(search, child))
    end

    while (not result and #tasks > 0) do
        task.wait()
    end

    return result
end

--Depth-First Boosted Search | As the name states it´s a version of DFS which in some cases can be faster
function Find.prototype.DBS(TARGET: string, ROOT: Instance)
    local result = nil;
    local function worker()
        result = Find.prototype.DFS(TARGET,ROOT)
    end
    worker()
    while (not result) do
		task.wait();
	end
	return result
end

--Breadth-first search | It starts at the root and explores all the childrens at the present depth prior to moving on to the nodes at the next depth level. 
function Find.prototype.BFS(TARGET: string, ROOT: Instance)
	local queue = {ROOT}
	while #queue > 0 do
		local current = table.remove(queue, 1)
		if current.Name == TARGET then
			return current
		end
		for _, child in ipairs(current:GetChildren()) do
			table.insert(queue, child)
		end
	end
	return nil
end

--Depth-first search | It starts at the root and explores as far as possible along each branch before backtracking and going to another child
function Find.prototype.DFS(TARGET: string, ROOT: Instance)
	local stack = {ROOT}
	while #stack > 0 do
		local current = table.remove(stack)
		if current.Name == TARGET then
			return current
		end
		for _, child in ipairs(current:GetChildren()) do
			table.insert(stack, child)
		end
	end
	return nil
end

--Name based search | Uses the name of the instance to find it, the name must be a valid path with the specified separator in Find.Separator
function Find.prototype.NBS(TARGET: string, ROOT: Instance)
    if (not TARGET:find(Find.Separator)) and (not game:FindFirstChild(TARGET)) then
        return nil
    end
    local currentDir = ROOT;
    for _, dir in ipairs(string.split(TARGET, Find.Separator)) do
        currentDir = Find.prototype.FFC(dir,currentDir);
        if (not currentDir) then
            return nil
        end
    end
    return currentDir;
end
---SCRIPT FUNCTIONS
function measureTime(func, ...)
    local start = tick()
    local result = func(...)
    local finish = tick()
    return finish - start, result
end

function createFolder(name, parent)
    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent
    return folder
end

function generateTree(ROOT: Instance, TARGET: string, MAX_DEPHT: number, MAX_CHILDREN: number)
    local placed = false
    local function addChildren(parent, depth)
        if (depth <= 0) then return end
        local numChildren = math.random(1, MAX_CHILDREN)
        for i = 1, numChildren do
            local child = createFolder("Folder_"..tostring(depth).."_"..tostring(i), parent)
            if (math.random() < 0.15) and (depth ~= MAX_DEPHT) then
                createFolder(TARGET, child)
                placed = true
            end
            addChildren(child, depth - 1)

        end
    end
    addChildren(ROOT, MAX_DEPHT)
    if (not placed) then
        createFolder(TARGET, ROOT)
    end
end

---USER FUNCTIONS
function Find.setMethod(METHOD)
    if (METHOD:len() > 3) then
        local WORDS = METHOD:split(" ")
        local result = "";
        for i,word in pairs(WORDS) do  
            result = result..word:sub(1,1);
        end
        METHOD = result;    
    end
    if (Find.prototype[METHOD]) then
		Find.__type = METHOD;
	else
        return error("Invalid method: " .. tostring(METHOD));
    end

end

function Find.addSeparator(SEPARATOR:string)
    if (typeof(SEPARATOR) ~= "string") then
        return warn(`SEPARATOR must be a string not {typeof(SEPARATOR)}`);
    end
    if (table.find(Find.__separators, SEPARATOR)) then
        return warn(`SEPARATOR already exists: {SEPARATOR}`);
    else
        table.insert(Find.__separators, SEPARATOR:find(SEPARATOR));
    end
end

function Find.compareMethods(TARGET: string, NUM_TESTS: number, TREE: searchTree | nil, WAIT: boolean|nil)
    if (typeof(TARGET) ~= "string") then
        return error(`TARGET must be a string not {typeof(TARGET)}`);
    end
    if typeof(NUM_TESTS) ~= "number" then
        return error(`NUM_TESTS must be a number not a {typeof(NUM_TESTS)}`);
    end
    if (WAIT) and (typeof(WAIT) ~= "boolean") then
        WAIT = true;
    end
    if (TREE) then
        TREE.MaxDepth = TREE[1];
        TREE.MaxChildren = TREE[2];
        TREE.Root = TREE[3];
        if (typeof(TREE) ~= "table") then
            return error(`The TREE must be a table not a {typeof(TREE)}`);
        elseif (TREE.Root) and (typeof(TREE.Root) ~= "Instance") then
            return error(`The TREE.Root must be a Instance not a {typeof(TREE.Root)}`);
        elseif (typeof(TREE.MaxDepth) ~= "number") then
            return error(`The TREE.MaxDepth must be a number not a {typeof(TREE.MaxDepth)}`);
        elseif (typeof(TREE.MaxChildren) ~= "number") then
            return error(`The TREE.MaxChildren must be a number not a {typeof(TREE.MaxChildren)}`);
        end
    end
    ----
    local results = {
        Roblox = {count = 0, correctCount = 0, totalTime = 0}};

    for name,_ in pairs(Find.prototype) do
        results[name] = {count = 0, correctCount = 0, totalTime = 0};
    end

    for test = 1, NUM_TESTS do
        if (TREE) then
            local gameDirs = game:GetChildren();
            if (not TREE.Root) then
                TREE.Root = Instance.new("Folder", gameDirs[math.random(1, #gameDirs)]);
                TREE.Root.Name = "TestRoot";
            end
            generateTree(TREE.Root, TARGET, TREE.MaxDepth, TREE.MaxChildren);
        end
        Find.setMethod("DFS");
        local PATH =  Find(TARGET, game):GetFullName();

        local fastestTime = math.huge;
        local fastestMethod = nil;

        for method in pairs(results) do
            local countTime = true;
            local time, result;
            if (method == "Roblox") then
                time, result = measureTime(function()
                    return game:FindFirstChild(TARGET, true);
                end)
            else
                Find.setMethod(method);
                if (method ~= "NBS") then
                    time, result = measureTime(function()
                        return Find(TARGET, game);
                    end)
                else
                    time, result = measureTime(function()
                        return Find(PATH, game);
                    end)
                end
            end
            if typeof(result) == "table" and result.andThen then
                result:andThen(function(resolvedResult)
                    if (resolvedResult) and (resolvedResult.Name == TARGET) then
                        results[method].correctCount += 1;
                    end
                end):catch(function(err)
                    countTime = false;
                end)
            elseif (result) and (result.Name == TARGET) then
                 results[method].correctCount += 1;
            else
                countTime = false;
            end

            results[method].totalTime += time;
            if (time < fastestTime) and (countTime) then
                fastestTime = time;
                fastestMethod = method;
            end
        end

        if (fastestMethod) then
            results[fastestMethod].count += 1;
        end

        if (WAIT) then
            task.wait();
        end
        if (TREE) and (TREE.Root) then
            pcall(function()
                TREE.Root:Destroy()
            end);
        end
    end

    print("Search Results:")
    for method, data in pairs(results) do
        local averageTotalTime = (data.totalTime / NUM_TESTS) * 1000;
        local successRate = (data.correctCount / NUM_TESTS) * 100;
        print(`{method}: {data.count} found first, Average time: {averageTotalTime} ms, Succes rate: %{successRate}`);
    end
end

function executeFind(TARGET: string, ROOT: Instance)
    if (typeof(TARGET) ~= "string") then
        return error(`The TARGET must be a string not {typeof(string)}`);
    end
    if (ROOT) then
        if (typeof(ROOT) ~= "Instance") then
            return error(`The ROOT must be an Instance not {typeof(Instance)}`);
        end
    else
        ROOT = game;
    end
    local RESULT = Find.prototype[Find.__type](TARGET,ROOT or game);
    if (Find.SafeMode) then
        if (RESULT) then
            return Promise.resolve(RESULT);
        else
            return Promise.reject(RESULT):catch(function()
                warn(`{TARGET} not finded with search method: {Find.__type} `);
            end);
        end
    end
    return RESULT;
end
setmetatable(Find, {
    __call = function(self,...)
       return executeFind(...);
    end
})


return Find :: FindModule;
---- CONSTANTES
local TOSTRING_NAME = "toString";
---- VARIABLES
local ClassStorage = {};
---- CODE
local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

local function createClass(NAME: string, STRUCTURE: {private:{any},public:{any}})
    local DESTRUCTOR_NAME = "_"..NAME;
    if (not NAME) then
        return error(`The NAME value must be specified to create the class`);
    elseif (typeof(NAME) ~= "string") then
        return error(`The NAME value must be a string not a {typeof(NAME)}`);
    end
    if (not STRUCTURE) then
        return error(`Can´t create a class without strcuture`);
    elseif (typeof(STRUCTURE) ~= "table") then
        return error(`The structure of the class must be a table not a {typeof(NAME)}`);
    elseif (not STRUCTURE["public"]) or (not STRUCTURE["private"]) then
        return error("The structure must have this form: {private = {}, public = {}}")
    end
    if (STRUCTURE.public[NAME]) and (typeof(STRUCTURE.public[NAME]) ~= "function") then
        return error("The public constructor of the class must be a function");
    end
    if (STRUCTURE.public[DESTRUCTOR_NAME]) and (typeof(STRUCTURE.public[DESTRUCTOR_NAME]) ~= "function") then
        return error("The public destructor of the class must be a function");
    end
    if (STRUCTURE.public[TOSTRING_NAME]) and (typeof(STRUCTURE.public[TOSTRING_NAME]) ~= "function") then
        return error("The public toString of the class must be a function");
    end
    --------------------------------------------------------------------------------
    local function defaultConstructor(self,...)
        local PARAMETERS = ...;
        local i = 1;
        for name, data in pairs(self.private) do
            if PARAMETERS[i] ~= nil then
                self[name] = PARAMETERS[i];
            end
            i += 1;
        end
    end

    local function defaultDestructor(self)
        self = {};
        print("Class destroyed:"..NAME);
    end
    
    local function defaultToString(self)
        local s = "";
        s ..= NAME;
        for name, data in pairs(self) do
            local value = nil;
            if (typeof(data) == "table") then
                value = "{"..table.concat(data,", ").."}";
            else
                value = data;
            end
            s ..="\n"..name.." = "..value;
        end
        return s;
    end

    if (not STRUCTURE.public[NAME]) then
        STRUCTURE.public[NAME] = defaultConstructor;
    end
    if (not STRUCTURE.public[DESTRUCTOR_NAME]) then
        STRUCTURE.public[DESTRUCTOR_NAME] = defaultDestructor;
    end
    if (not STRUCTURE.public[TOSTRING_NAME]) then
        STRUCTURE.public[TOSTRING_NAME] = defaultToString;
    end

    return setmetatable(STRUCTURE, {
        __call = function(BODY, ...)
            local CLASS_OBJECT = {deepcopy(BODY.private), deepcopy(BODY.public)};
            local CLASS_META = {
                __index = CLASS_OBJECT[2];
            }
            setmetatable(CLASS_OBJECT[1], CLASS_META);
            CLASS_OBJECT[2][NAME](CLASS_OBJECT[1], ...)
            for i, components in pairs(CLASS_OBJECT) do
                for name, data in pairs(components) do
                    if (typeof(data) == "function") then
                        CLASS_OBJECT[i][name] = function(...)
                            data(CLASS_OBJECT[1],...);
                            task.wait()
                        end
                    end
                end
            end
            return CLASS_OBJECT[2];
        end
    })
end

return createClass;
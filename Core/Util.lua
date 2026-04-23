local _, ns = ...

local Utils = {}
ns.Utils = Utils

function Utils.DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, nestedValue in pairs(value) do
        copy[key] = Utils.DeepCopy(nestedValue)
    end

    return copy
end

function Utils.MergeDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if target[key] == nil then
            target[key] = Utils.DeepCopy(value)
        elseif type(target[key]) == "table" and type(value) == "table" then
            Utils.MergeDefaults(target[key], value)
        end
    end

    return target
end

function Utils.GetPathValue(source, path)
    if type(source) ~= "table" or type(path) ~= "string" or path == "" then
        return nil
    end

    local cursor = source
    for segment in string.gmatch(path, "[^%.]+") do
        if type(cursor) ~= "table" then
            return nil
        end

        cursor = cursor[segment]
        if cursor == nil then
            return nil
        end
    end

    return cursor
end

function Utils.SetPathValue(target, path, value)
    if type(target) ~= "table" or type(path) ~= "string" or path == "" then
        return
    end

    local cursor = target
    local segments = {}

    for segment in string.gmatch(path, "[^%.]+") do
        segments[#segments + 1] = segment
    end

    for index = 1, #segments - 1 do
        local segment = segments[index]

        if type(cursor[segment]) ~= "table" then
            cursor[segment] = {}
        end

        cursor = cursor[segment]
    end

    cursor[segments[#segments]] = value
end

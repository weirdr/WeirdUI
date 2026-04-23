local _, ns = ...

local Addon = ns.Addon

local Registry = {
    entries = {},
    order = {},
    appliedTargets = setmetatable({}, { __mode = "k" }),
}

Addon.SkinRegistry = Registry

function Registry:Register(id, entry)
    if type(id) ~= "string" or id == "" then
        error("WeirdUI skin registration requires a non-empty string id.")
    end

    if type(entry) ~= "table" or type(entry.apply) ~= "function" then
        error(string.format("WeirdUI skin '%s' requires an apply function.", id))
    end

    if not self.entries[id] then
        self.order[#self.order + 1] = id
    end

    entry.id = id
    self.entries[id] = entry

    return entry
end

function Registry:Get(id)
    return self.entries[id]
end

function Registry:ResolveTarget(entry, explicitTarget)
    if explicitTarget then
        return explicitTarget
    end

    if entry.target then
        return entry.target
    end

    if type(entry.resolveTarget) == "function" then
        return entry.resolveTarget(Addon)
    end

    return nil
end

function Registry:Apply(id, explicitTarget)
    local entry = self.entries[id]
    if not entry then
        return false
    end

    local target = self:ResolveTarget(entry, explicitTarget)
    if not target then
        return false
    end

    if type(entry.isEligible) == "function" and not entry.isEligible(target, Addon) then
        return false
    end

    entry.apply(target, Addon, entry)
    self.appliedTargets[target] = id

    return true
end

function Registry:ApplyAll()
    local appliedCount = 0

    for _, id in ipairs(self.order) do
        if self:Apply(id) then
            appliedCount = appliedCount + 1
        end
    end

    return appliedCount
end

function Registry:ReapplyFrame(frame)
    local id = self.appliedTargets[frame]
    if not id then
        return false
    end

    return self:Apply(id, frame)
end

function Addon:InitializeSkinRegistry()
    self.Skins = Registry
end

function Addon:ReapplyAllSkins()
    return self.Skins:ApplyAll()
end

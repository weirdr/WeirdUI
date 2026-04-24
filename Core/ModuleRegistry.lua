local _, ns = ...

local Addon = ns.Addon

local Registry = {
    entries = {},
    order = {},
}

Addon.Modules = Registry

function Registry:Register(id, entry)
    if type(id) ~= "string" or id == "" then
        error("WeirdUI module registration requires a non-empty string id.")
    end

    if type(entry) ~= "table" then
        error(string.format("WeirdUI module '%s' requires a definition table.", id))
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

function Registry:GetEntries()
    local entries = {}

    for _, id in ipairs(self.order) do
        entries[#entries + 1] = self.entries[id]
    end

    return entries
end

function Addon:RegisterModule(id, entry)
    return Registry:Register(id, entry)
end

function Addon:GetModule(id)
    return Registry:Get(id)
end

function Addon:GetModules()
    return Registry:GetEntries()
end

function Addon:GetModuleSummaryText()
    local modules = self:GetModules()
    if #modules == 0 then
        return "No registered modules yet."
    end

    local labels = {}
    for _, module in ipairs(modules) do
        labels[#labels + 1] = module.label or module.id
    end

    return table.concat(labels, ", ")
end

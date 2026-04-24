local _, ns = ...

local Addon = ns.Addon
local Utils = ns.Utils

local Layout = {
    entries = {},
    order = {},
}

Addon.Layout = Layout

local function Round(value)
    if type(value) ~= "number" then
        return 0
    end

    if value >= 0 then
        return math.floor(value + 0.5)
    end

    return math.ceil(value - 0.5)
end

local function GetDefaultState(entry)
    return Utils.DeepCopy(entry and entry.defaults or {
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = 0,
    })
end

local function EnsureLayoutEditorState()
    local uiState = Addon:GetGlobalUIState()
    if not uiState then
        return nil
    end

    uiState.layoutEditor = uiState.layoutEditor or {
        enabled = false,
        selectedTarget = nil,
    }

    return uiState.layoutEditor
end

local function EnsureLayoutProfileState()
    local profile = Addon:GetCurrentProfile()
    if not profile then
        return nil
    end

    profile.layout = profile.layout or {
        targets = {},
    }
    profile.layout.targets = profile.layout.targets or {}

    return profile.layout
end

local function EnsureOverlay(frame)
    if frame.WeirdUILayoutOverlay then
        return frame.WeirdUILayoutOverlay
    end

    local overlay = CreateFrame("Frame", nil, frame)
    overlay:SetAllPoints()
    overlay:SetFrameStrata("TOOLTIP")
    overlay:EnableMouse(false)

    overlay.Fill = overlay:CreateTexture(nil, "OVERLAY")
    overlay.Fill:SetAllPoints()
    overlay.Fill:SetTexture("Interface\\Buttons\\WHITE8X8")

    overlay.Top = overlay:CreateTexture(nil, "OVERLAY")
    overlay.Top:SetTexture("Interface\\Buttons\\WHITE8X8")
    overlay.Top:SetPoint("TOPLEFT", 0, 0)
    overlay.Top:SetPoint("TOPRIGHT", 0, 0)
    overlay.Top:SetHeight(2)

    overlay.Bottom = overlay:CreateTexture(nil, "OVERLAY")
    overlay.Bottom:SetTexture("Interface\\Buttons\\WHITE8X8")
    overlay.Bottom:SetPoint("BOTTOMLEFT", 0, 0)
    overlay.Bottom:SetPoint("BOTTOMRIGHT", 0, 0)
    overlay.Bottom:SetHeight(2)

    overlay.Left = overlay:CreateTexture(nil, "OVERLAY")
    overlay.Left:SetTexture("Interface\\Buttons\\WHITE8X8")
    overlay.Left:SetPoint("TOPLEFT", 0, 0)
    overlay.Left:SetPoint("BOTTOMLEFT", 0, 0)
    overlay.Left:SetWidth(2)

    overlay.Right = overlay:CreateTexture(nil, "OVERLAY")
    overlay.Right:SetTexture("Interface\\Buttons\\WHITE8X8")
    overlay.Right:SetPoint("TOPRIGHT", 0, 0)
    overlay.Right:SetPoint("BOTTOMRIGHT", 0, 0)
    overlay.Right:SetWidth(2)

    overlay.Label = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    overlay.Label:SetPoint("BOTTOMRIGHT", -12, 12)
    overlay.Label:SetJustifyH("RIGHT")

    overlay.Instruction = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    overlay.Instruction:SetPoint("BOTTOMRIGHT", overlay.Label, "TOPRIGHT", 0, 4)
    overlay.Instruction:SetWidth(180)
    overlay.Instruction:SetJustifyH("RIGHT")
    overlay.Instruction:SetJustifyV("TOP")
    overlay.Instruction:SetWordWrap(true)

    frame.WeirdUILayoutOverlay = overlay
    return overlay
end

local function ApplyOverlayTheme(overlay)
    local accentPrimary = Addon.Theme:GetColor("accent", "primary") or Addon.Theme:GetToken("color.border.accent")
    local accentStrong = Addon.Theme:GetColor("accent", "strong") or Addon.Theme:GetToken("color.role.accent.strong")

    overlay.Fill:SetVertexColor(accentPrimary.r, accentPrimary.g, accentPrimary.b, 0.08)
    overlay.Top:SetVertexColor(accentPrimary.r, accentPrimary.g, accentPrimary.b, accentPrimary.a or 1)
    overlay.Bottom:SetVertexColor(accentPrimary.r, accentPrimary.g, accentPrimary.b, accentPrimary.a or 1)
    overlay.Left:SetVertexColor(accentPrimary.r, accentPrimary.g, accentPrimary.b, accentPrimary.a or 1)
    overlay.Right:SetVertexColor(accentPrimary.r, accentPrimary.g, accentPrimary.b, accentPrimary.a or 1)

    Addon.SkinHelpers:ApplyText(overlay.Label, {
        size = "xs",
        flags = "emphasis",
        colorPath = "color.role.accent.strong",
    })
    Addon.SkinHelpers:ApplyText(overlay.Instruction, {
        size = "xs",
        colorPath = "color.text.secondary",
    })

    overlay.Label:SetTextColor(accentStrong.r, accentStrong.g, accentStrong.b, accentStrong.a or 1)
end

function Layout:Register(id, entry)
    if type(id) ~= "string" or id == "" then
        error("WeirdUI layout target registration requires a non-empty string id.")
    end

    if type(entry) ~= "table" then
        error(string.format("WeirdUI layout target '%s' requires a definition table.", id))
    end

    if not self.entries[id] then
        self.order[#self.order + 1] = id
    end

    entry.id = id
    self.entries[id] = entry
    return entry
end

function Layout:Get(id)
    return self.entries[id]
end

function Layout:GetEntries()
    local entries = {}

    for _, id in ipairs(self.order) do
        entries[#entries + 1] = self.entries[id]
    end

    return entries
end

function Layout:ResolveFrame(entry)
    if type(entry) ~= "table" then
        return nil
    end

    if entry.frame then
        return entry.frame
    end

    if type(entry.resolveFrame) == "function" then
        return entry.resolveFrame(Addon, entry)
    end

    return nil
end

function Addon:RegisterLayoutTarget(id, entry)
    return Layout:Register(id, entry)
end

function Addon:GetLayoutTargetDefinition(id)
    return Layout:Get(id)
end

function Addon:GetLayoutTargetItems()
    local items = {}

    for _, entry in ipairs(Layout:GetEntries()) do
        items[#items + 1] = {
            value = entry.id,
            label = entry.label or entry.id,
        }
    end

    return items
end

function Addon:GetLayoutTargetLabels()
    local labels = {}

    for _, entry in ipairs(Layout:GetEntries()) do
        labels[#labels + 1] = entry.label or entry.id
    end

    return labels
end

function Addon:GetSelectedLayoutTargetID()
    local state = EnsureLayoutEditorState()
    if not state then
        return nil
    end

    local selected = state.selectedTarget
    if selected and Layout:Get(selected) then
        return selected
    end

    local firstID = Layout.order[1]
    state.selectedTarget = firstID
    return firstID
end

function Addon:SetSelectedLayoutTargetID(id)
    if type(id) ~= "string" or not Layout:Get(id) then
        return false
    end

    local state = EnsureLayoutEditorState()
    if not state then
        return false
    end

    state.selectedTarget = id
    self:ApplyLayoutEditingState()
    return true
end

function Addon:IsLayoutEditModeEnabled()
    local state = EnsureLayoutEditorState()
    return state and state.enabled == true or false
end

function Addon:GetLayoutTargetState(id)
    if type(id) ~= "string" or id == "" then
        return nil
    end

    local layoutState = EnsureLayoutProfileState()
    if not layoutState then
        return nil
    end

    if type(layoutState.targets[id]) ~= "table" then
        layoutState.targets[id] = GetDefaultState(Layout:Get(id))
    end

    return layoutState.targets[id]
end

function Addon:IsLayoutTargetAvailable(id)
    local entry = Layout:Get(id)
    local frame = entry and Layout:ResolveFrame(entry)
    return frame ~= nil
end

function Addon:OpenLayoutTarget(id)
    local entry = Layout:Get(id)
    if not entry then
        self:Debug(string.format("Unknown layout target '%s'.", tostring(id)))
        return false
    end

    if type(entry.open) == "function" then
        entry.open(self, entry)
    end

    local frame = Layout:ResolveFrame(entry)
    if not frame then
        self:Debug(string.format("Layout target '%s' is not available yet.", entry.label or id))
        return false
    end

    if frame.Show then
        frame:Show()
    end

    if frame.Raise then
        frame:Raise()
    end

    self:ApplyLayoutTarget(id)
    self:ApplyLayoutEditingState()
    return true
end

function Addon:ApplyLayoutTarget(id)
    local entry = Layout:Get(id)
    local state = self:GetLayoutTargetState(id)
    local frame = entry and Layout:ResolveFrame(entry)
    if not entry or not state or not frame then
        return false
    end

    frame:ClearAllPoints()
    frame:SetPoint(
        state.point or "CENTER",
        UIParent,
        state.relativePoint or state.point or "CENTER",
        state.x or 0,
        state.y or 0
    )

    if frame.SetSize then
        local width = type(state.width) == "number" and state.width or frame:GetWidth()
        local height = type(state.height) == "number" and state.height or frame:GetHeight()

        if type(entry.minimumWidth) == "number" then
            width = math.max(entry.minimumWidth, width or 0)
        end

        if type(entry.minimumHeight) == "number" then
            height = math.max(entry.minimumHeight, height or 0)
        end

        state.width = width
        state.height = height
        frame:SetSize(width, height)
    end

    if type(entry.afterApply) == "function" then
        entry.afterApply(frame, self, entry, state)
    end

    self:RefreshLayoutEditor()
    return true
end

function Addon:ApplyAllLayoutTargets()
    local appliedCount = 0

    for _, entry in ipairs(Layout:GetEntries()) do
        local frame = Layout:ResolveFrame(entry)
        if frame and self:ApplyLayoutTarget(entry.id) then
            appliedCount = appliedCount + 1
        end
    end

    return appliedCount
end

function Addon:CaptureLayoutTarget(id)
    local entry = Layout:Get(id)
    local frame = entry and Layout:ResolveFrame(entry)
    local state = self:GetLayoutTargetState(id)
    if not frame or not state then
        return false
    end

    local point, _, relativePoint, x, y = frame:GetPoint(1)
    state.point = point or "CENTER"
    state.relativePoint = relativePoint or state.point or "CENTER"
    state.x = Round(x)
    state.y = Round(y)
    state.width = Round(frame:GetWidth())
    state.height = Round(frame:GetHeight())

    self:RefreshLayoutEditor()
    return true
end

function Addon:ResetLayoutTarget(id)
    local entry = Layout:Get(id)
    local layoutState = EnsureLayoutProfileState()
    if not entry or not layoutState then
        return false
    end

    layoutState.targets[id] = GetDefaultState(entry)
    self:ApplyLayoutTarget(id)
    self:ApplyLayoutEditingState()
    return true
end

function Addon:GetLayoutTargetStatusText(id)
    local entry = Layout:Get(id)
    if not entry then
        return "No registered layout target selected."
    end

    local state = self:GetLayoutTargetState(id) or GetDefaultState(entry)
    local frame = Layout:ResolveFrame(entry)
    local visibility = frame and (frame:IsShown() and "Visible" or "Hidden") or "Not created yet"

    return string.format(
        "%s\nStored anchor: %s -> %s (%d, %d)\nStored size: %d x %d",
        visibility,
        state.point or "CENTER",
        state.relativePoint or state.point or "CENTER",
        state.x or 0,
        state.y or 0,
        state.width or 0,
        state.height or 0
    )
end

function Addon:RefreshLayoutEditor()
    local activeID = self:IsLayoutEditModeEnabled() and self:GetSelectedLayoutTargetID() or nil

    for _, entry in ipairs(Layout:GetEntries()) do
        local frame = Layout:ResolveFrame(entry)
        if frame then
            local overlay = EnsureOverlay(frame)
            local isActive = activeID ~= nil and entry.id == activeID and frame:IsShown()

            overlay:SetShown(isActive)
            if isActive then
                overlay:SetFrameLevel(math.max(frame:GetFrameLevel() + 10, 20))
                overlay.Label:SetText("Layout Edit")
                overlay.Instruction:SetText(string.format(
                    "%s\nDrag to move",
                    entry.label or entry.id
                ))
                if frame:GetHeight() < 320 then
                    overlay.Instruction:SetShown(false)
                else
                    overlay.Instruction:SetShown(true)
                end
                ApplyOverlayTheme(overlay)
            end
        end
    end
end

function Addon:ApplyLayoutEditingState()
    local activeID = self:IsLayoutEditModeEnabled() and self:GetSelectedLayoutTargetID() or nil

    for _, entry in ipairs(Layout:GetEntries()) do
        local frame = Layout:ResolveFrame(entry)
        if frame and type(entry.setEditingEnabled) == "function" then
            entry.setEditingEnabled(frame, entry.id == activeID, self, entry)
        end
    end

    self:RefreshLayoutEditor()

    local menu = self.Menu
    if menu and menu.frame and menu.frame:IsShown() then
        self:ReapplyMenu()
    end
end

function Addon:SetLayoutEditModeEnabled(enabled)
    local state = EnsureLayoutEditorState()
    if not state then
        return false
    end

    if InCombatLockdown and InCombatLockdown() then
        self:Debug("Layout edit mode is unavailable during combat.")
        return false
    end

    state.enabled = enabled and true or false
    self:ApplyLayoutEditingState()
    return true
end

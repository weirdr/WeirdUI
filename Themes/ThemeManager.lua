local _, ns = ...

local Addon = ns.Addon
local Constants = ns.Constants
local Utils = ns.Utils

local Theme = {}
Addon.Theme = Theme

local function GetBuiltinTheme(themeID)
    return ns.BuiltinThemes[themeID] or ns.BuiltinThemes[Constants.DefaultThemeID]
end

function Theme:GetDefaultTheme()
    return GetBuiltinTheme(Constants.DefaultThemeID)
end

function Theme:GetActiveThemeDefinition()
    local profile = Addon:GetCurrentProfile()
    local themeID = profile and profile.theme and profile.theme.activeTheme or Constants.DefaultThemeID
    local userTheme = Addon:GetUserTheme(themeID)

    if type(userTheme) == "table" and type(userTheme.tokens) == "table" then
        return userTheme
    end

    return GetBuiltinTheme(themeID)
end

function Theme:GetActiveThemeID()
    local theme = self:GetActiveThemeDefinition()
    return theme and theme.id or Constants.DefaultThemeID
end

function Theme:GetActiveThemeLabel()
    local theme = self:GetActiveThemeDefinition()
    return theme and theme.label or Constants.DefaultThemeID
end

function Theme:GetToken(path)
    local profile = Addon:GetCurrentProfile()
    if profile and profile.theme and profile.theme.overrides then
        local overrideValue = Utils.GetPathValue(profile.theme.overrides, path)
        if overrideValue ~= nil then
            return overrideValue
        end
    end

    local activeTheme = self:GetActiveThemeDefinition()
    if activeTheme and activeTheme.tokens then
        local themeValue = Utils.GetPathValue(activeTheme.tokens, path)
        if themeValue ~= nil then
            return themeValue
        end
    end

    return Utils.GetPathValue(self:GetDefaultTheme().tokens, path)
end

function Theme:GetColor(role, variant)
    return self:GetToken(string.format("color.role.%s.%s", role, variant or "primary"))
end

function Theme:GetWidgetState(state)
    return self:GetToken(string.format("color.state.%s", state or "normal")) or self:GetToken("color.state.normal")
end

function Theme:GetFont(name)
    return self:GetToken(string.format("typography.font.%s", name or "primary"))
end

function Theme:SetProfileOverride(path, value)
    local profile = Addon:GetCurrentProfile()
    if not profile or not profile.theme then
        return
    end

    Utils.SetPathValue(profile.theme.overrides, path, value)
end

function Addon:InitializeThemeManager()
    self.Theme = Theme
end

function Addon:GetThemeToken(path)
    return self.Theme:GetToken(path)
end

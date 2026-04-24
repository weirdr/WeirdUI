local addonName, ns = ...

local Addon = CreateFrame("Frame")
ns.Addon = Addon
ns.Name = addonName

local function GetMetadataValue(key)
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        return C_AddOns.GetAddOnMetadata(addonName, key)
    end

    return GetAddOnMetadata(addonName, key)
end

ns.Version = GetMetadataValue("Version") or "dev"
ns.Constants = {
    DatabaseVersion = 1,
    DefaultProfileName = "Default",
    DefaultThemeID = "weird-midnight",
}

function Addon:Debug(message)
    local prefix = string.format("|cff7aa6ff%s|r", addonName)
    print(prefix, message)
end

function Addon:GetCharacterKey()
    local characterName = UnitName("player") or "Unknown"
    local realmName = GetRealmName() or "UnknownRealm"
    return string.format("%s - %s", characterName, realmName)
end

function Addon:Initialize()
    self:InitializeDatabase()
    self:InitializeThemeManager()
    if self.InitializeSkinRegistry then
        self:InitializeSkinRegistry()
    end

    if self.InitializeMenu then
        self:InitializeMenu()
    end

    if self.InitializeObjectiveTrackerModule then
        self:InitializeObjectiveTrackerModule()
    end

    if self.InitializeDebugTools then
        self:InitializeDebugTools()
    end

    if self:GetCurrentProfile().ui.showLoadMessage then
        self:Debug(string.format("Loaded v%s with profile '%s' and theme '%s'.", ns.Version, self:GetCurrentProfileName(), self.Theme:GetActiveThemeID()))
    end

    C_Timer.After(0, function()
        if Addon.ToggleMenu and (not Addon.Menu or not Addon.Menu.frame or not Addon.Menu.frame:IsShown()) then
            Addon:ToggleMenu()
        end
    end)
end

Addon:RegisterEvent("PLAYER_LOGIN")
Addon:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        Addon:Initialize()
    end
end)

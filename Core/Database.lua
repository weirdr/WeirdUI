local _, ns = ...

local Addon = ns.Addon
local Constants = ns.Constants
local Utils = ns.Utils

local DefaultProfile = {
    layout = {
        targets = {},
    },
    theme = {
        activeTheme = Constants.DefaultThemeID,
        overrides = {},
    },
    ui = {
        objectiveTracker = {
            enabled = true,
            compactHeader = false,
            highlightCurrentZone = false,
            backgroundOpacity = 0.94,
            scale = 1,
            sectionCardOpacity = 0.60,
            sectionCardColors = {},
            sectionCardOpacities = {},
            sectionAccentColors = {},
            fontSizes = {
                detail = 13,
                meta = 11,
                questTitle = 15,
                sectionHeader = 16,
            },
            width = 300,
            height = 600,
            collapsed = {
                quests = false,
                world = false,
                delves = false,
                reputation = false,
                professions = false,
                pvp = false,
                events = false,
                instances = false,
            },
        },
        showLoadMessage = true,
        previewValue = 72,
        previewTone = "accent",
        previewEnabled = true,
        previewLabel = "Embedded Preview",
        previewSwatch = "accent",
        previewDensity = "comfortable",
        previewLeftValue = 28,
        previewRightValue = 76,
        previewWarningAcknowledged = false,
    },
}

ns.DatabaseDefaults = {
    version = Constants.DatabaseVersion,
    global = {
        themes = {},
        ui = {
            layoutEditor = {
                enabled = false,
                selectedTarget = "preview.frame",
            },
            onboarding = {
                completed = false,
            },
            menu = {
                lastPage = "overview",
                scale = 1,
            },
        },
    },
    profiles = {
        [Constants.DefaultProfileName] = DefaultProfile,
    },
    profileKeys = {},
}

function Addon:InitializeDatabase()
    if type(WeirdUIDB) ~= "table" then
        WeirdUIDB = {}
    end

    Utils.MergeDefaults(WeirdUIDB, ns.DatabaseDefaults)
    WeirdUIDB.version = Constants.DatabaseVersion

    local characterKey = self:GetCharacterKey()
    local profileName = WeirdUIDB.profileKeys[characterKey] or Constants.DefaultProfileName

    WeirdUIDB.profileKeys[characterKey] = profileName

    if type(WeirdUIDB.profiles[profileName]) ~= "table" then
        WeirdUIDB.profiles[profileName] = Utils.DeepCopy(DefaultProfile)
    end

    self.db = WeirdUIDB
    self.characterKey = characterKey
    self.profileName = profileName
    self.profile = WeirdUIDB.profiles[profileName]
end

function Addon:GetDatabase()
    return self.db
end

function Addon:GetCurrentProfile()
    return self.profile
end

function Addon:GetCurrentProfileName()
    return self.profileName
end

function Addon:GetProfileNames()
    if not self.db or type(self.db.profiles) ~= "table" then
        return {}
    end

    local names = {}
    for name in pairs(self.db.profiles) do
        names[#names + 1] = name
    end

    table.sort(names)
    return names
end

function Addon:UseProfile(profileName)
    if type(profileName) ~= "string" or profileName == "" or not self.db then
        return false
    end

    if type(self.db.profiles[profileName]) ~= "table" then
        self.db.profiles[profileName] = Utils.DeepCopy(DefaultProfile)
    end

    self.db.profileKeys[self.characterKey] = profileName
    self.profileName = profileName
    self.profile = self.db.profiles[profileName]
    if self.ApplyAllLayoutTargets then
        self:ApplyAllLayoutTargets()
    end
    return true
end

function Addon:CreateProfile(profileName)
    if type(profileName) ~= "string" then
        return false, "invalid"
    end

    profileName = strtrim(profileName)
    if profileName == "" then
        return false, "empty"
    end

    if not self.db then
        return false, "missing_db"
    end

    if self.db.profiles[profileName] then
        return false, "exists"
    end

    self.db.profiles[profileName] = Utils.DeepCopy(DefaultProfile)
    return true
end

function Addon:ResetCurrentProfile()
    if not self.db or not self.profileName then
        return false
    end

    self.db.profiles[self.profileName] = Utils.DeepCopy(DefaultProfile)
    self.profile = self.db.profiles[self.profileName]
    if self.ApplyAllLayoutTargets then
        self:ApplyAllLayoutTargets()
    end
    return true
end

function Addon:GetUserTheme(themeID)
    if not self.db then
        return nil
    end

    return self.db.global.themes[themeID]
end

function Addon:GetGlobalUIState()
    return self.db and self.db.global and self.db.global.ui
end

function Addon:IsOnboardingComplete()
    local uiState = self:GetGlobalUIState()
    return uiState and uiState.onboarding and uiState.onboarding.completed == true or false
end

function Addon:CompleteOnboarding()
    local uiState = self:GetGlobalUIState()
    if not uiState then
        return
    end

    uiState.onboarding = uiState.onboarding or {}
    uiState.onboarding.completed = true
end

local _, ns = ...

local Addon = ns.Addon
local Constants = ns.Constants
local Utils = ns.Utils

local DefaultProfile = {
    theme = {
        activeTheme = Constants.DefaultThemeID,
        overrides = {},
    },
    ui = {
        showLoadMessage = true,
    },
}

ns.DatabaseDefaults = {
    version = Constants.DatabaseVersion,
    global = {
        themes = {},
        ui = {
            menu = {
                lastPage = "overview",
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

function Addon:GetUserTheme(themeID)
    if not self.db then
        return nil
    end

    return self.db.global.themes[themeID]
end

function Addon:GetGlobalUIState()
    return self.db and self.db.global and self.db.global.ui
end

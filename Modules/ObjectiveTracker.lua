local _, ns = ...

local Addon = ns and ns.Addon
if not Addon then
    return
end

local Module = {
    eventFrame = nil,
    frame = nil,
    hooksRegistered = false,
    layoutRegistered = false,
    pageRegistered = false,
    suppressingBlizzardTracker = false,
    skinRegistered = false,
}

Addon.ObjectiveTracker = Module

local ROOT_LAYOUT_TARGET_ID = "objective-tracker.frame"
local TRACKER_SCALE_MIN = 0.75
local TRACKER_SCALE_MAX = 1.25
local TRACKER_SCALE_STEP = 0.01
local SECTION_ORDER = {
    { key = "quests", label = "Quests" },
    { key = "world", label = "World Quests" },
    { key = "delves", label = "Delves" },
    { key = "reputation", label = "Reputation" },
    { key = "professions", label = "Professions" },
    { key = "pvp", label = "PvP" },
    { key = "events", label = "Events" },
    { key = "instances", label = "Dungeons & Raids" },
}

local function CopyColor(color)
    if type(color) ~= "table" then
        return nil
    end

    return {
        r = color.r,
        g = color.g,
        b = color.b,
        a = color.a,
    }
end

local SECTION_STYLE_COLORS = {
    quests = {
        background = { r = 0.30, g = 0.19, b = 0.03, a = 1 },
        border = { r = 0.96, g = 0.76, b = 0.34, a = 1 },
        title = { r = 1.00, g = 0.88, b = 0.56, a = 1 },
    },
    world = {
        background = { r = 0.05, g = 0.16, b = 0.31, a = 1 },
        border = { r = 0.46, g = 0.67, b = 0.98, a = 1 },
        title = { r = 0.80, g = 0.89, b = 1.00, a = 1 },
    },
    delves = {
        background = { r = 0.18, g = 0.08, b = 0.33, a = 1 },
        border = { r = 0.76, g = 0.56, b = 0.97, a = 1 },
        title = { r = 0.90, g = 0.80, b = 1.00, a = 1 },
    },
    reputation = {
        background = { r = 0.26, g = 0.14, b = 0.05, a = 1 },
        border = { r = 0.84, g = 0.60, b = 0.34, a = 1 },
        title = { r = 0.95, g = 0.79, b = 0.58, a = 1 },
    },
    professions = {
        background = { r = 0.04, g = 0.23, b = 0.17, a = 1 },
        border = { r = 0.44, g = 0.86, b = 0.66, a = 1 },
        title = { r = 0.79, g = 0.98, b = 0.90, a = 1 },
    },
    pvp = {
        background = { r = 0.26, g = 0.05, b = 0.08, a = 1 },
        border = { r = 0.94, g = 0.40, b = 0.48, a = 1 },
        title = { r = 1.00, g = 0.79, b = 0.82, a = 1 },
    },
    events = {
        background = { r = 0.05, g = 0.20, b = 0.22, a = 1 },
        border = { r = 0.49, g = 0.85, b = 0.80, a = 1 },
        title = { r = 0.82, g = 1.00, b = 0.96, a = 1 },
    },
    instances = {
        background = { r = 0.26, g = 0.11, b = 0.04, a = 1 },
        border = { r = 1.00, g = 0.56, b = 0.34, a = 1 },
        title = { r = 1.00, g = 0.84, b = 0.69, a = 1 },
    },
}

local function GetSettings()
    local profile = Addon:GetCurrentProfile()
    profile.ui.objectiveTracker = profile.ui.objectiveTracker or {
        enabled = true,
        compactHeader = false,
        highlightCurrentZone = false,
        backgroundOpacity = 0.94,
        scale = 1,
        sectionCardOpacity = 0.60,
        fontSizes = {
            detail = 13,
            meta = 11,
            questTitle = 15,
            sectionHeader = 16,
        },
        width = 300,
        height = 600,
        sectionCardColors = {},
        sectionCardOpacities = {},
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
    }

    profile.ui.objectiveTracker.collapsed = profile.ui.objectiveTracker.collapsed or {
        quests = false,
        world = false,
        delves = false,
        reputation = false,
        professions = false,
        pvp = false,
        events = false,
        instances = false,
    }

    profile.ui.objectiveTracker.collapsed.delves = profile.ui.objectiveTracker.collapsed.delves or false
    profile.ui.objectiveTracker.collapsed.reputation = profile.ui.objectiveTracker.collapsed.reputation or false
    profile.ui.objectiveTracker.collapsed.professions = profile.ui.objectiveTracker.collapsed.professions or false
    profile.ui.objectiveTracker.collapsed.pvp = profile.ui.objectiveTracker.collapsed.pvp or false
    profile.ui.objectiveTracker.collapsed.events = profile.ui.objectiveTracker.collapsed.events or false
    profile.ui.objectiveTracker.collapsed.instances = profile.ui.objectiveTracker.collapsed.instances or false

    profile.ui.objectiveTracker.fontSizes = profile.ui.objectiveTracker.fontSizes or {
        detail = 13,
        meta = 11,
        questTitle = 15,
        sectionHeader = 16,
    }

    profile.ui.objectiveTracker.sectionCardColors = profile.ui.objectiveTracker.sectionCardColors or {}
    profile.ui.objectiveTracker.sectionCardOpacities = profile.ui.objectiveTracker.sectionCardOpacities or {}
    profile.ui.objectiveTracker.sectionAccentColors = profile.ui.objectiveTracker.sectionAccentColors or {}

    for _, sectionInfo in ipairs(SECTION_ORDER) do
        local key = sectionInfo.key
        local palette = SECTION_STYLE_COLORS[key] or SECTION_STYLE_COLORS.quests

        if type(profile.ui.objectiveTracker.sectionCardColors[key]) ~= "table" then
            profile.ui.objectiveTracker.sectionCardColors[key] = CopyColor(palette.border)
        end

        if type(profile.ui.objectiveTracker.sectionCardOpacities[key]) ~= "number" then
            profile.ui.objectiveTracker.sectionCardOpacities[key] = profile.ui.objectiveTracker.sectionCardOpacity or 0.60
        end

        if type(profile.ui.objectiveTracker.sectionAccentColors[key]) ~= "table" then
            profile.ui.objectiveTracker.sectionAccentColors[key] = CopyColor(palette.border)
        end
    end

    return profile.ui.objectiveTracker
end

local function GetFontSize(settings, key, defaultValue)
    local fontSizes = settings.fontSizes or {}
    local value = fontSizes[key]

    if type(value) ~= "number" then
        value = defaultValue
        fontSizes[key] = value
        settings.fontSizes = fontSizes
    end

    return math.max(8, math.min(32, math.floor(value + 0.5)))
end

local function GetBackgroundOpacity(settings)
    local value = settings.backgroundOpacity
    if type(value) ~= "number" then
        value = 0.94
        settings.backgroundOpacity = value
    end

    return math.max(0, math.min(1, value))
end

local function GetSectionCardOpacity(settings)
    local value = settings.sectionCardOpacity
    if type(value) ~= "number" then
        value = 0.60
        settings.sectionCardOpacity = value
    end

    return math.max(0, math.min(1, value))
end

local function GetTrackerScale(settings)
    local value = settings.scale
    if type(value) ~= "number" then
        value = 1
        settings.scale = value
    end

    return math.max(TRACKER_SCALE_MIN, math.min(TRACKER_SCALE_MAX, value))
end

local function GetTrackerWidth(settings)
    return math.max(240, math.min(520, math.floor((settings.width or 300) + 0.5)))
end

local function GetTrackerHeight(settings)
    return math.max(260, math.min(900, math.floor((settings.height or 600) + 0.5)))
end

local function GetBlizzardTrackerFrame()
    return _G.ObjectiveTrackerFrame
end

local function ShouldHideBlizzardTracker()
    local settings = GetSettings()
    return settings and settings.enabled ~= false
end

local function Clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
end

local function BlendColor(baseColor, tintColor, amount, alpha)
    if not baseColor then
        return tintColor
    end

    if not tintColor then
        return baseColor
    end

    amount = math.max(0, math.min(1, amount or 0))

    return {
        r = baseColor.r + ((tintColor.r or baseColor.r) - baseColor.r) * amount,
        g = baseColor.g + ((tintColor.g or baseColor.g) - baseColor.g) * amount,
        b = baseColor.b + ((tintColor.b or baseColor.b) - baseColor.b) * amount,
        a = alpha or baseColor.a or tintColor.a or 1,
    }
end

local function CreateText(parent, layer, template)
    return parent:CreateFontString(nil, layer or "OVERLAY", template or "GameFontHighlightSmall")
end

local function ApplyTrackerText(fontString, options)
    options = options or {}

    local fontFile = Addon.Theme:GetFont(options.font or "primary")
    local fallbackFile, fallbackSize, fallbackFlags = GameFontNormal:GetFont()
    local fontFlags = Addon.Theme:GetToken(string.format("typography.flag.%s", options.flags or "body")) or fallbackFlags or ""
    local color = Addon.Theme:GetToken(options.colorPath or "color.text.primary")
    local size = options.size or fallbackSize or 12

    fontString:SetFont(fontFile or fallbackFile, size, fontFlags)
    fontString:SetTextColor(color.r, color.g, color.b, color.a or 1)

    if options.shadow == false then
        fontString:SetShadowOffset(0, 0)
        fontString:SetShadowColor(0, 0, 0, 0)
    else
        local shadowAlpha = options.shadowAlpha or 0.8
        fontString:SetShadowOffset(options.shadowOffsetX or 1, options.shadowOffsetY or -1)
        fontString:SetShadowColor(0, 0, 0, shadowAlpha)
    end
end

local function ApplyColor(texture, color, alpha)
    if not texture or not color then
        return
    end

    if texture.SetColorTexture then
        texture:SetColorTexture(color.r, color.g, color.b, alpha or color.a or 1)
        return
    end

    texture:SetVertexColor(color.r, color.g, color.b, alpha or color.a or 1)
end

local function EnsureFillTexture(parent, key, layer, subLevel)
    if not parent[key] then
        parent[key] = parent:CreateTexture(nil, layer or "ARTWORK", nil, subLevel or 0)
        parent[key]:SetTexture("Interface\\Buttons\\WHITE8X8")
    end

    return parent[key]
end

local function MeasureTextHeight(fontString)
    if not fontString then
        return 0
    end

    local text = fontString:GetText()
    if not text or text == "" then
        return 0
    end

    return math.ceil(fontString:GetStringHeight() or 0)
end

local function GetSectionStyle(sectionKey)
    return sectionKey or "quests"
end

local function GetSectionPalette(sectionKey)
    local style = GetSectionStyle(sectionKey)
    return SECTION_STYLE_COLORS[style] or SECTION_STYLE_COLORS.quests
end

local function GetSectionAccentColor(settings, sectionKey)
    settings = settings or GetSettings()
    local colors = settings.sectionAccentColors or {}
    local palette = GetSectionPalette(sectionKey)
    return CopyColor(colors[sectionKey]) or CopyColor(palette.border)
end

local function GetSectionTitleColor(settings, sectionKey)
    settings = settings or GetSettings()
    local palette = GetSectionPalette(sectionKey)

    if settings.sectionAccentColors and type(settings.sectionAccentColors[sectionKey]) == "table" then
        return BlendColor(GetSectionAccentColor(settings, sectionKey), { r = 1, g = 1, b = 1, a = 1 }, 0.24, 1)
    end

    return CopyColor(palette.title)
end

local function GetRowPalette(settings, sectionKey)
    local palette = GetSectionPalette(sectionKey)
    return {
        background = {
            r = palette.background.r,
            g = palette.background.g,
            b = palette.background.b,
            a = 1,
        },
        border = GetSectionAccentColor(settings, sectionKey),
        title = GetSectionTitleColor(settings, sectionKey),
    }
end

local function GetSectionTintColor(settings, sectionKey)
    settings = settings or GetSettings()
    local colors = settings.sectionCardColors or {}
    local palette = GetSectionPalette(sectionKey)
    return CopyColor(colors[sectionKey]) or CopyColor(palette.border)
end

local function GetSectionTintOpacity(settings, sectionKey)
    local value = settings.sectionCardOpacities and settings.sectionCardOpacities[sectionKey]
    if type(value) ~= "number" then
        value = GetSectionCardOpacity(settings)
        settings.sectionCardOpacities = settings.sectionCardOpacities or {}
        settings.sectionCardOpacities[sectionKey] = value
    end

    return math.max(0, math.min(1, value))
end

local function CreateToggleButton(parent, onClick)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(18, 18)

    button.Horizontal = button:CreateTexture(nil, "OVERLAY")
    button.Horizontal:SetTexture("Interface\\Buttons\\WHITE8X8")
    button.Horizontal:SetPoint("CENTER")
    button.Horizontal:SetSize(8, 1)

    button.Vertical = button:CreateTexture(nil, "OVERLAY")
    button.Vertical:SetTexture("Interface\\Buttons\\WHITE8X8")
    button.Vertical:SetPoint("CENTER")
    button.Vertical:SetSize(1, 8)

    button:SetScript("OnClick", onClick)
    button:SetScript("OnEnter", function(control)
        control.hovered = true
        if Module.frame then
            Module:ApplyTheme()
        end
    end)
    button:SetScript("OnLeave", function(control)
        control.hovered = nil
        if Module.frame then
            Module:ApplyTheme()
        end
    end)

    return button
end

local function ApplyToggleTheme(button, collapsed)
    local tone = button.hovered and Addon.Theme:GetColor("accent", "strong") or Addon.Theme:GetToken("color.text.primary")
    ApplyColor(button.Horizontal, tone)
    ApplyColor(button.Vertical, tone)
    button.Vertical:SetShown(collapsed == true)
end

local function BuildQuestStateText(entry)
    if entry.ready then
        return "Ready for turn-in"
    end

    if entry.failed then
        return "Failed"
    end

    if entry.complete then
        return "Complete"
    end

    return nil
end

local function BuildQuestObjectiveText(entry)
    local lines = {}

    if entry.stateText then
        lines[#lines + 1] = entry.stateText
    end

    for _, objectiveText in ipairs(entry.objectives) do
        lines[#lines + 1] = objectiveText
    end

    if #lines == 0 then
        return "No objectives currently available."
    end

    return table.concat(lines, "\n")
end

local function BuildQuestEntry(questID, isWorldQuest)
    if not questID then
        return nil
    end

    local title = C_QuestLog.GetTitleForQuestID(questID)
    if not title or title == "" then
        title = string.format("Quest %d", questID)
        C_QuestLog.RequestLoadQuestByID(questID)
    end

    local objectives = {}
    for _, objectiveInfo in ipairs(C_QuestLog.GetQuestObjectives(questID) or {}) do
        if objectiveInfo.text and objectiveInfo.text ~= "" then
            objectives[#objectives + 1] = objectiveInfo.text
        end
    end

    local tagInfo = C_QuestLog.GetQuestTagInfo(questID)

    local entry = {
        complete = C_QuestLog.IsComplete(questID) == true,
        isWorldQuest = isWorldQuest == true or C_QuestLog.IsWorldQuest(questID),
        objectives = objectives,
        questID = questID,
        ready = C_QuestLog.ReadyForTurnIn(questID) == true,
        failed = C_QuestLog.IsFailed(questID),
        title = title,
        tag = tagInfo and tagInfo.tagName or nil,
    }

    entry.stateText = BuildQuestStateText(entry)
    entry.objectiveText = BuildQuestObjectiveText(entry)
    return entry
end

local function CreatePreviewEntry(options)
    options = options or {}

    local entry = {
        complete = options.complete == true,
        failed = options.failed == true,
        isPreview = true,
        isWorldQuest = options.isWorldQuest == true,
        objectives = options.objectives or {},
        questID = options.questID or 0,
        ready = options.ready == true,
        title = options.title or "Preview Objective",
        tag = options.tag,
    }

    entry.stateText = options.stateText or BuildQuestStateText(entry)
    entry.objectiveText = BuildQuestObjectiveText(entry)
    return entry
end

local function GetPreviewWeeklyData()
    return {
        delves = {
            CreatePreviewEntry({
                title = "A Call to Delves",
                tag = "Weekly Delve",
                objectives = {
                    "Complete 5 Delves in Khaz Algar.",
                    "Delves completed at any tier: 3 / 5",
                },
            }),
            CreatePreviewEntry({
                title = "Delver's Run: The Spiral Weave",
                tag = "Pinnacle Delve",
                ready = true,
                objectives = {
                    "Finish a bountiful Delve using a coffer key.",
                    "Bountiful Delve completed: 1 / 1",
                },
            }),
        },
        reputation = {
            CreatePreviewEntry({
                title = "A Worthy Ally: Dream Wardens",
                tag = "Weekly Reputation",
                objectives = {
                    "Earn 1,500 reputation with the Dream Wardens.",
                    "Reputation earned: 900 / 1,500",
                },
            }),
            CreatePreviewEntry({
                title = "A Worthy Ally: The Assembly of the Deeps",
                tag = "Weekly Reputation",
                complete = true,
                objectives = {
                    "Earn 1,500 reputation with the Assembly of the Deeps.",
                    "Reputation earned: 1,500 / 1,500",
                },
            }),
        },
        professions = {
            CreatePreviewEntry({
                title = "Engineering Services Requested",
                tag = "Weekly Profession",
                objectives = {
                    "Fill Engineering Crafting Orders for the Artisan's Consortium.",
                    "Orders fulfilled: 2 / 3",
                },
            }),
            CreatePreviewEntry({
                title = "Jewelcrafting Services Requested",
                tag = "Weekly Profession",
                ready = true,
                objectives = {
                    "Fill Jewelcrafting Crafting Orders for the Artisan's Consortium.",
                    "Orders fulfilled: 3 / 3",
                },
            }),
        },
        pvp = {
            CreatePreviewEntry({
                title = "Against Overwhelming Odds",
                tag = "Weekly War Mode PvP",
                objectives = {
                    "Slay 25 enemy players in War Mode.",
                    "Opponents defeated: 11 / 25",
                },
            }),
            CreatePreviewEntry({
                title = "Sparks of War: City Push",
                tag = "Weekly PvP Wrapper",
                objectives = {
                    "Earn 100 Sparks in world PvP activities.",
                    "Sparks earned: 76 / 100",
                },
            }),
        },
        events = {
            CreatePreviewEntry({
                title = "Hallowfall Fishing Derby",
                tag = "Weekly Event",
                objectives = {
                    "Catch these Trophy Fish before the Derby Dasher buff expires.",
                    "Catch a Queen's Lurefish",
                    "Catch a Regal Dottyback",
                    "Catch a Spiked Sea Raven",
                },
            }),
            CreatePreviewEntry({
                title = "Timewalking Bonus Event",
                tag = "Weekly Event",
                ready = true,
                objectives = {
                    "Complete 5 Timewalking dungeons.",
                    "Timewalking dungeons completed: 5 / 5",
                },
            }),
        },
        instances = {
            CreatePreviewEntry({
                title = "Disturbance Detected: Blackrock Depths",
                tag = "Weekly Timewalking",
                objectives = {
                    "Recover the Timewarped Ironforge Blueprints.",
                    "Dagran Thaurissan defeated",
                },
            }),
            CreatePreviewEntry({
                title = "Raid Recon: Shadowed Citadel",
                tag = "Weekly Raid",
                complete = true,
                objectives = {
                    "Defeat the final boss on any difficulty.",
                    "Final boss defeated: 1 / 1",
                },
            }),
        },
    }
end

local function GetQuestIconPresentation(entry, settings)
    if entry.failed then
        return "!", "color.role.danger.strong"
    end

    if entry.ready or entry.complete then
        return "?", "color.role.success.strong"
    end

    if entry.isWorldQuest then
        return "?", "color.role.warning.strong"
    end

    return "?", "color.text.primary"
end

function Module:RefreshData()
    local data = {
        quests = {},
        world = {},
        delves = {},
        reputation = {},
        professions = {},
        pvp = {},
        events = {},
        instances = {},
        previewTotal = 0,
        total = 0,
    }
    local seen = {}

    for watchIndex = 1, C_QuestLog.GetNumQuestWatches() do
        local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(watchIndex)
        if questID and not seen[questID] then
            seen[questID] = true
            local entry = BuildQuestEntry(questID, false)
            if entry then
                if entry.isWorldQuest then
                    data.world[#data.world + 1] = entry
                else
                    data.quests[#data.quests + 1] = entry
                end
                data.total = data.total + 1
            end
        end
    end

    for watchIndex = 1, C_QuestLog.GetNumWorldQuestWatches() do
        local questID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(watchIndex)
        if questID and not seen[questID] then
            seen[questID] = true
            local entry = BuildQuestEntry(questID, true)
            if entry then
                data.world[#data.world + 1] = entry
                data.total = data.total + 1
            end
        end
    end

    do
        local previewData = GetPreviewWeeklyData()

        for _, sectionInfo in ipairs(SECTION_ORDER) do
            local previewEntries = previewData[sectionInfo.key]
            if previewEntries then
                for _, entry in ipairs(previewEntries) do
                    data[sectionInfo.key][#data[sectionInfo.key] + 1] = entry
                    data.total = data.total + 1
                    data.previewTotal = data.previewTotal + 1
                end
            end
        end
    end

    self.data = data
    return data
end

local function AcquireQuestRow(section, index)
    if section.Rows[index] then
        return section.Rows[index]
    end

    local row = CreateFrame("Frame", nil, section.Content)

    row.IconHolder = CreateFrame("Frame", nil, row)
    row.IconHolder:SetSize(18, 18)

    row.IconGlyph = CreateText(row.IconHolder)
    row.IconGlyph:SetPoint("CENTER", 0, 0)
    row.IconGlyph:SetJustifyH("CENTER")

    row.IconShadow = CreateText(row.IconHolder, "BACKGROUND")
    row.IconShadow:SetPoint("CENTER", 1, -1)
    row.IconShadow:SetJustifyH("CENTER")

    row.Title = CreateText(row)
    row.Title:SetJustifyH("LEFT")

    row.Meta = CreateText(row)
    row.Meta:SetJustifyH("LEFT")

    row.Detail = CreateText(row)
    row.Detail:SetJustifyH("LEFT")
    row.Detail:SetJustifyV("TOP")
    row.Detail:SetWordWrap(true)

    row.Separator = row:CreateTexture(nil, "BORDER")
    row.Separator:SetTexture("Interface\\Buttons\\WHITE8X8")

    function row:SetQuest(entry, settings, contentWidth, isLast)
        local compact = settings.compactHeader == true
        local leftPadding = compact and 10 or 12
        local rightPadding = compact and 10 or 12
        local topPadding = compact and 10 or 12
        local bottomPadding = compact and 10 or 12
        local iconGap = compact and 8 or 10
        local detailGap = compact and 4 or 6
        local metaGap = compact and 2 or 3
        local detailSize = GetFontSize(settings, "detail", 13)
        local metaSize = GetFontSize(settings, "meta", 11)
        local questTitleSize = GetFontSize(settings, "questTitle", 15)
        local iconSize = math.max(18, questTitleSize + 2)
        local maxTextWidth = math.max(120, contentWidth - leftPadding - rightPadding - iconSize - iconGap)
        local rowPalette = GetRowPalette(settings, section.Key)
        local rowTintColor = GetSectionTintColor(settings, section.Key)
        local rowTintOpacity = GetSectionTintOpacity(settings, section.Key)
        local emphasizeTitles = settings.highlightCurrentZone == true
        local insetSurfaceColor = Addon.Theme:GetToken("color.surface.inset")
        local neutralTitleColor = Addon.Theme:GetToken("color.text.primary")
        local titleColorPath = entry.ready and "color.role.success.strong"
            or (entry.failed and "color.role.danger.strong")
            or nil
        local iconGlyph, iconColorPath = GetQuestIconPresentation(entry, settings)

        Addon.SkinHelpers:ApplyPanel(self, {
            accent = false,
            shadow = false,
            surfaceColorPath = "color.surface.inset",
            borderColorPath = "color.border.subtle",
        })
        if self.WeirdUIAccent then
            self.WeirdUIAccent:SetAlpha(0)
        end
        if self.WeirdUIBackground then
            ApplyColor(self.WeirdUIBackground, BlendColor(insetSurfaceColor, rowTintColor, 0.18, 1), 1)
            self.WeirdUIBackground:SetAlpha(rowTintOpacity * 0.12)
        end
        if self.WeirdUIBorderTop then
            self.WeirdUIBorderTop:SetAlpha(0)
        end
        if self.WeirdUIBorderLeft then
            self.WeirdUIBorderLeft:SetAlpha(0)
        end
        if self.WeirdUIBorderRight then
            self.WeirdUIBorderRight:SetAlpha(0)
        end
        if self.WeirdUIBorderBottom then
            self.WeirdUIBorderBottom:SetAlpha(0)
        end

        ApplyTrackerText(self.IconGlyph, {
            size = math.max(16, questTitleSize + 2),
            flags = "display",
            colorPath = iconColorPath,
        })
        if emphasizeTitles and not titleColorPath then
            self.IconGlyph:SetTextColor(rowPalette.title.r, rowPalette.title.g, rowPalette.title.b, rowPalette.title.a or 1)
        end
        ApplyTrackerText(self.IconShadow, {
            size = math.max(16, questTitleSize + 2),
            flags = "display",
            colorPath = "color.text.primary",
            shadow = false,
        })
        self.IconShadow:SetTextColor(0, 0, 0, 0.9)

        ApplyTrackerText(self.Title, {
            size = questTitleSize,
            flags = "emphasis",
            colorPath = titleColorPath or "color.text.primary",
        })
        if not titleColorPath then
            local titleColor = emphasizeTitles and rowPalette.title or neutralTitleColor
            self.Title:SetTextColor(titleColor.r, titleColor.g, titleColor.b, titleColor.a or 1)
        end
        ApplyTrackerText(self.Meta, {
            size = metaSize,
            colorPath = "color.text.secondary",
            shadow = false,
        })
        ApplyTrackerText(self.Detail, {
            size = detailSize,
            colorPath = "color.text.secondary",
            shadow = false,
        })

        self:SetWidth(contentWidth)
        self.IconGlyph:SetText(iconGlyph)
        self.IconShadow:SetText(iconGlyph)
        self.Title:SetText(entry.title)

        local metaParts = {}
        if entry.isPreview then
            metaParts[#metaParts + 1] = "Preview"
        end
        if entry.tag and entry.tag ~= "" then
            metaParts[#metaParts + 1] = entry.tag
        end
        if entry.ready then
            metaParts[#metaParts + 1] = "Ready"
        elseif entry.failed then
            metaParts[#metaParts + 1] = "Failed"
        elseif entry.isWorldQuest then
            metaParts[#metaParts + 1] = "World Quest"
        end

        self.Meta:SetText(table.concat(metaParts, " | "))
        self.Meta:SetShown(#metaParts > 0)
        self.Detail:SetText(entry.objectiveText)

        self.IconHolder:ClearAllPoints()
        self.IconHolder:SetPoint("TOPLEFT", leftPadding, -topPadding)
        self.IconHolder:SetSize(iconSize, iconSize)

        self.Title:ClearAllPoints()
        self.Title:SetPoint("TOPLEFT", self.IconHolder, "TOPRIGHT", compact and 8 or 10, compact and 0 or -1)
        self.Title:SetWidth(maxTextWidth)

        if self.Meta:IsShown() then
            self.Meta:ClearAllPoints()
            self.Meta:SetPoint("TOPLEFT", self.Title, "BOTTOMLEFT", 0, compact and -2 or -3)
            self.Meta:SetWidth(maxTextWidth)
            self.Detail:ClearAllPoints()
            self.Detail:SetPoint("TOPLEFT", self.Meta, "BOTTOMLEFT", 0, compact and -4 or -6)
        else
            self.Detail:ClearAllPoints()
            self.Detail:SetPoint("TOPLEFT", self.Title, "BOTTOMLEFT", 0, compact and -4 or -6)
        end

        self.Detail:SetWidth(maxTextWidth)

        local totalTextHeight = MeasureTextHeight(self.Title)
        if self.Meta:IsShown() then
            totalTextHeight = totalTextHeight + MeasureTextHeight(self.Meta) + metaGap
        end
        totalTextHeight = totalTextHeight + MeasureTextHeight(self.Detail) + detailGap

        local bodyHeight = math.max(iconSize, totalTextHeight)
        self:SetHeight(math.ceil(topPadding + bodyHeight + bottomPadding))

        self.Separator:ClearAllPoints()
        self.Separator:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 12, 0)
        self.Separator:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -12, 0)
        self.Separator:SetHeight(1)
        ApplyColor(self.Separator, rowPalette.border, 0.4)
        self.Separator:SetShown(isLast ~= true)
    end

    section.Rows[index] = row
    return row
end

local function AcquireSection(frame, key, label)
    frame.Sections = frame.Sections or {}
    if frame.Sections[key] then
        return frame.Sections[key]
    end

    local section = {
        Container = CreateFrame("Frame", nil, frame.ScrollChild),
        Key = key,
        Label = label,
        Rows = {},
    }

    section.Header = CreateFrame("Frame", nil, section.Container)
    section.Header:SetHeight(30)
    section.Header:SetPoint("TOPLEFT")

    section.Header.Title = CreateText(section.Header)
    section.Header.Title:SetPoint("LEFT", 12, 0)

    section.Header.Count = CreateText(section.Header)
    section.Header.Count:SetPoint("RIGHT", -30, 0)
    section.Header.Count:SetJustifyH("RIGHT")

    section.Header.Toggle = CreateToggleButton(section.Header, function()
        local settings = GetSettings()
        settings.collapsed[key] = not settings.collapsed[key]
        Addon:ReapplyObjectiveTracker()
    end)
    section.Header.Toggle:SetPoint("RIGHT", -8, 0)

    section.Header.Divider = section.Header:CreateTexture(nil, "BORDER")
    section.Header.Divider:SetTexture("Interface\\Buttons\\WHITE8X8")

    section.Content = CreateFrame("Frame", nil, section.Container)
    section.Content:SetPoint("TOPLEFT")
    section.Content:SetHeight(1)

    section.Container.WeirdUITint = EnsureFillTexture(section.Container, "WeirdUITint", "BACKGROUND", 1)
    section.Container.WeirdUITint:SetAllPoints()

    frame.Sections[key] = section
    return section
end

local function ApplyBlizzardTrackerVisibility(showBlizzardTracker)
    local frame = GetBlizzardTrackerFrame()
    if not frame then
        return
    end

    if showBlizzardTracker then
        Module.suppressingBlizzardTracker = false
        frame:SetAlpha(1)
        if frame.EnableMouse then
            frame:EnableMouse(true)
        end
        if not InCombatLockdown or not InCombatLockdown() then
            frame:Show()
        end
        return
    end

    Module.suppressingBlizzardTracker = true
    frame:SetAlpha(0)
    if frame.EnableMouse then
        frame:EnableMouse(false)
    end
    if not InCombatLockdown or not InCombatLockdown() then
        frame:Hide()
    end
end

local function SuppressBlizzardTracker(frame)
    if not frame or Module.suppressingBlizzardTracker ~= true or not ShouldHideBlizzardTracker() then
        return
    end

    frame:SetAlpha(0)
    if frame.EnableMouse then
        frame:EnableMouse(false)
    end
    if not InCombatLockdown or not InCombatLockdown() then
        frame:Hide()
    end
end

function Module:ApplyTheme()
    local frame = self.frame
    if not frame then
        return
    end

    local settings = GetSettings()
    local data = self.data or self:RefreshData()
    local detailSize = GetFontSize(settings, "detail", 13)
    local sectionHeaderSize = GetFontSize(settings, "sectionHeader", 16)
    local backgroundOpacity = GetBackgroundOpacity(settings)
    local canvasSurfaceColor = Addon.Theme:GetToken("color.surface.canvas")
    local elevatedSurfaceColor = Addon.Theme:GetToken("color.surface.elevated")
    local overlaySurfaceColor = Addon.Theme:GetToken("color.surface.overlay")
    local neutralHeaderColor = Addon.Theme:GetToken("color.text.primary")
    local neutralCountColor = Addon.Theme:GetToken("color.text.secondary")

    Addon.SkinHelpers:ApplyPanel(frame, {
        accent = false,
        surfaceColorPath = "color.surface.canvas",
        borderColorPath = "color.border.subtle",
    })
    if frame.WeirdUIAccent then
        frame.WeirdUIAccent:SetAlpha(0)
    end
    if frame.WeirdUIBackground then
        ApplyColor(frame.WeirdUIBackground, canvasSurfaceColor, 1)
        frame.WeirdUIBackground:SetAlpha(backgroundOpacity)
    end
    if frame.WeirdUIBorderTop then
        frame.WeirdUIBorderTop:SetAlpha(backgroundOpacity)
    end
    if frame.WeirdUIBorderBottom then
        frame.WeirdUIBorderBottom:SetAlpha(backgroundOpacity)
    end
    if frame.WeirdUIBorderLeft then
        frame.WeirdUIBorderLeft:SetAlpha(backgroundOpacity)
    end
    if frame.WeirdUIBorderRight then
        frame.WeirdUIBorderRight:SetAlpha(backgroundOpacity)
    end
    if frame.WeirdUIShadow then
        frame.WeirdUIShadow:SetAlpha((overlaySurfaceColor and overlaySurfaceColor.a or 0.9) * backgroundOpacity)
    end
    ApplyTrackerText(frame.EmptyText, {
        size = detailSize,
        colorPath = "color.text.secondary",
        shadow = false,
    })

    do
        local trackColor = Addon.Theme:GetToken("color.border.subtle")
        local fillColor = Addon.Theme:GetColor("accent", "primary")
        local thumbColor = Addon.Theme:GetColor("accent", "strong")

        ApplyColor(frame.ScrollBar.Track, trackColor, 0.65)
        ApplyColor(frame.ScrollBar.Thumb, thumbColor)
        ApplyColor(frame.ScrollBar.Fill, fillColor)
    end

    for _, sectionInfo in ipairs(SECTION_ORDER) do
        local entries = data[sectionInfo.key]
        local section = frame.Sections and frame.Sections[sectionInfo.key]
        if section and entries and #entries > 0 then
            local palette = GetSectionPalette(sectionInfo.key)
            local accentColor = GetSectionAccentColor(settings, sectionInfo.key)
            local titleTone = GetSectionTitleColor(settings, sectionInfo.key)
            local sectionTintColor = GetSectionTintColor(settings, sectionInfo.key)
            local sectionTintOpacity = GetSectionTintOpacity(settings, sectionInfo.key)
            local titleColor = settings.highlightCurrentZone == true
                and titleTone
                or BlendColor(neutralHeaderColor, titleTone, 0.35, 1)
            local countColor = settings.highlightCurrentZone == true
                and { r = titleTone.r, g = titleTone.g, b = titleTone.b, a = 0.8 }
                or BlendColor(neutralCountColor, titleTone, 0.20, 0.78)

            Addon.SkinHelpers:ApplyPanel(section.Container, {
                accent = false,
                shadow = false,
                surfaceColorPath = "color.surface.elevated",
                borderColorPath = "color.border.subtle",
            })
            if section.Container.WeirdUIAccent then
                section.Container.WeirdUIAccent:SetAlpha(0)
            end
            if section.Container.WeirdUIBackground then
                ApplyColor(section.Container.WeirdUIBackground, elevatedSurfaceColor, 1)
                section.Container.WeirdUIBackground:SetAlpha(backgroundOpacity)
            end
            if section.Container.WeirdUITint then
                ApplyColor(section.Container.WeirdUITint, sectionTintColor, 1)
                section.Container.WeirdUITint:SetAlpha(sectionTintOpacity)
            end
            if section.Container.WeirdUIBorderTop then
                ApplyColor(section.Container.WeirdUIBorderTop, accentColor)
                section.Container.WeirdUIBorderTop:SetAlpha(0.8)
            end
            if section.Container.WeirdUIBorderBottom then
                ApplyColor(section.Container.WeirdUIBorderBottom, accentColor)
                section.Container.WeirdUIBorderBottom:SetAlpha(0.8)
            end
            if section.Container.WeirdUIBorderLeft then
                ApplyColor(section.Container.WeirdUIBorderLeft, accentColor)
                section.Container.WeirdUIBorderLeft:SetAlpha(0.8)
            end
            if section.Container.WeirdUIBorderRight then
                ApplyColor(section.Container.WeirdUIBorderRight, accentColor)
                section.Container.WeirdUIBorderRight:SetAlpha(0.8)
            end

            ApplyTrackerText(section.Header.Title, {
                size = sectionHeaderSize,
                flags = "display",
                colorPath = settings.highlightCurrentZone == true and "color.role.accent.strong" or "color.text.primary",
            })
            section.Header.Title:SetTextColor(titleColor.r, titleColor.g, titleColor.b, titleColor.a or 1)
            ApplyTrackerText(section.Header.Count, {
                size = sectionHeaderSize,
                flags = "emphasis",
                colorPath = "color.text.secondary",
                shadow = false,
            })
            section.Header.Count:SetTextColor(countColor.r, countColor.g, countColor.b, countColor.a or 1)

            ApplyColor(section.Header.Divider, accentColor, 0.55)

            do
                local toggleTone = section.Header.Toggle.hovered and BlendColor(accentColor, { r = 1, g = 1, b = 1, a = 1 }, 0.30, 1) or accentColor
                ApplyColor(section.Header.Toggle.Horizontal, toggleTone)
                ApplyColor(section.Header.Toggle.Vertical, toggleTone)
                section.Header.Toggle.Vertical:SetShown(settings.collapsed[sectionInfo.key] == true)
            end
        end
    end
end

function Module:RefreshFrame()
    local frame = self.frame
    if not frame then
        return
    end

    local settings = GetSettings()
    local data = self:RefreshData()
    local width = GetTrackerWidth(settings)
    local sectionHeaderSize = GetFontSize(settings, "sectionHeader", 16)
    local fullHeight = GetTrackerHeight(settings)
    local currentY = 0
    local contentWidth
    local framePadding = 12
    local scrollbarGap = 10
    local scrollbarInset = 12
    local scrollbarWidth = frame.ScrollBar:GetWidth() or 4

    ApplyBlizzardTrackerVisibility(settings.enabled ~= true)

    if settings.enabled == false then
        frame:Hide()
        return
    end

    frame:SetWidth(width)
    frame:SetHeight(fullHeight)
    frame:SetScale(GetTrackerScale(settings))
    frame:Show()

    frame.ScrollFrame:SetShown(true)
    frame.ScrollBar:SetShown(false)
    frame.EmptyText:SetShown(false)

    frame.ScrollFrame:ClearAllPoints()
    frame.ScrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", framePadding, -framePadding)
    frame.ScrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(framePadding + scrollbarWidth + scrollbarGap), framePadding)

    frame.ScrollBar:ClearAllPoints()
    frame.ScrollBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -scrollbarInset, -framePadding)
    frame.ScrollBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -scrollbarInset, framePadding)

    contentWidth = math.max(180, width - ((framePadding * 2) + scrollbarWidth + scrollbarGap))
    frame.ScrollChild:SetWidth(contentWidth)

    for _, sectionInfo in ipairs(SECTION_ORDER) do
        local entries = data[sectionInfo.key]
        local section = AcquireSection(frame, sectionInfo.key, sectionInfo.label)
        local sectionCollapsed = settings.collapsed[sectionInfo.key] == true

        section.Container:SetShown(entries and #entries > 0)
        section.Header:SetShown(entries and #entries > 0)
        section.Content:SetShown(entries and #entries > 0 and not sectionCollapsed)

        if entries and #entries > 0 then
            ApplyTrackerText(section.Header.Title, {
                size = sectionHeaderSize,
                flags = "display",
                colorPath = settings.highlightCurrentZone == true and "color.role.accent.strong" or "color.text.primary",
            })
            ApplyTrackerText(section.Header.Count, {
                size = sectionHeaderSize,
                flags = "emphasis",
                colorPath = "color.text.secondary",
                shadow = false,
            })

            section.Container:ClearAllPoints()
            section.Container:SetPoint("TOPLEFT", frame.ScrollChild, "TOPLEFT", 0, -currentY)
            section.Container:SetPoint("TOPRIGHT", frame.ScrollChild, "TOPRIGHT", 0, -currentY)

            section.Header:ClearAllPoints()
            section.Header:SetPoint("TOPLEFT", section.Container, "TOPLEFT", 0, 0)
            section.Header:SetPoint("TOPRIGHT", section.Container, "TOPRIGHT", 0, 0)
            section.Header.Title:SetText(sectionInfo.label)
            section.Header.Count:SetText(string.format("%d", #entries))

            local sectionHeaderHeight = math.ceil(math.max(MeasureTextHeight(section.Header.Title), MeasureTextHeight(section.Header.Count), section.Header.Toggle:GetHeight() or 18) + (settings.compactHeader and 10 or 14))

            section.Header:SetHeight(sectionHeaderHeight)

            section.Header.Title:ClearAllPoints()
            section.Header.Title:SetPoint("LEFT", 12, 0)
            section.Header.Title:SetPoint("RIGHT", section.Header.Count, "LEFT", -10, 0)

            section.Header.Count:ClearAllPoints()
            section.Header.Count:SetPoint("RIGHT", section.Header.Toggle, "LEFT", -10, 0)

            section.Header.Toggle:ClearAllPoints()
            section.Header.Toggle:SetPoint("RIGHT", -8, 0)

            section.Header.Divider:ClearAllPoints()
            section.Header.Divider:SetPoint("BOTTOMLEFT", section.Header, "BOTTOMLEFT", 12, 0)
            section.Header.Divider:SetPoint("BOTTOMRIGHT", section.Header, "BOTTOMRIGHT", -12, 0)
            section.Header.Divider:SetHeight(1)
            section.Header.Divider:SetShown(not sectionCollapsed)

            if not sectionCollapsed then
                local sectionHeight = 0
                local rowGap = settings.compactHeader == true and 1 or 2

                for index, entry in ipairs(entries) do
                    local row = AcquireQuestRow(section, index)
                    row:SetShown(true)
                    row:SetQuest(entry, settings, contentWidth, index == #entries)
                    row:ClearAllPoints()
                    row:SetPoint("TOPLEFT", section.Content, "TOPLEFT", 0, -sectionHeight)
                    row:SetPoint("TOPRIGHT", section.Content, "TOPRIGHT", 0, -sectionHeight)
                    sectionHeight = sectionHeight + row:GetHeight() + rowGap
                end

                for index = #entries + 1, #section.Rows do
                    section.Rows[index]:Hide()
                end

                section.Content:ClearAllPoints()
                section.Content:SetPoint("TOPLEFT", section.Header, "BOTTOMLEFT", 0, 0)
                section.Content:SetPoint("TOPRIGHT", section.Header, "BOTTOMRIGHT", 0, 0)
                section.Content:SetHeight(math.max(1, sectionHeight > 0 and (sectionHeight - rowGap) or 1))

                section.Container:SetHeight(section.Header:GetHeight() + section.Content:GetHeight())
            else
                for _, row in ipairs(section.Rows) do
                    row:Hide()
                end
                section.Container:SetHeight(section.Header:GetHeight())
            end

            currentY = currentY + section.Container:GetHeight() + (settings.compactHeader == true and 8 or 12)
        else
            section.Container:Hide()
            for _, row in ipairs(section.Rows) do
                row:Hide()
            end
        end
    end

    if data.total == 0 then
        frame.EmptyText:SetShown(true)
        frame.EmptyText:ClearAllPoints()
        frame.EmptyText:SetPoint("TOPLEFT", frame.ScrollChild, "TOPLEFT", 4, -4)
        frame.EmptyText:SetPoint("TOPRIGHT", frame.ScrollChild, "TOPRIGHT", -4, -4)
        frame.EmptyText:SetText("No watched quests right now. Track a quest in the quest log and it will appear here.")
        currentY = math.max(currentY, frame.EmptyText:GetStringHeight() + 12)
    end

    frame.ScrollChild:SetHeight(math.max(1, currentY))

    do
        local viewHeight = frame.ScrollFrame:GetHeight() or 1
        local maxScroll = math.max(0, frame.ScrollChild:GetHeight() - viewHeight)
        local currentValue = Clamp(frame.ScrollBar:GetValue() or 0, 0, maxScroll)

        frame.ScrollBar:SetMinMaxValues(0, maxScroll)
        frame.ScrollBar:SetValue(currentValue)
        frame.ScrollBar:SetShown(maxScroll > 0)
        frame.ScrollFrame:SetVerticalScroll(currentValue)
    end

    self:ApplyTheme()
end

function Module:EnsureFrame()
    if self.frame then
        return self.frame
    end

    local frame = CreateFrame("Frame", "WeirdUIObjectiveTrackerFrame", UIParent)
    frame:SetPoint("TOPRIGHT", -60, -260)
    frame:SetSize(300, 600)
    frame:SetFrameStrata("LOW")
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(selfFrame)
        if not InCombatLockdown or not InCombatLockdown() then
            selfFrame:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(selfFrame)
        selfFrame:StopMovingOrSizing()
        if Addon.CaptureLayoutTarget then
            Addon:CaptureLayoutTarget(ROOT_LAYOUT_TARGET_ID)
        end
        if Addon.ApplyLayoutEditingState then
            Addon:ApplyLayoutEditingState()
        end
    end)
    frame:Hide()

    frame.ScrollFrame = CreateFrame("ScrollFrame", nil, frame)
    frame.ScrollFrame:EnableMouseWheel(true)
    frame.ScrollChild = CreateFrame("Frame", nil, frame.ScrollFrame)
    frame.ScrollChild:SetSize(1, 1)
    frame.ScrollFrame:SetScrollChild(frame.ScrollChild)
    frame.ScrollFrame:SetScript("OnMouseWheel", function(_, delta)
        local minimum, maximum = frame.ScrollBar:GetMinMaxValues()
        local nextValue = Clamp(frame.ScrollBar:GetValue() - (delta * 36), minimum, maximum)
        frame.ScrollBar:SetValue(nextValue)
    end)

    frame.ScrollBar = CreateFrame("Slider", nil, frame)
    frame.ScrollBar:SetOrientation("VERTICAL")
    frame.ScrollBar:SetWidth(2)
    frame.ScrollBar:SetMinMaxValues(0, 0)
    frame.ScrollBar:SetValueStep(24)
    frame.ScrollBar.Track = frame.ScrollBar:CreateTexture(nil, "BACKGROUND")
    frame.ScrollBar.Track:SetAllPoints()
    frame.ScrollBar.Track:SetTexture("Interface\\Buttons\\WHITE8X8")
    frame.ScrollBar.Fill = frame.ScrollBar:CreateTexture(nil, "ARTWORK")
    frame.ScrollBar.Fill:SetTexture("Interface\\Buttons\\WHITE8X8")
    frame.ScrollBar.Fill:SetAllPoints()
    frame.ScrollBar.Thumb = frame.ScrollBar:CreateTexture(nil, "ARTWORK")
    frame.ScrollBar.Thumb:SetTexture("Interface\\Buttons\\WHITE8X8")
    frame.ScrollBar.Thumb:SetSize(2, 24)
    frame.ScrollBar:SetThumbTexture(frame.ScrollBar.Thumb)
    frame.ScrollBar:SetScript("OnValueChanged", function(slider, value)
        frame.ScrollFrame:SetVerticalScroll(value)
    end)

    frame.EmptyText = CreateText(frame.ScrollChild)
    frame.EmptyText:SetJustifyH("LEFT")
    frame.EmptyText:SetJustifyV("TOP")
    frame.EmptyText:SetWordWrap(true)

    frame.Sections = {}
    self.frame = frame
    return frame
end

function Module:EnsureSkinRegistered()
    if self.skinRegistered then
        return
    end

    self:EnsureFrame()

    Addon.Skins:Register("objective-tracker.frame", {
        family = "module",
        resolveTarget = function()
            return Module.frame
        end,
        apply = function()
            Addon:ReapplyObjectiveTracker()
        end,
    })

    self.skinRegistered = true
end

function Module:EnsureLayoutRegistered()
    if self.layoutRegistered then
        return
    end

    Addon:RegisterLayoutTarget(ROOT_LAYOUT_TARGET_ID, {
        label = "Objective Tracker",
        category = "Gameplay",
        defaults = {
            point = "TOPRIGHT",
            relativePoint = "TOPRIGHT",
            x = -60,
            y = -260,
            width = 300,
            height = 600,
        },
        open = function(owner)
            Module:EnsureFrame()
            owner:ReapplyObjectiveTracker()
        end,
        resolveFrame = function()
            return Module.frame
        end,
        afterApply = function()
            Addon:ReapplyObjectiveTracker()
        end,
        setEditingEnabled = function(frame, enabled)
            frame:SetMovable(true)
        end,
    })

    self.layoutRegistered = true
end

function Module:EnsureHooksRegistered()
    if self.hooksRegistered then
        return
    end

    local blizzardTracker = GetBlizzardTrackerFrame()
    if blizzardTracker and not self.blizzardTrackerHooksRegistered then
        blizzardTracker:HookScript("OnShow", function(shownFrame)
            SuppressBlizzardTracker(shownFrame)
        end)

        self.blizzardTrackerHooksRegistered = true
    end

    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:SetScript("OnEvent", function()
        Addon:ReapplyObjectiveTracker()
        if Addon.Menu and Addon.Menu.activePage == "objective-tracker" then
            Addon:ReapplyMenu()
        end
    end)

    for _, event in ipairs({
        "PLAYER_ENTERING_WORLD",
        "QUEST_ACCEPTED",
        "QUEST_LOG_UPDATE",
        "QUEST_POI_UPDATE",
        "QUEST_REMOVED",
        "QUEST_TURNED_IN",
        "QUEST_WATCH_LIST_CHANGED",
        "QUEST_WATCH_UPDATE",
        "TASK_PROGRESS_UPDATE",
        "ZONE_CHANGED",
        "ZONE_CHANGED_NEW_AREA",
    }) do
        self.eventFrame:RegisterEvent(event)
    end

    self.hooksRegistered = true
end

function Addon:ReapplyObjectiveTracker()
    Module:EnsureFrame()

    local settings = GetSettings()
    if settings.enabled == false then
        ApplyBlizzardTrackerVisibility(true)
        if Module.frame then
            Module.frame:Hide()
        end
        return false
    end

    Module:RefreshFrame()
    return true
end

function Addon:InitializeObjectiveTrackerModule()
    Module:EnsureFrame()
    Module:EnsureSkinRegistered()
    Module:EnsureLayoutRegistered()
    if self.ApplyLayoutTarget then
        self:ApplyLayoutTarget(ROOT_LAYOUT_TARGET_ID)
    end
    Module:EnsureHooksRegistered()

    if not Module.pageRegistered and Addon.RegisterModulePage and ns.MenuWidgets then
        Addon:RegisterModulePage("objective-tracker", {
            title = "Tracker",
            moduleLabel = "Objective Tracker",
            moduleStatus = "Implemented",
            moduleCategory = "Gameplay",
            moduleDescription = "Custom WeirdUI tracker surface driven by watched quest data, with its own frame, layout target, and live tracker settings.",
            build = function(page, frame)
                local Widgets = ns.MenuWidgets

                page.Header = Widgets:CreateSectionHeader(frame, "Objective Tracker", "Custom WeirdUI tracker surface driven by watched quests. This replaces the Blizzard tracker while enabled and uses the WeirdUI layout and theme system directly.")
                page.Header:SetPoint("TOPLEFT", 8, -8)

                page.Notice = Widgets:CreateNoticeRow(
                    frame,
                    "Custom tracker surface",
                    "This module now renders its own tracker frame instead of only skinning Blizzard's tracker shell. Width and height controls apply to the WeirdUI tracker itself.",
                    "accent"
                )
                page.Notice:SetPoint("TOPLEFT", page.Header, "BOTTOMLEFT", 0, -18)

                page.StatusGroup = Widgets:CreateGroupPanel(
                    frame,
                    "Status & Actions",
                    "Enable the tracker, review its current state, and force refresh actions from one place."
                )
                page.StatusGroup:SetPoint("TOPLEFT", page.Notice, "BOTTOMLEFT", 0, -18)

                page.Enabled = Widgets:CreateCheckboxRow(
                    page.StatusGroup.Content,
                    "Enable WeirdUI tracker",
                    "Show the custom WeirdUI Objective Tracker and hide the Blizzard tracker while this module is enabled.",
                    function()
                        return GetSettings().enabled ~= false
                    end,
                    function(value)
                        GetSettings().enabled = value and true or false
                        Addon:ReapplyObjectiveTracker()
                    end
                )
                page.StatusGroup:AddBlock(page.Enabled, 16)

                page.State = Widgets:CreateValueRow(page.StatusGroup.Content, "Tracker State")
                page.StatusGroup:AddBlock(page.State, 14)

                page.Watched = Widgets:CreateValueRow(page.StatusGroup.Content, "Watched Quests")
                page.StatusGroup:AddBlock(page.Watched, 14)

                page.OpenTracker = Widgets:CreateActionRow(
                    page.StatusGroup.Content,
                    "Open custom tracker",
                    "Show the custom Objective Tracker frame and reapply the latest watched quest data immediately.",
                    "Open Tracker",
                    function()
                        local settings = GetSettings()
                        if settings.enabled == false then
                            settings.enabled = true
                        end

                        Addon:ReapplyObjectiveTracker()
                        Addon:ReapplyMenu()
                        if Module.frame then
                            Module.frame:Raise()
                        end
                    end
                )
                page.StatusGroup:AddBlock(page.OpenTracker, 14)

                page.Reapply = Widgets:CreateActionRow(
                    page.StatusGroup.Content,
                    "Refresh tracker data",
                    "Refresh watched quest data and repaint the custom Objective Tracker immediately.",
                    "Refresh Tracker",
                    function()
                        Addon:ReapplyObjectiveTracker()
                        Addon:ReapplyMenu()
                    end
                )
                page.StatusGroup:AddBlock(page.Reapply, 14)

                page.LayoutGroup = Widgets:CreateGroupPanel(
                    frame,
                    "Layout & Scale",
                    "Control the tracker footprint and overall scale independently. Width and height change the layout area, while scale multiplies the entire frame."
                )
                page.LayoutGroup:SetPoint("TOPLEFT", page.StatusGroup, "BOTTOMLEFT", 0, -18)

                page.Width = Widgets:CreateSliderRow(
                    page.LayoutGroup.Content,
                    "Tracker width",
                    "Set the custom WeirdUI tracker width.",
                    {
                        minimum = 240,
                        maximum = 520,
                        step = 1,
                        getter = function()
                            return GetTrackerWidth(GetSettings())
                        end,
                        setter = function(value)
                            GetSettings().width = math.floor(value + 0.5)
                            Addon:ReapplyObjectiveTracker()
                        end,
                        formatter = function(value)
                            return string.format("%d px", math.floor(value + 0.5))
                        end,
                    }
                )
                page.LayoutGroup:AddBlock(page.Width, 16)

                page.Height = Widgets:CreateSliderRow(
                    page.LayoutGroup.Content,
                    "Tracker height",
                    "Set the custom WeirdUI tracker height.",
                    {
                        minimum = 260,
                        maximum = 900,
                        step = 1,
                        getter = function()
                            return GetTrackerHeight(GetSettings())
                        end,
                        setter = function(value)
                            GetSettings().height = math.floor(value + 0.5)
                            Addon:ReapplyObjectiveTracker()
                        end,
                        formatter = function(value)
                            return string.format("%d px", math.floor(value + 0.5))
                        end,
                    }
                )
                page.LayoutGroup:AddBlock(page.Height, 14)

                page.Scale = Widgets:CreateSliderRow(
                    page.LayoutGroup.Content,
                    "Tracker scale",
                    "Scale the custom Objective Tracker without changing its saved width and height.",
                    {
                        minimum = TRACKER_SCALE_MIN,
                        maximum = TRACKER_SCALE_MAX,
                        step = TRACKER_SCALE_STEP,
                        getter = function()
                            return GetTrackerScale(GetSettings())
                        end,
                        setter = function(value)
                            GetSettings().scale = value
                            Addon:ReapplyObjectiveTracker()
                        end,
                        formatter = function(value)
                            return string.format("%d%%", math.floor((value * 100) + 0.5))
                        end,
                    }
                )
                page.LayoutGroup:AddBlock(page.Scale, 14)

                page.LayoutTarget = Widgets:CreateValueRow(page.LayoutGroup.Content, "Layout Target")
                page.LayoutGroup:AddBlock(page.LayoutTarget, 14)

                page.AppearanceGroup = Widgets:CreateGroupPanel(
                    frame,
                    "Appearance",
                    "Tune the overall tracker frame treatment and row presentation without affecting the tracker data or layout."
                )
                page.AppearanceGroup:SetPoint("TOPLEFT", page.LayoutGroup, "BOTTOMLEFT", 0, -18)

                page.CompactHeader = Widgets:CreateCheckboxRow(
                    page.AppearanceGroup.Content,
                    "Compact tracker header",
                    "Reduce section header height, row padding, and vertical spacing throughout the custom tracker.",
                    function()
                        return GetSettings().compactHeader == true
                    end,
                    function(value)
                        GetSettings().compactHeader = value and true or false
                        Addon:ReapplyObjectiveTracker()
                    end
                )
                page.AppearanceGroup:AddBlock(page.CompactHeader, 16)

                page.Emphasis = Widgets:CreateCheckboxRow(
                    page.AppearanceGroup.Content,
                    "Emphasize quest titles",
                    "Use stronger section palette colors on quest titles and quest icons. Section headers stay color-coded either way.",
                    function()
                        return GetSettings().highlightCurrentZone ~= false
                    end,
                    function(value)
                        GetSettings().highlightCurrentZone = value and true or false
                        Addon:ReapplyObjectiveTracker()
                    end
                )
                page.AppearanceGroup:AddBlock(page.Emphasis, 14)

                page.BackgroundOpacity = Widgets:CreateSliderRow(
                    page.AppearanceGroup.Content,
                    "Tracker background opacity",
                    "Adjust the opacity of the main tracker background surface from fully invisible to fully solid.",
                    {
                        minimum = 0,
                        maximum = 1,
                        step = 0.01,
                        getter = function()
                            return GetBackgroundOpacity(GetSettings())
                        end,
                        setter = function(value)
                            GetSettings().backgroundOpacity = value
                            Addon:ReapplyObjectiveTracker()
                        end,
                        formatter = function(value)
                            return string.format("%d%%", math.floor((value * 100) + 0.5))
                        end,
                    }
                )
                page.AppearanceGroup:AddBlock(page.BackgroundOpacity, 14)

                page.SectionCardGroup = Widgets:CreateGroupPanel(
                    frame,
                    "Quest Type Cards",
                    "Set the background tint, tint opacity, and accent color for each quest-type card independently."
                )
                page.SectionCardGroup:SetPoint("TOPLEFT", page.AppearanceGroup, "BOTTOMLEFT", 0, -18)

                page.SectionCardControls = {}

                for index, sectionInfo in ipairs(SECTION_ORDER) do
                    local key = sectionInfo.key

                    page.SectionCardControls[key] = {
                        color = Widgets:CreateColorPickerRow(
                            page.SectionCardGroup.Content,
                            string.format("%s color", sectionInfo.label),
                            string.format("Choose the tint color used for the %s card background.", string.lower(sectionInfo.label)),
                            {
                                getter = function()
                                    return GetSectionTintColor(GetSettings(), key)
                                end,
                                setter = function(color)
                                    local settings = GetSettings()
                                    settings.sectionCardColors = settings.sectionCardColors or {}
                                    settings.sectionCardColors[key] = CopyColor(color)
                                    Addon:ReapplyObjectiveTracker()
                                end,
                                pickerTitle = string.format("%s Background", sectionInfo.label),
                                pickerDescription = string.format("Set the tint color used for the %s card background.", string.lower(sectionInfo.label)),
                            }
                        ),
                        opacity = Widgets:CreateSliderRow(
                            page.SectionCardGroup.Content,
                            string.format("%s opacity", sectionInfo.label),
                            string.format("Adjust the tint opacity used for the %s card background.", string.lower(sectionInfo.label)),
                            {
                                minimum = 0,
                                maximum = 1,
                                step = 0.01,
                                getter = function()
                                    return GetSectionTintOpacity(GetSettings(), key)
                                end,
                                setter = function(value)
                                    local settings = GetSettings()
                                    settings.sectionCardOpacities = settings.sectionCardOpacities or {}
                                    settings.sectionCardOpacities[key] = value
                                    Addon:ReapplyObjectiveTracker()
                                end,
                                formatter = function(value)
                                    return string.format("%d%%", math.floor((value * 100) + 0.5))
                                end,
                            }
                        ),
                        accent = Widgets:CreateColorPickerRow(
                            page.SectionCardGroup.Content,
                            string.format("%s accent", sectionInfo.label),
                            string.format("Choose the accent color used for %s borders, headers, and dividers.", string.lower(sectionInfo.label)),
                            {
                                getter = function()
                                    return GetSectionAccentColor(GetSettings(), key)
                                end,
                                setter = function(color)
                                    local settings = GetSettings()
                                    settings.sectionAccentColors = settings.sectionAccentColors or {}
                                    settings.sectionAccentColors[key] = CopyColor(color)
                                    Addon:ReapplyObjectiveTracker()
                                end,
                                pickerTitle = string.format("%s Accent", sectionInfo.label),
                                pickerDescription = string.format("Set the accent color used for %s borders, titles, dividers, and toggle controls.", string.lower(sectionInfo.label)),
                            }
                        ),
                    }

                    page.SectionCardGroup:AddBlock(page.SectionCardControls[key].color, index == 1 and 16 or 14)
                    page.SectionCardGroup:AddBlock(page.SectionCardControls[key].opacity, 10)
                    page.SectionCardGroup:AddBlock(page.SectionCardControls[key].accent, 10)
                end

                page.TypographyGroup = Widgets:CreateGroupPanel(
                    frame,
                    "Typography",
                    "Control the sizing of section labels, quest titles, and supporting tracker text."
                )
                page.TypographyGroup:SetPoint("TOPLEFT", page.SectionCardGroup, "BOTTOMLEFT", 0, -18)

                page.HeaderFontSize = Widgets:CreateSliderRow(
                    page.TypographyGroup.Content,
                    "Header text size",
                    "Control the font size for section headers like Quests and World Quests.",
                    {
                        minimum = 12,
                        maximum = 28,
                        step = 1,
                        getter = function()
                            return GetFontSize(GetSettings(), "sectionHeader", 16)
                        end,
                        setter = function(value)
                            GetSettings().fontSizes.sectionHeader = math.floor(value + 0.5)
                            Addon:ReapplyObjectiveTracker()
                        end,
                        formatter = function(value)
                            return string.format("%d px", math.floor(value + 0.5))
                        end,
                    }
                )
                page.TypographyGroup:AddBlock(page.HeaderFontSize, 16)

                page.QuestTitleFontSize = Widgets:CreateSliderRow(
                    page.TypographyGroup.Content,
                    "Quest title size",
                    "Control the font size for quest title lines.",
                    {
                        minimum = 10,
                        maximum = 24,
                        step = 1,
                        getter = function()
                            return GetFontSize(GetSettings(), "questTitle", 15)
                        end,
                        setter = function(value)
                            GetSettings().fontSizes.questTitle = math.floor(value + 0.5)
                            Addon:ReapplyObjectiveTracker()
                        end,
                        formatter = function(value)
                            return string.format("%d px", math.floor(value + 0.5))
                        end,
                    }
                )
                page.TypographyGroup:AddBlock(page.QuestTitleFontSize, 14)

                page.MetaFontSize = Widgets:CreateSliderRow(
                    page.TypographyGroup.Content,
                    "Meta text size",
                    "Control the font size for tag and status text on quest rows.",
                    {
                        minimum = 8,
                        maximum = 18,
                        step = 1,
                        getter = function()
                            return GetFontSize(GetSettings(), "meta", 11)
                        end,
                        setter = function(value)
                            GetSettings().fontSizes.meta = math.floor(value + 0.5)
                            Addon:ReapplyObjectiveTracker()
                        end,
                        formatter = function(value)
                            return string.format("%d px", math.floor(value + 0.5))
                        end,
                    }
                )
                page.TypographyGroup:AddBlock(page.MetaFontSize, 14)

                page.DetailFontSize = Widgets:CreateSliderRow(
                    page.TypographyGroup.Content,
                    "Objective text size",
                    "Control the font size for objective and detail text.",
                    {
                        minimum = 8,
                        maximum = 20,
                        step = 1,
                        getter = function()
                            return GetFontSize(GetSettings(), "detail", 13)
                        end,
                        setter = function(value)
                            GetSettings().fontSizes.detail = math.floor(value + 0.5)
                            Addon:ReapplyObjectiveTracker()
                        end,
                        formatter = function(value)
                            return string.format("%d px", math.floor(value + 0.5))
                        end,
                    }
                )
                page.TypographyGroup:AddBlock(page.DetailFontSize, 14)
            end,
            applyTheme = function(page)
                local data = Module:RefreshData()
                local settings = GetSettings()
                local trackerVisible = Module.frame and Module.frame:IsShown()
                local stateText = settings.enabled == false and "Custom tracker disabled" or (trackerVisible and "Custom tracker active" or "Custom tracker hidden")

                page.Header:ApplyTheme()
                page.Notice:ApplyTheme()
                page.State:SetValue(stateText)
                page.Watched:SetValue(string.format("%d total | %d quests | %d world | %d weekly preview", data.total or 0, #data.quests, #data.world, data.previewTotal or 0))
                page.LayoutTarget:SetValue(ROOT_LAYOUT_TARGET_ID)
                page.Enabled:Sync()
                page.CompactHeader:Sync()
                page.Emphasis:Sync()
                page.Width:Sync()
                page.Height:Sync()
                page.Scale:Sync()
                page.BackgroundOpacity:Sync()
                page.HeaderFontSize:Sync()
                page.QuestTitleFontSize:Sync()
                page.MetaFontSize:Sync()
                page.DetailFontSize:Sync()
                if page.SectionCardControls then
                    for _, sectionInfo in ipairs(SECTION_ORDER) do
                        local controls = page.SectionCardControls[sectionInfo.key]
                        if controls then
                            controls.color:Sync()
                            controls.opacity:Sync()
                            controls.accent:Sync()
                        end
                    end
                end
                page.StatusGroup:ApplyTheme()
                page.LayoutGroup:ApplyTheme()
                page.AppearanceGroup:ApplyTheme()
                page.SectionCardGroup:ApplyTheme()
                page.TypographyGroup:ApplyTheme()
            end,
        })

        Module.pageRegistered = true
    end

    C_Timer.After(0, function()
        Addon:ReapplyObjectiveTracker()
    end)
end

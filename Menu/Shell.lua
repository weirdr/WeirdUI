local _, ns = ...

local Addon = ns.Addon
local Widgets = ns.MenuWidgets

local RESIZE_DEBOUNCE_SECONDS = 0.01
local MIN_WIDTH = 760
local MIN_HEIGHT = 460
local MAX_WIDTH = 1280
local MAX_HEIGHT = 900
local NAV_WIDTH = 188
local HEADER_HEIGHT = 70
local OUTER_PADDING = 16
local CONTENT_GAP = 18
local CONTENT_INSET = 14
local SCROLLBAR_WIDTH = 8

local Menu = {
    pages = {},
    order = {},
    navButtons = {},
    layoutTicker = nil,
}

Addon.Menu = Menu

local function TrackSpecialFrame(frameName)
    for _, name in ipairs(UISpecialFrames) do
        if name == frameName then
            return
        end
    end

    table.insert(UISpecialFrames, frameName)
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

local function ApplyColor(texture, color)
    texture:SetColorTexture(color.r, color.g, color.b, color.a or 1)
end

local function ClampFrameSize(frame)
    if not frame or frame.WeirdUIClampingSize then
        return
    end

    local width = Clamp(frame:GetWidth(), MIN_WIDTH, MAX_WIDTH)
    local height = Clamp(frame:GetHeight(), MIN_HEIGHT, MAX_HEIGHT)

    if width == frame:GetWidth() and height == frame:GetHeight() then
        return
    end

    frame.WeirdUIClampingSize = true
    frame:SetSize(width, height)
    frame.WeirdUIClampingSize = nil
end

function Menu:RegisterPage(id, definition)
    if self.pages[id] then
        return
    end

    definition.id = id
    self.pages[id] = definition
    self.order[#self.order + 1] = id
end

function Menu:CreateShell()
    local frame = CreateFrame("Frame", "WeirdUIMenuFrame", UIParent)
    frame:SetSize(860, 520)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetScript("OnSizeChanged", function(resizedFrame)
        ClampFrameSize(resizedFrame)
        self:ScheduleLayoutUpdate()
    end)
    frame:Hide()

    TrackSpecialFrame("WeirdUIMenuFrame")

    frame.Title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.Title:SetPoint("TOPLEFT", 20, -18)
    frame.Title:SetText("WeirdUI")

    frame.Subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.Subtitle:SetPoint("TOPLEFT", frame.Title, "BOTTOMLEFT", 0, -4)
    frame.Subtitle:SetText("Phase 00 menu shell")

    frame.CloseButton = CreateFrame("Button", nil, frame)
    frame.CloseButton:SetPoint("TOPRIGHT", -18, -18)
    frame.CloseButton:SetSize(24, 24)

    frame.CloseButton.Label = frame.CloseButton:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.CloseButton.Label:SetPoint("CENTER")
    frame.CloseButton.Label:SetText(ns.IconFont.Glyph.Close)

    frame.CloseButton.Underline = frame.CloseButton:CreateTexture(nil, "ARTWORK")
    frame.CloseButton.Underline:SetPoint("BOTTOMLEFT", 2, 0)
    frame.CloseButton.Underline:SetPoint("BOTTOMRIGHT", -2, 0)
    frame.CloseButton.Underline:SetHeight(2)
    frame.CloseButton.Underline:SetTexture("Interface\\Buttons\\WHITE8X8")

    frame.CloseButton:SetScript("OnEnter", function(control)
        control.hovered = true
        Addon:ReapplyMenu()
    end)

    frame.CloseButton:SetScript("OnLeave", function(control)
        control.hovered = nil
        Addon:ReapplyMenu()
    end)

    frame.CloseButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    frame.Nav = CreateFrame("Frame", nil, frame)
    frame.Content = CreateFrame("Frame", nil, frame)

    frame.ScrollFrame = CreateFrame("ScrollFrame", nil, frame.Content)
    frame.ScrollFrame:EnableMouseWheel(true)

    frame.ScrollChild = CreateFrame("Frame", nil, frame.ScrollFrame)
    frame.ScrollChild:SetSize(1, 1)
    frame.ScrollFrame:SetScrollChild(frame.ScrollChild)

    frame.ScrollBar = CreateFrame("Slider", nil, frame.Content)
    frame.ScrollBar:SetOrientation("VERTICAL")
    frame.ScrollBar:SetWidth(8)
    frame.ScrollBar:SetMinMaxValues(0, 0)
    frame.ScrollBar:SetValueStep(24)

    frame.ScrollBar.Track = frame.ScrollBar:CreateTexture(nil, "BACKGROUND")
    frame.ScrollBar.Track:SetAllPoints()
    frame.ScrollBar.Track:SetTexture("Interface\\Buttons\\WHITE8X8")

    frame.ScrollBar.Thumb = frame.ScrollBar:CreateTexture(nil, "ARTWORK")
    frame.ScrollBar.Thumb:SetTexture("Interface\\Buttons\\WHITE8X8")
    frame.ScrollBar.Thumb:SetSize(8, 36)
    frame.ScrollBar:SetThumbTexture(frame.ScrollBar.Thumb)

    frame.ScrollBar:SetScript("OnValueChanged", function(slider, value)
        frame.ScrollFrame:SetVerticalScroll(value)
    end)

    frame.ScrollFrame:SetScript("OnMouseWheel", function(_, delta)
        local minimum, maximum = frame.ScrollBar:GetMinMaxValues()
        local nextValue = Clamp(frame.ScrollBar:GetValue() - (delta * 36), minimum, maximum)
        frame.ScrollBar:SetValue(nextValue)
    end)

    frame.ResizeHandle = CreateFrame("Button", nil, frame)
    frame.ResizeHandle:SetSize(28, 28)
    frame.ResizeHandle:SetPoint("BOTTOMRIGHT", -6, 6)
    frame.ResizeHandle:EnableMouse(true)

    frame.ResizeHandle.Glyph = frame.ResizeHandle:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.ResizeHandle.Glyph:SetPoint("CENTER", 0, 0)
    frame.ResizeHandle.Glyph:SetText(ns.IconFont.Glyph.ResizeBottomRight)

    frame.ResizeHandle:SetScript("OnEnter", function(control)
        control.hovered = true
        Addon:ReapplyMenu()
    end)

    frame.ResizeHandle:SetScript("OnLeave", function(control)
        control.hovered = nil
        if not control.resizing then
            Addon:ReapplyMenu()
        end
    end)

    frame.ResizeHandle:SetScript("OnMouseDown", function(control, button)
        if button ~= "LeftButton" then
            return
        end

        control.resizing = true
        control:GetParent():SetClampedToScreen(true)
        control:GetParent():StartSizing("BOTTOMRIGHT")
        self:BeginResizeUpdates()
        Addon:ReapplyMenu()
    end)

    frame.ResizeHandle:SetScript("OnMouseUp", function(control)
        if control.resizing then
            control.resizing = nil
            control:GetParent():StopMovingOrSizing()
            ClampFrameSize(control:GetParent())
            self:EndResizeUpdates()
            self:ForceLayoutUpdate()
            Addon:ReapplyMenu()
        end
    end)

    self.frame = frame
    return frame
end

function Menu:EnsurePageFrame(page)
    if page.frame then
        return page.frame
    end

    local frame = CreateFrame("Frame", nil, self.frame.ScrollChild)
    frame:SetPoint("TOPLEFT", self.frame.ScrollChild, "TOPLEFT", 0, 0)
    frame:SetPoint("TOPRIGHT", self.frame.ScrollChild, "TOPRIGHT", 0, 0)
    frame:SetHeight(1)
    frame:Hide()
    page.frame = frame

    if type(page.build) == "function" then
        page:build(frame)
    end

    return frame
end

function Menu:SelectPage(id)
    local page = self.pages[id]
    if not page then
        return
    end

    self.activePage = id

    for _, pageID in ipairs(self.order) do
        local candidate = self.pages[pageID]
        local pageFrame = self:EnsurePageFrame(candidate)
        pageFrame:SetShown(pageID == id)
    end

    for pageID, button in pairs(self.navButtons) do
        button.active = pageID == id
    end

    local uiState = Addon:GetGlobalUIState()
    if uiState and uiState.menu then
        uiState.menu.lastPage = id
    end

    self.frame.ScrollBar:SetValue(0)
    self:ForceLayoutUpdate()
end

function Menu:ApplyPageWidths(width)
    local pageWidth = math.max(240, width)

    for _, id in ipairs(self.order) do
        local page = self.pages[id]
        if page and page.frame then
            page.frame:SetWidth(pageWidth)

            for _, child in ipairs({ page.frame:GetChildren() }) do
                if child.SetContentWidth then
                    child:SetContentWidth(pageWidth)
                end
            end

            for _, region in ipairs({ page.frame:GetRegions() }) do
                if region.SetContentWidth then
                    region:SetContentWidth(pageWidth)
                end
            end
        end
    end
end

function Menu:BuildNavigation()
    local previous

    for _, id in ipairs(self.order) do
        local page = self.pages[id]
        local button = CreateFrame("Button", nil, self.frame.Nav)
        button:SetSize(172, 26)

        button.Label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        button.Label:SetPoint("LEFT", 12, 0)
        button.Label:SetText(page.title)

        button.Indicator = button:CreateTexture(nil, "ARTWORK")
        button.Indicator:SetPoint("LEFT", 0, 0)
        button.Indicator:SetSize(3, 18)
        button.Indicator:SetTexture("Interface\\Buttons\\WHITE8X8")

        button.Underline = button:CreateTexture(nil, "ARTWORK")
        button.Underline:SetPoint("BOTTOMLEFT", 12, 0)
        button.Underline:SetPoint("BOTTOMRIGHT", -12, 0)
        button.Underline:SetHeight(1)
        button.Underline:SetTexture("Interface\\Buttons\\WHITE8X8")

        if previous then
            button:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -10)
        else
            button:SetPoint("TOPLEFT", 6, -6)
        end

        button:SetScript("OnEnter", function(control)
            control.hovered = true
            Addon:ReapplyMenu()
        end)

        button:SetScript("OnLeave", function(control)
            control.hovered = nil
            Addon:ReapplyMenu()
        end)

        button:SetScript("OnClick", function()
            self:SelectPage(id)
            Addon:ReapplyMenu()
        end)

        self.navButtons[id] = button
        previous = button
    end
end

function Menu:EnsureFrame()
    if self.frame then
        return self.frame
    end

    self:CreateShell()
    self:BuildNavigation()
    self:ApplyLayout()
    return self.frame
end

function Menu:GetPageContentHeight(pageFrame)
    local top = pageFrame:GetTop()
    if not top then
        return self.frame.ScrollFrame:GetHeight()
    end

    local minimumBottom = top

    for _, child in ipairs({ pageFrame:GetChildren() }) do
        if child:IsShown() then
            local bottom = child:GetBottom()
            if bottom and bottom < minimumBottom then
                minimumBottom = bottom
            end
        end
    end

    for _, region in ipairs({ pageFrame:GetRegions() }) do
        if region:IsShown() and region.GetBottom then
            local bottom = region:GetBottom()
            if bottom and bottom < minimumBottom then
                minimumBottom = bottom
            end
        end
    end

    return math.max(self.frame.ScrollFrame:GetHeight(), math.ceil(top - minimumBottom + 18))
end

function Menu:ApplyLayout()
    local frame = self.frame
    if not frame then
        return
    end

    local width = frame:GetWidth()
    local height = frame:GetHeight()
    local contentHeight = height - HEADER_HEIGHT - OUTER_PADDING
    local contentWidth = width - (OUTER_PADDING * 2) - NAV_WIDTH - CONTENT_GAP

    frame.Nav:ClearAllPoints()
    frame.Nav:SetPoint("TOPLEFT", OUTER_PADDING, -HEADER_HEIGHT)
    frame.Nav:SetSize(NAV_WIDTH, contentHeight)

    frame.Content:ClearAllPoints()
    frame.Content:SetPoint("TOPLEFT", frame.Nav, "TOPRIGHT", CONTENT_GAP, 0)
    frame.Content:SetSize(contentWidth, contentHeight)

    frame.ScrollFrame:ClearAllPoints()
    frame.ScrollFrame:SetPoint("TOPLEFT", CONTENT_INSET, -CONTENT_INSET)
    frame.ScrollFrame:SetPoint("BOTTOMRIGHT", -18, CONTENT_INSET)

    frame.ScrollBar:ClearAllPoints()
    frame.ScrollBar:SetPoint("TOPRIGHT", -6, -CONTENT_INSET)
    frame.ScrollBar:SetPoint("BOTTOMRIGHT", -6, CONTENT_INSET)

    self:ApplyPageWidths(frame.ScrollFrame:GetWidth())

    if self.activePage then
        local page = self.pages[self.activePage]
        if page and page.frame then
            local scrollWidth = frame.ScrollFrame:GetWidth()
            local scrollHeight = frame.ScrollFrame:GetHeight()

            if scrollWidth and scrollWidth > 0 and scrollHeight and scrollHeight > 0 then
                frame.ScrollChild:SetWidth(scrollWidth)
                page.frame:SetWidth(scrollWidth)

                local pageHeight = self:GetPageContentHeight(page.frame)
                frame.ScrollChild:SetHeight(pageHeight)
                page.frame:SetHeight(pageHeight)

                local maximum = math.max(0, pageHeight - scrollHeight)
                local current = Clamp(frame.ScrollBar:GetValue(), 0, maximum)
                frame.ScrollBar:SetMinMaxValues(0, maximum)
                frame.ScrollBar:SetValue(current)
                frame.ScrollBar:SetShown(maximum > 0)

                if maximum > 0 then
                    local adjustedWidth = frame.ScrollFrame:GetWidth() - SCROLLBAR_WIDTH - 8
                    self:ApplyPageWidths(adjustedWidth)
                    frame.ScrollChild:SetWidth(adjustedWidth)
                    page.frame:SetWidth(adjustedWidth)
                    pageHeight = self:GetPageContentHeight(page.frame)
                    frame.ScrollChild:SetHeight(pageHeight)
                    page.frame:SetHeight(pageHeight)
                    maximum = math.max(0, pageHeight - scrollHeight)
                    current = Clamp(frame.ScrollBar:GetValue(), 0, maximum)
                    frame.ScrollBar:SetMinMaxValues(0, maximum)
                    frame.ScrollBar:SetValue(current)
                end

                if maximum == 0 then
                    frame.ScrollFrame:SetVerticalScroll(0)
                end
            end
        end
    else
        frame.ScrollBar:SetShown(false)
    end
end

function Menu:ForceLayoutUpdate()
    self:ApplyLayout()
end

function Menu:ScheduleLayoutUpdate()
    if self.layoutScheduled then
        return
    end

    self.layoutScheduled = true
    C_Timer.After(0, function()
        self.layoutScheduled = nil
        if self.frame then
            self:ApplyLayout()
        end
    end)
end

function Menu:BeginResizeUpdates()
    if self.layoutTicker then
        return
    end

    self.layoutTicker = C_Timer.NewTicker(RESIZE_DEBOUNCE_SECONDS, function()
        if self.frame then
            ClampFrameSize(self.frame)
        end

        self:ApplyLayout()
    end)
end

function Menu:EndResizeUpdates()
    if self.layoutTicker then
        self.layoutTicker:Cancel()
        self.layoutTicker = nil
    end
end

function Addon:ReapplyMenu()
    local menu = self.Menu
    if not menu or not menu.frame then
        return
    end

    self.SkinHelpers:ApplyPanel(menu.frame, {
        accent = false,
        surfaceColorPath = "color.surface.canvas",
    })
    self.SkinHelpers:ApplyPanel(menu.frame.Nav, {
        accent = false,
        shadow = false,
        surfaceColorPath = "color.surface.inset",
        borderColorPath = "color.border.subtle",
    })
    self.SkinHelpers:ApplyPanel(menu.frame.Content, {
        accent = false,
        shadow = false,
    })

    do
        local trackColor = self.Theme:GetToken("color.surface.inset")
        local thumbColor = self.Theme:GetColor("accent", "primary")
        menu.frame.ScrollBar.Track:SetVertexColor(trackColor.r, trackColor.g, trackColor.b, 0.65)
        menu.frame.ScrollBar.Thumb:SetVertexColor(thumbColor.r, thumbColor.g, thumbColor.b, thumbColor.a or 1)
    end

    do
        local resizeColor = menu.frame.ResizeHandle.hovered and self.Theme:GetColor("accent", "primary") or self.Theme:GetToken("color.border.subtle")
        self.SkinHelpers:ApplyText(menu.frame.ResizeHandle.Glyph, {
            fontFile = ns.IconFont.Path,
            size = "lg",
            flags = "body",
            colorPath = menu.frame.ResizeHandle.hovered and "color.role.accent.strong" or "color.border.subtle",
        })
        menu.frame.ResizeHandle.Glyph:SetAlpha(menu.frame.ResizeHandle.hovered and 1 or 0.8)
    end

    self.SkinHelpers:ApplyText(menu.frame.Title, {
        size = "xl",
        flags = "display",
    })
    self.SkinHelpers:ApplyText(menu.frame.Subtitle, {
        size = "sm",
        colorPath = "color.text.secondary",
    })
    self.SkinHelpers:ApplyTextButton(menu.frame.CloseButton, {
        fontFile = ns.IconFont.Path,
        size = "md",
        idleAlpha = 0.25,
        activeAlpha = 0.95,
    })

    for id, button in pairs(menu.navButtons) do
        local selected = id == menu.activePage
        local indicatorColor = selected and self.Theme:GetColor("accent", "primary") or self.Theme:GetToken("color.border.subtle")

        button.active = selected
        self.SkinHelpers:ApplyTextButton(button, {
            size = "sm",
            colorPath = "color.text.secondary",
            activeColorPath = "color.text.primary",
            hoverColorPath = "color.role.accent.strong",
            idleAlpha = 0.2,
            activeAlpha = 0.9,
        })
        button.Indicator:SetVertexColor(indicatorColor.r, indicatorColor.g, indicatorColor.b, indicatorColor.a or 1)
        button.Indicator:SetAlpha(selected and 1 or 0.35)
    end

    for _, id in ipairs(menu.order) do
        local page = menu.pages[id]
        if page and type(page.applyTheme) == "function" then
            page:applyTheme()
        end
    end

    menu:ScheduleLayoutUpdate()
end

function Addon:ToggleMenu()
    local menu = self.Menu
    menu:EnsureFrame()

    if menu.frame:IsShown() then
        menu.frame:Hide()
        return
    end

    local uiState = self:GetGlobalUIState()
    local targetPage = uiState and uiState.menu and uiState.menu.lastPage or menu.order[1]

    menu:SelectPage(targetPage)
    self:ReapplyMenu()
    menu.frame:Show()
end

function Menu:RegisterBuiltinPages()
    self:RegisterPage("overview", {
        title = "Overview",
        build = function(page, frame)
            page.Header = Widgets:CreateSectionHeader(frame, "Overview", "Minimal Phase 00 menu shell. This page only exposes settings and tools that are implemented right now.")
            page.Header:SetPoint("TOPLEFT", 8, -8)

            page.ProfileRow = Widgets:CreateValueRow(frame, "Active Profile")
            page.ProfileRow:SetPoint("TOPLEFT", page.Header, "BOTTOMLEFT", 0, -18)

            page.ThemeRow = Widgets:CreateValueRow(frame, "Active Theme")
            page.ThemeRow:SetPoint("TOPLEFT", page.ProfileRow, "BOTTOMLEFT", 0, -16)

            page.VersionRow = Widgets:CreateValueRow(frame, "Addon Version")
            page.VersionRow:SetPoint("TOPLEFT", page.ThemeRow, "BOTTOMLEFT", 0, -16)

            page.LoadMessageToggle = Widgets:CreateCheckboxRow(
                frame,
                "Show startup chat message",
                "Controls the WeirdUI load message printed when the character logs in.",
                function()
                    return Addon:GetCurrentProfile().ui.showLoadMessage
                end,
                function(value)
                    Addon:GetCurrentProfile().ui.showLoadMessage = value
                end
            )
            page.LoadMessageToggle:SetPoint("TOPLEFT", page.VersionRow, "BOTTOMLEFT", 0, -18)

            page.OpenPreview = Widgets:CreateActionRow(
                frame,
                "Theme preview frame",
                "Open the current developer preview surface for tokens, buttons, text, and status bars.",
                "Open Preview",
                function()
                    Addon:ShowPreviewFrame()
                end
            )
            page.OpenPreview:SetPoint("TOPLEFT", page.LoadMessageToggle, "BOTTOMLEFT", 0, -22)

            page.Reapply = Widgets:CreateActionRow(
                frame,
                "Reapply current skins",
                "Repaint the current preview and menu surfaces without reloading the UI.",
                "Reapply",
                function()
                    Addon:ReapplyAllSkins()
                    Addon:ReapplyPreview()
                    Addon:ReapplyMenu()
                end
            )
            page.Reapply:SetPoint("TOPLEFT", page.OpenPreview, "BOTTOMLEFT", 0, -14)
        end,
        applyTheme = function(page)
            page.Header:ApplyTheme()
            page.ProfileRow:SetValue(Addon:GetCurrentProfileName())
            page.ProfileRow:ApplyTheme()
            page.ThemeRow:SetValue(Addon.Theme:GetActiveThemeLabel())
            page.ThemeRow:ApplyTheme()
            page.VersionRow:SetValue(ns.Version)
            page.VersionRow:ApplyTheme()
            page.LoadMessageToggle:Sync()
            page.LoadMessageToggle:ApplyTheme()
            page.OpenPreview:ApplyTheme()
            page.Reapply:ApplyTheme()
        end,
    })

    self:RegisterPage("theme", {
        title = "Theme",
        build = function(page, frame)
            page.Header = Widgets:CreateSectionHeader(frame, "Theme", "Only the currently implemented built-in theme is exposed here. No placeholder packs or future module controls are shown.")
            page.Header:SetPoint("TOPLEFT", 8, -8)

            page.ThemeID = Widgets:CreateValueRow(frame, "Theme ID")
            page.ThemeID:SetPoint("TOPLEFT", page.Header, "BOTTOMLEFT", 0, -18)

            page.Fallback = Widgets:CreateValueRow(frame, "Fallback Order")
            page.Fallback:SetPoint("TOPLEFT", page.ThemeID, "BOTTOMLEFT", 0, -16)

            page.SwatchesLabel = Widgets:CreateBodyText(frame, "Token samples")
            page.SwatchesLabel:SetPoint("TOPLEFT", page.Fallback, "BOTTOMLEFT", 0, -20)

            page.Accent = Widgets:CreateColorSwatchRow(frame, "Accent", "Primary interactive emphasis color.", "color.role.accent.primary")
            page.Accent:SetPoint("TOPLEFT", page.SwatchesLabel, "BOTTOMLEFT", 0, -12)

            page.Success = Widgets:CreateColorSwatchRow(frame, "Success", "Positive state and completion color.", "color.role.success.primary")
            page.Success:SetPoint("TOPLEFT", page.Accent, "BOTTOMLEFT", 0, -12)

            page.Warning = Widgets:CreateColorSwatchRow(frame, "Warning", "Caution state and high-attention notices.", "color.role.warning.primary")
            page.Warning:SetPoint("TOPLEFT", page.Success, "BOTTOMLEFT", 0, -12)

            page.Danger = Widgets:CreateColorSwatchRow(frame, "Danger", "Error and harmful-state emphasis.", "color.role.danger.primary")
            page.Danger:SetPoint("TOPLEFT", page.Warning, "BOTTOMLEFT", 0, -12)
        end,
        applyTheme = function(page)
            page.Header:ApplyTheme()
            page.ThemeID:SetValue(Addon.Theme:GetActiveThemeID())
            page.ThemeID:ApplyTheme()
            page.Fallback:SetValue(table.concat(ns.ThemeSchema.fallbackOrder, " -> "))
            page.Fallback:ApplyTheme()
            page.SwatchesLabel:ApplyTheme()
            page.Accent:ApplyTheme()
            page.Success:ApplyTheme()
            page.Warning:ApplyTheme()
            page.Danger:ApplyTheme()
        end,
    })

    self:RegisterPage("tools", {
        title = "Tools",
        build = function(page, frame)
            page.Header = Widgets:CreateSectionHeader(frame, "Tools", "These are the only developer tools currently implemented in the addon.")
            page.Header:SetPoint("TOPLEFT", 8, -8)

            page.Preview = Widgets:CreateActionRow(
                frame,
                "Preview surface",
                "Open the current preview frame used to test tokens and shared skin helpers.",
                "Open Preview",
                function()
                    Addon:ShowPreviewFrame()
                end
            )
            page.Preview:SetPoint("TOPLEFT", page.Header, "BOTTOMLEFT", 0, -18)

            page.Reapply = Widgets:CreateActionRow(
                frame,
                "Live reapply",
                "Reapply currently registered skins and refresh open developer surfaces.",
                "Reapply",
                function()
                    Addon:ReapplyAllSkins()
                    Addon:ReapplyPreview()
                    Addon:ReapplyMenu()
                end
            )
            page.Reapply:SetPoint("TOPLEFT", page.Preview, "BOTTOMLEFT", 0, -14)

            page.SlashCommands = Widgets:CreateValueRow(frame, "Slash Commands")
            page.SlashCommands:SetPoint("TOPLEFT", page.Reapply, "BOTTOMLEFT", 0, -22)
        end,
        applyTheme = function(page)
            page.Header:ApplyTheme()
            page.Preview:ApplyTheme()
            page.Reapply:ApplyTheme()
            page.SlashCommands:SetValue("/weirdui, /weirdui preview, /weirdui reapply, /weirdui token <path>, /rl")
            page.SlashCommands:ApplyTheme()
        end,
    })
end

function Addon:InitializeMenu()
    self.Menu = Menu
    Menu:RegisterBuiltinPages()
end

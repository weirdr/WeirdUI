local _, ns = ...

local Addon = ns.Addon
local Widgets = ns.MenuWidgets

local RESIZE_DEBOUNCE_SECONDS = 0.01
local MIN_WIDTH = 760
local MIN_HEIGHT = 460
local MAX_WIDTH = 1280
local MAX_HEIGHT = 900
local MENU_SCALE_DEBOUNCE_SECONDS = 0.001
local MENU_SCALE_MIN = 0.75
local MENU_SCALE_MAX = 1.25
local MENU_SCALE_STEP = 0.01
local NAV_WIDTH = 188
local HEADER_HEIGHT = 70
local PAGE_LEFT_INSET = 8
local OUTER_PADDING = 16
local CONTENT_GAP = 18
local CONTENT_INSET = 14
local SCROLLBAR_WIDTH = 8

local Menu = {
    pages = {},
    order = {},
    navButtons = {},
    layoutTicker = nil,
    modulePages = {},
    moduleOrder = {},
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

local function RoundToStep(value, step)
    if type(value) ~= "number" then
        return 1
    end

    local safeStep = step or 0.05
    return math.floor((value / safeStep) + 0.5) * safeStep
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

function Menu:RegisterModulePage(id, definition)
    if type(definition) ~= "table" then
        return
    end

    Addon:RegisterModule(id, {
        label = definition.moduleLabel or definition.title or id,
        status = definition.moduleStatus or "Prototype",
        description = definition.moduleDescription or "Registered module page.",
        pageID = id,
        category = definition.moduleCategory or "General",
    })

    definition.kind = "module"
    self:RegisterPage(id, definition)

    if not self.modulePages[id] then
        self.moduleOrder[#self.moduleOrder + 1] = id
    end

    self.modulePages[id] = self.pages[id]
end

function Menu:GetModulePageNames()
    local names = {}

    for _, id in ipairs(self.moduleOrder) do
        local page = self.modulePages[id]
        if page then
            names[#names + 1] = page.title or id
        end
    end

    return names
end

function Addon:RegisterModulePage(id, definition)
    Menu:RegisterModulePage(id, definition)
end

function Menu:GetSavedScale()
    local uiState = Addon:GetGlobalUIState()
    local menuState = uiState and uiState.menu
    local scale = type(menuState and menuState.scale) == "number" and menuState.scale or 1

    scale = RoundToStep(scale, MENU_SCALE_STEP)
    return Clamp(scale, MENU_SCALE_MIN, MENU_SCALE_MAX)
end

function Menu:ApplyScale(scale, options)
    options = options or {}

    local clamped = Clamp(options.snap == false and scale or RoundToStep(scale, MENU_SCALE_STEP), MENU_SCALE_MIN, MENU_SCALE_MAX)
    local uiState = Addon:GetGlobalUIState()

    if uiState then
        uiState.menu = uiState.menu or {}
        uiState.menu.scale = clamped
    end

    if self.frame then
        self.frame:SetScale(clamped)

        local control = self.frame.ScaleControl
        if control then
            control.Syncing = true
            control.Slider:SetValue(clamped)
            control.Syncing = nil
            control:UpdateValueDisplay(clamped)
        end
    end

    return clamped
end

function Menu:UpdateScaleControlFromCursor()
    local frame = self.frame
    local control = frame and frame.ScaleControl
    if not control or not control.dragging then
        return
    end

    local cursorX = GetCursorPosition()
    local deltaX = cursorX - control.DragCursorStartX
    local sliderWidth = math.max(1, control.DragSliderWidth or control.Slider:GetWidth() or 1)
    local ratioDelta = deltaX / sliderWidth
    local range = MENU_SCALE_MAX - MENU_SCALE_MIN
    local nextValue = Clamp(control.DragValueStart + (ratioDelta * range), MENU_SCALE_MIN, MENU_SCALE_MAX)

    control.PendingValue = nextValue
    control.Syncing = true
    control.Slider:SetValue(nextValue)
    control.Syncing = nil
    control:UpdateValueDisplay(nextValue)
end

function Menu:BeginScaleDrag()
    local frame = self.frame
    local control = frame and frame.ScaleControl
    if not control or control.dragging then
        return
    end

    control.dragging = true
    control.DragCursorStartX = GetCursorPosition()
    control.DragValueStart = self:GetSavedScale()
    control.DragSliderWidth = math.max(1, control.Slider:GetWidth() or 1)
    control.PendingValue = control.DragValueStart
    control:UpdateValueDisplay(control.DragValueStart)

    if self.scaleDragTicker then
        self.scaleDragTicker:Cancel()
    end

    self.scaleDragTicker = C_Timer.NewTicker(MENU_SCALE_DEBOUNCE_SECONDS, function()
        local currentControl = self.frame and self.frame.ScaleControl
        if not currentControl or not currentControl.dragging then
            if self.scaleDragTicker then
                self.scaleDragTicker:Cancel()
                self.scaleDragTicker = nil
            end
            return
        end

        self:UpdateScaleControlFromCursor()

        if type(currentControl.PendingValue) == "number" then
            self:ApplyScale(currentControl.PendingValue, {
                snap = false,
                skipControlSync = true,
            })
        end
    end)
end

function Menu:EndScaleDrag()
    local control = self.frame and self.frame.ScaleControl
    if not control or not control.dragging then
        return
    end

    control.dragging = nil
    self:UpdateScaleControlFromCursor()

    if self.scaleDragTicker then
        self.scaleDragTicker:Cancel()
        self.scaleDragTicker = nil
    end

    self:ApplyScale(control.PendingValue or control.Slider:GetValue())
    control.PendingValue = nil
    control.DragCursorStartX = nil
    control.DragValueStart = nil
    control.DragSliderWidth = nil
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

    frame.ScaleControl = CreateFrame("Frame", nil, frame)
    frame.ScaleControl:SetSize(128, 20)
    frame.ScaleControl:SetPoint("RIGHT", frame.CloseButton, "LEFT", -10, 0)

    frame.ScaleControl.Value = frame.ScaleControl:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.ScaleControl.Value:SetPoint("RIGHT", 0, 0)
    frame.ScaleControl.Value:SetJustifyH("RIGHT")

    frame.ScaleControl.Slider = CreateFrame("Slider", nil, frame.ScaleControl)
    frame.ScaleControl.Slider:SetPoint("LEFT", 0, 0)
    frame.ScaleControl.Slider:SetPoint("RIGHT", frame.ScaleControl.Value, "LEFT", -8, 0)
    frame.ScaleControl.Slider:SetHeight(12)
    frame.ScaleControl.Slider:SetMinMaxValues(MENU_SCALE_MIN, MENU_SCALE_MAX)
    frame.ScaleControl.Slider:SetValueStep(MENU_SCALE_STEP)
    frame.ScaleControl.Slider:SetObeyStepOnDrag(false)
    frame.ScaleControl.Slider:EnableMouse(false)

    frame.ScaleControl.Slider.Track = frame.ScaleControl.Slider:CreateTexture(nil, "BACKGROUND")
    frame.ScaleControl.Slider.Track:SetTexture("Interface\\Buttons\\WHITE8X8")
    frame.ScaleControl.Slider.Track:SetPoint("LEFT", 0, 0)
    frame.ScaleControl.Slider.Track:SetPoint("RIGHT", 0, 0)
    frame.ScaleControl.Slider.Track:SetHeight(2)

    frame.ScaleControl.Slider.Fill = frame.ScaleControl.Slider:CreateTexture(nil, "ARTWORK")
    frame.ScaleControl.Slider.Fill:SetTexture("Interface\\Buttons\\WHITE8X8")
    frame.ScaleControl.Slider.Fill:SetPoint("LEFT", 0, 0)
    frame.ScaleControl.Slider.Fill:SetHeight(2)

    frame.ScaleControl.Slider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
    frame.ScaleControl.Slider:GetThumbTexture():SetSize(1, 1)
    frame.ScaleControl.Slider:GetThumbTexture():SetAlpha(0)

    function frame.ScaleControl:UpdateValueDisplay(value)
        local slider = self.Slider
        local clamped = Clamp(value or 1, MENU_SCALE_MIN, MENU_SCALE_MAX)
        local range = MENU_SCALE_MAX - MENU_SCALE_MIN
        local ratio = range > 0 and ((clamped - MENU_SCALE_MIN) / range) or 0
        local sliderWidth = math.max(1, slider:GetWidth() or 1)

        self.Value:SetText(string.format("%d%%", math.floor((clamped * 100) + 0.5)))
        slider.Fill:SetWidth(math.max(0, math.floor(sliderWidth * ratio)))
    end

    frame.ScaleControl:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            self:BeginScaleDrag()
        end
    end)

    frame.ScaleControl:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            self:EndScaleDrag()
        end
    end)

    frame.ScaleControl:SetScript("OnHide", function()
        self:EndScaleDrag()
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
    self:ApplyScale(self:GetSavedScale())
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

    if id ~= "welcome" and not Addon:IsOnboardingComplete() then
        id = "welcome"
        page = self.pages[id]
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
    self:ApplyScale(self:GetSavedScale())
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

    self:ApplyPageWidths(math.max(240, frame.ScrollFrame:GetWidth() - PAGE_LEFT_INSET))

    if self.activePage then
        local page = self.pages[self.activePage]
        if page and page.frame then
                local scrollWidth = frame.ScrollFrame:GetWidth()
                local scrollHeight = frame.ScrollFrame:GetHeight()

                if scrollWidth and scrollWidth > 0 and scrollHeight and scrollHeight > 0 then
                    local availableWidth = math.max(240, scrollWidth - PAGE_LEFT_INSET)

                    frame.ScrollChild:SetWidth(availableWidth)
                    page.frame:SetWidth(availableWidth)

                    local pageHeight = self:GetPageContentHeight(page.frame)
                    frame.ScrollChild:SetHeight(pageHeight)
                    page.frame:SetHeight(pageHeight)

                local maximum = math.max(0, pageHeight - scrollHeight)
                local current = Clamp(frame.ScrollBar:GetValue(), 0, maximum)
                frame.ScrollBar:SetMinMaxValues(0, maximum)
                frame.ScrollBar:SetValue(current)
                frame.ScrollBar:SetShown(maximum > 0)

                if maximum > 0 then
                    local adjustedWidth = frame.ScrollFrame:GetWidth() - SCROLLBAR_WIDTH - 8 - PAGE_LEFT_INSET
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

function Menu:RefreshToolsPreview()
    local page = self.pages and self.pages.tools
    if not page or not page.frame or not self.activePage or self.activePage ~= "tools" then
        return
    end

    local previewState = Addon:GetCurrentProfile().ui
    local previewTone = previewState.previewTone or "accent"
    local previewValue = previewState.previewValue or 72
    local previewEnabled = previewState.previewEnabled ~= false
    local previewLabel = previewState.previewLabel or "Embedded Preview"
    local previewSwatch = previewState.previewSwatch or "accent"
    local previewDensity = previewState.previewDensity or "comfortable"
    local previewLeftValue = previewState.previewLeftValue or 28
    local previewRightValue = previewState.previewRightValue or 76
    local previewWarningAcknowledged = previewState.previewWarningAcknowledged and true or false
    local toneStrong = Addon.Theme:GetColor(previewTone, "strong") or Addon.Theme:GetColor("accent", "strong")
    local tonePrimary = Addon.Theme:GetColor(previewTone, "primary") or Addon.Theme:GetColor("accent", "primary")
    local swatchPrimary = Addon.Theme:GetColor(previewSwatch, "primary") or Addon.Theme:GetColor("accent", "primary")

    if page.PreviewValue then
        page.PreviewValue:Sync()
        page.PreviewValue:ApplyTheme()
    end

    if page.PreviewEnabled then
        page.PreviewEnabled:Sync()
        page.PreviewEnabled:ApplyTheme()
    end

    if page.PreviewTone then
        page.PreviewTone:ApplyTheme()
    end

    if page.PreviewSwatch then
        local color = Addon.Theme:GetColor(previewSwatch, "primary") or Addon.Theme:GetColor("accent", "primary")

        Addon.SkinHelpers:ApplyPanel(page.PreviewSwatch.Swatch, {
            accent = false,
            shadow = false,
            surfaceColorPath = "color.surface.inset",
            borderColorPath = "color.border.subtle",
        })
        Addon.SkinHelpers:ApplyText(page.PreviewSwatch.Label, {
            size = "sm",
            flags = "emphasis",
        })
        Addon.SkinHelpers:ApplyText(page.PreviewSwatch.Description, {
            size = "xs",
            colorPath = "color.text.secondary",
        })
        page.PreviewSwatch.Swatch.Fill:SetColorTexture(color.r, color.g, color.b, color.a or 1)
        page.PreviewSwatch:Layout()
    end

    if page.PreviewSwatchSelect then
        page.PreviewSwatchSelect:ApplyTheme()
    end

    if page.PreviewDensity then
        page.PreviewDensity:ApplyTheme()
    end

    if page.CompactPair then
        page.CompactPair.Left:Sync()
        page.CompactPair.Right:Sync()
        page.CompactPair:ApplyTheme()
    end

    if page.WarningActions then
        page.WarningActions.Notice.Description:SetText(previewWarningAcknowledged
            and "Warning acknowledged. Use the secondary action to put the preview back into its unresolved state."
            or "Example warning action group. Use the primary or secondary action to change the embedded preview state.")
        page.WarningActions:ApplyTheme()
    end

    if page.Requirement then
        page.Requirement:ApplyTheme()
    end

    if page.ResetPreview then
        page.ResetPreview:ApplyTheme()
    end

    if page.PreviewSurface then
        local previousHeight = page.PreviewSurface:GetHeight()

        Addon.SkinHelpers:ApplyPanel(page.PreviewSurface, {
            accent = false,
            shadow = false,
            surfaceColorPath = "color.surface.panel",
            borderColorPath = "color.border.subtle",
        })
        Addon.SkinHelpers:ApplyText(page.PreviewSurface.Title, {
            size = "sm",
            flags = "display",
        })
        Addon.SkinHelpers:ApplyText(page.PreviewSurface.Subtitle, {
            size = "xs",
            colorPath = "color.text.secondary",
        })
        Addon.SkinHelpers:ApplyText(page.PreviewSurface.StatusLabel, {
            size = "xs",
            flags = "emphasis",
            colorPath = string.format("color.role.%s.strong", previewTone),
        })
        Addon.SkinHelpers:ApplyText(page.PreviewSurface.Detail, {
            size = "sm",
            colorPath = "color.text.secondary",
        })
        Addon.SkinHelpers:ApplyStatusBar(page.PreviewSurface.StatusBar)
        Addon.SkinHelpers:ApplyIcon(page.PreviewSurface.Icon)

        do
            local fillColor = Addon.Theme:GetColor(previewTone, "primary") or Addon.Theme:GetColor("accent", "primary")
            local mutedColor = Addon.Theme:GetColor("disabled", "primary") or Addon.Theme:GetToken("color.text.muted")
            local barColor = previewEnabled and fillColor or mutedColor
            page.PreviewSurface.StatusBar:SetStatusBarColor(barColor.r, barColor.g, barColor.b, barColor.a or 1)
        end

        page.PreviewSurface.Title:SetText(previewLabel)
        page.PreviewSurface.Title:SetTextColor(toneStrong.r, toneStrong.g, toneStrong.b, toneStrong.a or 1)
        page.PreviewSurface.StatusBar:SetValue(previewValue)
        page.PreviewSurface.Icon:SetDesaturated(not previewEnabled)
        page.PreviewSurface.Icon:SetVertexColor(swatchPrimary.r, swatchPrimary.g, swatchPrimary.b, previewEnabled and (swatchPrimary.a or 1) or 0.45)
        page.PreviewSurface.Detail:SetText(string.format(
            "Tone: %s\nSwatch: %s\nDensity: %s\nPair values: %d / %d\nSample value: %d%%\nEnabled: %s\nWarning acknowledged: %s\nProfile: %s",
            previewTone,
            previewSwatch,
            previewDensity,
            previewLeftValue,
            previewRightValue,
            previewValue,
            previewEnabled and "Yes" or "No",
            previewWarningAcknowledged and "Yes" or "No",
            Addon:GetCurrentProfileName()
        ))

        do
            local width = page.PreviewSurface:GetWidth() or 520
            local detailWidth = math.max(240, width - 28)

            page.PreviewSurface.Subtitle:SetWidth(detailWidth)
            page.PreviewSurface.Detail:SetWidth(detailWidth)

            local contentBottom = page.PreviewSurface.Detail:GetBottom()
            local frameTop = page.PreviewSurface:GetTop()
            if contentBottom and frameTop then
                local measuredHeight = math.ceil(frameTop - contentBottom + 16)
                page.PreviewSurface:SetHeight(math.max(198, measuredHeight))
            end
        end

        if page.PreviewSurface:GetHeight() ~= previousHeight then
            self:ScheduleLayoutUpdate()
        end
    end
end

function Menu:RefreshWelcomePreview()
    local page = self.pages and self.pages.welcome
    if not page or not page.frame or not self.activePage or self.activePage ~= "welcome" then
        return
    end

    local previewState = Addon:GetCurrentProfile().ui
    local previewTone = previewState.previewTone or "accent"
    local previewDensity = previewState.previewDensity or "comfortable"
    local previewEnabled = previewState.showLoadMessage ~= false
    local toneStrong = Addon.Theme:GetColor(previewTone, "strong") or Addon.Theme:GetColor("accent", "strong")
    local tonePrimary = Addon.Theme:GetColor(previewTone, "primary") or Addon.Theme:GetColor("accent", "primary")

    if page.StartupMessage then
        page.StartupMessage:Sync()
        page.StartupMessage:ApplyTheme()
    end

    if page.OnboardingTone then
        page.OnboardingTone:ApplyTheme()
    end

    if page.OnboardingDensity then
        page.OnboardingDensity:ApplyTheme()
    end

    if page.PreviewSurface then
        local previousHeight = page.PreviewSurface:GetHeight()

        Addon.SkinHelpers:ApplyPanel(page.PreviewSurface, {
            accent = false,
            shadow = false,
            surfaceColorPath = "color.surface.panel",
            borderColorPath = "color.border.subtle",
        })
        Addon.SkinHelpers:ApplyText(page.PreviewSurface.Title, {
            size = "sm",
            flags = "display",
        })
        Addon.SkinHelpers:ApplyText(page.PreviewSurface.Subtitle, {
            size = "xs",
            colorPath = "color.text.secondary",
        })
        Addon.SkinHelpers:ApplyText(page.PreviewSurface.StatusLabel, {
            size = "xs",
            flags = "emphasis",
            colorPath = string.format("color.role.%s.strong", previewTone),
        })
        Addon.SkinHelpers:ApplyText(page.PreviewSurface.Detail, {
            size = "sm",
            colorPath = "color.text.secondary",
        })
        Addon.SkinHelpers:ApplyStatusBar(page.PreviewSurface.StatusBar)
        Addon.SkinHelpers:ApplyIcon(page.PreviewSurface.Icon)

        page.PreviewSurface.Title:SetText("Onboarding Preview")
        page.PreviewSurface.Title:SetTextColor(toneStrong.r, toneStrong.g, toneStrong.b, toneStrong.a or 1)
        page.PreviewSurface.Icon:SetDesaturated(not previewEnabled)
        page.PreviewSurface.Icon:SetVertexColor(tonePrimary.r, tonePrimary.g, tonePrimary.b, previewEnabled and (tonePrimary.a or 1) or 0.45)
        page.PreviewSurface.StatusBar:SetStatusBarColor(tonePrimary.r, tonePrimary.g, tonePrimary.b, tonePrimary.a or 1)
        page.PreviewSurface.StatusBar:SetValue(previewDensity == "compact" and 34 or (previewDensity == "spacious" and 82 or 58))
        page.PreviewSurface.Detail:SetText(string.format(
            "Startup message: %s\nPreview tone: %s\nPreview density: %s\nThis is the same settings model the full menu will use after setup.",
            previewEnabled and "Enabled" or "Disabled",
            previewTone,
            previewDensity
        ))

        do
            local width = page.PreviewSurface:GetWidth() or 520
            local detailWidth = math.max(240, width - 28)

            page.PreviewSurface.Subtitle:SetWidth(detailWidth)
            page.PreviewSurface.Detail:SetWidth(detailWidth)

            local contentBottom = page.PreviewSurface.Detail:GetBottom()
            local frameTop = page.PreviewSurface:GetTop()
            if contentBottom and frameTop then
                local measuredHeight = math.ceil(frameTop - contentBottom + 16)
                page.PreviewSurface:SetHeight(math.max(182, measuredHeight))
            end
        end

        if page.PreviewSurface:GetHeight() ~= previousHeight then
            self:ScheduleLayoutUpdate()
        end
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
    self.SkinHelpers:ApplyText(menu.frame.ScaleControl.Value, {
        size = "xs",
        flags = "emphasis",
        colorPath = "color.role.accent.strong",
    })
    self.SkinHelpers:ApplyTextButton(menu.frame.CloseButton, {
        fontFile = ns.IconFont.Path,
        size = "md",
        idleAlpha = 0.25,
        activeAlpha = 0.95,
    })

    do
        local trackColor = self.Theme:GetToken("color.border.subtle")
        local fillColor = self.Theme:GetColor("accent", "primary")
        local slider = menu.frame.ScaleControl.Slider

        slider.Track:SetVertexColor(trackColor.r, trackColor.g, trackColor.b, trackColor.a or 1)
        slider.Fill:SetVertexColor(fillColor.r, fillColor.g, fillColor.b, fillColor.a or 1)
        menu.frame.ScaleControl:UpdateValueDisplay(slider:GetValue())
    end

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
    local targetPage = not self:IsOnboardingComplete() and "welcome" or (uiState and uiState.menu and uiState.menu.lastPage or menu.order[1])

    menu:SelectPage(targetPage)
    self:ReapplyMenu()
    menu.frame:Show()
end

function Menu:RegisterBuiltinPages()
    self:RegisterPage("welcome", {
        title = "Welcome",
        build = function(page, frame)
            page.Header = Widgets:CreateSectionHeader(frame, "Welcome to WeirdUI", "This short setup flow appears on first launch so you can make a few high-value choices before using the normal menu.")
            page.Header:SetPoint("TOPLEFT", 8, -8)

            page.Intro = Widgets:CreateNoticeRow(
                frame,
                "First-run setup",
                "Keep this quick. Choose a theme emphasis, decide whether the startup message should print, and then continue into the standard menu shell.",
                "accent"
            )
            page.Intro:SetPoint("TOPLEFT", page.Header, "BOTTOMLEFT", 0, -18)

            page.Setup = Widgets:CreateGroupPanel(
                frame,
                "Quick Setup",
                "These choices map directly into the same saved settings used by the regular menu."
            )
            page.Setup:SetPoint("TOPLEFT", page.Intro, "BOTTOMLEFT", 0, -18)

            page.StartupMessage = Widgets:CreateCheckboxRow(
                page.Setup.Content,
                "Show startup chat message",
                "Keep the WeirdUI load message enabled when the character logs in.",
                function()
                    return Addon:GetCurrentProfile().ui.showLoadMessage
                end,
                function(value)
                    Addon:GetCurrentProfile().ui.showLoadMessage = value and true or false
                    Addon:GetCurrentProfile().ui.previewEnabled = value and true or false
                    Addon.Menu:RefreshWelcomePreview()
                end
            )
            page.Setup:AddBlock(page.StartupMessage, 16)

            page.OnboardingTone = Widgets:CreateRadioChoiceRow(
                page.Setup.Content,
                "Initial preview tone",
                "Choose the initial accent emphasis used by the embedded preview examples.",
                {
                    items = {
                        { value = "accent", label = "Accent" },
                        { value = "success", label = "Success" },
                        { value = "warning", label = "Warning" },
                    },
                    getter = function()
                        return Addon:GetCurrentProfile().ui.previewTone or "accent"
                    end,
                    setter = function(value)
                        Addon:GetCurrentProfile().ui.previewTone = value
                        Addon.Menu:RefreshWelcomePreview()
                    end,
                }
            )
            page.Setup:AddBlock(page.OnboardingTone, 14)

            page.OnboardingDensity = Widgets:CreateRadioChoiceRow(
                page.Setup.Content,
                "Initial density",
                "Choose the density mode the preview gallery should start with.",
                {
                    items = {
                        { value = "compact", label = "Compact" },
                        { value = "comfortable", label = "Comfortable" },
                        { value = "spacious", label = "Spacious" },
                    },
                    getter = function()
                        return Addon:GetCurrentProfile().ui.previewDensity or "comfortable"
                    end,
                    setter = function(value)
                        Addon:GetCurrentProfile().ui.previewDensity = value
                        Addon.Menu:RefreshWelcomePreview()
                    end,
                }
            )
            page.Setup:AddBlock(page.OnboardingDensity, 14)

            page.PreviewSurface = CreateFrame("Frame", nil, frame)
            page.PreviewSurface:SetSize(520, 182)
            page.PreviewSurface:SetPoint("TOPLEFT", page.Setup, "BOTTOMLEFT", 0, -22)

            function page.PreviewSurface:SetContentWidth(width)
                self:SetWidth(width or 520)
            end

            page.PreviewSurface.Title = page.PreviewSurface:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            page.PreviewSurface.Title:SetPoint("TOPLEFT", 14, -14)
            page.PreviewSurface.Title:SetText("Onboarding Preview")

            page.PreviewSurface.Subtitle = page.PreviewSurface:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            page.PreviewSurface.Subtitle:SetPoint("TOPLEFT", page.PreviewSurface.Title, "BOTTOMLEFT", 0, -6)
            page.PreviewSurface.Subtitle:SetWidth(460)
            page.PreviewSurface.Subtitle:SetJustifyH("LEFT")
            page.PreviewSurface.Subtitle:SetText("These first-run choices update this preview immediately so you can see the direction before entering the full menu.")

            page.PreviewSurface.Icon = page.PreviewSurface:CreateTexture(nil, "ARTWORK")
            page.PreviewSurface.Icon:SetPoint("TOPRIGHT", -14, -14)
            page.PreviewSurface.Icon:SetSize(24, 24)
            page.PreviewSurface.Icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

            page.PreviewSurface.StatusLabel = page.PreviewSurface:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            page.PreviewSurface.StatusLabel:SetPoint("TOPLEFT", page.PreviewSurface.Subtitle, "BOTTOMLEFT", 0, -18)
            page.PreviewSurface.StatusLabel:SetText("Setup Status")

            page.PreviewSurface.StatusBar = CreateFrame("StatusBar", nil, page.PreviewSurface)
            page.PreviewSurface.StatusBar:SetPoint("TOPLEFT", page.PreviewSurface.StatusLabel, "BOTTOMLEFT", 0, -10)
            page.PreviewSurface.StatusBar:SetSize(280, 18)
            page.PreviewSurface.StatusBar:SetMinMaxValues(0, 100)

            page.PreviewSurface.Detail = page.PreviewSurface:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            page.PreviewSurface.Detail:SetPoint("TOPLEFT", page.PreviewSurface.StatusBar, "BOTTOMLEFT", 0, -12)
            page.PreviewSurface.Detail:SetWidth(460)
            page.PreviewSurface.Detail:SetJustifyH("LEFT")
            page.PreviewSurface.Detail:SetText("")

            page.Complete = Widgets:CreateActionRow(
                frame,
                "Finish setup",
                "Save these initial choices and continue into the full WeirdUI menu.",
                "Enter Menu",
                function()
                    Addon:CompleteOnboarding()

                    local uiState = Addon:GetGlobalUIState()
                    if uiState and uiState.menu then
                        uiState.menu.lastPage = "overview"
                    end

                    Addon:GetCurrentProfile().ui.previewEnabled = Addon:GetCurrentProfile().ui.showLoadMessage ~= false
                    Addon.Menu:SelectPage("overview")
                    Addon:ReapplyMenu()
                end
            )
            page.Complete:SetPoint("TOPLEFT", page.PreviewSurface, "BOTTOMLEFT", 0, -22)
        end,
        applyTheme = function(page)
            page.Header:ApplyTheme()
            page.Intro:ApplyTheme()
            page.Setup:ApplyTheme()
            page.StartupMessage:Sync()
            page.StartupMessage:ApplyTheme()
            page.OnboardingTone:ApplyTheme()
            page.OnboardingDensity:ApplyTheme()
            Addon.Menu:RefreshWelcomePreview()
            page.Complete:ApplyTheme()
        end,
    })

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

    self:RegisterPage("profiles", {
        title = "Profiles",
        build = function(page, frame)
            page.Header = Widgets:CreateSectionHeader(frame, "Profiles", "Manage the active WeirdUI profile and preview the future entry points for presets and import/export.")
            page.Header:SetPoint("TOPLEFT", 8, -8)

            page.ActiveProfile = Widgets:CreateValueRow(frame, "Active Profile")
            page.ActiveProfile:SetPoint("TOPLEFT", page.Header, "BOTTOMLEFT", 0, -18)

            page.ProfileSelect = Widgets:CreateSelectRow(
                frame,
                "Switch profile",
                "Cycle through existing saved profiles for this addon. Switching applies the selected profile to the current character immediately.",
                {
                    items = {},
                    getter = function()
                        return Addon:GetCurrentProfileName()
                    end,
                    setter = function(value)
                        if Addon:UseProfile(value) then
                            Addon:ReapplyAllSkins()
                            Addon:ReapplyPreview()
                            Addon:ReapplyMenu()
                        end
                    end,
                }
            )
            page.ProfileSelect:SetPoint("TOPLEFT", page.ActiveProfile, "BOTTOMLEFT", 0, -18)

            page.NewProfile = Widgets:CreateTextInputRow(
                frame,
                "Create profile",
                "Enter a new profile name. The create action below will add it without switching until you select it.",
                {
                    getter = function()
                        local uiState = Addon:GetGlobalUIState()
                        return uiState and uiState.menu and uiState.menu.newProfileName or ""
                    end,
                    setter = function(value)
                        local uiState = Addon:GetGlobalUIState()
                        if uiState and uiState.menu then
                            uiState.menu.newProfileName = value
                        end
                    end,
                    placeholder = "New profile name",
                }
            )
            page.NewProfile:SetPoint("TOPLEFT", page.ProfileSelect, "BOTTOMLEFT", 0, -18)

            page.CreateProfile = Widgets:CreateActionRow(
                frame,
                "Add profile",
                "Create a new empty profile using the default WeirdUI settings baseline.",
                "Create Profile",
                function()
                    local uiState = Addon:GetGlobalUIState()
                    local requestedName = uiState and uiState.menu and uiState.menu.newProfileName or ""
                    local ok = Addon:CreateProfile(requestedName)
                    if ok then
                        if uiState and uiState.menu then
                            uiState.menu.newProfileName = ""
                        end
                        Addon:ReapplyMenu()
                    end
                end
            )
            page.CreateProfile:SetPoint("TOPLEFT", page.NewProfile, "BOTTOMLEFT", 0, -18)

            page.ResetProfile = Widgets:CreateConfirmActionRow(
                frame,
                "Reset active profile",
                "Restore the active profile to the default WeirdUI baseline. This affects only the current active profile.",
                "Reset Profile",
                "Confirm Reset",
                function()
                    if Addon:ResetCurrentProfile() then
                        Addon:ReapplyAllSkins()
                        Addon:ReapplyPreview()
                        Addon:ReapplyMenu()
                    end
                end
            )
            page.ResetProfile:SetPoint("TOPLEFT", page.CreateProfile, "BOTTOMLEFT", 0, -14)

            page.PresetsNotice = Widgets:CreateNoticeRow(
                frame,
                "Presets are separate from profiles",
                "Profiles are personal saved configurations. Presets will be curated starter configurations later and should not be confused with profile switching.",
                "warning"
            )
            page.PresetsNotice:SetPoint("TOPLEFT", page.ResetProfile, "BOTTOMLEFT", 0, -22)

            page.PresetEntry = Widgets:CreateRequirementRow(
                frame,
                "Preset browser",
                "Future entry point for curated presets and starter configurations.",
                {
                    getter = function()
                        return false
                    end,
                    requirementText = "Preset catalog not implemented yet",
                }
            )
            page.PresetEntry:SetPoint("TOPLEFT", page.PresetsNotice, "BOTTOMLEFT", 0, -18)

            page.ImportExportNotice = Widgets:CreateNoticeRow(
                frame,
                "Import and export are separate entry points",
                "Import/export will support future whole-profile and partial configuration workflows. They are intentionally separate from both profile switching and presets.",
                "accent"
            )
            page.ImportExportNotice:SetPoint("TOPLEFT", page.PresetEntry, "BOTTOMLEFT", 0, -22)

            page.ImportEntry = Widgets:CreateRequirementRow(
                frame,
                "Import configuration",
                "Future entry point for pasted or shared configuration payloads.",
                {
                    getter = function()
                        return false
                    end,
                    requirementText = "Import flow not implemented yet",
                }
            )
            page.ImportEntry:SetPoint("TOPLEFT", page.ImportExportNotice, "BOTTOMLEFT", 0, -18)

            page.ExportEntry = Widgets:CreateRequirementRow(
                frame,
                "Export configuration",
                "Future entry point for sharing or backing up profile and module configuration data.",
                {
                    getter = function()
                        return false
                    end,
                    requirementText = "Export flow not implemented yet",
                }
            )
            page.ExportEntry:SetPoint("TOPLEFT", page.ImportEntry, "BOTTOMLEFT", 0, -14)
        end,
        applyTheme = function(page)
            local profileItems = {}
            for _, name in ipairs(Addon:GetProfileNames()) do
                profileItems[#profileItems + 1] = {
                    value = name,
                    label = name,
                }
            end

            page.Header:ApplyTheme()
            page.ActiveProfile:SetValue(Addon:GetCurrentProfileName())
            page.ActiveProfile:ApplyTheme()
            page.ProfileSelect.Items = profileItems
            page.ProfileSelect:ApplyTheme()
            page.NewProfile:Sync()
            page.NewProfile:ApplyTheme()
            page.CreateProfile:ApplyTheme()
            page.ResetProfile:ApplyTheme()
            page.PresetsNotice:ApplyTheme()
            page.PresetEntry:ApplyTheme()
            page.ImportExportNotice:ApplyTheme()
            page.ImportEntry:ApplyTheme()
            page.ExportEntry:ApplyTheme()
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

    self:RegisterPage("layout", {
        title = "Layout",
        build = function(page, frame)
            page.Header = Widgets:CreateSectionHeader(frame, "Layout", "Define the first WeirdUI layout-edit workflow now so future modules can register real movable targets and settings pages against a stable model.")
            page.Header:SetPoint("TOPLEFT", 8, -8)

            page.Notice = Widgets:CreateNoticeRow(
                frame,
                "Per-profile layout editing",
                "Layout positions are stored on the active profile. This keeps future module placement tied to the same profile workflow used everywhere else in the shell.",
                "accent"
            )
            page.Notice:SetPoint("TOPLEFT", page.Header, "BOTTOMLEFT", 0, -18)

            page.EditMode = Widgets:CreateCheckboxRow(
                frame,
                "Enable layout edit mode",
                "Turn on the minimal layout editor. The selected target becomes draggable on screen and gets an overlay with live position information.",
                function()
                    return Addon:IsLayoutEditModeEnabled()
                end,
                function(value)
                    Addon:SetLayoutEditModeEnabled(value and true or false)
                end
            )
            page.EditMode:SetPoint("TOPLEFT", page.Notice, "BOTTOMLEFT", 0, -18)

            page.Target = Widgets:CreateSelectRow(
                frame,
                "Active layout target",
                "Cycle through registered layout targets. This is the contract future modules should plug into when they expose movable frames.",
                {
                    items = {},
                    getter = function()
                        return Addon:GetSelectedLayoutTargetID()
                    end,
                    setter = function(value)
                        Addon:SetSelectedLayoutTargetID(value)
                    end,
                }
            )
            page.Target:SetPoint("TOPLEFT", page.EditMode, "BOTTOMLEFT", 0, -18)

            page.TargetStatus = Widgets:CreateValueRow(frame, "Target Status")
            page.TargetStatus:SetPoint("TOPLEFT", page.Target, "BOTTOMLEFT", 0, -18)

            page.ModulePages = Widgets:CreateValueRow(frame, "Registered Module Pages")
            page.ModulePages:SetPoint("TOPLEFT", page.TargetStatus, "BOTTOMLEFT", 0, -16)

            page.OpenTarget = Widgets:CreateActionRow(
                frame,
                "Open selected target",
                "Show the currently selected target and apply its stored layout state so you can move it immediately while edit mode is active.",
                "Open Target",
                function()
                    local targetID = Addon:GetSelectedLayoutTargetID()
                    if targetID then
                        Addon:OpenLayoutTarget(targetID)
                    end
                end
            )
            page.OpenTarget:SetPoint("TOPLEFT", page.ModulePages, "BOTTOMLEFT", 0, -22)

            page.ResetTarget = Widgets:CreateConfirmActionRow(
                frame,
                "Reset selected target",
                "Restore the currently selected target to its registered default anchor and size for this profile.",
                "Reset Target",
                "Confirm Reset",
                function()
                    local targetID = Addon:GetSelectedLayoutTargetID()
                    if targetID then
                        Addon:ResetLayoutTarget(targetID)
                        Addon:OpenLayoutTarget(targetID)
                    end
                end
            )
            page.ResetTarget:SetPoint("TOPLEFT", page.OpenTarget, "BOTTOMLEFT", 0, -14)

            page.ModelNotice = Widgets:CreateNoticeRow(
                frame,
                "Registration model",
                "Builtin pages remain shell-owned. Future feature pages should register as module pages, and movable surfaces should register as layout targets. The Tools page now uses that module-page path.",
                "warning"
            )
            page.ModelNotice:SetPoint("TOPLEFT", page.ResetTarget, "BOTTOMLEFT", 0, -22)
        end,
        applyTheme = function(page)
            local modulePages = Menu:GetModulePageNames()
            local targetItems = Addon:GetLayoutTargetItems()
            local targetID = Addon:GetSelectedLayoutTargetID()

            page.Header:ApplyTheme()
            page.Notice:ApplyTheme()
            page.EditMode:Sync()
            page.EditMode:ApplyTheme()
            page.Target.Items = targetItems
            page.Target:ApplyTheme()
            page.TargetStatus:SetValue(Addon:GetLayoutTargetStatusText(targetID))
            page.TargetStatus:ApplyTheme()
            page.ModulePages:SetValue(#modulePages > 0 and table.concat(modulePages, ", ") or "None")
            page.ModulePages:ApplyTheme()
            page.OpenTarget:ApplyTheme()
            page.ResetTarget:ApplyTheme()
            page.ModelNotice:ApplyTheme()
        end,
    })

    self:RegisterPage("modules", {
        title = "Modules",
        build = function(page, frame)
            page.Header = Widgets:CreateSectionHeader(frame, "Modules", "Track which real WeirdUI modules have registered into the shell so later feature work can expose page, status, and layout capabilities through one shared model.")
            page.Header:SetPoint("TOPLEFT", 8, -8)

            page.Notice = Widgets:CreateNoticeRow(
                frame,
                "Registry-backed module list",
                "This page reflects the current module registry instead of hardcoded placeholder content. Modules can register status, descriptions, shell pages, and layout targets independently.",
                "accent"
            )
            page.Notice:SetPoint("TOPLEFT", page.Header, "BOTTOMLEFT", 0, -18)

            page.ModuleCount = Widgets:CreateValueRow(frame, "Registered Modules")
            page.ModuleCount:SetPoint("TOPLEFT", page.Notice, "BOTTOMLEFT", 0, -18)

            page.ModuleNames = Widgets:CreateValueRow(frame, "Module Names")
            page.ModuleNames:SetPoint("TOPLEFT", page.ModuleCount, "BOTTOMLEFT", 0, -16)

            page.ToolsStatus = Widgets:CreateValueRow(frame, "Tools Module")
            page.ToolsStatus:SetPoint("TOPLEFT", page.ModuleNames, "BOTTOMLEFT", 0, -16)

            page.ModelNotice = Widgets:CreateNoticeRow(
                frame,
                "How this fits",
                "Builtin shell pages like Overview, Profiles, Theme, Layout, and Modules remain shell-owned. Feature surfaces like Tools should register as modules so the shell can reason about them consistently.",
                "warning"
            )
            page.ModelNotice:SetPoint("TOPLEFT", page.ToolsStatus, "BOTTOMLEFT", 0, -22)
        end,
        applyTheme = function(page)
            local modules = Addon:GetModules()
            local toolsModule = Addon:GetModule("tools")
            local toolsStatus = "Not registered"

            if toolsModule then
                toolsStatus = string.format(
                    "%s\nStatus: %s\nCategory: %s\nPage ID: %s",
                    toolsModule.description or "Registered module page.",
                    toolsModule.status or "Prototype",
                    toolsModule.category or "General",
                    toolsModule.pageID or toolsModule.id
                )
            end

            page.Header:ApplyTheme()
            page.Notice:ApplyTheme()
            page.ModuleCount:SetValue(string.format("%d", #modules))
            page.ModuleCount:ApplyTheme()
            page.ModuleNames:SetValue(Addon:GetModuleSummaryText())
            page.ModuleNames:ApplyTheme()
            page.ToolsStatus:SetValue(toolsStatus)
            page.ToolsStatus:ApplyTheme()
            page.ModelNotice:ApplyTheme()
        end,
    })

    self:RegisterModulePage("tools", {
        title = "Tools",
        moduleLabel = "Tools",
        moduleStatus = "Implemented",
        moduleCategory = "Developer",
        moduleDescription = "Developer control gallery and embedded preview surface used to validate shared settings patterns during Phase 00.",
        build = function(page, frame)
            page.Header = Widgets:CreateSectionHeader(frame, "Tools", "These are the only developer tools currently implemented in the addon.")
            page.Header:SetPoint("TOPLEFT", 8, -8)

            page.Notice = Widgets:CreateNoticeRow(
                frame,
                "Developer surfaces only",
                "These controls exist to validate shared WeirdUI settings patterns during Phase 00. They are not final player-facing module settings.",
                "warning"
            )
            page.Notice:SetPoint("TOPLEFT", page.Header, "BOTTOMLEFT", 0, -18)

            page.PreviewGroup = Widgets:CreateGroupPanel(
                frame,
                "Preview Controls",
                "Shared action, slider, select, and confirmation patterns for the embedded developer preview surface."
            )
            page.PreviewGroup:SetPoint("TOPLEFT", page.Notice, "BOTTOMLEFT", 0, -18)

            page.PreviewValue = Widgets:CreateSliderRow(
                page.PreviewGroup.Content,
                "Preview bar value",
                "Adjust the sample status bar value used by the embedded preview surface and keep it persisted in the current profile.",
                {
                    minimum = 0,
                    maximum = 100,
                    step = 1,
                    getter = function()
                        local ui = Addon:GetCurrentProfile().ui
                        return type(ui.previewValue) == "number" and ui.previewValue or 72
                    end,
                    setter = function(value)
                        Addon:GetCurrentProfile().ui.previewValue = math.floor(value + 0.5)
                        if Addon.Preview then
                            Addon.Preview.value = Addon:GetCurrentProfile().ui.previewValue
                        end
                        Addon:ReapplyPreview()
                    end,
                    formatter = function(value)
                        return string.format("%d%%", math.floor(value + 0.5))
                    end,
                    toneGetter = function()
                        return Addon:GetCurrentProfile().ui.previewTone or "accent"
                    end,
                }
            )
            page.PreviewGroup:AddBlock(page.PreviewValue, 14)

            page.PreviewEnabled = Widgets:CreateCheckboxRow(
                page.PreviewGroup.Content,
                "Preview enabled",
                "Example checkbox row. Toggle the embedded preview between active and muted states.",
                function()
                    local ui = Addon:GetCurrentProfile().ui
                    return ui.previewEnabled ~= false
                end,
                function(value)
                    Addon:GetCurrentProfile().ui.previewEnabled = value and true or false
                    Addon.Menu:RefreshToolsPreview()
                end
            )
            page.PreviewGroup:AddBlock(page.PreviewEnabled, 14)

            page.PreviewLabel = Widgets:CreateTextInputRow(
                page.PreviewGroup.Content,
                "Preview label",
                "Example text-input row. Update the embedded preview title directly from the settings surface.",
                {
                    getter = function()
                        return Addon:GetCurrentProfile().ui.previewLabel or "Embedded Preview"
                    end,
                    setter = function(value)
                        Addon:GetCurrentProfile().ui.previewLabel = value ~= "" and value or "Embedded Preview"
                        Addon.Menu:RefreshToolsPreview()
                    end,
                    placeholder = "Embedded Preview",
                }
            )
            page.PreviewGroup:AddBlock(page.PreviewLabel, 14)

            page.PreviewTone = Widgets:CreateSelectRow(
                page.PreviewGroup.Content,
                "Preview tone",
                "Cycle a lightweight shared select-row pattern. This stores a simple developer-facing tone choice in the profile for future preview use.",
                {
                    items = {
                        { value = "accent", label = "Accent" },
                        { value = "success", label = "Success" },
                        { value = "warning", label = "Warning" },
                    },
                    getter = function()
                        return Addon:GetCurrentProfile().ui.previewTone or "accent"
                    end,
                    setter = function(value)
                        Addon:GetCurrentProfile().ui.previewTone = value
                        Addon.Menu:RefreshToolsPreview()
                    end,
                }
            )
            page.PreviewGroup:AddBlock(page.PreviewTone, 14)

            page.PreviewSwatch = Widgets:CreateColorSwatchRow(
                page.PreviewGroup.Content,
                "Preview swatch",
                "Example color-swatch row. This reflects the currently selected preview swatch source.",
                "color.role.accent.primary"
            )
            page.PreviewGroup:AddBlock(page.PreviewSwatch, 14)

            page.PreviewSwatchSelect = Widgets:CreateSelectRow(
                page.PreviewGroup.Content,
                "Swatch source",
                "Cycle which semantic tone the preview swatch represents.",
                {
                    items = {
                        { value = "accent", label = "Accent" },
                        { value = "success", label = "Success" },
                        { value = "warning", label = "Warning" },
                        { value = "danger", label = "Danger" },
                    },
                    getter = function()
                        return Addon:GetCurrentProfile().ui.previewSwatch or "accent"
                    end,
                    setter = function(value)
                        Addon:GetCurrentProfile().ui.previewSwatch = value
                        Addon.Menu:RefreshToolsPreview()
                    end,
                }
            )
            page.PreviewGroup:AddBlock(page.PreviewSwatchSelect, 14)

            page.PreviewDensity = Widgets:CreateRadioChoiceRow(
                page.PreviewGroup.Content,
                "Preview density",
                "Example radio-choice row. Choose the preview density mode that the embedded preview should report.",
                {
                    items = {
                        { value = "compact", label = "Compact" },
                        { value = "comfortable", label = "Comfortable" },
                        { value = "spacious", label = "Spacious" },
                    },
                    getter = function()
                        return Addon:GetCurrentProfile().ui.previewDensity or "comfortable"
                    end,
                    setter = function(value)
                        Addon:GetCurrentProfile().ui.previewDensity = value
                        Addon.Menu:RefreshToolsPreview()
                    end,
                }
            )
            page.PreviewGroup:AddBlock(page.PreviewDensity, 14)

            page.CompactPair = Widgets:CreateCompactDualSliderRow(
                page.PreviewGroup.Content,
                "Compact paired sliders",
                "Example side-by-side compact row pattern for two related numeric controls.",
                {
                    label = "Left Value",
                    description = "First paired sample.",
                    minimum = 0,
                    maximum = 100,
                    step = 1,
                    getter = function()
                        return Addon:GetCurrentProfile().ui.previewLeftValue or 28
                    end,
                    setter = function(value)
                        Addon:GetCurrentProfile().ui.previewLeftValue = math.floor(value + 0.5)
                        Addon.Menu:RefreshToolsPreview()
                    end,
                    formatter = function(value)
                        return string.format("%d", math.floor(value + 0.5))
                    end,
                    tone = "accent",
                },
                {
                    label = "Right Value",
                    description = "Second paired sample.",
                    minimum = 0,
                    maximum = 100,
                    step = 1,
                    getter = function()
                        return Addon:GetCurrentProfile().ui.previewRightValue or 76
                    end,
                    setter = function(value)
                        Addon:GetCurrentProfile().ui.previewRightValue = math.floor(value + 0.5)
                        Addon.Menu:RefreshToolsPreview()
                    end,
                    formatter = function(value)
                        return string.format("%d", math.floor(value + 0.5))
                    end,
                    tone = "success",
                }
            )
            page.PreviewGroup:AddBlock(page.CompactPair, 14)

            page.WarningActions = Widgets:CreateWarningActionGroup(
                page.PreviewGroup.Content,
                "Preview warning actions",
                "Example warning action group. Use the primary or secondary action to change the embedded preview state.",
                {
                    tone = "warning",
                    primaryText = "Acknowledge",
                    secondaryText = "Restore Warning",
                    onPrimary = function()
                        Addon:GetCurrentProfile().ui.previewWarningAcknowledged = true
                        Addon:GetCurrentProfile().ui.previewEnabled = true
                        Addon.Menu:RefreshToolsPreview()
                    end,
                    onSecondary = function()
                        Addon:GetCurrentProfile().ui.previewWarningAcknowledged = false
                        Addon:GetCurrentProfile().ui.previewEnabled = false
                        Addon.Menu:RefreshToolsPreview()
                    end,
                }
            )
            page.PreviewGroup:AddBlock(page.WarningActions, 14)

            page.Requirement = Widgets:CreateRequirementRow(
                page.PreviewGroup.Content,
                "Module settings lock",
                "Example disabled-state and requirement messaging pattern for settings that should remain unavailable until a module or prerequisite system exists.",
                {
                    getter = function()
                        return false
                    end,
                    requirementText = "Requires future module registration",
                }
            )
            page.PreviewGroup:AddBlock(page.Requirement, 14)

            page.Reapply = Widgets:CreateActionRow(
                page.PreviewGroup.Content,
                "Live reapply",
                "Reapply currently registered skins and refresh open developer surfaces.",
                "Reapply",
                function()
                    Addon:ReapplyAllSkins()
                    Addon:ReapplyPreview()
                    Addon:ReapplyMenu()
                end
            )
            page.PreviewGroup:AddBlock(page.Reapply, 14)

            page.ResetPreview = Widgets:CreateConfirmActionRow(
                page.PreviewGroup.Content,
                "Reset preview value",
                "Example confirmation-action pattern for global or destructive controls. This resets the preview bar value back to its default sample.",
                "Reset",
                "Confirm Reset",
                function()
                    Addon:GetCurrentProfile().ui.previewValue = 72
                    Addon:GetCurrentProfile().ui.previewTone = "accent"
                    Addon:GetCurrentProfile().ui.previewEnabled = true
                    Addon:GetCurrentProfile().ui.previewLabel = "Embedded Preview"
                    Addon:GetCurrentProfile().ui.previewSwatch = "accent"
                    Addon:GetCurrentProfile().ui.previewDensity = "comfortable"
                    Addon:GetCurrentProfile().ui.previewLeftValue = 28
                    Addon:GetCurrentProfile().ui.previewRightValue = 76
                    Addon:GetCurrentProfile().ui.previewWarningAcknowledged = false
                    if Addon.Preview then
                        Addon.Preview.value = 72
                    end
                    Addon:ReapplyPreview()
                    Addon.Menu:RefreshToolsPreview()
                end
            )
            page.PreviewGroup:AddBlock(page.ResetPreview, 14)

            page.PreviewSurface = CreateFrame("Frame", nil, frame)
            page.PreviewSurface:SetSize(520, 198)
            page.PreviewSurface:SetPoint("TOPLEFT", page.PreviewGroup, "BOTTOMLEFT", 0, -22)

            function page.PreviewSurface:SetContentWidth(width)
                self:SetWidth(width or 520)
            end

            page.PreviewSurface.Title = page.PreviewSurface:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            page.PreviewSurface.Title:SetPoint("TOPLEFT", 14, -14)
            page.PreviewSurface.Title:SetText("Embedded Preview")

            page.PreviewSurface.Subtitle = page.PreviewSurface:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            page.PreviewSurface.Subtitle:SetPoint("TOPLEFT", page.PreviewSurface.Title, "BOTTOMLEFT", 0, -6)
            page.PreviewSurface.Subtitle:SetWidth(460)
            page.PreviewSurface.Subtitle:SetJustifyH("LEFT")
            page.PreviewSurface.Subtitle:SetText("The controls above update this card directly, so the menu itself acts as the preview surface.")

            page.PreviewSurface.Icon = page.PreviewSurface:CreateTexture(nil, "ARTWORK")
            page.PreviewSurface.Icon:SetPoint("TOPRIGHT", -14, -14)
            page.PreviewSurface.Icon:SetSize(24, 24)
            page.PreviewSurface.Icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

            page.PreviewSurface.StatusLabel = page.PreviewSurface:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            page.PreviewSurface.StatusLabel:SetPoint("TOPLEFT", page.PreviewSurface.Subtitle, "BOTTOMLEFT", 0, -18)
            page.PreviewSurface.StatusLabel:SetText("Live Preview Status")

            page.PreviewSurface.StatusBar = CreateFrame("StatusBar", nil, page.PreviewSurface)
            page.PreviewSurface.StatusBar:SetPoint("TOPLEFT", page.PreviewSurface.StatusLabel, "BOTTOMLEFT", 0, -10)
            page.PreviewSurface.StatusBar:SetSize(320, 18)
            page.PreviewSurface.StatusBar:SetMinMaxValues(0, 100)

            page.PreviewSurface.Detail = page.PreviewSurface:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            page.PreviewSurface.Detail:SetPoint("TOPLEFT", page.PreviewSurface.StatusBar, "BOTTOMLEFT", 0, -12)
            page.PreviewSurface.Detail:SetWidth(460)
            page.PreviewSurface.Detail:SetJustifyH("LEFT")
            page.PreviewSurface.Detail:SetText("")

            page.SlashCommands = Widgets:CreateValueRow(frame, "Slash Commands")
            page.SlashCommands:SetPoint("TOPLEFT", page.PreviewSurface, "BOTTOMLEFT", 0, -22)
        end,
        applyTheme = function(page)
            page.Header:ApplyTheme()
            page.Notice:ApplyTheme()
            page.PreviewGroup:ApplyTheme()
            page.PreviewValue:Sync()
            page.PreviewValue:ApplyTheme()
            page.PreviewEnabled:Sync()
            page.PreviewEnabled:ApplyTheme()
            page.PreviewLabel:Sync()
            page.PreviewLabel:ApplyTheme()
            page.PreviewTone:ApplyTheme()
            page.Requirement:ApplyTheme()
            page.Reapply:ApplyTheme()
            page.ResetPreview:ApplyTheme()
            Addon.Menu:RefreshToolsPreview()

            page.SlashCommands:SetValue("/weirdui, /weirdui preview, /weirdui reapply, /weirdui token <path>, /rl")
            page.SlashCommands:ApplyTheme()
        end,
    })
end

function Addon:InitializeMenu()
    self.Menu = Menu
    Menu:RegisterBuiltinPages()
end

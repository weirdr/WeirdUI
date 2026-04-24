local _, ns = ...

local Addon = ns.Addon

local Preview = {
    value = 72,
}

Addon.Preview = Preview

local function EnsurePreviewLayoutTargetRegistered()
    if Addon.GetLayoutTargetDefinition and Addon:GetLayoutTargetDefinition("preview.frame") then
        return
    end

    Addon:RegisterLayoutTarget("preview.frame", {
        label = "Preview Frame",
        category = "Developer",
        defaults = {
            point = "CENTER",
            relativePoint = "CENTER",
            x = 0,
            y = 0,
            width = 520,
            height = 340,
        },
        minimumWidth = 520,
        minimumHeight = 340,
        open = function(owner)
            owner:ShowPreviewFrame()
        end,
        resolveFrame = function(owner)
            return owner.Preview and owner.Preview.frame or nil
        end,
        afterApply = function(frame)
            Addon:ReapplyPreview(frame)
        end,
        setEditingEnabled = function(frame, enabled)
            frame:SetMovable(enabled and true or false)
        end,
    })
end

local function CreatePreviewFrame()
    local frame = CreateFrame("Frame", "WeirdUIPreviewFrame", UIParent)
    frame:SetSize(520, 340)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:SetScript("OnDragStart", function(self)
        if Addon.IsLayoutEditModeEnabled and Addon:IsLayoutEditModeEnabled() then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if Addon.CaptureLayoutTarget then
            Addon:CaptureLayoutTarget("preview.frame")
        end
        if Addon.ApplyLayoutEditingState then
            Addon:ApplyLayoutEditingState()
        end
    end)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetText("WeirdUI Theme Preview")
    frame.Title = title

    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetJustifyH("LEFT")
    subtitle:SetJustifyV("TOP")
    subtitle:SetWordWrap(true)
    subtitle:SetText("Developer preview surface for Phase 00 tokens, panel shells, buttons, text, icons, and bars.")
    frame.Subtitle = subtitle

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(28, 28)
    icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    frame.Icon = icon

    local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    button:SetSize(156, 32)
    button:SetText("Reapply Preview")
    frame.Button = button

    local close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    close:SetSize(124, 32)
    close:SetText("Close")
    frame.CloseButton = close

    local statusBar = CreateFrame("StatusBar", nil, frame)
    statusBar:SetMinMaxValues(0, 100)
    frame.StatusBar = statusBar

    local statusLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusLabel:SetText("Accent Status Sample")
    frame.StatusLabel = statusLabel

    local detail = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    detail:SetJustifyH("LEFT")
    detail:SetJustifyV("TOP")
    detail:SetWordWrap(true)
    detail:SetText("")
    frame.Detail = detail

    function frame:Layout()
        local width = self:GetWidth() or 520
        local contentWidth = math.max(280, width - 36)
        local topInset = 18
        local leftInset = 18
        local rightInset = 18
        local bottomInset = 18

        self.Title:ClearAllPoints()
        self.Title:SetPoint("TOPLEFT", leftInset, -topInset)

        self.Icon:ClearAllPoints()
        self.Icon:SetPoint("TOPRIGHT", -rightInset, -topInset)

        self.Subtitle:ClearAllPoints()
        self.Subtitle:SetPoint("TOPLEFT", self.Title, "BOTTOMLEFT", 0, -8)
        self.Subtitle:SetPoint("TOPRIGHT", self.Icon, "TOPLEFT", -12, 0)
        self.Subtitle:SetWidth(math.max(180, contentWidth - 40))

        self.Detail:ClearAllPoints()
        self.Detail:SetPoint("TOPLEFT", self.Subtitle, "BOTTOMLEFT", 0, -18)
        self.Detail:SetWidth(contentWidth)

        self.StatusLabel:ClearAllPoints()
        self.StatusLabel:SetPoint("TOPLEFT", self.Detail, "BOTTOMLEFT", 0, -18)

        self.StatusBar:ClearAllPoints()
        self.StatusBar:SetPoint("TOPLEFT", self.StatusLabel, "BOTTOMLEFT", 0, -10)
        self.StatusBar:SetWidth(contentWidth)
        self.StatusBar:SetHeight(18)

        self.Button:ClearAllPoints()
        self.Button:SetPoint("BOTTOMLEFT", leftInset, bottomInset)

        self.CloseButton:ClearAllPoints()
        self.CloseButton:SetPoint("LEFT", self.Button, "RIGHT", 12, 0)

        local frameTop = self:GetTop()
        local barBottom = self.StatusBar:GetBottom()
        if frameTop and barBottom then
            local measuredHeight = math.ceil(frameTop - barBottom + 68)
            if measuredHeight ~= self:GetHeight() then
                self:SetHeight(math.max(340, measuredHeight))
            end
        end
    end

    button:SetScript("OnClick", function()
        Preview.value = Preview.value + 7
        if Preview.value > 100 then
            Preview.value = 21
        end

        local profile = Addon:GetCurrentProfile()
        if profile and profile.ui then
            profile.ui.previewValue = Preview.value
        end

        Addon:ReapplyPreview()
    end)

    close:SetScript("OnClick", function()
        frame:Hide()
    end)

    return frame
end

function Addon:ReapplyPreview()
    local frame = self.Preview.frame
    if not frame then
        return
    end

    local profile = self:GetCurrentProfile()
    if profile and profile.ui and type(profile.ui.previewValue) == "number" then
        Preview.value = profile.ui.previewValue
    end

    self.SkinHelpers:ApplyPanel(frame)
    self.SkinHelpers:ApplyText(frame.Title, {
        size = "lg",
        flags = "display",
        colorPath = "color.text.primary",
    })
    self.SkinHelpers:ApplyText(frame.Subtitle, {
        size = "sm",
        colorPath = "color.text.secondary",
    })
    self.SkinHelpers:ApplyText(frame.StatusLabel, {
        size = "xs",
        flags = "emphasis",
        colorPath = "color.role.accent.strong",
    })
    self.SkinHelpers:ApplyText(frame.Detail, {
        size = "sm",
        colorPath = "color.text.secondary",
    })
    self.SkinHelpers:ApplyButton(frame.Button)
    self.SkinHelpers:ApplyButton(frame.CloseButton)
    self.SkinHelpers:ApplyStatusBar(frame.StatusBar)
    self.SkinHelpers:ApplyIcon(frame.Icon)

    frame.StatusBar:SetValue(Preview.value)
    frame.Detail:SetText(string.format(
        "Profile: %s\nTheme: %s\nToken sample: color.role.accent.primary\nBar value: %d%%",
        self:GetCurrentProfileName(),
        self.Theme:GetActiveThemeID(),
        Preview.value
    ))
    frame:Layout()
end

function Addon:ShowPreviewFrame()
    EnsurePreviewLayoutTargetRegistered()

    if not Preview.frame then
        Preview.frame = CreatePreviewFrame()

        self.Skins:Register("preview.frame", {
            family = "frame",
            target = Preview.frame,
            apply = function(frame)
                Addon:ReapplyPreview(frame)
            end,
        })

        self:ApplyLayoutTarget("preview.frame")
    end

    self:ReapplyPreview()
    if self.ApplyLayoutEditingState then
        self:ApplyLayoutEditingState()
    end
    Preview.frame:Show()
    Preview.frame:Raise()
end

EnsurePreviewLayoutTargetRegistered()

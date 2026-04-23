local _, ns = ...

local Addon = ns.Addon

local Preview = {
    value = 72,
}

Addon.Preview = Preview

local function CreatePreviewFrame()
    local frame = CreateFrame("Frame", "WeirdUIPreviewFrame", UIParent)
    frame:SetSize(380, 240)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOPLEFT", 16, -18)
    title:SetText("WeirdUI Theme Preview")
    frame.Title = title

    local subtitle = frame:CreateFontString(nil, "OVERLAY")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetWidth(340)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetText("Developer preview surface for Phase 00 tokens, panel shells, buttons, text, icons, and bars.")
    frame.Subtitle = subtitle

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPRIGHT", -18, -18)
    icon:SetSize(28, 28)
    icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    frame.Icon = icon

    local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    button:SetPoint("BOTTOMLEFT", 16, 18)
    button:SetSize(132, 28)
    button:SetText("Reapply Preview")
    frame.Button = button

    local close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    close:SetPoint("LEFT", button, "RIGHT", 8, 0)
    close:SetSize(96, 28)
    close:SetText("Close")
    frame.CloseButton = close

    local statusBar = CreateFrame("StatusBar", nil, frame)
    statusBar:SetPoint("BOTTOMLEFT", button, "TOPLEFT", 0, 36)
    statusBar:SetSize(220, 18)
    statusBar:SetMinMaxValues(0, 100)
    frame.StatusBar = statusBar

    local statusLabel = frame:CreateFontString(nil, "OVERLAY")
    statusLabel:SetPoint("BOTTOMLEFT", statusBar, "TOPLEFT", 0, 8)
    statusLabel:SetText("Accent Status Sample")
    frame.StatusLabel = statusLabel

    local detail = frame:CreateFontString(nil, "OVERLAY")
    detail:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -16)
    detail:SetWidth(340)
    detail:SetJustifyH("LEFT")
    detail:SetText("")
    frame.Detail = detail

    button:SetScript("OnClick", function()
        Preview.value = Preview.value + 7
        if Preview.value > 100 then
            Preview.value = 21
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
end

function Addon:ShowPreviewFrame()
    if not Preview.frame then
        Preview.frame = CreatePreviewFrame()

        self.Skins:Register("preview.frame", {
            family = "frame",
            target = Preview.frame,
            apply = function(frame)
                Addon:ReapplyPreview(frame)
            end,
        })
    end

    self:ReapplyPreview()
    Preview.frame:Show()
end

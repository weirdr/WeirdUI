local _, ns = ...

local Addon = ns.Addon

local Widgets = {}
ns.MenuWidgets = Widgets

local function CreateText(parent, layer, template)
    return parent:CreateFontString(nil, layer or "OVERLAY", template or "GameFontHighlightSmall")
end

function Widgets:CreateFlowColumn(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetPoint("TOPLEFT", 0, 0)
    frame:SetPoint("TOPRIGHT", 0, 0)
    frame:SetHeight(1)
    frame.NextOffset = 0

    function frame:AddBlock(block, spacing)
        spacing = spacing or 16

        if self.LastBlock then
            block:SetPoint("TOPLEFT", self.LastBlock, "BOTTOMLEFT", 0, -spacing)
        else
            block:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
        end

        self.LastBlock = block
        self.NextOffset = self.NextOffset + block:GetHeight() + spacing
        self:SetHeight(self.NextOffset)
    end

    return frame
end

function Widgets:CreateSectionHeader(parent, title, description)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(520, 58)

    frame.Title = CreateText(frame)
    frame.Title:SetPoint("TOPLEFT")
    frame.Title:SetText(title)

    frame.Description = CreateText(frame)
    frame.Description:SetPoint("TOPLEFT", frame.Title, "BOTTOMLEFT", 0, -6)
    frame.Description:SetWidth(520)
    frame.Description:SetJustifyH("LEFT")
    frame.Description:SetText(description or "")

    function frame:SetContentWidth(width)
        self.Description:SetWidth(width or 520)
    end

    function frame:ApplyTheme()
        Addon.SkinHelpers:ApplyText(self.Title, {
            size = "lg",
            flags = "display",
        })
        Addon.SkinHelpers:ApplyText(self.Description, {
            size = "sm",
            colorPath = "color.text.secondary",
        })
    end

    frame:ApplyTheme()
    return frame
end

function Widgets:CreateValueRow(parent, label)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(520, 38)

    frame.Label = CreateText(frame)
    frame.Label:SetPoint("TOPLEFT")
    frame.Label:SetText(label)

    frame.Value = CreateText(frame)
    frame.Value:SetPoint("TOPLEFT", frame.Label, "BOTTOMLEFT", 0, -4)
    frame.Value:SetWidth(520)
    frame.Value:SetJustifyH("LEFT")

    function frame:SetContentWidth(width)
        self.Value:SetWidth(width or 520)
    end

    function frame:SetValue(value)
        self.Value:SetText(value or "")
    end

    function frame:ApplyTheme()
        Addon.SkinHelpers:ApplyText(self.Label, {
            size = "xs",
            flags = "emphasis",
            colorPath = "color.role.accent.strong",
        })
        Addon.SkinHelpers:ApplyText(self.Value, {
            size = "sm",
            colorPath = "color.text.primary",
        })
    end

    frame:ApplyTheme()
    return frame
end

function Widgets:CreateBodyText(parent, text)
    local label = CreateText(parent)
    label:SetWidth(520)
    label:SetJustifyH("LEFT")
    label:SetText(text or "")

    function label:SetContentWidth(width)
        self:SetWidth(width or 520)
    end

    function label:ApplyTheme()
        Addon.SkinHelpers:ApplyText(self, {
            size = "sm",
            colorPath = "color.text.secondary",
        })
    end

    label:ApplyTheme()
    return label
end

function Widgets:CreateActionRow(parent, label, description, buttonText, onClick)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(520, 54)

    frame.Label = CreateText(frame)
    frame.Label:SetPoint("TOPLEFT")
    frame.Label:SetText(label)

    frame.Description = CreateText(frame)
    frame.Description:SetPoint("TOPLEFT", frame.Label, "BOTTOMLEFT", 0, -4)
    frame.Description:SetWidth(360)
    frame.Description:SetJustifyH("LEFT")
    frame.Description:SetJustifyV("TOP")
    frame.Description:SetWordWrap(true)
    frame.Description:SetText(description or "")

    frame.Button = CreateFrame("Button", nil, frame)
    frame.Button:SetPoint("TOPRIGHT", 0, -2)
    frame.Button:SetSize(144, 24)

    frame.Button.Label = frame.Button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.Button.Label:SetPoint("CENTER")
    frame.Button.Label:SetText(buttonText)

    frame.Button.Underline = frame.Button:CreateTexture(nil, "ARTWORK")
    frame.Button.Underline:SetPoint("BOTTOMLEFT", 6, 0)
    frame.Button.Underline:SetPoint("BOTTOMRIGHT", -6, 0)
    frame.Button.Underline:SetHeight(2)
    frame.Button.Underline:SetTexture("Interface\\Buttons\\WHITE8X8")

    frame.Button:SetScript("OnEnter", function(control)
        control.hovered = true
        Addon.SkinHelpers:ApplyTextButton(control)
    end)

    frame.Button:SetScript("OnLeave", function(control)
        control.hovered = nil
        Addon.SkinHelpers:ApplyTextButton(control)
    end)

    frame.Button:SetScript("OnClick", onClick)

    function frame:Layout()
        local safeWidth = self.ContentWidth or 520
        local buttonWidth = math.max(144, math.ceil(self.Button.Label:GetStringWidth()) + 28)

        self:SetWidth(safeWidth)
        self.Button:SetWidth(buttonWidth)

        self.Description:ClearAllPoints()
        self.Description:SetPoint("TOPLEFT", self.Label, "BOTTOMLEFT", 0, -4)
        self.Description:SetPoint("TOPRIGHT", self.Button, "TOPLEFT", -28, 0)

        self:SetHeight(math.max(54, math.ceil(self.Label:GetStringHeight() + self.Description:GetStringHeight() + 16)))
    end

    function frame:SetContentWidth(width)
        self.ContentWidth = width or 520
        self:Layout()
    end

    function frame:ApplyTheme()
        Addon.SkinHelpers:ApplyText(self.Label, {
            size = "sm",
            flags = "emphasis",
        })
        Addon.SkinHelpers:ApplyText(self.Description, {
            size = "xs",
            colorPath = "color.text.secondary",
        })
        Addon.SkinHelpers:ApplyTextButton(self.Button)
        self:Layout()
    end

    frame:ApplyTheme()
    return frame
end

function Widgets:CreateCheckboxRow(parent, label, description, getter, setter)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(520, 52)

    frame.Checkbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    frame.Checkbox:SetPoint("TOPLEFT", -4, 2)

    frame.Label = CreateText(frame)
    frame.Label:SetPoint("TOPLEFT", frame.Checkbox, "TOPRIGHT", 8, -2)
    frame.Label:SetText(label)

    frame.Description = CreateText(frame)
    frame.Description:SetPoint("TOPLEFT", frame.Label, "BOTTOMLEFT", 0, -4)
    frame.Description:SetWidth(460)
    frame.Description:SetJustifyH("LEFT")
    frame.Description:SetText(description or "")

    function frame:SetContentWidth(width)
        local safeWidth = width or 520
        self.Description:SetWidth(math.max(240, safeWidth - 60))
    end

    function frame:Sync()
        self.Checkbox:SetChecked(getter())
    end

    function frame:ApplyTheme()
        Addon.SkinHelpers:ApplyCheckbox(self.Checkbox)
        Addon.SkinHelpers:ApplyText(self.Label, {
            size = "sm",
            flags = "emphasis",
        })
        Addon.SkinHelpers:ApplyText(self.Description, {
            size = "xs",
            colorPath = "color.text.secondary",
        })
    end

    frame.Checkbox:SetScript("OnClick", function(button)
        setter(button:GetChecked() and true or false)
    end)

    frame:Sync()
    frame:ApplyTheme()
    return frame
end

function Widgets:CreateColorSwatchRow(parent, label, description, colorPath)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(520, 46)

    frame.Label = CreateText(frame)
    frame.Label:SetPoint("TOPLEFT")
    frame.Label:SetText(label)

    frame.Description = CreateText(frame)
    frame.Description:SetPoint("TOPLEFT", frame.Label, "BOTTOMLEFT", 0, -4)
    frame.Description:SetWidth(420)
    frame.Description:SetJustifyH("LEFT")
    frame.Description:SetText(description or "")

    frame.Swatch = CreateFrame("Frame", nil, frame)
    frame.Swatch:SetPoint("RIGHT", 0, 0)
    frame.Swatch:SetSize(32, 32)
    frame.Swatch.Fill = frame.Swatch:CreateTexture(nil, "ARTWORK")
    frame.Swatch.Fill:SetAllPoints()

    function frame:SetContentWidth(width)
        local safeWidth = width or 520
        self.Description:SetWidth(math.max(240, safeWidth - 100))
    end

    function frame:ApplyTheme()
        local color = Addon:GetThemeToken(colorPath)
        Addon.SkinHelpers:ApplyPanel(self.Swatch, {
            accent = false,
            shadow = false,
            surfaceColorPath = "color.surface.inset",
            borderColorPath = "color.border.subtle",
        })
        Addon.SkinHelpers:ApplyText(self.Label, {
            size = "sm",
            flags = "emphasis",
        })
        Addon.SkinHelpers:ApplyText(self.Description, {
            size = "xs",
            colorPath = "color.text.secondary",
        })

        if color then
            self.Swatch.Fill:SetColorTexture(color.r, color.g, color.b, color.a or 1)
        end
    end

    frame:ApplyTheme()
    return frame
end

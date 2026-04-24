local _, ns = ...

local Addon = ns.Addon

local Widgets = {}
ns.MenuWidgets = Widgets

local DEFAULT_CONTENT_WIDTH = 520

local function GetToneColor(tone, variant)
    return Addon.Theme:GetColor(tone or "neutral", variant or "primary")
        or Addon.Theme:GetToken("color.text.secondary")
end

local function CreateText(parent, layer, template)
    return parent:CreateFontString(nil, layer or "OVERLAY", template or "GameFontHighlightSmall")
end

local function NormalizeColor(color, fallback)
    fallback = fallback or { r = 1, g = 1, b = 1, a = 1 }
    color = type(color) == "table" and color or fallback

    local r = tonumber(color.r or color[1]) or fallback.r or 1
    local g = tonumber(color.g or color[2]) or fallback.g or 1
    local b = tonumber(color.b or color[3]) or fallback.b or 1
    local a = tonumber(color.a or color[4]) or fallback.a or 1

    return {
        r = math.max(0, math.min(1, r)),
        g = math.max(0, math.min(1, g)),
        b = math.max(0, math.min(1, b)),
        a = math.max(0, math.min(1, a)),
    }
end

local function FormatColorHex(color)
    color = NormalizeColor(color)

    return string.format(
        "#%02X%02X%02X",
        math.floor((color.r * 255) + 0.5),
        math.floor((color.g * 255) + 0.5),
        math.floor((color.b * 255) + 0.5)
    )
end

local function ParseHexColor(text)
    if type(text) ~= "string" then
        return nil
    end

    local hex = strtrim(text):gsub("#", "")
    if #hex == 3 then
        hex = string.format("%s%s%s%s%s%s", hex:sub(1, 1), hex:sub(1, 1), hex:sub(2, 2), hex:sub(2, 2), hex:sub(3, 3), hex:sub(3, 3))
    end

    if #hex ~= 6 or not hex:match("^[0-9A-Fa-f]+$") then
        return nil
    end

    return {
        r = tonumber(hex:sub(1, 2), 16) / 255,
        g = tonumber(hex:sub(3, 4), 16) / 255,
        b = tonumber(hex:sub(5, 6), 16) / 255,
        a = 1,
    }
end

local function EnsureColorPickerFrame()
    if Widgets.ColorPickerFrame then
        return Widgets.ColorPickerFrame
    end

    local frame = ColorPickerFrame
    if not frame then
        return nil
    end

    local function GetPickerWidget()
        return frame.Content and frame.Content.ColorPicker or frame
    end

    local function GetTitleTextWidget()
        return frame.TitleText
            or (frame.TitleContainer and frame.TitleContainer.TitleText)
            or (frame.Header and frame.Header.Text)
    end

    local function ReadPickerColor(fallback)
        local picker = GetPickerWidget()
        if picker and picker.GetColorRGB then
            local r, g, b = picker:GetColorRGB()
            return NormalizeColor({ r = r, g = g, b = b, a = 1 }, fallback)
        end

        if frame.GetColorRGB then
            local r, g, b = frame:GetColorRGB()
            return NormalizeColor({ r = r, g = g, b = b, a = 1 }, fallback)
        end

        return NormalizeColor(fallback)
    end

    local function SetPickerColor(color)
        color = NormalizeColor(color)

        local picker = GetPickerWidget()
        if picker and picker.SetColorRGB then
            picker:SetColorRGB(color.r, color.g, color.b)
            if picker.SetColorAlpha then
                picker:SetColorAlpha(color.a or 1)
            end
        end

        if frame.SetColorRGB then
            frame:SetColorRGB(color.r, color.g, color.b)
            if frame.SetColorAlpha then
                frame:SetColorAlpha(color.a or 1)
            end
        end
    end

    if not frame.WeirdUIHexLabel then
        frame.WeirdUIHexLabel = CreateText(frame)
        frame.WeirdUIHexLabel:SetText("Hex")
    end

    if not frame.WeirdUIHexInput then
        frame.WeirdUIHexInput = CreateFrame("EditBox", nil, frame)
        frame.WeirdUIHexInput:SetAutoFocus(false)
        frame.WeirdUIHexInput:SetFontObject(GameFontHighlightSmall)
        frame.WeirdUIHexInput:SetSize(112, 28)
        frame.WeirdUIHexInput:SetMaxLetters(7)
        frame.WeirdUIHexInput:SetScript("OnEscapePressed", function(editBox)
            editBox:ClearFocus()
            if frame.WeirdUIUpdateHex then
                frame:WeirdUIUpdateHex(ReadPickerColor(frame.WeirdUIColorFallback))
            end
        end)
        frame.WeirdUIHexInput:SetScript("OnEnterPressed", function(editBox)
            if frame.WeirdUIApplyHexInput then
                frame:WeirdUIApplyHexInput()
            end
            editBox:ClearFocus()
        end)
        frame.WeirdUIHexInput:SetScript("OnEditFocusLost", function(editBox)
            if editBox.WeirdUIDirty and frame.WeirdUIApplyHexInput then
                frame:WeirdUIApplyHexInput()
            elseif frame.WeirdUIUpdateHex then
                frame:WeirdUIUpdateHex(ReadPickerColor(frame.WeirdUIColorFallback))
            end
            editBox.WeirdUIDirty = nil
        end)
        frame.WeirdUIHexInput:SetScript("OnTextChanged", function(editBox, userInput)
            if not frame.WeirdUIHexSyncing and userInput then
                editBox.WeirdUIDirty = true
            end
        end)
    end

    function frame:WeirdUIUpdateHex(color)
        if not self.WeirdUIHexInput then
            return
        end

        self.WeirdUIHexSyncing = true
        self.WeirdUIHexInput:SetText(FormatColorHex(color))
        self.WeirdUIHexInput.WeirdUIDirty = nil
        self.WeirdUIHexSyncing = nil
    end

    function frame:WeirdUIApplyHexInput()
        if not self.WeirdUIHexInput then
            return
        end

        local color = ParseHexColor(self.WeirdUIHexInput:GetText())
        if not color then
            self:WeirdUIUpdateHex(ReadPickerColor(self.WeirdUIColorFallback))
            return
        end

        self.WeirdUIColorSuppressCallback = true
        SetPickerColor(color)
        self.WeirdUIColorSuppressCallback = nil
        self:WeirdUIUpdateHex(color)

        if type(self.WeirdUIOnChanged) == "function" then
            self.WeirdUIOnChanged(color)
        end
    end

    function frame:ApplyTheme()
        if self.NineSlice then
            self.NineSlice:SetAlpha(0)
        end

        if not self.WeirdUITexturesHidden then
            for _, region in ipairs({ self:GetRegions() }) do
                if region and region:GetObjectType() == "Texture" then
                    region:SetAlpha(0)
                end
            end
            self.WeirdUITexturesHidden = true
        end

        Addon.SkinHelpers:ApplyPanel(self, {
            accent = false,
            surfaceColorPath = "color.surface.panel",
            borderColorPath = "color.border.subtle",
        })
        if self.WeirdUIAccent then
            self.WeirdUIAccent:SetAlpha(0)
        end

        if self.Footer then
            if self.Footer.OkayButton then
                Addon.SkinHelpers:ApplyButton(self.Footer.OkayButton)
            end
            if self.Footer.CancelButton then
                Addon.SkinHelpers:ApplyButton(self.Footer.CancelButton)
            end
        end

        Addon.SkinHelpers:ApplyText(self.WeirdUIHexLabel, {
            size = "xs",
            flags = "emphasis",
            colorPath = "color.role.accent.strong",
        })
        Addon.SkinHelpers:ApplyEditBox(self.WeirdUIHexInput)

        local titleText = GetTitleTextWidget()
        if titleText then
            Addon.SkinHelpers:ApplyText(titleText, {
                size = "lg",
                flags = "display",
                colorPath = "color.text.primary",
            })
        end

        self.WeirdUIHexLabel:ClearAllPoints()
        self.WeirdUIHexLabel:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 18, 56)

        self.WeirdUIHexInput:ClearAllPoints()
        self.WeirdUIHexInput:SetPoint("LEFT", self.WeirdUIHexLabel, "RIGHT", 10, 0)
        self.WeirdUIHexInput:SetSize(112, 28)
    end

    Widgets.ColorPickerFrame = frame
    return frame
end

local function ShowColorPicker(initialColor, onChanged, options)
    if type(onChanged) ~= "function" then
        return
    end

    local frame = EnsureColorPickerFrame()
    if not frame or not frame.SetupColorPickerAndShow then
        return
    end

    local startColor = NormalizeColor(initialColor)

    frame.WeirdUIColorFallback = startColor
    frame.WeirdUIOnChanged = onChanged

    local function HandlePickerChanged()
        if frame.WeirdUIColorSuppressCallback then
            return
        end

        local color = ReadPickerColor(startColor)
        frame:WeirdUIUpdateHex(color)
        onChanged(color)
    end

    frame:SetupColorPickerAndShow({
        r = startColor.r,
        g = startColor.g,
        b = startColor.b,
        opacity = 0,
        hasOpacity = false,
        swatchFunc = HandlePickerChanged,
        opacityFunc = HandlePickerChanged,
        cancelFunc = function(previousValues)
            local color = NormalizeColor(previousValues or startColor, startColor)
            frame:WeirdUIUpdateHex(color)
            onChanged(color)
        end,
    })

    local titleText = frame.TitleText
        or (frame.TitleContainer and frame.TitleContainer.TitleText)
        or (frame.Header and frame.Header.Text)
    if titleText then
        titleText:SetText((options and options.title) or "Choose Color")
    end

    frame:ApplyTheme()
    frame:WeirdUIUpdateHex(startColor)
end

function Widgets:CreateFlowColumn(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetPoint("TOPLEFT", 0, 0)
    frame:SetPoint("TOPRIGHT", 0, 0)
    frame:SetHeight(1)
    frame.ContentWidth = DEFAULT_CONTENT_WIDTH
    frame.Blocks = {}

    function frame:RefreshLayout()
        local previous
        local totalHeight = 0

        for index, entry in ipairs(self.Blocks) do
            local block = entry.block
            local spacing = entry.spacing or 16

            if block.SetContentWidth then
                block:SetContentWidth(self.ContentWidth)
            end

            block:ClearAllPoints()
            if previous then
                block:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -spacing)
                totalHeight = totalHeight + spacing
            else
                block:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
            end

            totalHeight = totalHeight + block:GetHeight()
            previous = block
        end

        self:SetHeight(math.max(1, totalHeight))
    end

    function frame:AddBlock(block, spacing)
        self.Blocks[#self.Blocks + 1] = {
            block = block,
            spacing = spacing,
        }
        self:RefreshLayout()
    end

    function frame:SetContentWidth(width)
        self.ContentWidth = width or DEFAULT_CONTENT_WIDTH
        self:SetWidth(self.ContentWidth)
        self:RefreshLayout()
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
    frame.Description:SetJustifyV("TOP")
    frame.Description:SetWordWrap(true)
    frame.Description:SetText(description or "")

    function frame:Layout()
        local safeWidth = self.ContentWidth or DEFAULT_CONTENT_WIDTH
        self:SetWidth(safeWidth)
        self.Description:SetWidth(safeWidth)
        self:SetHeight(math.max(58, math.ceil(self.Title:GetStringHeight() + self.Description:GetStringHeight() + 12)))
    end

    function frame:SetContentWidth(width)
        self.ContentWidth = width or DEFAULT_CONTENT_WIDTH
        self:Layout()
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
        self:Layout()
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
    frame.Value:SetJustifyV("TOP")
    frame.Value:SetWordWrap(true)

    function frame:Layout()
        local safeWidth = self.ContentWidth or DEFAULT_CONTENT_WIDTH
        self:SetWidth(safeWidth)
        self.Value:SetWidth(safeWidth)
        self:SetHeight(math.max(38, math.ceil(self.Label:GetStringHeight() + self.Value:GetStringHeight() + 10)))
    end

    function frame:SetContentWidth(width)
        self.ContentWidth = width or DEFAULT_CONTENT_WIDTH
        self:Layout()
    end

    function frame:SetValue(value)
        self.Value:SetText(value or "")
        self:Layout()
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
        self:Layout()
    end

    frame:ApplyTheme()
    return frame
end

function Widgets:CreateBodyText(parent, text)
    local label = CreateText(parent)
    label:SetWidth(520)
    label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    label:SetWordWrap(true)
    label:SetText(text or "")

    function label:SetContentWidth(width)
        self:SetWidth(width or DEFAULT_CONTENT_WIDTH)
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

function Widgets:CreateNoticeRow(parent, label, description, tone)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(DEFAULT_CONTENT_WIDTH, 56)
    frame.Tone = tone or "accent"

    frame.Stripe = frame:CreateTexture(nil, "ARTWORK")
    frame.Stripe:SetTexture("Interface\\Buttons\\WHITE8X8")

    frame.Label = CreateText(frame)
    frame.Label:SetPoint("TOPLEFT", 14, -10)
    frame.Label:SetText(label)

    frame.Description = CreateText(frame)
    frame.Description:SetPoint("TOPLEFT", frame.Label, "BOTTOMLEFT", 0, -4)
    frame.Description:SetJustifyH("LEFT")
    frame.Description:SetJustifyV("TOP")
    frame.Description:SetWordWrap(true)
    frame.Description:SetText(description or "")

    function frame:Layout()
        local safeWidth = self.ContentWidth or DEFAULT_CONTENT_WIDTH
        self:SetWidth(safeWidth)
        self.Stripe:ClearAllPoints()
        self.Stripe:SetPoint("TOPLEFT", 0, -2)
        self.Stripe:SetPoint("BOTTOMLEFT", 0, 2)
        self.Stripe:SetWidth(3)
        self.Description:SetWidth(safeWidth - 28)
        self:SetHeight(math.max(56, math.ceil(self.Label:GetStringHeight() + self.Description:GetStringHeight() + 22)))
    end

    function frame:SetContentWidth(width)
        self.ContentWidth = width or DEFAULT_CONTENT_WIDTH
        self:Layout()
    end

    function frame:ApplyTheme()
        local toneStrong = GetToneColor(self.Tone, "strong")
        local tonePrimary = GetToneColor(self.Tone, "primary")

        Addon.SkinHelpers:ApplyPanel(self, {
            accent = false,
            shadow = false,
            surfaceColorPath = "color.surface.elevated",
            borderColorPath = "color.border.subtle",
        })
        Addon.SkinHelpers:ApplyText(self.Label, {
            size = "sm",
            flags = "emphasis",
            colorPath = "color.text.primary",
        })
        Addon.SkinHelpers:ApplyText(self.Description, {
            size = "xs",
            colorPath = "color.text.secondary",
        })

        self.Label:SetTextColor(toneStrong.r, toneStrong.g, toneStrong.b, toneStrong.a or 1)
        self.Stripe:SetVertexColor(tonePrimary.r, tonePrimary.g, tonePrimary.b, tonePrimary.a or 1)
        self:Layout()
    end

    frame:ApplyTheme()
    return frame
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
    frame.Description:SetJustifyV("TOP")
    frame.Description:SetWordWrap(true)
    frame.Description:SetText(description or "")

    function frame:Layout()
        local safeWidth = self.ContentWidth or DEFAULT_CONTENT_WIDTH
        self:SetWidth(safeWidth)
        self.Description:SetWidth(math.max(240, safeWidth - 60))
        self:SetHeight(math.max(52, math.ceil(self.Label:GetStringHeight() + self.Description:GetStringHeight() + 16)))
    end

    function frame:SetContentWidth(width)
        self.ContentWidth = width or DEFAULT_CONTENT_WIDTH
        self:Layout()
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
        self:Layout()
    end

    frame.Checkbox:SetScript("OnClick", function(button)
        setter(button:GetChecked() and true or false)
    end)

    frame:Sync()
    frame:ApplyTheme()
    return frame
end

function Widgets:CreateTextInputRow(parent, label, description, options)
    options = options or {}

    local getter = options.getter or function()
        return ""
    end
    local setter = options.setter or function()
    end
    local placeholder = options.placeholder or ""

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(DEFAULT_CONTENT_WIDTH, 84)

    frame.Label = CreateText(frame)
    frame.Label:SetPoint("TOPLEFT")
    frame.Label:SetText(label)

    frame.Description = CreateText(frame)
    frame.Description:SetPoint("TOPLEFT", frame.Label, "BOTTOMLEFT", 0, -4)
    frame.Description:SetJustifyH("LEFT")
    frame.Description:SetJustifyV("TOP")
    frame.Description:SetWordWrap(true)
    frame.Description:SetText(description or "")

    frame.Input = CreateFrame("EditBox", nil, frame)
    frame.Input:SetAutoFocus(false)
    frame.Input:SetFontObject(GameFontHighlightSmall)
    frame.Input:SetHeight(28)

    frame.Placeholder = frame.Input:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.Placeholder:SetPoint("LEFT", 8, 0)
    frame.Placeholder:SetJustifyH("LEFT")
    frame.Placeholder:SetText(placeholder)

    local function RefreshPlaceholder()
        local hasText = frame.Input:GetText() and frame.Input:GetText() ~= ""
        frame.Placeholder:SetShown(not hasText)
    end

    function frame:Layout()
        local safeWidth = self.ContentWidth or DEFAULT_CONTENT_WIDTH
        self:SetWidth(safeWidth)
        self.Description:SetWidth(safeWidth)
        self.Input:ClearAllPoints()
        self.Input:SetPoint("TOPLEFT", self.Description, "BOTTOMLEFT", 0, -10)
        self.Input:SetWidth(safeWidth)
        self:SetHeight(math.max(84, math.ceil(self.Label:GetStringHeight() + self.Description:GetStringHeight() + self.Input:GetHeight() + 20)))
    end

    function frame:SetContentWidth(width)
        self.ContentWidth = width or DEFAULT_CONTENT_WIDTH
        self:Layout()
    end

    function frame:Sync()
        self.Input:SetText(getter() or "")
        RefreshPlaceholder()
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
        Addon.SkinHelpers:ApplyText(self.Placeholder, {
            size = "sm",
            colorPath = "color.text.muted",
        })
        Addon.SkinHelpers:ApplyEditBox(self.Input)
        self:Layout()
        RefreshPlaceholder()
    end

    frame.Input:SetScript("OnTextChanged", function(editBox)
        setter(editBox:GetText() or "")
        RefreshPlaceholder()
    end)

    frame.Input:SetScript("OnEditFocusGained", function()
        frame:ApplyTheme()
    end)

    frame.Input:SetScript("OnEditFocusLost", function()
        frame:ApplyTheme()
    end)

    frame:Sync()
    frame:ApplyTheme()
    return frame
end

function Widgets:CreateSliderRow(parent, label, description, options)
    options = options or {}

    local minimum = options.minimum or 0
    local maximum = options.maximum or 100
    local step = options.step or 1
    local getter = options.getter or function()
        return minimum
    end
    local setter = options.setter or function()
    end
    local toneGetter = options.toneGetter or function()
        return options.tone or "accent"
    end
    local formatter = options.formatter or function(value)
        if step >= 1 then
            return string.format("%.0f", value)
        end

        return string.format("%.2f", value)
    end

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(DEFAULT_CONTENT_WIDTH, 76)

    frame.Label = CreateText(frame)
    frame.Label:SetPoint("TOPLEFT")
    frame.Label:SetText(label)

    frame.Value = CreateText(frame)
    frame.Value:SetPoint("TOPRIGHT")
    frame.Value:SetJustifyH("RIGHT")

    frame.Description = CreateText(frame)
    frame.Description:SetPoint("TOPLEFT", frame.Label, "BOTTOMLEFT", 0, -4)
    frame.Description:SetJustifyH("LEFT")
    frame.Description:SetJustifyV("TOP")
    frame.Description:SetWordWrap(true)
    frame.Description:SetText(description or "")

    frame.Slider = CreateFrame("Slider", nil, frame)
    frame.Slider:SetOrientation("HORIZONTAL")
    frame.Slider:SetMinMaxValues(minimum, maximum)
    frame.Slider:SetValueStep(step)
    frame.Slider:SetObeyStepOnDrag(true)
    frame.Slider:SetHeight(18)
    frame.Slider:EnableMouse(true)

    frame.Slider.Track = frame.Slider:CreateTexture(nil, "BACKGROUND")
    frame.Slider.Track:SetTexture("Interface\\Buttons\\WHITE8X8")
    frame.Slider.Track:SetPoint("LEFT", 0, 0)
    frame.Slider.Track:SetPoint("RIGHT", 0, 0)
    frame.Slider.Track:SetHeight(4)

    frame.Slider.Fill = frame.Slider:CreateTexture(nil, "ARTWORK")
    frame.Slider.Fill:SetTexture("Interface\\Buttons\\WHITE8X8")
    frame.Slider.Fill:SetPoint("LEFT", 0, 0)
    frame.Slider.Fill:SetHeight(4)

    frame.Slider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
    frame.Slider:GetThumbTexture():SetSize(10, 16)

    function frame:UpdateValueDisplay(value)
        local clamped = math.max(minimum, math.min(maximum, value or minimum))
        local sliderWidth = math.max(1, self.Slider:GetWidth() or 1)
        local range = maximum - minimum
        local ratio = range > 0 and ((clamped - minimum) / range) or 0

        self.Value:SetText(formatter(clamped))
        self.Slider.Fill:SetWidth(math.max(0, math.floor(sliderWidth * ratio)))
    end

    function frame:Layout()
        local safeWidth = self.ContentWidth or DEFAULT_CONTENT_WIDTH
        self:SetWidth(safeWidth)
        self.Description:SetWidth(safeWidth)
        self.Slider:ClearAllPoints()
        self.Slider:SetPoint("TOPLEFT", self.Description, "BOTTOMLEFT", 0, -10)
        self.Slider:SetWidth(safeWidth)
        self:SetHeight(math.max(76, math.ceil(self.Label:GetStringHeight() + self.Description:GetStringHeight() + self.Slider:GetHeight() + 18)))
        self:UpdateValueDisplay(self.Slider:GetValue())
    end

    function frame:SetContentWidth(width)
        self.ContentWidth = width or DEFAULT_CONTENT_WIDTH
        self:Layout()
    end

    function frame:Sync()
        self.Syncing = true
        self.Slider:SetValue(getter())
        self.Syncing = nil
        self:UpdateValueDisplay(self.Slider:GetValue())
    end

    function frame:ApplyTheme()
        local trackColor = Addon.Theme:GetToken("color.border.subtle")
        local tone = toneGetter()
        local fillColor = Addon.Theme:GetColor(tone, "primary") or Addon.Theme:GetColor("accent", "primary")
        local thumbColor = Addon.Theme:GetColor(tone, "strong") or Addon.Theme:GetColor("accent", "strong")

        Addon.SkinHelpers:ApplyText(self.Label, {
            size = "sm",
            flags = "emphasis",
        })
        Addon.SkinHelpers:ApplyText(self.Value, {
            size = "xs",
            flags = "emphasis",
            colorPath = "color.role.accent.strong",
        })
        Addon.SkinHelpers:ApplyText(self.Description, {
            size = "xs",
            colorPath = "color.text.secondary",
        })

        self.Slider.Track:SetVertexColor(trackColor.r, trackColor.g, trackColor.b, trackColor.a or 1)
        self.Slider.Fill:SetVertexColor(fillColor.r, fillColor.g, fillColor.b, fillColor.a or 1)
        self.Slider:GetThumbTexture():SetVertexColor(thumbColor.r, thumbColor.g, thumbColor.b, thumbColor.a or 1)
        self:Layout()
    end

    frame.Slider:SetScript("OnValueChanged", function(slider, value)
        frame:UpdateValueDisplay(value)
        if not frame.Syncing then
            setter(value)
        end
    end)

    frame:Sync()
    frame:ApplyTheme()
    return frame
end

function Widgets:CreateRequirementRow(parent, label, description, options)
    options = options or {}

    local requirementText = options.requirementText or "Additional requirements must be met before this control becomes available."
    local getter = options.getter or function()
        return false
    end

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(DEFAULT_CONTENT_WIDTH, 60)

    frame.Label = CreateText(frame)
    frame.Label:SetPoint("TOPLEFT")
    frame.Label:SetText(label)

    frame.Description = CreateText(frame)
    frame.Description:SetPoint("TOPLEFT", frame.Label, "BOTTOMLEFT", 0, -4)
    frame.Description:SetJustifyH("LEFT")
    frame.Description:SetJustifyV("TOP")
    frame.Description:SetWordWrap(true)
    frame.Description:SetText(description or "")

    frame.Requirement = CreateText(frame)
    frame.Requirement:SetJustifyH("RIGHT")
    frame.Requirement:SetJustifyV("TOP")
    frame.Requirement:SetWordWrap(true)
    frame.Requirement:SetText(requirementText)

    function frame:Layout()
        local safeWidth = self.ContentWidth or DEFAULT_CONTENT_WIDTH
        local requirementWidth = math.max(160, math.floor(safeWidth * 0.34))
        local textWidth = math.max(180, safeWidth - requirementWidth - 24)

        self:SetWidth(safeWidth)
        self.Description:SetWidth(textWidth)
        self.Requirement:ClearAllPoints()
        self.Requirement:SetPoint("TOPRIGHT", 0, 0)
        self.Requirement:SetWidth(requirementWidth)
        self:SetHeight(math.max(60, math.ceil(self.Label:GetStringHeight() + math.max(self.Description:GetStringHeight(), self.Requirement:GetStringHeight()) + 14)))
    end

    function frame:SetContentWidth(width)
        self.ContentWidth = width or DEFAULT_CONTENT_WIDTH
        self:Layout()
    end

    function frame:ApplyTheme()
        local enabled = getter()

        Addon.SkinHelpers:ApplyText(self.Label, {
            size = "sm",
            flags = "emphasis",
            colorPath = enabled and "color.text.primary" or "color.role.disabled.strong",
        })
        Addon.SkinHelpers:ApplyText(self.Description, {
            size = "xs",
            colorPath = enabled and "color.text.secondary" or "color.role.disabled.primary",
        })
        Addon.SkinHelpers:ApplyText(self.Requirement, {
            size = "xs",
            flags = "emphasis",
            colorPath = enabled and "color.role.success.strong" or "color.role.warning.strong",
        })

        self.Requirement:SetText(enabled and "Available" or requirementText)
        self:Layout()
    end

    frame:ApplyTheme()
    return frame
end

function Widgets:CreateSelectRow(parent, label, description, options)
    options = options or {}

    local items = options.items or {}
    local getter = options.getter or function()
        return items[1] and items[1].value or nil
    end
    local setter = options.setter or function()
    end

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(DEFAULT_CONTENT_WIDTH, 58)
    frame.Items = items

    local function GetItems()
        return frame.Items or items
    end

    frame.Label = CreateText(frame)
    frame.Label:SetPoint("TOPLEFT")
    frame.Label:SetText(label)

    frame.Description = CreateText(frame)
    frame.Description:SetPoint("TOPLEFT", frame.Label, "BOTTOMLEFT", 0, -4)
    frame.Description:SetJustifyH("LEFT")
    frame.Description:SetJustifyV("TOP")
    frame.Description:SetWordWrap(true)
    frame.Description:SetText(description or "")

    frame.Button = CreateFrame("Button", nil, frame)
    frame.Button:SetPoint("TOPRIGHT", 0, 0)
    frame.Button:SetHeight(24)

    frame.Button.Label = frame.Button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.Button.Label:SetPoint("LEFT", 0, 0)
    frame.Button.Label:SetJustifyH("RIGHT")

    frame.Button.Caret = frame.Button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.Button.Caret:SetPoint("RIGHT", 0, 0)
    frame.Button.Caret:SetText(">")

    local function GetItemLabel(value)
        local currentItems = GetItems()

        for _, item in ipairs(currentItems) do
            if item.value == value then
                return item.label
            end
        end

        return currentItems[1] and currentItems[1].label or "Unavailable"
    end

    function frame:AdvanceSelection()
        local currentItems = GetItems()

        if #currentItems == 0 then
            return
        end

        local current = getter()
        local nextIndex = 1

        for index, item in ipairs(currentItems) do
            if item.value == current then
                nextIndex = index + 1
                break
            end
        end

        if nextIndex > #currentItems then
            nextIndex = 1
        end

        setter(currentItems[nextIndex].value)
        self:ApplyTheme()
    end

    function frame:Layout()
        local safeWidth = self.ContentWidth or DEFAULT_CONTENT_WIDTH
        local buttonWidth = math.max(164, math.ceil(self.Button.Label:GetStringWidth()) + 26)

        self:SetWidth(safeWidth)
        self.Button:SetWidth(buttonWidth)
        self.Description:SetWidth(math.max(180, safeWidth - buttonWidth - 28))
        self:SetHeight(math.max(58, math.ceil(self.Label:GetStringHeight() + self.Description:GetStringHeight() + 14)))
    end

    function frame:SetContentWidth(width)
        self.ContentWidth = width or DEFAULT_CONTENT_WIDTH
        self:Layout()
    end

    function frame:ApplyTheme()
        local selectedLabel = GetItemLabel(getter())

        self.Button.Label:SetText(selectedLabel)
        Addon.SkinHelpers:ApplyText(self.Label, {
            size = "sm",
            flags = "emphasis",
        })
        Addon.SkinHelpers:ApplyText(self.Description, {
            size = "xs",
            colorPath = "color.text.secondary",
        })
        Addon.SkinHelpers:ApplyTextButton(self.Button, {
            size = "sm",
            colorPath = "color.text.primary",
            activeColorPath = "color.role.accent.strong",
            hoverColorPath = "color.role.accent.strong",
            idleAlpha = 0.25,
            activeAlpha = 0.9,
        })
        Addon.SkinHelpers:ApplyText(self.Button.Caret, {
            size = "xs",
            colorPath = self.Button.hovered and "color.role.accent.strong" or "color.text.secondary",
        })
        self:Layout()
    end

    frame.Button:SetScript("OnEnter", function(control)
        control.hovered = true
        frame:ApplyTheme()
    end)

    frame.Button:SetScript("OnLeave", function(control)
        control.hovered = nil
        frame:ApplyTheme()
    end)

    frame.Button:SetScript("OnClick", function()
        frame:AdvanceSelection()
    end)

    frame:ApplyTheme()
    return frame
end

function Widgets:CreateRadioChoiceRow(parent, label, description, options)
    options = options or {}

    local items = options.items or {}
    local getter = options.getter or function()
        return items[1] and items[1].value or nil
    end
    local setter = options.setter or function()
    end

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(DEFAULT_CONTENT_WIDTH, 88)
    frame.Items = {}

    frame.Label = CreateText(frame)
    frame.Label:SetPoint("TOPLEFT")
    frame.Label:SetText(label)

    frame.Description = CreateText(frame)
    frame.Description:SetPoint("TOPLEFT", frame.Label, "BOTTOMLEFT", 0, -4)
    frame.Description:SetJustifyH("LEFT")
    frame.Description:SetJustifyV("TOP")
    frame.Description:SetWordWrap(true)
    frame.Description:SetText(description or "")

    frame.Choices = CreateFrame("Frame", nil, frame)

    for index, item in ipairs(items) do
        local button = CreateFrame("Button", nil, frame.Choices)
        button:SetHeight(22)
        button.Value = item.value

        button.Marker = button:CreateTexture(nil, "ARTWORK")
        button.Marker:SetTexture("Interface\\Buttons\\WHITE8X8")
        button.Marker:SetPoint("LEFT", 0, 0)
        button.Marker:SetSize(8, 8)

        button.Label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        button.Label:SetPoint("LEFT", button.Marker, "RIGHT", 8, 0)
        button.Label:SetText(item.label)

        button:SetScript("OnEnter", function(control)
            control.hovered = true
            frame:ApplyTheme()
        end)

        button:SetScript("OnLeave", function(control)
            control.hovered = nil
            frame:ApplyTheme()
        end)

        button:SetScript("OnClick", function()
            setter(item.value)
            frame:ApplyTheme()
        end)

        frame.Items[#frame.Items + 1] = button
    end

    function frame:Layout()
        local safeWidth = self.ContentWidth or DEFAULT_CONTENT_WIDTH
        local previous

        self:SetWidth(safeWidth)
        self.Description:SetWidth(safeWidth)
        self.Choices:ClearAllPoints()
        self.Choices:SetPoint("TOPLEFT", self.Description, "BOTTOMLEFT", 0, -10)
        self.Choices:SetWidth(safeWidth)

        for _, button in ipairs(self.Items) do
            button:ClearAllPoints()
            if previous then
                button:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -8)
            else
                button:SetPoint("TOPLEFT", self.Choices, "TOPLEFT", 0, 0)
            end
            button:SetWidth(safeWidth)
            previous = button
        end

        local choicesHeight = (#self.Items > 0) and (#self.Items * 22 + (#self.Items - 1) * 8) or 0
        self.Choices:SetHeight(choicesHeight)
        self:SetHeight(math.max(88, math.ceil(self.Label:GetStringHeight() + self.Description:GetStringHeight() + choicesHeight + 18)))
    end

    function frame:SetContentWidth(width)
        self.ContentWidth = width or DEFAULT_CONTENT_WIDTH
        self:Layout()
    end

    function frame:ApplyTheme()
        local current = getter()

        Addon.SkinHelpers:ApplyText(self.Label, {
            size = "sm",
            flags = "emphasis",
        })
        Addon.SkinHelpers:ApplyText(self.Description, {
            size = "xs",
            colorPath = "color.text.secondary",
        })

        for _, button in ipairs(self.Items) do
            local selected = button.Value == current
            local markerColor = selected and Addon.Theme:GetColor("accent", "primary") or Addon.Theme:GetToken("color.border.subtle")

            Addon.SkinHelpers:ApplyText(button.Label, {
                size = "sm",
                flags = selected and "emphasis" or "body",
                colorPath = selected and "color.text.primary" or "color.text.secondary",
            })
            button.Marker:SetVertexColor(markerColor.r, markerColor.g, markerColor.b, selected and (markerColor.a or 1) or 0.65)
            button.Marker:SetAlpha(button.hovered and 1 or (selected and 1 or 0.7))
        end

        self:Layout()
    end

    frame:ApplyTheme()
    return frame
end

function Widgets:CreateCompactDualSliderRow(parent, label, description, leftOptions, rightOptions)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(DEFAULT_CONTENT_WIDTH, 128)

    frame.Label = CreateText(frame)
    frame.Label:SetPoint("TOPLEFT")
    frame.Label:SetText(label)

    frame.Description = CreateText(frame)
    frame.Description:SetPoint("TOPLEFT", frame.Label, "BOTTOMLEFT", 0, -4)
    frame.Description:SetJustifyH("LEFT")
    frame.Description:SetJustifyV("TOP")
    frame.Description:SetWordWrap(true)
    frame.Description:SetText(description or "")

    frame.Left = Widgets:CreateSliderRow(frame, leftOptions.label, leftOptions.description, leftOptions)
    frame.Right = Widgets:CreateSliderRow(frame, rightOptions.label, rightOptions.description, rightOptions)

    function frame:Layout()
        local safeWidth = self.ContentWidth or DEFAULT_CONTENT_WIDTH
        local gutter = 16
        local columnWidth = math.floor((safeWidth - gutter) / 2)

        self:SetWidth(safeWidth)
        self.Description:SetWidth(safeWidth)

        self.Left:ClearAllPoints()
        self.Left:SetPoint("TOPLEFT", self.Description, "BOTTOMLEFT", 0, -12)
        self.Left:SetContentWidth(columnWidth)

        self.Right:ClearAllPoints()
        self.Right:SetPoint("TOPLEFT", self.Left, "TOPRIGHT", gutter, 0)
        self.Right:SetContentWidth(columnWidth)

        self:SetHeight(math.max(128, math.ceil(self.Label:GetStringHeight() + self.Description:GetStringHeight() + math.max(self.Left:GetHeight(), self.Right:GetHeight()) + 20)))
    end

    function frame:SetContentWidth(width)
        self.ContentWidth = width or DEFAULT_CONTENT_WIDTH
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
        self.Left:ApplyTheme()
        self.Right:ApplyTheme()
        self:Layout()
    end

    frame:ApplyTheme()
    return frame
end

function Widgets:CreateWarningActionGroup(parent, label, description, options)
    options = options or {}

    local primaryText = options.primaryText or "Acknowledge"
    local secondaryText = options.secondaryText or "Dismiss"
    local onPrimary = options.onPrimary or function()
    end
    local onSecondary = options.onSecondary or function()
    end
    local tone = options.tone or "warning"

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(DEFAULT_CONTENT_WIDTH, 96)

    frame.Notice = Widgets:CreateNoticeRow(frame, label, description, tone)
    frame.Primary = CreateFrame("Button", nil, frame)
    frame.Primary:SetHeight(24)
    frame.Primary.Label = frame.Primary:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.Primary.Label:SetPoint("CENTER")
    frame.Primary.Label:SetText(primaryText)
    frame.Primary.Underline = frame.Primary:CreateTexture(nil, "ARTWORK")
    frame.Primary.Underline:SetPoint("BOTTOMLEFT", 6, 0)
    frame.Primary.Underline:SetPoint("BOTTOMRIGHT", -6, 0)
    frame.Primary.Underline:SetHeight(2)
    frame.Primary.Underline:SetTexture("Interface\\Buttons\\WHITE8X8")

    frame.Secondary = CreateFrame("Button", nil, frame)
    frame.Secondary:SetHeight(24)
    frame.Secondary.Label = frame.Secondary:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.Secondary.Label:SetPoint("CENTER")
    frame.Secondary.Label:SetText(secondaryText)
    frame.Secondary.Underline = frame.Secondary:CreateTexture(nil, "ARTWORK")
    frame.Secondary.Underline:SetPoint("BOTTOMLEFT", 6, 0)
    frame.Secondary.Underline:SetPoint("BOTTOMRIGHT", -6, 0)
    frame.Secondary.Underline:SetHeight(2)
    frame.Secondary.Underline:SetTexture("Interface\\Buttons\\WHITE8X8")

    local function BindTextButtonScripts(button)
        button:SetScript("OnEnter", function(control)
            control.hovered = true
            frame:ApplyTheme()
        end)
        button:SetScript("OnLeave", function(control)
            control.hovered = nil
            frame:ApplyTheme()
        end)
    end

    BindTextButtonScripts(frame.Primary)
    BindTextButtonScripts(frame.Secondary)

    frame.Primary:SetScript("OnClick", function()
        onPrimary()
        frame:ApplyTheme()
    end)

    frame.Secondary:SetScript("OnClick", function()
        onSecondary()
        frame:ApplyTheme()
    end)

    function frame:Layout()
        local safeWidth = self.ContentWidth or DEFAULT_CONTENT_WIDTH
        local primaryWidth = math.max(120, math.ceil(frame.Primary.Label:GetStringWidth()) + 28)
        local secondaryWidth = math.max(96, math.ceil(frame.Secondary.Label:GetStringWidth()) + 28)

        self:SetWidth(safeWidth)
        self.Notice:SetContentWidth(safeWidth)
        self.Primary:SetWidth(primaryWidth)
        self.Secondary:SetWidth(secondaryWidth)

        self.Primary:ClearAllPoints()
        self.Primary:SetPoint("TOPLEFT", self.Notice, "BOTTOMLEFT", 0, -12)

        self.Secondary:ClearAllPoints()
        self.Secondary:SetPoint("LEFT", self.Primary, "RIGHT", 14, 0)

        self:SetHeight(math.max(96, self.Notice:GetHeight() + 36))
    end

    function frame:SetContentWidth(width)
        self.ContentWidth = width or DEFAULT_CONTENT_WIDTH
        self:Layout()
    end

    function frame:ApplyTheme()
        self.Notice:ApplyTheme()
        Addon.SkinHelpers:ApplyTextButton(self.Primary, {
            size = "sm",
            colorPath = string.format("color.role.%s.strong", tone),
            hoverColorPath = string.format("color.role.%s.strong", tone),
            activeColorPath = string.format("color.role.%s.strong", tone),
            idleAlpha = 0.3,
            activeAlpha = 0.95,
        })
        Addon.SkinHelpers:ApplyTextButton(self.Secondary, {
            size = "sm",
            colorPath = "color.text.secondary",
            hoverColorPath = "color.text.primary",
            activeColorPath = "color.text.primary",
            idleAlpha = 0.2,
            activeAlpha = 0.85,
        })
        self:Layout()
    end

    frame:ApplyTheme()
    return frame
end

function Widgets:CreateConfirmActionRow(parent, label, description, buttonText, confirmText, onConfirm)
    local frame

    frame = self:CreateActionRow(parent, label, description, buttonText, function()
        if frame.Confirming then
            if type(onConfirm) == "function" then
                onConfirm()
            end
            frame.Confirming = nil
        else
            frame.Confirming = true
        end

        frame:ApplyTheme()
    end)

    frame.DefaultButtonText = buttonText
    frame.ConfirmButtonText = confirmText or "Confirm"

    function frame:ApplyTheme()
        self.Button.Label:SetText(self.Confirming and self.ConfirmButtonText or self.DefaultButtonText)
        Addon.SkinHelpers:ApplyText(self.Label, {
            size = "sm",
            flags = "emphasis",
        })
        Addon.SkinHelpers:ApplyText(self.Description, {
            size = "xs",
            colorPath = "color.text.secondary",
        })
        Addon.SkinHelpers:ApplyTextButton(self.Button, {
            size = "sm",
            colorPath = self.Confirming and "color.role.warning.strong" or "color.text.primary",
            activeColorPath = self.Confirming and "color.role.warning.strong" or "color.role.accent.strong",
            hoverColorPath = self.Confirming and "color.role.warning.strong" or "color.role.accent.strong",
            idleAlpha = 0.25,
            activeAlpha = 0.95,
        })
        self:Layout()
    end

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
    frame.Description:SetJustifyV("TOP")
    frame.Description:SetWordWrap(true)
    frame.Description:SetText(description or "")

    frame.Swatch = CreateFrame("Frame", nil, frame)
    frame.Swatch:SetPoint("RIGHT", 0, 0)
    frame.Swatch:SetSize(32, 32)
    frame.Swatch.Fill = frame.Swatch:CreateTexture(nil, "ARTWORK")
    frame.Swatch.Fill:SetAllPoints()

    function frame:Layout()
        local safeWidth = self.ContentWidth or DEFAULT_CONTENT_WIDTH
        self:SetWidth(safeWidth)
        self.Description:SetWidth(math.max(240, safeWidth - 100))
        self:SetHeight(math.max(46, math.ceil(self.Label:GetStringHeight() + self.Description:GetStringHeight() + 12)))
    end

    function frame:SetContentWidth(width)
        self.ContentWidth = width or DEFAULT_CONTENT_WIDTH
        self:Layout()
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

        self:Layout()
    end

    frame:ApplyTheme()
    return frame
end

function Widgets:CreateColorPickerRow(parent, label, description, options)
    options = options or {}

    local getter = options.getter or function()
        return { r = 1, g = 1, b = 1, a = 1 }
    end
    local setter = options.setter or function()
    end
    local pickerTitle = options.pickerTitle or label or "Choose Color"
    local pickerDescription = options.pickerDescription or description or "Adjust the red, green, and blue channels below."

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(DEFAULT_CONTENT_WIDTH, 52)

    frame.Label = CreateText(frame)
    frame.Label:SetPoint("TOPLEFT")
    frame.Label:SetText(label)

    frame.Value = CreateText(frame)
    frame.Value:SetPoint("TOPRIGHT")
    frame.Value:SetJustifyH("RIGHT")

    frame.Description = CreateText(frame)
    frame.Description:SetPoint("TOPLEFT", frame.Label, "BOTTOMLEFT", 0, -4)
    frame.Description:SetJustifyH("LEFT")
    frame.Description:SetJustifyV("TOP")
    frame.Description:SetWordWrap(true)
    frame.Description:SetText(description or "")

    frame.SwatchButton = CreateFrame("Button", nil, frame)
    frame.SwatchButton:SetSize(36, 24)
    frame.SwatchButton.Fill = frame.SwatchButton:CreateTexture(nil, "ARTWORK")
    frame.SwatchButton.Fill:SetPoint("TOPLEFT", 4, -4)
    frame.SwatchButton.Fill:SetPoint("BOTTOMRIGHT", -4, 4)
    frame.SwatchButton:SetScript("OnClick", function()
        ShowColorPicker(getter(), function(color)
            setter(color)
            frame:Sync()
            frame:ApplyTheme()
        end, {
            title = pickerTitle,
            description = pickerDescription,
        })
    end)
    frame.SwatchButton:SetScript("OnEnter", function(control)
        control.hovered = true
        frame:ApplyTheme()
    end)
    frame.SwatchButton:SetScript("OnLeave", function(control)
        control.hovered = nil
        frame:ApplyTheme()
    end)

    function frame:Layout()
        local safeWidth = self.ContentWidth or DEFAULT_CONTENT_WIDTH
        self:SetWidth(safeWidth)
        self.Description:SetWidth(math.max(220, safeWidth - 110))
        self.SwatchButton:ClearAllPoints()
        self.SwatchButton:SetPoint("RIGHT", 0, 0)
        self:SetHeight(math.max(52, math.ceil(self.Label:GetStringHeight() + self.Description:GetStringHeight() + 12)))
    end

    function frame:SetContentWidth(width)
        self.ContentWidth = width or DEFAULT_CONTENT_WIDTH
        self:Layout()
    end

    function frame:Sync()
        self.Color = NormalizeColor(getter())
        self.Value:SetText(FormatColorHex(self.Color))
    end

    function frame:ApplyTheme()
        local color = self.Color or NormalizeColor(getter())
        local borderColor = self.SwatchButton.hovered and GetToneColor("accent", "primary") or Addon.Theme:GetToken("color.border.subtle")

        Addon.SkinHelpers:ApplyText(self.Label, {
            size = "sm",
            flags = "emphasis",
        })
        Addon.SkinHelpers:ApplyText(self.Value, {
            size = "xs",
            flags = "emphasis",
            colorPath = self.SwatchButton.hovered and "color.role.accent.strong" or "color.text.secondary",
        })
        Addon.SkinHelpers:ApplyText(self.Description, {
            size = "xs",
            colorPath = "color.text.secondary",
        })
        Addon.SkinHelpers:ApplyPanel(self.SwatchButton, {
            accent = false,
            shadow = false,
            surfaceColorPath = "color.surface.inset",
            borderColorPath = "color.border.subtle",
        })

        if self.SwatchButton.WeirdUIBorderTop then
            self.SwatchButton.WeirdUIBorderTop:SetVertexColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
        end
        if self.SwatchButton.WeirdUIBorderBottom then
            self.SwatchButton.WeirdUIBorderBottom:SetVertexColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
        end
        if self.SwatchButton.WeirdUIBorderLeft then
            self.SwatchButton.WeirdUIBorderLeft:SetVertexColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
        end
        if self.SwatchButton.WeirdUIBorderRight then
            self.SwatchButton.WeirdUIBorderRight:SetVertexColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
        end

        self.SwatchButton.Fill:SetColorTexture(color.r, color.g, color.b, 1)
        self.Value:SetText(FormatColorHex(color))
        self:Layout()
    end

    frame:Sync()
    frame:ApplyTheme()
    return frame
end

function Widgets:CreateGroupPanel(parent, title, description)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(DEFAULT_CONTENT_WIDTH, 96)

    frame.Title = CreateText(frame)
    frame.Title:SetPoint("TOPLEFT", 12, -12)
    frame.Title:SetText(title)

    frame.Description = CreateText(frame)
    frame.Description:SetPoint("TOPLEFT", frame.Title, "BOTTOMLEFT", 0, -6)
    frame.Description:SetJustifyH("LEFT")
    frame.Description:SetJustifyV("TOP")
    frame.Description:SetWordWrap(true)
    frame.Description:SetText(description or "")

    frame.Content = self:CreateFlowColumn(frame)

    function frame:Layout()
        local safeWidth = self.ContentWidth or DEFAULT_CONTENT_WIDTH
        local titleHeight = self.Title:GetStringHeight()
        local descriptionHeight = self.Description:GetStringHeight()
        local bodyTopOffset = 12 + titleHeight + 6 + descriptionHeight + 12

        self:SetWidth(safeWidth)
        self.Description:SetWidth(safeWidth - 24)
        self.Content:ClearAllPoints()
        self.Content:SetPoint("TOPLEFT", 12, -bodyTopOffset)
        self.Content:SetPoint("TOPRIGHT", -12, -bodyTopOffset)
        self.Content:SetContentWidth(safeWidth - 24)
        self:SetHeight(math.max(96, math.ceil(bodyTopOffset + self.Content:GetHeight() + 12)))
    end

    function frame:AddBlock(block, spacing)
        self.Content:AddBlock(block, spacing)
        self:Layout()
    end

    function frame:SetContentWidth(width)
        self.ContentWidth = width or DEFAULT_CONTENT_WIDTH
        self:Layout()
    end

    function frame:ApplyTheme()
        Addon.SkinHelpers:ApplyPanel(self, {
            accent = false,
            shadow = false,
            surfaceColorPath = "color.surface.panel",
            borderColorPath = "color.border.subtle",
        })
        Addon.SkinHelpers:ApplyText(self.Title, {
            size = "sm",
            flags = "emphasis",
        })
        Addon.SkinHelpers:ApplyText(self.Description, {
            size = "xs",
            colorPath = "color.text.secondary",
        })

        for _, entry in ipairs(self.Content.Blocks) do
            if entry.block.ApplyTheme then
                entry.block:ApplyTheme()
            end
        end

        self:Layout()
    end

    frame:ApplyTheme()
    return frame
end

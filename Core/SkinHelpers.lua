local _, ns = ...

local Addon = ns.Addon

local Helpers = {}
Addon.SkinHelpers = Helpers

local function EnsureTexture(parent, key, layer)
    if not parent[key] then
        parent[key] = parent:CreateTexture(nil, layer or "ARTWORK")
    end

    return parent[key]
end

local function EnsureLine(parent, key, layer)
    if not parent[key] then
        parent[key] = parent:CreateTexture(nil, layer or "BORDER")
        parent[key]:SetTexture("Interface\\Buttons\\WHITE8X8")
    end

    return parent[key]
end

local function ApplyColor(texture, color)
    if not texture or type(color) ~= "table" then
        return
    end

    texture:SetColorTexture(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
end

local function GetFontFallback()
    local fontFile, fontSize, fontFlags = GameFontNormal:GetFont()
    return fontFile, fontSize, fontFlags
end

local function GetIconFont()
    return ns.IconFont and ns.IconFont.Path
end

local function HideButtonArt(button)
    local namedRegions = {
        button.Left,
        button.Middle,
        button.Right,
        button.LeftDisabled,
        button.MiddleDisabled,
        button.RightDisabled,
    }

    for _, region in ipairs(namedRegions) do
        if region then
            region:SetAlpha(0)
        end
    end

    local textures = {
        button.GetNormalTexture and button:GetNormalTexture() or nil,
        button.GetPushedTexture and button:GetPushedTexture() or nil,
        button.GetHighlightTexture and button:GetHighlightTexture() or nil,
        button.GetDisabledTexture and button:GetDisabledTexture() or nil,
    }

    for _, texture in ipairs(textures) do
        if texture then
            texture:SetAlpha(0)
        end
    end
end

local function HideCheckButtonArt(button)
    if not button then
        return
    end

    if button.SetNormalTexture then
        button:SetNormalTexture(0)
    end

    if button.SetPushedTexture then
        button:SetPushedTexture(0)
    end

    if button.SetHighlightTexture then
        button:SetHighlightTexture(0)
    end

    if button.SetDisabledTexture then
        button:SetDisabledTexture(0)
    end

    local checked = button.GetCheckedTexture and button:GetCheckedTexture() or nil
    local disabledChecked = button.GetDisabledCheckedTexture and button:GetDisabledCheckedTexture() or nil

    if checked then
        checked:SetAlpha(0)
    end

    if disabledChecked then
        disabledChecked:SetAlpha(0)
    end
end

function Helpers:ApplyPanel(frame, options)
    options = options or {}

    local theme = Addon.Theme
    local panelColor = theme:GetToken(options.surfaceColorPath or "color.surface.panel")
    local borderColor = theme:GetToken(options.borderColorPath or "color.border.strong")
    local accentColor = theme:GetToken("color.role.accent.primary")
    local shadowColor = theme:GetToken("color.surface.overlay")

    local background = EnsureTexture(frame, "WeirdUIBackground", "BACKGROUND")
    background:SetAllPoints()
    ApplyColor(background, panelColor)
    background:SetAlpha(panelColor and panelColor.a or 1)

    local shadow = EnsureTexture(frame, "WeirdUIShadow", "BACKGROUND")
    shadow:SetPoint("TOPLEFT", -4, 4)
    shadow:SetPoint("BOTTOMRIGHT", 4, -4)
    ApplyColor(shadow, shadowColor)
    shadow:SetShown(options.shadow ~= false)

    local top = EnsureLine(frame, "WeirdUIBorderTop")
    top:SetPoint("TOPLEFT")
    top:SetPoint("TOPRIGHT")
    top:SetHeight(1)
    ApplyColor(top, borderColor)

    local bottom = EnsureLine(frame, "WeirdUIBorderBottom")
    bottom:SetPoint("BOTTOMLEFT")
    bottom:SetPoint("BOTTOMRIGHT")
    bottom:SetHeight(1)
    ApplyColor(bottom, borderColor)

    local left = EnsureLine(frame, "WeirdUIBorderLeft")
    left:SetPoint("TOPLEFT")
    left:SetPoint("BOTTOMLEFT")
    left:SetWidth(1)
    ApplyColor(left, borderColor)

    local right = EnsureLine(frame, "WeirdUIBorderRight")
    right:SetPoint("TOPRIGHT")
    right:SetPoint("BOTTOMRIGHT")
    right:SetWidth(1)
    ApplyColor(right, borderColor)

    local accent = EnsureLine(frame, "WeirdUIAccent")
    accent:SetPoint("TOPLEFT", 12, -12)
    accent:SetSize(72, 2)
    ApplyColor(accent, accentColor)
    accent:SetShown(options.accent ~= false)
end

function Helpers:ApplyText(fontString, options)
    options = options or {}

    local fontName = options.font or "primary"
    local sizeName = options.size or "md"
    local colorPath = options.colorPath or "color.text.primary"
    local flagsName = options.flags or "body"

    local fontFile = options.fontFile or Addon.Theme:GetFont(fontName)
    local fontSize = Addon.Theme:GetToken(string.format("typography.size.%s", sizeName))
    local fontFlags = Addon.Theme:GetToken(string.format("typography.flag.%s", flagsName))
    local fallbackFile, fallbackSize, fallbackFlags = GetFontFallback()
    local color = Addon.Theme:GetToken(colorPath)

    fontString:SetFont(fontFile or fallbackFile, fontSize or fallbackSize or 12, fontFlags or fallbackFlags or "")
    if color then
        fontString:SetTextColor(color.r, color.g, color.b, color.a or 1)
    end
end

function Helpers:ApplyButton(button)
    HideButtonArt(button)
    self:ApplyPanel(button)

    local text = button.GetFontString and button:GetFontString()
    if text then
        self:ApplyText(text, {
            size = "sm",
            colorPath = "color.text.primary",
            flags = "emphasis",
        })
    end

    if not button.WeirdUIButtonScripts then
        button:HookScript("OnEnter", function(control)
            local state = Addon.Theme:GetWidgetState("hover")
            local color = state and state.tint or Addon.Theme:GetToken("color.role.accent.primary")
            ApplyColor(control.WeirdUIBackground, color)
            control.WeirdUIBackground:SetAlpha(0.18)
        end)

        button:HookScript("OnLeave", function(control)
            local color = Addon.Theme:GetToken("color.surface.panel")
            ApplyColor(control.WeirdUIBackground, color)
            control.WeirdUIBackground:SetAlpha(color and color.a or 1)
        end)

        button:HookScript("OnMouseDown", function(control)
            local state = Addon.Theme:GetWidgetState("pressed")
            local color = state and state.tint or Addon.Theme:GetToken("color.role.accent.primary")
            ApplyColor(control.WeirdUIBackground, color)
            control.WeirdUIBackground:SetAlpha(0.26)
        end)

        button:HookScript("OnMouseUp", function(control)
            local state = control:IsMouseOver() and Addon.Theme:GetWidgetState("hover") or nil
            local color = state and state.tint or Addon.Theme:GetToken("color.surface.panel")
            ApplyColor(control.WeirdUIBackground, color)
            control.WeirdUIBackground:SetAlpha(state and 0.18 or 1)
        end)

        button:HookScript("OnDisable", function(control)
            local state = Addon.Theme:GetWidgetState("disabled")
            ApplyColor(control.WeirdUIBackground, state and state.tint)
            control:SetAlpha(state and state.alphaMultiplier or 0.4)
        end)

        button:HookScript("OnEnable", function(control)
            local color = Addon.Theme:GetToken("color.surface.panel")
            ApplyColor(control.WeirdUIBackground, color)
            control.WeirdUIBackground:SetAlpha(color and color.a or 1)
            control:SetAlpha(1)
        end)

        button.WeirdUIButtonScripts = true
    end
end

function Helpers:ApplyTextButton(button, options)
    options = options or {}

    local hovered = button.hovered
    local active = button.active
    local textColorPath = active and (options.activeColorPath or "color.text.primary") or (hovered and (options.hoverColorPath or "color.role.accent.strong") or (options.colorPath or "color.text.secondary"))
    local flags = (hovered or active) and (options.activeFlags or "emphasis") or (options.flags or "body")
    local underlineColor = (hovered or active) and Addon.Theme:GetColor("accent", "primary") or Addon.Theme:GetToken(options.underlineColorPath or "color.border.subtle")

    self:ApplyText(button.Label, {
        fontFile = options.fontFile,
        font = options.font,
        size = options.size or "sm",
        flags = flags,
        colorPath = textColorPath,
    })

    if button.Underline then
        button.Underline:SetVertexColor(underlineColor.r, underlineColor.g, underlineColor.b, underlineColor.a or 1)
        button.Underline:SetAlpha((hovered or active) and (options.activeAlpha or 0.95) or (options.idleAlpha or 0.2))
    end
end

function Helpers:ApplyCheckbox(button)
    if not button then
        return
    end

    HideCheckButtonArt(button)

    if not button.WeirdUICheckboxBox then
        button.WeirdUICheckboxBox = CreateFrame("Frame", nil, button)
        button.WeirdUICheckboxBox:SetPoint("TOPLEFT", 4, -4)
        button.WeirdUICheckboxBox:SetPoint("BOTTOMRIGHT", -4, 4)

        button.WeirdUICheckboxGlyph = button.WeirdUICheckboxBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        button.WeirdUICheckboxGlyph:SetPoint("CENTER", 0, 0)
        button.WeirdUICheckboxGlyph:SetText(ns.IconFont.Glyph.Check)

        button:HookScript("OnEnter", function(control)
            control.hovered = true
            Addon.SkinHelpers:ApplyCheckbox(control)
        end)

        button:HookScript("OnLeave", function(control)
            control.hovered = nil
            Addon.SkinHelpers:ApplyCheckbox(control)
        end)

        button:HookScript("OnDisable", function(control)
            Addon.SkinHelpers:ApplyCheckbox(control)
        end)

        button:HookScript("OnEnable", function(control)
            Addon.SkinHelpers:ApplyCheckbox(control)
        end)
    end

    self:ApplyPanel(button.WeirdUICheckboxBox, {
        accent = false,
        shadow = false,
        surfaceColorPath = button.hovered and "color.surface.elevated" or "color.surface.inset",
        borderColorPath = button:GetChecked() and "color.border.accent" or "color.border.subtle",
    })

    local checkColor = Addon.Theme:GetColor("accent", "primary")
    local alpha = button:GetChecked() and 1 or 0
    if not button:IsEnabled() then
        alpha = alpha * 0.45
        button:SetAlpha(0.65)
    else
        button:SetAlpha(1)
    end

    self:ApplyText(button.WeirdUICheckboxGlyph, {
        fontFile = GetIconFont(),
        size = "md",
        flags = "body",
        colorPath = "color.role.accent.primary",
    })
    button.WeirdUICheckboxGlyph:SetAlpha(alpha)
end

function Helpers:ApplyStatusBar(statusBar)
    local fillColor = Addon.Theme:GetColor("accent", "primary")
    local backgroundColor = Addon.Theme:GetToken("color.surface.inset")
    local borderColor = Addon.Theme:GetToken("color.border.subtle")

    self:ApplyPanel(statusBar)
    statusBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    statusBar:GetStatusBarTexture():SetHorizTile(false)
    statusBar:GetStatusBarTexture():SetVertTile(false)
    statusBar:SetStatusBarColor(fillColor.r, fillColor.g, fillColor.b, fillColor.a or 1)

    local bg = EnsureTexture(statusBar, "WeirdUIStatusBarBackground", "BACKGROUND")
    bg:SetAllPoints()
    ApplyColor(bg, backgroundColor)

    ApplyColor(statusBar.WeirdUIBorderTop, borderColor)
    ApplyColor(statusBar.WeirdUIBorderBottom, borderColor)
    ApplyColor(statusBar.WeirdUIBorderLeft, borderColor)
    ApplyColor(statusBar.WeirdUIBorderRight, borderColor)
end

function Helpers:ApplyIcon(texture)
    local crop = Addon.Theme:GetToken("icon.crop.standard") or 0.07
    texture:SetTexCoord(crop, 1 - crop, crop, 1 - crop)
end

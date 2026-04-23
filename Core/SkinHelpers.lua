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

function Helpers:ApplyPanel(frame)
    local theme = Addon.Theme
    local panelColor = theme:GetToken("color.surface.panel")
    local borderColor = theme:GetToken("color.border.strong")
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
end

function Helpers:ApplyText(fontString, options)
    options = options or {}

    local fontName = options.font or "primary"
    local sizeName = options.size or "md"
    local colorPath = options.colorPath or "color.text.primary"
    local flagsName = options.flags or "body"

    local fontFile = Addon.Theme:GetFont(fontName)
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

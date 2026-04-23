local _, ns = ...

local Addon = ns.Addon

local function PrintHelp()
    Addon:Debug("Commands: /weirdui preview, /weirdui reapply, /weirdui token <path>")
end

local function Trim(text)
    return (text and text:match("^%s*(.-)%s*$")) or ""
end

local function HandleTokenCommand(rest)
    local path = Trim(rest)
    if path == "" then
        Addon:Debug("Usage: /weirdui token color.role.accent.primary")
        return
    end

    local value = Addon:GetThemeToken(path)
    if type(value) == "table" then
        if value.r then
            Addon:Debug(string.format("%s = rgba(%.2f, %.2f, %.2f, %.2f)", path, value.r, value.g, value.b, value.a or 1))
            return
        end

        Addon:Debug(string.format("%s = [table]", path))
        return
    end

    Addon:Debug(string.format("%s = %s", path, tostring(value)))
end

SLASH_WEIRDUI1 = "/weirdui"
SLASH_WEIRDUI2 = "/wui"
SlashCmdList.WEIRDUI = function(message)
    local command, rest = string.match(message or "", "^(%S*)%s*(.-)$")
    command = string.lower(command or "")

    if command == "" or command == "help" then
        PrintHelp()
        return
    end

    if command == "preview" then
        Addon:ShowPreviewFrame()
        return
    end

    if command == "reapply" then
        local appliedCount = Addon:ReapplyAllSkins()
        Addon:ReapplyPreview()
        Addon:Debug(string.format("Reapplied %d registered skin target(s).", appliedCount))
        return
    end

    if command == "token" then
        HandleTokenCommand(rest)
        return
    end

    PrintHelp()
end

function Addon:InitializeDebugTools()
    self.DebugCommandsReady = true
end

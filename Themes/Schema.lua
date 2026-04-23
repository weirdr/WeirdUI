local _, ns = ...

ns.ThemeSchema = {
    version = 1,
    pathSeparator = ".",
    namingRules = {
        "Use semantic family.branch.leaf paths such as color.role.accent.primary.",
        "Prefer intent-based names over literal values.",
        "Reserve component branches for repeated widget patterns instead of one-off modules.",
        "Add new tokens under existing families before inventing a new top-level branch.",
    },
    fallbackOrder = {
        "profile.theme.overrides",
        "activeTheme.tokens",
        "builtinDefaultTheme.tokens",
    },
    families = {
        color = {
            branches = {
                "role",
                "text",
                "surface",
                "border",
                "state",
                "icon",
            },
        },
        typography = {
            branches = {
                "font",
                "size",
                "flag",
                "lineHeight",
            },
        },
        spacing = {
            branches = {
                "xxs",
                "xs",
                "sm",
                "md",
                "lg",
                "xl",
                "xxl",
            },
        },
        radius = {
            branches = {
                "sm",
                "md",
                "lg",
                "pill",
            },
        },
        border = {
            branches = {
                "width",
                "inset",
                "style",
            },
        },
        opacity = {
            branches = {
                "disabled",
                "muted",
                "overlay",
                "hidden",
            },
        },
        shadow = {
            branches = {
                "size",
                "alpha",
            },
        },
        glow = {
            branches = {
                "size",
                "alpha",
            },
        },
        icon = {
            branches = {
                "size",
                "crop",
                "desaturateUnavailable",
            },
        },
        animation = {
            branches = {
                "duration",
                "easing",
            },
        },
        component = {
            branches = {
                "button",
                "panel",
                "statusBar",
                "tooltip",
            },
        },
    },
    semanticColorRoles = {
        "neutral",
        "accent",
        "success",
        "warning",
        "danger",
        "disabled",
        "emphasis",
        "combatAlert",
    },
    widgetStates = {
        "normal",
        "hover",
        "pressed",
        "checked",
        "active",
        "selected",
        "disabled",
        "highlighted",
        "unavailable",
    },
}

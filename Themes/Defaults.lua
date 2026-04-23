local _, ns = ...

local function Color(r, g, b, a)
    return {
        r = r,
        g = g,
        b = b,
        a = a or 1,
    }
end

ns.BuiltinThemes = {
    [ns.Constants.DefaultThemeID] = {
        id = ns.Constants.DefaultThemeID,
        label = "Weird Midnight",
        description = "Default WeirdUI theme for Midnight retail.",
        tokens = {
            color = {
                role = {
                    neutral = {
                        primary = Color(0.82, 0.86, 0.92),
                        subtle = Color(0.46, 0.51, 0.60),
                        strong = Color(0.94, 0.96, 0.99),
                    },
                    accent = {
                        primary = Color(0.36, 0.56, 0.98),
                        subtle = Color(0.23, 0.34, 0.58),
                        strong = Color(0.72, 0.83, 1.00),
                    },
                    success = {
                        primary = Color(0.32, 0.78, 0.52),
                        subtle = Color(0.15, 0.32, 0.22),
                        strong = Color(0.72, 0.94, 0.79),
                    },
                    warning = {
                        primary = Color(0.93, 0.68, 0.22),
                        subtle = Color(0.37, 0.24, 0.07),
                        strong = Color(1.00, 0.88, 0.62),
                    },
                    danger = {
                        primary = Color(0.89, 0.33, 0.36),
                        subtle = Color(0.36, 0.12, 0.16),
                        strong = Color(0.98, 0.77, 0.79),
                    },
                    disabled = {
                        primary = Color(0.38, 0.41, 0.47),
                        subtle = Color(0.19, 0.21, 0.25),
                        strong = Color(0.56, 0.60, 0.67),
                    },
                    emphasis = {
                        primary = Color(0.69, 0.45, 0.96),
                        subtle = Color(0.28, 0.17, 0.41),
                        strong = Color(0.88, 0.76, 1.00),
                    },
                    combatAlert = {
                        primary = Color(1.00, 0.18, 0.18),
                        subtle = Color(0.38, 0.05, 0.05),
                        strong = Color(1.00, 0.69, 0.69),
                    },
                },
                text = {
                    primary = Color(0.92, 0.94, 0.97),
                    secondary = Color(0.69, 0.73, 0.79),
                    muted = Color(0.47, 0.51, 0.57),
                    inverse = Color(0.07, 0.08, 0.11),
                },
                surface = {
                    canvas = Color(0.02, 0.02, 0.03, 0.98),
                    panel = Color(0.05, 0.06, 0.07, 0.96),
                    elevated = Color(0.08, 0.09, 0.11, 0.97),
                    inset = Color(0.03, 0.04, 0.05, 0.94),
                    overlay = Color(0.01, 0.01, 0.02, 0.90),
                    shellTop = Color(0.07, 0.08, 0.10, 0.94),
                    shellBottom = Color(0.02, 0.02, 0.03, 0.98),
                    shellGlow = Color(0.10, 0.13, 0.18, 0.24),
                },
                border = {
                    subtle = Color(0.16, 0.18, 0.22),
                    strong = Color(0.27, 0.31, 0.38),
                    accent = Color(0.36, 0.56, 0.98),
                },
                state = {
                    normal = {
                        tint = Color(1.00, 1.00, 1.00),
                        alphaMultiplier = 1.00,
                    },
                    hover = {
                        tint = Color(0.92, 0.97, 1.00),
                        alphaMultiplier = 1.00,
                    },
                    pressed = {
                        tint = Color(0.82, 0.89, 1.00),
                        alphaMultiplier = 1.00,
                    },
                    checked = {
                        tint = Color(0.70, 0.82, 1.00),
                        alphaMultiplier = 1.00,
                    },
                    active = {
                        tint = Color(0.78, 0.87, 1.00),
                        alphaMultiplier = 1.00,
                    },
                    selected = {
                        tint = Color(0.84, 0.90, 1.00),
                        alphaMultiplier = 1.00,
                    },
                    disabled = {
                        tint = Color(0.60, 0.64, 0.72),
                        alphaMultiplier = 0.40,
                    },
                    highlighted = {
                        tint = Color(0.95, 0.87, 0.55),
                        alphaMultiplier = 1.00,
                    },
                    unavailable = {
                        tint = Color(0.54, 0.58, 0.64),
                        alphaMultiplier = 0.55,
                    },
                },
                icon = {
                    desaturated = Color(0.40, 0.42, 0.48),
                    quest = Color(1.00, 0.84, 0.33),
                    reward = Color(0.63, 0.84, 1.00),
                },
            },
            typography = {
                font = {
                    primary = "Fonts\\FRIZQT__.TTF",
                    accent = "Fonts\\ARIALN.TTF",
                    mono = "Fonts\\ARIALN.TTF",
                },
                size = {
                    xs = 10,
                    sm = 12,
                    md = 14,
                    lg = 18,
                    xl = 24,
                },
                flag = {
                    body = "",
                    emphasis = "OUTLINE",
                    display = "THICKOUTLINE",
                },
                lineHeight = {
                    compact = 1.00,
                    normal = 1.15,
                    relaxed = 1.30,
                },
            },
            spacing = {
                xxs = 2,
                xs = 4,
                sm = 8,
                md = 12,
                lg = 16,
                xl = 24,
                xxl = 32,
            },
            radius = {
                sm = 4,
                md = 8,
                lg = 12,
                pill = 999,
            },
            border = {
                width = {
                    hairline = 1,
                    thin = 2,
                    thick = 3,
                },
                inset = {
                    panel = 1,
                    focus = 2,
                },
                style = {
                    default = "solid",
                    emphasis = "accent",
                },
            },
            opacity = {
                disabled = 0.40,
                muted = 0.65,
                overlay = 0.88,
                hidden = 0.00,
            },
            shadow = {
                size = {
                    sm = 4,
                    md = 8,
                    lg = 14,
                },
                alpha = {
                    soft = 0.16,
                    medium = 0.28,
                    strong = 0.42,
                },
            },
            glow = {
                size = {
                    subtle = 6,
                    emphasis = 10,
                },
                alpha = {
                    subtle = 0.18,
                    emphasis = 0.36,
                },
            },
            icon = {
                size = {
                    xs = 14,
                    sm = 18,
                    md = 24,
                    lg = 32,
                },
                crop = {
                    standard = 0.07,
                },
                desaturateUnavailable = true,
            },
            animation = {
                duration = {
                    instant = 0.00,
                    fast = 0.10,
                    standard = 0.18,
                    slow = 0.32,
                },
                easing = {
                    emphasize = "out",
                    standard = "in_out",
                },
            },
            component = {
                button = {
                    padding = 4,
                    borderWidth = 2,
                },
                panel = {
                    padding = 12,
                    borderWidth = 1,
                },
                statusBar = {
                    height = 12,
                },
                tooltip = {
                    padding = 10,
                },
            },
        },
    },
}

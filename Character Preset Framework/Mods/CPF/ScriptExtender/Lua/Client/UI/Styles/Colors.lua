UIColors = {}

UIColors.COLOR_GREEN = { 0.2, 0.67, 0.2, 0.67 }
UIColors.COLOR_RED = { 0.8, 0.2, 0.2, 0.67 }
UIColors.COLOR_ORANGE = { 0.8, 0.67, 0.2, 0.67 }
UIColors.COLOR_GRAY = { 0.5, 0.5, 0.5, 0.67 }
UIColors.BUTTON_DISABLED = Color.NormalizedRGBA(117, 102, 74, 0.2)

-- TODO: add API to MCM and use it. Copied from MCM's UIStyle.Colors, which is internal.
UIColors.BUTTON = Color.NormalizedRGBA(117, 102, 74, 0.5)
UIColors.BUTTON_ACTIVE = Color.NormalizedRGBA(183, 122, 81, 0.7)
UIColors.TEXT_DISABLED = Color.NormalizedRGBA(219, 201, 173, 0.18)

return UIColors

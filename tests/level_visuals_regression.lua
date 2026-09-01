-- Focused Lua 5.1 regression checks for the real modules/level_visuals.lua.
-- Run from the addon root with: lua51.exe tests/level_visuals_regression.lua

local function fail(message)
    error(message, 2)
end

local function expect(condition, message)
    if not condition then
        fail(message)
    end
end

CT_CONTROL = 1
CT_TEXTURE = 2
CT_LABEL = 3
DL_OVERLAY = 1
TEXT_ALIGN_CENTER = 1
MODIFY_TEXT_TYPE_NONE = 0
TOPLEFT = 1
LEFT = 2

local function NewControl(controlType)
    local control =
    {
        controlType = controlType,
        width = 0,
        height = 0,
        hidden = false,
        text = "",
    }

    function control:SetDimensions(width, height)
        self.width = width
        self.height = height
    end

    function control:GetWidth()
        return self.width
    end

    function control:GetHeight()
        return self.height
    end

    function control:SetTexture(texture)
        self.texture = texture
    end

    function control:SetText(text)
        self.text = text or ""
    end

    function control:GetTextWidth()
        -- Deliberately echo the currently assigned box. This is the failure
        -- mode that used to make badge widths depend on the previous target.
        return self.width
    end

    function control:GetStringWidth(text)
        -- Intrinsic measurement is independent from this control's current
        -- dimensions, matching ESO's LabelControl:GetStringWidth(text).
        return string.len(text or "") * 8
    end

    function control:SetHidden(hidden)
        self.hidden = hidden == true
    end

    function control:IsHidden()
        return self.hidden
    end

    function control:SetAnchorFill(anchorTarget)
        self.anchorFill = anchorTarget
    end

    function control:ClearAnchors()
        self.anchorFill = nil
        self.anchor = nil
    end

    function control:SetAnchor(...)
        self.anchor = { ... }
    end

    function control:SetFont(font)
        self.font = font
    end

    function control:SetHorizontalAlignment(alignment)
        self.horizontalAlignment = alignment
    end

    function control:SetVerticalAlignment(alignment)
        self.verticalAlignment = alignment
    end

    function control:SetModifyTextType(modifyType)
        self.modifyTextType = modifyType
    end

    function control:SetColor(...)
        self.color = { ... }
    end

    function control:SetDrawLayer(layer)
        self.drawLayer = layer
    end

    function control:SetDrawLevel(level)
        self.drawLevel = level
    end

    function control:SetAutoRectClipChildren(enabled)
        self.autoRectClipChildren = enabled
    end

    function control:SetAlpha(alpha)
        self.alpha = alpha
    end

    return control
end

WINDOW_MANAGER =
{
    CreateControl = function(_, name, parent, controlType)
        local control = NewControl(controlType)
        control.name = name
        control.parent = parent
        return control
    end,
}

local officialChampionTexture = "EsoUI/mock/champion_points_small.dds"
ZO_GetChampionPointsIconSmall = function()
    return officialChampionTexture
end

Nirnsteel_UI = {}
assert(loadfile("modules/level_visuals.lua"))()
local LevelVisuals = Nirnsteel_UI.LevelVisuals

local parent = NewControl(CT_CONTROL)
local championBadge = LevelVisuals:Create(parent,
{
    name = "TestChampionBadge",
    height = 24,
    minimumWidth = 42,
    maximumWidth = 90,
    horizontalPadding = 8,
    showChampionIcon = true,
    championIconSize = 16,
    championIconGap = 2,
    font = "$(BOLD_FONT)|16|thick-outline",
})

expect(championBadge.championIcon.texture == officialChampionTexture,
    "the badge must use ZO_GetChampionPointsIconSmall when it is available")

-- A four-digit Champion value must reserve its intrinsic width beside the
-- icon, regardless of the badge's previous or currently assigned dimensions.
local championWidth = LevelVisuals:Apply(championBadge,
{
    champion = true,
    championPoints = 2334,
    level = 50,
},
{
    shown = true,
    styled = true,
})

expect(championBadge.championIcon.hidden == false, "Champion badges must show the Champion icon")
expect(championWidth == 58, "a four-digit Champion badge must reserve intrinsic text and icon width")
expect(championBadge.label.width == 34, "four-digit Champion text must retain its intrinsic width")

-- Switching the same badge to an ordinary level must remove the icon and its
-- reserved space without inheriting the prior Champion dimensions.
local ordinaryWidth = LevelVisuals:Apply(championBadge,
{
    champion = false,
    championPoints = 0,
    level = 50,
},
{
    shown = true,
    styled = true,
})

expect(championBadge.championIcon.hidden == true, "ordinary levels must hide the Champion icon")
expect(ordinaryWidth == championBadge.minimumWidth,
    "ordinary levels must use their intrinsic width and configured minimum")
expect(championBadge.label.anchorFill == championBadge.control,
    "ordinary level text must return to the full badge layout")
expect(ordinaryWidth < championWidth, "ordinary levels must not retain Champion icon spacing")

-- Returning to a same-length Champion value must reproduce the original
-- compact width. In particular, it must not feed the ordinary badge box back
-- into the Champion measurement.
local transitionedChampionWidth = LevelVisuals:Apply(championBadge,
{
    champion = true,
    championPoints = 2816,
    level = 50,
},
{
    shown = true,
    styled = true,
})

expect(transitionedChampionWidth == championWidth,
    "Champion badge width must be stable across ordinary/Champion transitions")
expect(championBadge.label.width == 34,
    "transitioned Champion text must not inherit the ordinary badge box")

-- The Target Frame uses a denser badge than Group Frames: a 14px Champion
-- icon, 3px gap, and 6px total horizontal padding. Its four-digit values must
-- remain compact and keep the icon immediately left of the value.
local compactBadge = LevelVisuals:Create(parent,
{
    name = "TestCompactTargetBadge",
    height = 22,
    minimumWidth = 36,
    maximumWidth = 86,
    horizontalPadding = 6,
    showChampionIcon = true,
    championIconSize = 14,
    championIconGap = 3,
})
local compactChampionWidth = LevelVisuals:Apply(compactBadge,
{
    champion = true,
    championPoints = 2305,
    level = 50,
},
{
    shown = true,
    styled = true,
})

expect(compactChampionWidth == 55,
    "Target Frame Champion badges must use the compact 14px icon geometry")
expect(compactBadge.championIcon.width == 14 and compactBadge.championIcon.height == 14,
    "the compact Champion icon must remain 14px square")
expect(compactBadge.championIcon.anchor[4] == 2 and compactBadge.label.anchor[4] == 19,
    "the compact Champion icon and value must form one centered badge")

local compactOrdinaryWidth = LevelVisuals:Apply(compactBadge,
{
    champion = false,
    championPoints = 0,
    level = 50,
},
{
    shown = true,
    styled = true,
})
expect(compactOrdinaryWidth == 36,
    "ordinary Target Frame levels must collapse to the compact minimum width")
expect(compactBadge.championIcon.hidden == true,
    "ordinary Target Frame levels must release the Champion icon slot")

-- Preserve the helper's existing measured-width behavior for non-Champion
-- consumers such as Group Frames.
local ordinaryBadge = LevelVisuals:Create(parent,
{
    name = "TestOrdinaryBadge",
    height = 18,
    minimumWidth = 34,
    maximumWidth = 64,
    horizontalPadding = 10,
    showChampionIcon = false,
})
local measuredOrdinaryWidth = LevelVisuals:Apply(ordinaryBadge,
{
    champion = false,
    level = 160,
},
{
    shown = true,
    styled = false,
})

expect(measuredOrdinaryWidth == 42,
    "ordinary measured width must remain text width plus horizontal padding")
expect(ordinaryBadge.championIcon.hidden == true, "Champion icon must remain hidden when disabled")

print("level_visuals_regression.lua: all checks passed")

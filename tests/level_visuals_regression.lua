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
        if self.hidden and self.OnHide then self.OnHide() end
    end

    function control:SetHandler(event, handler)
        self[event] = handler
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

ANIMATION_TRANSLATE = 1
ANIMATION_ALPHA = 2
ANIMATION_PLAYBACK_ONE_SHOT = 1
ANIMATION_MANAGER = {}
function ANIMATION_MANAGER:CreateTimeline()
    local timeline = { animations = {}, plays = 0 }
    function timeline:InsertAnimation(kind, control, offset)
        local animation = { kind = kind, control = control, offset = offset }
        function animation:SetDuration(value) self.duration = value end
        function animation:SetAlphaValues(first, last) self.first = first; self.last = last end
        function animation:SetTranslateOffsets(...) self.translation = { ... } end
        function animation:SetEasingFunction(value) self.easing = value end
        self.animations[#self.animations + 1] = animation
        return animation
    end
    function timeline:SetHandler(event, handler) self[event] = handler end
    function timeline:SetPlaybackType(value) self.playback = value end
    function timeline:PlayFromStart() self.plays = self.plays + 1 end
    function timeline:Stop() self:OnStop() end
    return timeline
end

local cases = {
    { 0, "FFFFFF", 0 }, { 599, "FFFFFF", 0 },
    { 600, "00FF00", 0 }, { 1199, "00FF00", 0 },
    { 1200, "4040FF", 0 }, { 1799, "4040FF", 0 },
    { 1800, "A020F0", 0.30 }, { 2399, "A020F0", 0.30 },
    { 2400, "FFFF00", 0.50 }, { 2999, "FFFF00", 0.50 },
    { 3000, "FFA500", 0.70 }, { 3599, "FFA500", 0.70 },
    { 3600, "FFA500", 0.70 }, { 4000, "FFA500", 0.70 },
}
for _, case in ipairs(cases) do
    local cp, hex, intensity = case[1], case[2], case[3]
    LevelVisuals:Apply(compactBadge, { champion = true, championPoints = cp })
    for color in compactBadge.label.text:gmatch("|c(%x%x%x%x%x%x)") do
        expect(color == hex, "all digits must retain bracket color at CP " .. cp)
    end
    expect(compactBadge.shimmerIntensity == intensity, "wrong shimmer strength at CP " .. cp)
    LevelVisuals:Play(compactBadge)
    if intensity > 0 then
        local timeline = compactBadge.timeline
        local sweeps, finish = 0, 0
        for _, animation in ipairs(timeline.animations) do
            if animation.kind == ANIMATION_TRANSLATE and animation.control == compactBadge.clip then
                sweeps = sweeps + 1
                expect(animation.duration == 720, "sweeps must last 720 ms")
                expect(animation.offset == (sweeps == 1 and 0 or 900), "incorrect sweep delay")
            end
            if animation.control == compactBadge.glow and animation.offset >= 1620 then
                finish = finish + animation.duration
            end
        end
        expect(sweeps == (cp >= 3000 and 2 or 1), "incorrect sweep count")
        expect(finish == (cp >= 3600 and 600 or 0), "incorrect cap finishing pulse")
        LevelVisuals:Play(compactBadge)
        expect(timeline.plays == 1, "active animations must not overlap")
        timeline:Stop()
        expect(not compactBadge.playing and compactBadge.clip.hidden and compactBadge.glow.hidden,
            "completion must clear effects")
    else
        expect(not compactBadge.playing, "lower brackets must not animate")
    end
end

LevelVisuals:Apply(compactBadge, { champion = true, championPoints = 3600 })
LevelVisuals:Play(compactBadge)
local oldTimeline = compactBadge.timeline
LevelVisuals:Apply(compactBadge, { champion = true, championPoints = 1800 })
expect(not compactBadge.playing and compactBadge.timeline == nil, "tier changes must discard active timelines")
LevelVisuals:Play(compactBadge)
expect(compactBadge.timeline ~= oldTimeline, "new tiers must rebuild their animation")
compactBadge.control:SetHidden(true)
expect(not compactBadge.playing and compactBadge.glow.hidden, "hiding must stop playback")
LevelVisuals:Apply(compactBadge, { champion = true, championPoints = 3600 })
LevelVisuals:Play(compactBadge)
LevelVisuals:Apply(compactBadge, { champion = true, championPoints = 3600 }, { styled = false })
expect(compactBadge.label.text == "3600" and compactBadge.shimmerIntensity == 0
    and not compactBadge.playing, "disabling styling must restore plain text and stop effects")
LevelVisuals:Apply(compactBadge, { champion = true, championPoints = 3600 }, { shown = false })
expect(compactBadge.control.hidden and compactBadge.clip.hidden, "hidden badges must clear effects")
expect(compactBadge.glow.parent == compactBadge.control and compactBadge.glow.font == compactBadge.label.font,
    "glow must remain aligned with stationary digits")
LevelVisuals:Apply(compactBadge, { champion = true, championPoints = 3600 })
expect(compactBadge.glow.text ~= compactBadge.label.text,
    "the finishing glow must brighten the base digits")
expect(LevelVisuals.SHIMMER_CADENCE_MS == 4200, "repeat cadence must remain 4.2 seconds")

print("level_visuals_regression.lua: all checks passed")

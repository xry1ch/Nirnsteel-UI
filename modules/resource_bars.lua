local ADDON_NAME = "Nirnsteel-UI"
local EVENT_NAMESPACE = ADDON_NAME .. "_ResourceBars"

Nirnsteel_UI = Nirnsteel_UI or {}
local ResourceBars = {}
Nirnsteel_UI.ResourceBars = ResourceBars

local DEFAULT_SETTINGS =
{
    enabled = true,
    unlocked = false,
    scale = 100,
    barHeight = 18,
    rowSpacing = 0,
    columnSpacing = 6,
    rowHealthWidth = 280,
    rowMagickaWidth = 270,
    rowStaminaWidth = 270,
    opacity = 100,
    glossEnabled = true,
    healthTextFormat = "numberAndPercent",
    magickaTextFormat = "numberAndPercent",
    staminaTextFormat = "numberAndPercent",
    healthTextPosition = "center",
    magickaTextPosition = "center",
    staminaTextPosition = "center",
    shieldOverlayEnabled = true,
    shieldTextMode = "healthAndShield",
    barTextureKey = "genericTall",
    healthTextureKey = "genericTall",
    magickaTextureKey = "genericTall",
    staminaTextureKey = "genericTall",
    barPatternEnabled = false,
    barPatternKey = "smoke",
    barPatternOpacity = 18,
    barPatternScale = 96,
    shieldTextureKey = "genericTall",
    borderWidth = 0,
    cornerSize = 0,
    innerShadowAlpha = 20,
    outerShadowAlpha = 0,
    textFontKey = "gameSmall",
    textSize = 16,
    textOutline = "soft-shadow-thick",
    textOpacity = 100,
    textInset = 6,
    textVerticalOffset = 2,
    textColor = { r = 0.96, g = 0.92, b = 0.82 },
}

local DEFAULT_POSITION = { x = 0, y = -120 }
local VISIBILITY_HOLD_MS = 1500
local DEFAULT_ROW_WIDTH = 420
local MIN_ROW_WIDTH = 300
local MAX_ROW_WIDTH = 620
local MIN_HEALTH_WIDTH = 220
local MIN_RESOURCE_WIDTH = 96
local MIN_BAR_HEIGHT = 10
local MAX_BAR_HEIGHT = 48
local MIN_ALPHA = 10
local MAX_ALPHA = 100
local EDGE_FRAME_TEXTURE = "EsoUI/Art/Miscellaneous/Gamepad/edgeframeGamepadBorder_thin.dds"

local BAR_TEXTURES =
{
    genericTall = {
        texture = "EsoUI/Art/Miscellaneous/progressbar_genericFill_tall.dds",
        gloss = "EsoUI/Art/Miscellaneous/timerBar_genericFill_gloss.dds",
        coords = { 0, 1, 0, 0.8125 },
    },
    genericArrow = {
        texture = "EsoUI/Art/Miscellaneous/progressbar_genericFill.dds",
        gloss = "EsoUI/Art/Miscellaneous/progressbar_genericFill_gloss.dds",
        coords = { 0, 1, 0, 0.625 },
    },
    gamepadMedium = {
        texture = "EsoUI/Art/Miscellaneous/Gamepad/gp_dynamicBar_medium_fill.dds",
        gloss = "EsoUI/Art/Miscellaneous/timerBar_genericFill_gloss.dds",
        coords = { 0, 1, 0, 1 },
    },
    gamepadLarge = {
        texture = "EsoUI/Art/Miscellaneous/Gamepad/gp_dynamicBar_large_fill.dds",
        gloss = "EsoUI/Art/Miscellaneous/timerBar_genericFill_gloss.dds",
        coords = { 0, 1, 0, 1 },
    },
    tributeLarge = {
        texture = "EsoUI/Art/Miscellaneous/progressbar_large_genericFill.dds",
        gloss = "EsoUI/Art/Miscellaneous/progressbar_large_genericFill_gloss.dds",
        coords = { 0, 1, 0, 1 },
    },
}

local FONT_FACES =
{
    gameSmall = "$(BOLD_FONT)",
    gameMedium = "$(MEDIUM_FONT)",
    antique = "$(ANTIQUE_FONT)",
    trajan = "EsoUI/Common/Fonts/TrajanPro-Regular.slug",
    univers = "EsoUI/Common/Fonts/Univers57.slug",
    chat = "$(CHAT_FONT)",
}

local BAR_PATTERNS =
{
    smoke = "/art/fx/texture/smokecombinetexture.dds",
    stillwater = "/art/maps/housing/stillwatersretreatext_base_0.dds",
    Smoke = "/art/fx/texture/smokecombinetexture.dds",
    Stillwater = "/art/maps/housing/stillwatersretreatext_base_0.dds",
}

local RESOURCE_DATA =
{
    health = {
        powerType = COMBAT_MECHANIC_FLAGS_HEALTH,
        color = { 0.72, 0.06, 0.08, 0.96 },
        endColor = { 0.98, 0.18, 0.20, 0.98 },
        label = "Health",
    },
    magicka = {
        powerType = COMBAT_MECHANIC_FLAGS_MAGICKA,
        color = { 0.04, 0.30, 0.62, 0.94 },
        endColor = { 0.16, 0.64, 0.96, 0.96 },
        label = "Magicka",
    },
    stamina = {
        powerType = COMBAT_MECHANIC_FLAGS_STAMINA,
        color = { 0.03, 0.42, 0.25, 0.94 },
        endColor = { 0.16, 0.78, 0.42, 0.96 },
        label = "Stamina",
    },
}

local POWER_KEY_BY_TYPE =
{
    [COMBAT_MECHANIC_FLAGS_HEALTH] = "health",
    [COMBAT_MECHANIC_FLAGS_MAGICKA] = "magicka",
    [COMBAT_MECHANIC_FLAGS_STAMINA] = "stamina",
}

local TEXT_FORMAT_SETTING =
{
    number = RESOURCE_NUMBERS_SETTING_NUMBER_ONLY,
    percent = RESOURCE_NUMBERS_SETTING_PERCENT_ONLY,
    numberAndPercent = RESOURCE_NUMBERS_SETTING_NUMBER_AND_PERCENT,
}

local BAR_ORDER = { "health", "magicka", "stamina" }

local TEXT_FORMAT_ALIASES =
{
    number = "number",
    Number = "number",
    percent = "percent",
    Percent = "percent",
    numberAndPercent = "numberAndPercent",
    ["Number + Percent"] = "numberAndPercent",
    ["Number and Percent"] = "numberAndPercent",
}

local TEXT_POSITION_ALIASES =
{
    center = "center",
    Center = "center",
    sides = "sides",
    Sides = "sides",
}

local SHIELD_TEXT_ALIASES =
{
    off = "off",
    Off = "off",
    shieldOnly = "shieldOnly",
    ["Shield Only"] = "shieldOnly",
    healthAndShield = "healthAndShield",
    ["Health + Shield"] = "healthAndShield",
}

local function ClampNumber(value, minValue, maxValue)
    value = tonumber(value) or minValue
    return math.min(math.max(value, minValue), maxValue)
end

local function NormalizeTextFormat(value)
    return TEXT_FORMAT_ALIASES[value] or "numberAndPercent"
end

local function NormalizeTextPosition(value)
    return TEXT_POSITION_ALIASES[value] or "center"
end

local function NormalizeShieldTextMode(value)
    return SHIELD_TEXT_ALIASES[value] or "healthAndShield"
end

local function GetSettings()
    if Nirnsteel_UI.Settings then
        return Nirnsteel_UI.Settings:GetResourceBars()
    end

    return DEFAULT_SETTINGS
end

local function GetSettingValue(key)
    local settings = GetSettings()
    local value = settings and settings[key]
    if value == nil then
        return DEFAULT_SETTINGS[key]
    end

    return value
end

local function IsModuleEnabled()
    return not Nirnsteel_UI.Settings or Nirnsteel_UI.Settings:IsResourceBarsEnabled()
end

local function IsModuleUnlocked()
    return IsModuleEnabled()
        and Nirnsteel_UI.Settings
        and Nirnsteel_UI.Settings:IsResourceBarsUnlocked()
end

local function GetPosition()
    if Nirnsteel_UI.Settings then
        return Nirnsteel_UI.Settings:GetResourceBarsPosition()
    end

    return DEFAULT_POSITION
end

local function GetScale()
    return ClampNumber(GetSettingValue("scale"), 70, 160) / 100
end

local function GetConfiguredBarHeight()
    return ClampNumber(GetSettingValue("barHeight"), MIN_BAR_HEIGHT, MAX_BAR_HEIGHT)
end

local function GetConfiguredAlpha()
    return ClampNumber(GetSettingValue("opacity"), MIN_ALPHA, MAX_ALPHA) / 100
end

local function GetRowSpacing()
    return ClampNumber(GetSettingValue("rowSpacing"), 0, 32)
end

local function GetColumnSpacing()
    return ClampNumber(GetSettingValue("columnSpacing"), 0, 32)
end

local function ShouldShowGloss()
    return GetSettingValue("glossEnabled") ~= false
end

local function ShouldShowShieldOverlay()
    return GetSettingValue("shieldOverlayEnabled") ~= false
end

local function ShouldShowBarPattern()
    return GetSettingValue("barPatternEnabled") == true
end

local function GetBarTextureInfo(settingKey, fallbackSettingKey)
    local textureKey = GetSettingValue(settingKey)
    if not BAR_TEXTURES[textureKey] and fallbackSettingKey then
        textureKey = GetSettingValue(fallbackSettingKey)
    end
    return BAR_TEXTURES[textureKey] or BAR_TEXTURES.genericTall
end

local function GetResourceTextureInfo(resourceKey)
    return GetBarTextureInfo(resourceKey .. "TextureKey", "barTextureKey")
end

local function BuildTextFont()
    local face = FONT_FACES[GetSettingValue("textFontKey")] or FONT_FACES.gameSmall
    local size = ClampNumber(GetSettingValue("textSize"), 8, 32)
    local outline = GetSettingValue("textOutline")
    if outline == "none" then
        return string.format("%s|%d", face, size)
    end

    return string.format("%s|%d|%s", face, size, outline or "soft-shadow-thick")
end

local function ApplyLabelTextStyle(label, font, r, g, b, alpha)
    if not label then
        return
    end

    label:SetFont(font)
    label:SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
    label:SetColor(r, g, b, alpha)
end

local function SetStatusBarTextures(bar, textureInfo)
    textureInfo = textureInfo or GetBarTextureInfo("barTextureKey")
    bar:SetTexture(textureInfo.texture)
    bar:SetTextureCoords(unpack(textureInfo.coords))
    bar:EnableLeadingEdge(false)
    bar:SetPixelRoundingEnabled(false)
end

local function ConfigureStatusBar(bar, data, key)
    SetStatusBarTextures(bar, GetResourceTextureInfo(key))
    bar:SetGradientColors(data.color[1], data.color[2], data.color[3], data.color[4], data.endColor[1], data.endColor[2], data.endColor[3], data.endColor[4])
end

local function SetResourceFillDirection(frame, key)
    local alignment = BAR_ALIGNMENT_NORMAL
    if key == "health" then
        alignment = BAR_ALIGNMENT_CENTER
    elseif key == "magicka" then
        alignment = BAR_ALIGNMENT_REVERSE
    end

    if frame.bar and frame.bar.SetBarAlignment then
        frame.bar:SetBarAlignment(alignment)
    end
    if frame.patternBar and frame.patternBar.SetBarAlignment then
        frame.patternBar:SetBarAlignment(alignment)
    end
    if frame.gloss and frame.gloss.SetBarAlignment then
        frame.gloss:SetBarAlignment(alignment)
    end
end

local function UpdatePatternTexture(frame)
    if not frame or not frame.patternBar then
        return
    end

    local pattern = BAR_PATTERNS[GetSettingValue("barPatternKey")] or BAR_PATTERNS.smoke
    local opacity = ClampNumber(GetSettingValue("barPatternOpacity"), 0, 100) / 100
    local scale = ClampNumber(GetSettingValue("barPatternScale"), 24, 256)
    local width = frame.patternWidth or frame.layoutWidth or frame:GetWidth()
    local height = frame.layoutHeight or frame:GetHeight()

    if frame.patternBar.currentPattern ~= pattern then
        frame.patternBar:SetTexture("")
        frame.patternBar.currentPattern = pattern
    end
    frame.patternBar:SetTexture(pattern)
    frame.patternBar:SetTextureCoords(0, math.max(width / scale, 0.01), 0, math.max(height / scale, 0.01))
    frame.patternBar:SetColor(1, 1, 1, opacity)
    frame.patternBar:SetHidden(not ShouldShowBarPattern() or opacity <= 0 or width <= 0)
end

local function ApplyFrameStyle(frame, width, height)
    local borderWidth = ClampNumber(GetSettingValue("borderWidth"), 0, 8)
    local cornerSize = ClampNumber(GetSettingValue("cornerSize"), 0, 12)
    local innerShadowAlpha = ClampNumber(GetSettingValue("innerShadowAlpha"), 0, 100) / 100
    local outerShadowAlpha = ClampNumber(GetSettingValue("outerShadowAlpha"), 0, 100) / 100
    local alpha = GetConfiguredAlpha()

    frame.outerShadow:SetHidden(outerShadowAlpha <= 0)
    frame.outerShadow:ClearAnchors()
    frame.outerShadow:SetAnchor(TOPLEFT, frame, TOPLEFT, -math.max(borderWidth + 2, 3), -math.max(borderWidth + 2, 3))
    frame.outerShadow:SetAnchor(BOTTOMRIGHT, frame, BOTTOMRIGHT, math.max(borderWidth + 2, 3), math.max(borderWidth + 2, 3))
    frame.outerShadow:SetEdgeColor(0, 0, 0, outerShadowAlpha)
    frame.outerShadow:SetCenterColor(0, 0, 0, outerShadowAlpha * 0.20)
    frame.outerShadow:SetEdgeTexture(EDGE_FRAME_TEXTURE, 128, 16, math.max(cornerSize, 1), 0)

    frame.border:SetHidden(borderWidth <= 0)
    frame.border:SetEdgeColor(0, 0, 0, 1)
    frame.border:SetCenterColor(0, 0, 0, 0)
    frame.border:SetEdgeTexture(EDGE_FRAME_TEXTURE, 128, 16, math.max(cornerSize, 1), 0)

    frame.track:ClearAnchors()
    frame.track:SetAnchor(TOPLEFT, frame, TOPLEFT, borderWidth, borderWidth)
    frame.track:SetAnchor(BOTTOMRIGHT, frame, BOTTOMRIGHT, -borderWidth, -borderWidth)
    frame.track:SetCenterColor(0.01, 0.01, 0.01, 0.55 * alpha)
    frame.track:SetEdgeTexture(EDGE_FRAME_TEXTURE, 128, 16, math.max(cornerSize - borderWidth, 1), 0)

    frame.innerShadow:SetHidden(innerShadowAlpha <= 0)
    frame.innerShadow:ClearAnchors()
    frame.innerShadow:SetAnchorFill(frame.track)
    frame.innerShadow:SetCenterColor(0, 0, 0, innerShadowAlpha * 0.16)
    frame.innerShadow:SetEdgeColor(0, 0, 0, innerShadowAlpha)
    frame.innerShadow:SetEdgeTexture(EDGE_FRAME_TEXTURE, 128, 16, math.max(cornerSize - borderWidth, 1), 0)

    frame.bar:SetAlpha(alpha)
    SetStatusBarTextures(frame.bar, GetResourceTextureInfo(frame.powerKey))
    UpdatePatternTexture(frame)

    if frame.shieldBar then
        SetStatusBarTextures(frame.shieldBar, GetBarTextureInfo("shieldTextureKey"))
        frame.shieldBar:SetAlpha(alpha)
    end

    if frame.gloss then
        local textureInfo = GetResourceTextureInfo(frame.powerKey)
        frame.gloss:SetTexture(textureInfo.gloss)
        frame.gloss:SetTextureCoords(unpack(textureInfo.coords))
        frame.gloss:SetHidden(not ShouldShowGloss())
    end

    local font = BuildTextFont()
    local textAlpha = ClampNumber(GetSettingValue("textOpacity"), 10, 100) / 100
    local textColor = GetSettingValue("textColor") or DEFAULT_SETTINGS.textColor
    local textR = tonumber(textColor.r) or DEFAULT_SETTINGS.textColor.r
    local textG = tonumber(textColor.g) or DEFAULT_SETTINGS.textColor.g
    local textB = tonumber(textColor.b) or DEFAULT_SETTINGS.textColor.b
    ApplyLabelTextStyle(frame.centerLabel, font, textR, textG, textB, textAlpha)
    ApplyLabelTextStyle(frame.leftLabel, font, textR, textG, textB, textAlpha)
    ApplyLabelTextStyle(frame.rightLabel, font, textR, textG, textB, textAlpha)

    frame.contentWidth = math.max(width - (borderWidth * 2), 1)
    frame.contentHeight = math.max(height - (borderWidth * 2), 1)
end

local function FormatByMode(current, maximum, mode)
    mode = NormalizeTextFormat(mode)
    local override = TEXT_FORMAT_SETTING[mode] or RESOURCE_NUMBERS_SETTING_NUMBER_AND_PERCENT
    if ZO_FormatResourceBarCurrentAndMax then
        return ZO_FormatResourceBarCurrentAndMax(current or 0, maximum or 0, override)
    end

    return zo_strformat(SI_ATTRIBUTE_NUMBERS_WITH_PERCENT, current or 0, 0)
end

local function ShouldShowResource(current, effectiveMax, fadeUntilMS)
    local showSetting = tonumber(GetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_RESOURCE_BARS))
    if showSetting == RESOURCE_BARS_SETTING_CHOICE_ALWAYS_SHOW then
        return true
    elseif showSetting == RESOURCE_BARS_SETTING_CHOICE_DONT_SHOW then
        return false
    end

    if not current or not effectiveMax or effectiveMax == 0 then
        return false
    end

    if current < effectiveMax and current ~= 0 then
        return true
    end

    if not GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_FADE_PLAYER_BARS) then
        return true
    end

    return fadeUntilMS and fadeUntilMS > GetFrameTimeMilliseconds()
end

local function IsHudSceneShowing()
    local hudShowing = HUD_SCENE and HUD_SCENE.IsShowing and HUD_SCENE:IsShowing()
    local hudUiShowing = HUD_UI_SCENE and HUD_UI_SCENE.IsShowing and HUD_UI_SCENE:IsShowing()
    if HUD_SCENE or HUD_UI_SCENE then
        return hudShowing or hudUiShowing
    end

    return true
end

local function CreateBarFrame(parent)
    local frame = WINDOW_MANAGER:CreateControl(nil, parent, CT_CONTROL)

    frame.outerShadow = WINDOW_MANAGER:CreateControl(nil, frame, CT_BACKDROP)
    frame.outerShadow:SetAnchor(TOPLEFT, frame, TOPLEFT, -3, -3)
    frame.outerShadow:SetAnchor(BOTTOMRIGHT, frame, BOTTOMRIGHT, 3, 3)
    frame.outerShadow:SetCenterColor(0, 0, 0, 0)
    frame.outerShadow:SetEdgeColor(0, 0, 0, 0)
    frame.outerShadow:SetEdgeTexture(EDGE_FRAME_TEXTURE, 128, 16, 4, 0)
    frame.outerShadow:SetDrawLayer(DL_BACKGROUND)

    frame.border = WINDOW_MANAGER:CreateControl(nil, frame, CT_BACKDROP)
    frame.border:SetAnchorFill(frame)
    frame.border:SetCenterColor(0, 0, 0, 0)
    frame.border:SetEdgeColor(0, 0, 0, 1)
    frame.border:SetEdgeTexture(EDGE_FRAME_TEXTURE, 128, 16, 1, 0)
    frame.border:SetDrawLayer(DL_BACKGROUND)

    frame.track = WINDOW_MANAGER:CreateControl(nil, frame, CT_BACKDROP)
    frame.track:SetAnchorFill(frame)
    frame.track:SetCenterColor(0.01, 0.01, 0.01, 0.55)
    frame.track:SetEdgeColor(0, 0, 0, 0)
    frame.track:SetEdgeTexture("", 1, 1, 0)

    frame.innerShadow = WINDOW_MANAGER:CreateControl(nil, frame, CT_BACKDROP)
    frame.innerShadow:SetAnchorFill(frame.track)
    frame.innerShadow:SetCenterColor(0, 0, 0, 0)
    frame.innerShadow:SetEdgeColor(0, 0, 0, 0)
    frame.innerShadow:SetEdgeTexture(EDGE_FRAME_TEXTURE, 128, 16, 2, 0)
    frame.innerShadow:SetDrawLayer(DL_OVERLAY)

    return frame
end

local function CreateGloss(parent, resourceKey)
    local gloss = WINDOW_MANAGER:CreateControl(nil, parent, CT_STATUSBAR)
    gloss:SetAnchorFill(parent)
    local textureInfo = GetResourceTextureInfo(resourceKey)
    gloss:SetTexture(textureInfo.gloss)
    gloss:SetTextureCoords(unpack(textureInfo.coords))
    gloss:EnableLeadingEdge(false)
    gloss:SetColor(1, 1, 1, 0.13)
    gloss:SetMinMax(0, 1)
    gloss:SetValue(1)
    return gloss
end

local function GetBarTextSettings(key)
    local formatKey = key .. "TextFormat"
    local positionKey = key .. "TextPosition"
    local formatValue = NormalizeTextFormat(GetSettingValue(formatKey))
    local positionValue = NormalizeTextPosition(GetSettingValue(positionKey))
    return formatValue, positionValue
end

function ResourceBars:CreateResourceBar(key, data)
    local root = self:GetRoot()
    local frame = CreateBarFrame(root)
    frame.powerKey = key

    frame.bar = WINDOW_MANAGER:CreateControl(nil, frame.track, CT_STATUSBAR)
    frame.bar:SetAnchorFill(frame.track)
    ConfigureStatusBar(frame.bar, data, key)

    frame.patternBar = WINDOW_MANAGER:CreateControl(nil, frame.track, CT_STATUSBAR)
    frame.patternBar:SetAnchorFill(frame.track)
    frame.patternBar:EnableLeadingEdge(false)
    frame.patternBar:SetDrawLayer(DL_OVERLAY)
    frame.patternBar:SetDrawLevel(1)
    frame.patternBar:SetHidden(true)

    if key == "health" then
        frame.shieldBar = WINDOW_MANAGER:CreateControl(nil, frame.track, CT_STATUSBAR)
        SetStatusBarTextures(frame.shieldBar, GetBarTextureInfo("shieldTextureKey"))
        frame.shieldBar:SetColor(0.62, 0.84, 1.0, 0.34)
        frame.shieldBar:EnableLeadingEdge(false)
        frame.shieldBar:SetMinMax(0, 1)
        frame.shieldBar:SetValue(1)
        frame.shieldBar:SetDrawLayer(DL_OVERLAY)
    end

    frame.gloss = CreateGloss(frame.bar, key)
    SetResourceFillDirection(frame, key)

    frame.centerLabel = WINDOW_MANAGER:CreateControl(nil, frame, CT_LABEL)
    frame.centerLabel:SetAnchor(CENTER, frame, CENTER, 0, 0)
    frame.centerLabel:SetFont(BuildTextFont())
    frame.centerLabel:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    frame.centerLabel:SetVerticalAlignment(TEXT_ALIGN_CENTER)
    frame.centerLabel:SetColor(0.96, 0.92, 0.82, 1)
    frame.centerLabel:SetDrawLayer(DL_OVERLAY)
    frame.centerLabel:SetDrawLevel(3)

    frame.leftLabel = WINDOW_MANAGER:CreateControl(nil, frame, CT_LABEL)
    frame.leftLabel:SetAnchor(LEFT, frame, LEFT, 6, 0)
    frame.leftLabel:SetFont(BuildTextFont())
    frame.leftLabel:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    frame.leftLabel:SetVerticalAlignment(TEXT_ALIGN_CENTER)
    frame.leftLabel:SetColor(0.96, 0.92, 0.82, 1)
    frame.leftLabel:SetDrawLayer(DL_OVERLAY)
    frame.leftLabel:SetDrawLevel(3)

    frame.rightLabel = WINDOW_MANAGER:CreateControl(nil, frame, CT_LABEL)
    frame.rightLabel:SetAnchor(RIGHT, frame, RIGHT, -6, 0)
    frame.rightLabel:SetFont(BuildTextFont())
    frame.rightLabel:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
    frame.rightLabel:SetVerticalAlignment(TEXT_ALIGN_CENTER)
    frame.rightLabel:SetColor(0.96, 0.92, 0.82, 1)
    frame.rightLabel:SetDrawLayer(DL_OVERLAY)
    frame.rightLabel:SetDrawLevel(3)

    frame.data = data
    self.bars[key] = frame
    return frame
end

function ResourceBars:GetRoot()
    if self.root then
        return self.root
    end

    local root = WINDOW_MANAGER:CreateTopLevelWindow("Nirnsteel_UI_ResourceBarsRoot")
    root:SetDimensions(DEFAULT_ROW_WIDTH, (GetConfiguredBarHeight() * 2) + 5)
    root:SetClampedToScreen(true)
    root:SetMouseEnabled(false)
    root:SetMovable(false)
    root:SetDrawTier(DT_HIGH)
    root:SetHidden(true)
    self.root = root

    self.bars = {}
    self:CreateResourceBar("health", RESOURCE_DATA.health)
    self:CreateResourceBar("magicka", RESOURCE_DATA.magicka)
    self:CreateResourceBar("stamina", RESOURCE_DATA.stamina)

    return root
end

function ResourceBars:GetMover()
    if self.mover then
        return self.mover
    end

    local mover = WINDOW_MANAGER:CreateTopLevelWindow("Nirnsteel_UI_ResourceBarsMover")
    mover:SetDimensions(DEFAULT_ROW_WIDTH, (GetConfiguredBarHeight() * 2) + 5)
    mover:SetClampedToScreen(true)
    mover:SetMouseEnabled(true)
    mover:SetMovable(false)
    mover:SetDrawTier(DT_HIGH)
    mover:SetHidden(true)

    local backdrop = WINDOW_MANAGER:CreateControl(nil, mover, CT_BACKDROP)
    backdrop:SetAnchorFill(mover)
    backdrop:SetCenterColor(0.02, 0.02, 0.02, 0.32)
    backdrop:SetEdgeColor(0.85, 0.72, 0.25, 0.9)
    backdrop:SetEdgeTexture("", 1, 1, 2)

    local label = WINDOW_MANAGER:CreateControl(nil, mover, CT_LABEL)
    label:SetAnchor(CENTER, mover, CENTER, 0, 0)
    label:SetFont("ZoFontGameBold")
    label:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    label:SetText("Nirnsteel Resource Bars")
    label:SetColor(0.95, 0.86, 0.35, 1)

    mover:SetHandler("OnMouseDown", function(control, button)
        if button == MOUSE_BUTTON_INDEX_LEFT then
            control:SetMovable(true)
            control:StartMoving()
        else
            control:SetMovable(false)
        end
    end)

    mover:SetHandler("OnMouseUp", function(control, button)
        if button == MOUSE_BUTTON_INDEX_LEFT then
            control:StopMovingOrResizing()
        end
        control:SetMovable(false)
    end)

    mover:SetHandler("OnMoveStop", function(control)
        control:SetMovable(false)
        local x = control:GetLeft() + (control:GetWidth() * 0.5) - (GuiRoot:GetWidth() * 0.5)
        local y = control:GetTop() + (control:GetHeight() * 0.5) - (GuiRoot:GetHeight() * 0.5)
        if Nirnsteel_UI.Settings then
            Nirnsteel_UI.Settings:SetResourceBarsPosition(x, y)
        end
        self:ApplyLayout()
    end)

    self.mover = mover
    return mover
end

function ResourceBars:UpdateLabelLayout(frame, width, height)
    ApplyFrameStyle(frame, width, height)

    local textInset = ClampNumber(GetSettingValue("textInset"), 0, 24)
    local textVerticalOffset = ClampNumber(GetSettingValue("textVerticalOffset"), -8, 8)
    local labelWidth = frame.contentWidth or width
    local labelHeight = frame.contentHeight or height

    frame.layoutWidth = labelWidth
    frame.layoutHeight = labelHeight

    frame.centerLabel:ClearAnchors()
    frame.centerLabel:SetAnchor(CENTER, frame.track, CENTER, 0, textVerticalOffset)
    frame.centerLabel:SetDimensions(math.max(labelWidth - (textInset * 2), 10), labelHeight)

    frame.leftLabel:ClearAnchors()
    frame.leftLabel:SetAnchor(LEFT, frame.track, LEFT, textInset, textVerticalOffset)
    frame.leftLabel:SetDimensions(math.max(labelWidth * 0.5 - textInset, 10), labelHeight)

    frame.rightLabel:ClearAnchors()
    frame.rightLabel:SetAnchor(RIGHT, frame.track, RIGHT, -textInset, textVerticalOffset)
    frame.rightLabel:SetDimensions(math.max(labelWidth * 0.5 - textInset, 10), labelHeight)
end

function ResourceBars:GetResourceText(key)
    local state = self.state and self.state[key]
    local current = state and state.current or 0
    local effectiveMax = state and state.effectiveMax or state and state.maximum or 0
    local formatMode, position = GetBarTextSettings(key)
    local main = FormatByMode(current, effectiveMax, formatMode)
    local shieldMode
    local shieldValue = 0
    local shieldText = ""

    if key == "health" then
        shieldMode = NormalizeShieldTextMode(GetSettingValue("shieldTextMode"))
        shieldValue = self.shieldValue or 0
        if shieldValue > 0 then
            shieldText = ZO_AbbreviateAndLocalizeNumber(shieldValue, NUMBER_ABBREVIATION_PRECISION_TENTHS, USE_LOWERCASE_NUMBER_SUFFIXES)
        end
        if shieldMode == "shieldOnly" then
            main = zo_strformat("<<1>>", shieldText)
        elseif shieldMode == "healthAndShield" and shieldValue > 0 then
            main = string.format("%s [+%s]", main, shieldText)
        end
    end

    if position == "sides" then
        local numberText = FormatByMode(current, effectiveMax, "number")
        local percentText = FormatByMode(current, effectiveMax, "percent")
        local sideShieldText = ""
        if key == "health" and shieldMode == "shieldOnly" then
            numberText = shieldText
            percentText = ""
        elseif key == "health" and shieldMode == "healthAndShield" and shieldValue > 0 then
            sideShieldText = string.format(" [+%s]", shieldText)
        end

        if formatMode == "number" then
            return nil, numberText .. sideShieldText, ""
        elseif formatMode == "percent" then
            return nil, sideShieldText, percentText
        end
        return nil, numberText .. sideShieldText, percentText
    end

    return main, nil, nil
end

function ResourceBars:UpdateAllLabels()
    if not self.bars then
        return
    end

    self:ApplyTextStyle()

    for _, key in ipairs(BAR_ORDER) do
        local frame = self.bars[key]
        if frame then
            local centerText, leftText, rightText = self:GetResourceText(key)
            local _, position = GetBarTextSettings(key)
            if position == "sides" then
                frame.centerLabel:SetHidden(true)
                frame.leftLabel:SetHidden(false)
                frame.rightLabel:SetHidden(false)
                frame.leftLabel:SetText(leftText or "")
                frame.rightLabel:SetText(rightText or "")
            else
                frame.centerLabel:SetHidden(false)
                frame.leftLabel:SetHidden(true)
                frame.rightLabel:SetHidden(true)
                frame.centerLabel:SetText(centerText or "")
            end
        end
    end
end

function ResourceBars:ComputeLayoutMetrics()
    local barHeight = GetConfiguredBarHeight()
    local rowGap = GetRowSpacing()
    local colGap = GetColumnSpacing()
    local healthWidth = ClampNumber(GetSettingValue("rowHealthWidth"), MIN_HEALTH_WIDTH, MAX_ROW_WIDTH)
    local magickaWidth = ClampNumber(GetSettingValue("rowMagickaWidth"), MIN_RESOURCE_WIDTH, MAX_ROW_WIDTH)
    local staminaWidth = ClampNumber(GetSettingValue("rowStaminaWidth"), MIN_RESOURCE_WIDTH, MAX_ROW_WIDTH)
    local pyramidGap = colGap
    local bottomTotalWidth = magickaWidth + staminaWidth + pyramidGap
    local layoutWidth = math.max(healthWidth, bottomTotalWidth)

    return {
        barHeight = barHeight,
        width = layoutWidth,
        height = (barHeight * 2) + rowGap,
        rowGap = rowGap,
        pyramid = {
            healthWidth = healthWidth,
            magickaWidth = magickaWidth,
            staminaWidth = staminaWidth,
            bottomWidth = bottomTotalWidth,
            gap = pyramidGap,
        },
    }
end

function ResourceBars:ApplyTextStyle()
    if not self.bars then
        return
    end

    local font = BuildTextFont()
    local textAlpha = ClampNumber(GetSettingValue("textOpacity"), 10, 100) / 100
    local textColor = GetSettingValue("textColor") or DEFAULT_SETTINGS.textColor
    local textR = tonumber(textColor.r) or DEFAULT_SETTINGS.textColor.r
    local textG = tonumber(textColor.g) or DEFAULT_SETTINGS.textColor.g
    local textB = tonumber(textColor.b) or DEFAULT_SETTINGS.textColor.b

    for _, key in ipairs(BAR_ORDER) do
        local frame = self.bars[key]
        if frame then
            ApplyLabelTextStyle(frame.centerLabel, font, textR, textG, textB, textAlpha)
            ApplyLabelTextStyle(frame.leftLabel, font, textR, textG, textB, textAlpha)
            ApplyLabelTextStyle(frame.rightLabel, font, textR, textG, textB, textAlpha)
        end
    end
end

function ResourceBars:ApplyLayoutGeometry()
    if not self.bars then
        return
    end

    self.metrics = self:ComputeLayoutMetrics()
    local metrics = self.metrics

    local root = self:GetRoot()
    local mover = self:GetMover()

    root:SetDimensions(metrics.width, metrics.height)
    mover:SetDimensions(metrics.width, metrics.height)

    for _, key in ipairs(BAR_ORDER) do
        local frame = self.bars[key]
        SetResourceFillDirection(frame, key)
    end

    local p = metrics.pyramid
    local health = self.bars.health
    local magicka = self.bars.magicka
    local stamina = self.bars.stamina
    local healthCenterX = 0

    health:SetDimensions(p.healthWidth, metrics.barHeight)
    self:UpdateLabelLayout(health, p.healthWidth, metrics.barHeight)
    health:ClearAnchors()
    health:SetAnchor(TOP, root, TOP, healthCenterX, 0)

    magicka:SetDimensions(p.magickaWidth, metrics.barHeight)
    self:UpdateLabelLayout(magicka, p.magickaWidth, metrics.barHeight)
    magicka:ClearAnchors()
    magicka:SetAnchor(TOP, root, TOP, healthCenterX - ((p.staminaWidth + p.gap) * 0.5), metrics.barHeight + metrics.rowGap)

    stamina:SetDimensions(p.staminaWidth, metrics.barHeight)
    self:UpdateLabelLayout(stamina, p.staminaWidth, metrics.barHeight)
    stamina:ClearAnchors()
    stamina:SetAnchor(TOP, root, TOP, healthCenterX + ((p.magickaWidth + p.gap) * 0.5), metrics.barHeight + metrics.rowGap)

    for _, key in ipairs(BAR_ORDER) do
        local state = self.state and self.state[key]
        if state then
            self:UpdatePatternOverlay(self.bars[key], state.current or 0, state.maximum or 0)
        end
    end
end

function ResourceBars:ApplyLayout()
    local position = GetPosition()
    local scale = GetScale()
    local root = self:GetRoot()
    local mover = self:GetMover()

    self:ApplyLayoutGeometry()

    root:SetScale(scale)
    root:ClearAnchors()
    root:SetAnchor(CENTER, GuiRoot, CENTER, position.x, position.y)

    local health = self.state and self.state.health
    if health then
        self:UpdateHealthShieldOverlay(health.current or 0, health.maximum or 0)
    end

    mover:SetScale(scale)
    mover:ClearAnchors()
    mover:SetAnchor(CENTER, GuiRoot, CENTER, position.x, position.y)
    mover:SetHidden(not IsModuleUnlocked())
end

function ResourceBars:SetStockPlayerBarsHidden(hidden)
    if ZO_PlayerAttribute then
        local health = ZO_PlayerAttribute:GetNamedChild("Health")
        local magicka = ZO_PlayerAttribute:GetNamedChild("Magicka")
        local stamina = ZO_PlayerAttribute:GetNamedChild("Stamina")

        if health then
            health:SetHidden(hidden)
        end
        if magicka then
            magicka:SetHidden(hidden)
        end
        if stamina then
            stamina:SetHidden(hidden)
        end
    end
end

function ResourceBars:SetSettingsPreviewActive(active)
    self.settingsPreviewActive = active or nil
    if self.settingsPreviewActive then
        self:RefreshPowerValues(true)
        self:ApplyLayout()
    end
    self:UpdateVisibility()
end

function ResourceBars:UpdateVisibility()
    local root = self:GetRoot()
    if not IsModuleEnabled() then
        root:SetHidden(true)
        return
    end

    if self.settingsPreviewActive then
        root:SetHidden(false)
        return
    end

    if not IsHudSceneShowing() then
        root:SetHidden(true)
        return
    end

    local shouldShow = false
    for _, key in ipairs(BAR_ORDER) do
        local state = self.state and self.state[key]
        if state and ShouldShowResource(state.current, state.effectiveMax, state.fadeUntilMS) then
            shouldShow = true
            break
        end
    end

    root:SetHidden(not shouldShow)
end

function ResourceBars:UpdateBarValue(frame, current, maximum, instant)
    frame.bar:SetMinMax(0, maximum)
    if instant or not ZO_StatusBar_SmoothTransition then
        frame.bar:SetValue(current)
    else
        ZO_StatusBar_SmoothTransition(frame.bar, current, maximum)
    end

    self:UpdatePatternOverlay(frame, current, maximum)
end

function ResourceBars:UpdatePatternOverlay(frame, current, maximum)
    if not frame or not frame.patternBar then
        return
    end

    if not ShouldShowBarPattern() then
        frame.patternBar:SetHidden(true)
        return
    end

    local maxValue = tonumber(maximum) or 0
    local ratio = maxValue > 0 and zo_clamp((tonumber(current) or 0) / maxValue, 0, 1) or 0
    if ratio <= 0 then
        frame.patternBar:SetHidden(true)
        return
    end

    local trackWidth = frame.layoutWidth or frame:GetWidth()
    local trackHeight = frame.layoutHeight or frame:GetHeight()
    frame.patternWidth = trackWidth
    frame.patternBar:ClearAnchors()
    frame.patternBar:SetAnchorFill(frame.track)
    frame.patternBar:SetDimensions(trackWidth, trackHeight)
    frame.patternBar:SetMinMax(0, maxValue)
    frame.patternBar:SetValue(tonumber(current) or 0)
    UpdatePatternTexture(frame)
end

function ResourceBars:UpdateHealthShieldOverlay(_healthCurrent, healthMax)
    local frame = self.bars and self.bars.health
    if not frame or not frame.shieldBar then
        return
    end

    if not ShouldShowShieldOverlay() then
        frame.shieldBar:SetHidden(true)
        return
    end

    local shield = self.shieldValue or 0
    local maxHealth = tonumber(healthMax) or 0
    local shieldRatio = maxHealth > 0 and zo_clamp(shield / maxHealth, 0, 1) or 0
    frame.shieldBar:SetHidden(shieldRatio <= 0)
    if shieldRatio <= 0 then
        return
    end

    local trackWidth = frame.layoutWidth or frame:GetWidth()
    local trackHeight = frame.layoutHeight or frame:GetHeight()

    local shieldWidth = math.max(trackWidth * shieldRatio, 1)
    frame.shieldBar:ClearAnchors()
    frame.shieldBar:SetAnchor(CENTER, frame.track, CENTER, 0, 0)
    frame.shieldBar:SetDimensions(shieldWidth, trackHeight)
end

function ResourceBars:UpdateResource(key, current, maximum, effectiveMax, instant)
    self.state = self.state or {}
    self.state[key] = self.state[key] or {}
    self.state[key].current = current
    self.state[key].maximum = maximum
    self.state[key].effectiveMax = effectiveMax or maximum
    self.state[key].fadeUntilMS = GetFrameTimeMilliseconds() + VISIBILITY_HOLD_MS

    local frame = self.bars and self.bars[key]
    if not frame then
        return
    end

    self:UpdateBarValue(frame, current, maximum, instant or key == "health")
    if key == "health" then
        self:UpdateHealthShieldOverlay(current, maximum)
    end

    self:ApplyLayout()
    self:UpdateAllLabels()
    self:UpdateVisibility()
end

function ResourceBars:RefreshPowerValues(instant)
    self:GetRoot()
    for key, data in pairs(RESOURCE_DATA) do
        local current, maximum, effectiveMax = GetUnitPower("player", data.powerType)
        self:UpdateResource(key, current, maximum, effectiveMax, instant)
    end
    self:RefreshShieldState(true)
    self:UpdateAllLabels()
end

function ResourceBars:OnPowerUpdate(unitTag, powerIndex, powerType, current, maximum, effectiveMax)
    if unitTag ~= "player" then
        return
    end

    local key = POWER_KEY_BY_TYPE[powerType]
    if not key then
        return
    end

    self:UpdateResource(key, current, maximum, effectiveMax, false)
end

function ResourceBars:RefreshShieldState(force)
    local value, maxValue, sequenceId = GetUnitAttributeVisualizerEffectInfo("player", ATTRIBUTE_VISUAL_POWER_SHIELDING, STAT_MITIGATION, ATTRIBUTE_HEALTH, COMBAT_MECHANIC_FLAGS_HEALTH)
    self.shieldValue = math.max(tonumber(value) or 0, 0)
    self.shieldMax = math.max(tonumber(maxValue) or 0, 0)
    self.shieldSequenceId = sequenceId or self.shieldSequenceId

    local health = self.state and self.state.health
    if health then
        self:UpdateHealthShieldOverlay(health.current or 0, health.maximum or 0)
    end

    if force then
        self:UpdateAllLabels()
    end
end

function ResourceBars:OnShieldVisualAdded(unitTag, visualType, statType, attributeType, powerType, value, maxValue, sequenceId)
    if unitTag ~= "player" or visualType ~= ATTRIBUTE_VISUAL_POWER_SHIELDING or attributeType ~= ATTRIBUTE_HEALTH then
        return
    end

    self.shieldValue = math.max((self.shieldValue or 0) + (tonumber(value) or 0), 0)
    self.shieldMax = math.max((self.shieldMax or 0) + (tonumber(maxValue) or 0), 0)
    self.shieldSequenceId = sequenceId or self.shieldSequenceId
    self:RefreshShieldState(true)
end

function ResourceBars:OnShieldVisualUpdated(unitTag, visualType, statType, attributeType, powerType, oldValue, newValue, oldMaxValue, newMaxValue, sequenceId)
    if unitTag ~= "player" or visualType ~= ATTRIBUTE_VISUAL_POWER_SHIELDING or attributeType ~= ATTRIBUTE_HEALTH then
        return
    end

    self.shieldValue = math.max((self.shieldValue or 0) + ((tonumber(newValue) or 0) - (tonumber(oldValue) or 0)), 0)
    self.shieldMax = math.max((self.shieldMax or 0) + ((tonumber(newMaxValue) or 0) - (tonumber(oldMaxValue) or 0)), 0)
    self.shieldSequenceId = sequenceId or self.shieldSequenceId
    self:RefreshShieldState(true)
end

function ResourceBars:OnShieldVisualRemoved(unitTag, visualType, statType, attributeType, powerType, value, maxValue, sequenceId)
    if unitTag ~= "player" or visualType ~= ATTRIBUTE_VISUAL_POWER_SHIELDING or attributeType ~= ATTRIBUTE_HEALTH then
        return
    end

    self.shieldValue = math.max((self.shieldValue or 0) - (tonumber(value) or 0), 0)
    self.shieldMax = math.max((self.shieldMax or 0) - (tonumber(maxValue) or 0), 0)
    self.shieldSequenceId = sequenceId or self.shieldSequenceId
    self:RefreshShieldState(true)
end

function ResourceBars:RegisterEvents()
    if self.eventsRegistered then
        return
    end

    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_POWER_UPDATE, function(_, ...)
        self:OnPowerUpdate(...)
    end)
    EVENT_MANAGER:AddFilterForEvent(EVENT_NAMESPACE, EVENT_POWER_UPDATE, REGISTER_FILTER_UNIT_TAG, "player")

    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE .. "_ShieldAdded", EVENT_UNIT_ATTRIBUTE_VISUAL_ADDED, function(_, ...)
        self:OnShieldVisualAdded(...)
    end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE .. "_ShieldUpdated", EVENT_UNIT_ATTRIBUTE_VISUAL_UPDATED, function(_, ...)
        self:OnShieldVisualUpdated(...)
    end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE .. "_ShieldRemoved", EVENT_UNIT_ATTRIBUTE_VISUAL_REMOVED, function(_, ...)
        self:OnShieldVisualRemoved(...)
    end)

    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE .. "_Activated", EVENT_PLAYER_ACTIVATED, function()
        self:RefreshPowerValues(true)
        self:ApplyLayout()
        self:SetStockPlayerBarsHidden(IsModuleEnabled())
    end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE .. "_SettingsChanged", EVENT_INTERFACE_SETTING_CHANGED, function(_, settingType, settingId)
        if settingType == SETTING_TYPE_UI
            and (settingId == UI_SETTING_SHOW_RESOURCE_BARS
                or settingId == UI_SETTING_FADE_PLAYER_BARS
                or settingId == UI_SETTING_RESOURCE_NUMBERS) then
            self:RefreshPowerValues(true)
            self:UpdateVisibility()
        end
    end)
    EVENT_MANAGER:AddFilterForEvent(EVENT_NAMESPACE .. "_SettingsChanged", EVENT_INTERFACE_SETTING_CHANGED, REGISTER_FILTER_SETTING_SYSTEM_TYPE, SETTING_TYPE_UI)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE .. "_ScreenResized", EVENT_SCREEN_RESIZED, function()
        self:ApplyLayout()
    end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE .. "_Gamepad", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function()
        self:ApplyLayout()
    end)

    if HUD_SCENE then
        HUD_SCENE:RegisterCallback("StateChange", function()
            self:UpdateVisibility()
            self:SetStockPlayerBarsHidden(IsModuleEnabled())
        end)
    end

    if HUD_UI_SCENE then
        HUD_UI_SCENE:RegisterCallback("StateChange", function()
            self:UpdateVisibility()
            self:SetStockPlayerBarsHidden(IsModuleEnabled())
        end)
    end

    self.eventsRegistered = true
end

function ResourceBars:RefreshSettings()
    self:RegisterEvents()
    self:ApplyTextStyle()
    self:ApplyLayout()

    if IsModuleEnabled() then
        self:SetStockPlayerBarsHidden(true)
        self:RefreshPowerValues(true)
    else
        self:SetStockPlayerBarsHidden(false)
        self:GetRoot():SetHidden(true)
        self:GetMover():SetHidden(true)
    end
end

local function RegisterDebugCommands()
    SLASH_COMMANDS["/nsbars"] = function()
        ResourceBars:RefreshPowerValues(true)
        ResourceBars:ApplyLayout()
    end
end

local function OnAddOnLoaded(_, addonName)
    if addonName ~= ADDON_NAME then
        return
    end

    EVENT_MANAGER:UnregisterForEvent(EVENT_NAMESPACE .. "_Loaded", EVENT_ADD_ON_LOADED)
    ResourceBars:RefreshSettings()
    RegisterDebugCommands()
    zo_callLater(function() ResourceBars:RefreshSettings() end, 1000)
end

EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE .. "_Loaded", EVENT_ADD_ON_LOADED, OnAddOnLoaded)

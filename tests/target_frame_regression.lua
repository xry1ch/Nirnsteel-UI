-- Focused Lua 5.1 regression checks for modules/target_frame.lua.
-- Run from the addon root with: lua51.exe tests/target_frame_regression.lua

local function fail(message)
    error(message, 2)
end

local function expect(condition, message)
    if not condition then
        fail(message)
    end
end

local function noop()
end

local function NewControl(height)
    local control =
    {
        height = height or 24,
        width = 0,
        hidden = false,
        text = "",
    }

    function control:SetText(text)
        self.text = text or ""
    end

    function control:GetTextWidth()
        return self.width
    end

    function control:GetStringWidth(text)
        return string.len(text or "") * 10
    end

    function control:SetDimensions(width, newHeight)
        self.width = width
        self.height = newHeight
    end

    function control:GetWidth()
        return self.width
    end

    function control:GetHeight()
        return self.height
    end

    function control:SetHidden(hidden)
        self.hidden = hidden == true
    end

    function control:IsHidden()
        return self.hidden
    end

    function control:SetTexture(texture)
        self.texture = texture
    end

    function control:SetColor(...)
        self.color = { ... }
    end

    function control:SetHorizontalAlignment(alignment)
        self.horizontalAlignment = alignment
    end

    function control:ClearAnchors()
        self.anchor = nil
    end

    function control:SetAnchor(...)
        self.anchor = { ... }
    end

    function control:SetHandler(name, handler)
        self.handlers = self.handlers or {}
        self.handlers[name] = handler
    end

    function control:SetScale(scale)
        self.scale = scale
    end

    return control
end

COMBAT_MECHANIC_FLAGS_HEALTH = 1
ALLIANCE_NONE = 0
ALLIANCE_ALDMERI_DOMINION = 1
TARGET_MARKER_TYPE_NONE = 0
ATTRIBUTE_VISUAL_POWER_SHIELDING = 1
STAT_MITIGATION = 1
ATTRIBUTE_HEALTH = 1
BAR_ALIGNMENT_NORMAL = 1
NUMBER_ABBREVIATION_PRECISION_TENTHS = 1
USE_LOWERCASE_NUMBER_SUFFIXES = true
SI_UNIT_NAME = 1
LEFT = 1
CENTER = 2
TOPLEFT = 3
TOP = 4
BOTTOMRIGHT = 5
zo_strformat = function(_, value)
    return "unexpected-format:" .. tostring(value)
end

local nextEventCode = 100
local function DefineEvent(name)
    nextEventCode = nextEventCode + 1
    _G[name] = nextEventCode
end

local eventNames =
{
    "EVENT_ADD_ON_LOADED",
    "EVENT_RETICLE_TARGET_CHANGED",
    "EVENT_RETICLE_TARGET_PLAYER_CHANGED",
    "EVENT_RETICLE_TARGET_COMPANION_CHANGED",
    "EVENT_TARGET_CHANGED",
    "EVENT_UNIT_CREATED",
    "EVENT_UNIT_DESTROYED",
    "EVENT_UNIT_CHARACTER_NAME_CHANGED",
    "EVENT_POWER_UPDATE",
    "EVENT_DISPOSITION_UPDATE",
    "EVENT_LEVEL_UPDATE",
    "EVENT_CHAMPION_POINT_UPDATE",
    "EVENT_TITLE_UPDATE",
    "EVENT_UNIT_DEATH_STATE_CHANGED",
    "EVENT_UNIT_ATTRIBUTE_VISUAL_ADDED",
    "EVENT_UNIT_ATTRIBUTE_VISUAL_UPDATED",
    "EVENT_UNIT_ATTRIBUTE_VISUAL_REMOVED",
    "EVENT_TARGET_MARKER_UPDATE",
    "EVENT_RANK_POINT_UPDATE",
    "EVENT_PLAYER_ACTIVATED",
    "EVENT_GAME_CAMERA_UI_MODE_CHANGED",
    "EVENT_RETICLE_HIDDEN_UPDATE",
    "EVENT_SCREEN_RESIZED",
    "EVENT_GAMEPAD_PREFERRED_MODE_CHANGED",
}

for _, eventName in ipairs(eventNames) do
    DefineEvent(eventName)
end

local registrations = {}
local eventHandlers = {}
local updateRegistrations = {}
EVENT_MANAGER =
{
    RegisterForEvent = function(_, namespace, eventCode, handler)
        registrations[eventCode] = (registrations[eventCode] or 0) + 1
        eventHandlers[eventCode] = handler
    end,
    UnregisterForEvent = noop,
    RegisterForUpdate = function(_, namespace, interval, handler)
        updateRegistrations[namespace] = { interval = interval, handler = handler }
    end,
    UnregisterForUpdate = function(_, namespace)
        updateRegistrations[namespace] = nil
    end,
}

local scheduled = {}
zo_callLater = function(callback, delay)
    scheduled[#scheduled + 1] = { callback = callback, delay = delay }
end

zo_round = function(value)
    return math.floor((tonumber(value) or 0) + 0.5)
end

local nowMS = 1000
GetFrameTimeMilliseconds = function()
    return nowMS
end

IsInGamepadPreferredMode = function()
    return false
end

local settings =
{
    enabled = true,
    unlocked = false,
    width = 300,
    nameTextSize = 20,
    textOpacity = 100,
    showClass = true,
    showLevel = true,
    showLevelStyle = true,
    showVeterancyIcon = false,
}

local BarVisuals =
{
    Fonts = { gameSmall = "mock-font" },
    Textures = { genericTall = "mock-texture" },
    Patterns = { smoke = "mock-pattern" },
    HideFeedback = noop,
    StopLossTrail = noop,
    SetShield = noop,
    SetValue = function(_, frame, current, maximum, smooth, animateLoss)
        frame.valueCalls = frame.valueCalls or {}
        frame.valueCalls[#frame.valueCalls + 1] =
        {
            current = current,
            maximum = maximum,
            smooth = smooth,
            animateLoss = animateLoss,
        }
    end,
    PlayFeedback = noop,
}

local LevelVisuals =
{
    SHIMMER_CADENCE_MS = 8000,
    Apply = function(_, badge, data, options)
        badge.lastData = data
        badge.lastOptions = options
        badge.control:SetHidden(not options.shown)
        if not options.shown then
            return 0, nil
        end
        return data.champion and 63 or 34, 1
    end,
    Stop = noop,
    Play = noop,
}

Nirnsteel_UI =
{
    BarVisuals = BarVisuals,
    LevelVisuals = LevelVisuals,
    Settings =
    {
        GetTargetFrame = function()
            return settings
        end,
    },
}

-- Exercise the preferred platform-aware helper directly. The valid fallback
-- helpers are intentionally absent so they cannot mask this path.
ZO_GetPlatformClassIcon = function(classId)
    return string.format("EsoUI/mock/class_%d.dds", classId)
end
ZO_GetClassIcon = nil
GetClassIcon = nil

assert(loadfile("modules/target_frame.lua"))()
local TargetFrame = Nirnsteel_UI.TargetFrame

TargetFrame.identity = NewControl(24)
TargetFrame.identityContent = NewControl(24)
TargetFrame.nameLabel = NewControl(24)
TargetFrame.targetMarker = NewControl(18)
TargetFrame.classIcon = NewControl(20)
TargetFrame.rankIcon = NewControl(18)
TargetFrame.levelBadge = { control = NewControl(24) }
TargetFrame.health = NewControl(25)

local playerData =
{
    name = "@WolfswoAccount",
    isPlayer = true,
    classId = 2,
    classIcon = nil,
    level = 50,
    champion = true,
    championPoints = 2334,
    marker = TARGET_MARKER_TYPE_NONE,
    alliance = ALLIANCE_ALDMERI_DOMINION,
}

TargetFrame:UpdateIdentity(playerData)
expect(TargetFrame.classIcon.hidden == false, "player class icon must be visible")
expect(TargetFrame.classIcon.texture == "EsoUI/mock/class_2.dds",
    "player class icon must use ESO's supported platform helper")
expect(TargetFrame.nameLabel.text == "@WolfswoAccount", "player name must not be rewritten")
expect(TargetFrame.nameLabel.width == 154,
    "player name width must come from intrinsic string measurement, not its previous box")
expect(TargetFrame.identityContent.width == 249,
    "class, name, and level must form one compact centered cluster")
expect(TargetFrame.classIcon.anchor[4] == 0, "the class icon must start the centered identity row")
expect(TargetFrame.levelBadge.control.anchor[4] == 186,
    "level badge must follow the class and name using the configured compact gaps")
expect(TargetFrame.classIcon.anchor[5] == -2,
    "the class icon must use the shared optical centerline")
expect(TargetFrame.levelBadge.control.anchor[5] == -1,
    "the level badge and number must use the shared optical centerline")

-- GetUnitAvARank returns rank and sub-rank. The second return must never leak
-- into tonumber as its optional base argument (which crashes player renders).
settings.showVeterancyIcon = true
GetUnitAvARank = function()
    return 20, 99
end
GetAvARankIcon = function(rank)
    return string.format("EsoUI/mock/rank_%d.dds", rank)
end
TargetFrame:UpdateIdentity(playerData)
expect(TargetFrame.rankIcon.hidden == false, "enabled player rank icon must render")
expect(TargetFrame.rankIcon.texture == "EsoUI/mock/rank_20.dds",
    "player rank rendering must use only the first GetUnitAvARank return value")
expect(TargetFrame.identityContent.width == 273,
    "the rank icon must extend the centered cluster by one compact slot")
expect(TargetFrame.rankIcon.anchor[4] == 255,
    "the rank icon must follow the level badge with the configured gap")

ZO_GetPlatformTargetMarkerIcon = function(markerType)
    return string.format("EsoUI/mock/marker_%d.dds", markerType)
end

-- Every visibility combination must retain deterministic geometry. The marker
-- is intentionally excluded because it belongs to the bar corner, not the row.
local toggleValues = { false, true }
for _, showClass in ipairs(toggleValues) do
    for _, showLevel in ipairs(toggleValues) do
        for _, showRank in ipairs(toggleValues) do
            for _, showMarker in ipairs(toggleValues) do
                settings.showClass = showClass
                settings.showLevel = showLevel
                settings.showVeterancyIcon = showRank
                playerData.marker = showMarker and 3 or TARGET_MARKER_TYPE_NONE
                TargetFrame:UpdateIdentity(playerData)

                local expectedWidth = 154
                if showClass then
                    expectedWidth = expectedWidth + 18 + 6
                end
                if showLevel then
                    expectedWidth = expectedWidth + 8 + 63
                end
                if showRank then
                    expectedWidth = expectedWidth + (showLevel and 6 or 8) + 18
                end
                expect(TargetFrame.identityContent.width == expectedWidth,
                    "identity width must depend only on class, name, level, and rank")
                expect(TargetFrame.classIcon.hidden == not showClass,
                    "class visibility must follow its setting")
                expect(TargetFrame.levelBadge.control.hidden == not showLevel,
                    "level visibility must follow its setting")
                expect(TargetFrame.rankIcon.hidden == not showRank,
                    "rank visibility must follow its setting")
                expect(TargetFrame.targetMarker.hidden == not showMarker,
                    "marker visibility must follow target data")
                if showClass then
                    expect(TargetFrame.classIcon.anchor[5] == -2,
                        "class icons must remain optically centered in every layout")
                end
                if showLevel then
                    expect(TargetFrame.levelBadge.control.anchor[5] == -1,
                        "level badges must remain optically centered in every layout")
                end
                if showRank then
                    expect(TargetFrame.rankIcon.anchor[5] == -2,
                        "rank icons must share the class icon centerline")
                end
                if showMarker then
                    expect(TargetFrame.targetMarker.anchor[1] == BOTTOMRIGHT
                        and TargetFrame.targetMarker.anchor[2] == TargetFrame.health
                        and TargetFrame.targetMarker.anchor[3] == TOPLEFT
                        and TargetFrame.targetMarker.anchor[4] == -2
                        and TargetFrame.targetMarker.anchor[5] == -2,
                        "the target marker must stay outside the bar's upper-left corner")
                end
            end
        end
    end
end

-- At minimum bar width, the complete one-line identity may grow beyond the bar
-- rather than shortening the target's name.
settings.width = 180
settings.showClass = true
settings.showLevel = true
settings.showVeterancyIcon = true
TargetFrame.health:SetDimensions(settings.width, 25)
local longNameData = {}
for key, value in pairs(playerData) do
    longNameData[key] = value
end
longNameData.name = "@AnExtremelyLongPlayerDisplayName"
longNameData.marker = 3
TargetFrame:UpdateIdentity(longNameData)
local expectedLongNameWidth = string.len(longNameData.name) * 10 + 4
expect(TargetFrame.nameLabel.text == longNameData.name,
    "long player names must remain unchanged")
expect(TargetFrame.nameLabel.width == expectedLongNameWidth,
    "long player names must retain their complete intrinsic width")
expect(TargetFrame.identityContent.width == expectedLongNameWidth + 119,
    "the decorated identity cluster must expand beyond a narrow bar")
expect(TargetFrame.identityContent.width > settings.width,
    "identity overflow must not resize or constrain the configured bar width")
expect(TargetFrame.health.width == settings.width,
    "expanding the identity header must leave the configured health bar width unchanged")
expect(TargetFrame.levelBadge.control.anchor[4] == expectedLongNameWidth + 32,
    "the level badge must follow the complete player name")
expect(TargetFrame.rankIcon.anchor[4] == expectedLongNameWidth + 101,
    "the rank icon must follow the complete player name and level")

-- NPCs use the same centered row without player-only slots.
settings.width = 300
local npcData =
{
    name = "The Precursor",
    isPlayer = false,
    classId = 0,
    classIcon = nil,
    level = 50,
    champion = false,
    championPoints = 0,
    marker = TARGET_MARKER_TYPE_NONE,
    alliance = ALLIANCE_NONE,
}
TargetFrame:UpdateIdentity(npcData)
expect(TargetFrame.identityContent.width == 176,
    "NPC name and level must form their own centered compact cluster")
expect(TargetFrame.classIcon.hidden == true and TargetFrame.rankIcon.hidden == true,
    "NPC layouts must omit player-only icon slots")
expect(TargetFrame.levelBadge.control.anchor[4] == 142,
    "the NPC level must sit directly after its name")

-- Multibyte localized names use the same full-width header behavior.
settings.width = 180
npcData.name = "Стражник Дома"
TargetFrame:UpdateIdentity(npcData)
local expectedLocalizedNameWidth = string.len(npcData.name) * 10 + 4
expect(TargetFrame.nameLabel.text == npcData.name,
    "localized NPC names must remain unchanged")
expect(TargetFrame.nameLabel.width == expectedLocalizedNameWidth,
    "localized NPC names must retain their complete intrinsic width")
expect(TargetFrame.identityContent.width == expectedLocalizedNameWidth + 42,
    "localized NPC identity clusters must expand beyond a narrow bar")
expect(TargetFrame.identityContent.width > settings.width,
    "localized names must not be capped to the configured bar width")
expect(TargetFrame.levelBadge.control.anchor[4] == expectedLocalizedNameWidth + 8,
    "the NPC level must follow the complete localized name")

-- The title row was removed. Font extremes must now produce deterministic
-- geometry from only the identity row, fixed gap, and bar.
settings.width = 300
local layoutRoot = NewControl(1)
local layoutMover = NewControl(1)
TargetFrame.root = layoutRoot
TargetFrame.rootReady = true
TargetFrame.mover = layoutMover
TargetFrame.moverReady = true
settings.nameTextSize = 20
settings.barHeight = 25
settings.scale = 100
TargetFrame:ApplyLayout(playerData)
expect(layoutRoot.width == 300 and layoutRoot.height == 53,
    "default layout must use a 24px identity row, 4px gap, and 25px bar")
expect(TargetFrame.health.anchor[5] == 28,
    "the title-free layout must retain the fixed header-to-bar gap")

settings.width = 700
settings.nameTextSize = 36
settings.barHeight = 48
settings.scale = 160
TargetFrame:ApplyLayout(playerData)
expect(layoutRoot.width == 700 and layoutRoot.height == 92 and layoutRoot.scale == 1.6,
    "maximum font, size, and scale settings must retain deterministic geometry")
expect(TargetFrame.health.anchor[5] == 44,
    "large fonts must expand rows without misaligning the bar")

settings.width = 300
settings.nameTextSize = 20
settings.barHeight = 25
settings.scale = 100
settings.showClass = true
settings.showLevel = true
settings.showVeterancyIcon = false
playerData.marker = TARGET_MARKER_TYPE_NONE

TargetFrame.eventsRegistered = nil
TargetFrame:RegisterEvents()
expect(registrations[EVENT_RETICLE_TARGET_CHANGED], "reticle target changes must be observed")
expect(registrations[EVENT_RETICLE_TARGET_PLAYER_CHANGED],
    "the dedicated player-reticle lifecycle must be observed")
expect(registrations[EVENT_UNIT_CREATED], "reticleover unit creation must be observed")
expect(registrations[EVENT_UNIT_DESTROYED], "reticleover unit destruction must be observed")
expect(registrations[EVENT_UNIT_CHARACTER_NAME_CHANGED],
    "late player character-name availability must be observed")
expect(not registrations[EVENT_TITLE_UPDATE],
    "title updates must not be observed after removing titles from the frame")
expect(not registrations[EVENT_TARGET_CHANGED],
    "EVENT_TARGET_CHANGED tracks the target's own target and must not rebuild reticleover")

local originalQueueTargetReadinessRefresh = TargetFrame.QueueTargetReadinessRefresh
local readinessRequests = {}
TargetFrame.QueueTargetReadinessRefresh = function()
    readinessRequests[#readinessRequests + 1] = true
end
eventHandlers[EVENT_UNIT_CREATED](EVENT_UNIT_CREATED, "group1")
expect(#readinessRequests == 0, "unit readiness events must ignore unrelated unit tags")
eventHandlers[EVENT_UNIT_CREATED](EVENT_UNIT_CREATED, "reticleover")
eventHandlers[EVENT_UNIT_CHARACTER_NAME_CHANGED](EVENT_UNIT_CHARACTER_NAME_CHANGED, "reticleover")
eventHandlers[EVENT_UNIT_CREATED](EVENT_UNIT_CREATED, "reticleoverplayer")
expect(#readinessRequests == 3,
    "reticleover and reticleoverplayer readiness events must both request reconciliation")
TargetFrame.QueueTargetReadinessRefresh = originalQueueTargetReadinessRefresh

local generalTargetExists = false
local playerTargetExists = false
local titleReadCount = 0
DoesUnitExist = function(unitTag)
    return (unitTag == "reticleover" and generalTargetExists)
        or (unitTag == "reticleoverplayer" and playerTargetExists)
end
GetUnitPower = function()
    return 31000, 40000
end
IsUnitPlayer = function()
    return true
end
IsUnitChampion = function()
    return true
end
GetUnitEffectiveChampionPoints = function()
    return 2334
end
GetUnitClassId = function()
    return 2
end
GetUnitClass = function()
    return "Sorcerer"
end
GetUnitTitle = function()
    titleReadCount = titleReadCount + 1
    return "Unused Title"
end
GetUnitLevel = function()
    return 50
end
ZO_GetPrimaryPlayerNameFromUnitTag = function()
    return "@WolfswoAccount"
end
IsUnitDead = function()
    return false
end
IsUnitAttackable = function()
    return true
end
GetUnitAlliance = function()
    return ALLIANCE_ALDMERI_DOMINION
end
GetUnitTargetMarkerType = function()
    return TARGET_MARKER_TYPE_NONE
end

local root = NewControl(64)
local mover = NewControl(64)
TargetFrame.root = root
TargetFrame.mover = mover
TargetFrame.GetRoot = function()
    return root
end
TargetFrame.GetMover = function()
    return mover
end
TargetFrame.ApplyLayout = function()
    return 300, 25
end
TargetFrame.ApplyStyle = noop
TargetFrame.UpdateFeedback = noop
TargetFrame.UpdateText = noop
TargetFrame.UpdateExecute = noop
TargetFrame.UpdateVisibility = function(self)
    root:SetHidden(self.currentData == nil)
end
TargetFrame.health = NewControl(25)
TargetFrame.currentData = nil
TargetFrame.lastLiveData = nil
TargetFrame.targetIdentity = nil
TargetFrame.settingsPreviewActive = nil
TargetFrame.debugPreviewMode = nil

-- New targets must always snap even if they were first discovered through a
-- non-instant power update. Only later updates for the same identity may use
-- the normal smooth health animation.
local transitionData =
{
    name = "First Target", isPlayer = false, classId = 0, classIcon = nil,
    level = 50, champion = false, championPoints = 0,
    current = 40000, maximum = 40000, shield = 0,
    dead = false, attackable = true, alliance = ALLIANCE_NONE,
    marker = TARGET_MARKER_TYPE_NONE,
}
TargetFrame:ApplyTargetData(transitionData, false)
local firstValueCall = TargetFrame.health.valueCalls[#TargetFrame.health.valueCalls]
expect(firstValueCall.smooth == false and firstValueCall.animateLoss == false,
    "a newly acquired target must snap without fill or loss animations")

transitionData.current = 30000
TargetFrame:ApplyTargetData(transitionData, false)
local sameTargetValueCall = TargetFrame.health.valueCalls[#TargetFrame.health.valueCalls]
expect(sameTargetValueCall.smooth == true,
    "later health updates for the same target may retain smooth animation")

transitionData.name = "Second Target"
TargetFrame:ApplyTargetData(transitionData, false)
local changedTargetValueCall = TargetFrame.health.valueCalls[#TargetFrame.health.valueCalls]
expect(changedTargetValueCall.smooth == false and changedTargetValueCall.animateLoss == false,
    "changing identity through a power update must cancel smoothing")
TargetFrame:ApplyTargetData(nil, true)
TargetFrame.health.valueCalls = {}

scheduled = {}
TargetFrame:RefreshChangedTarget()
expect(TargetFrame.currentData == nil, "a not-yet-created reticle unit should initially remain absent")
expect(#scheduled >= 3, "target changes must schedule multiple readiness retries")
local longestDelay = 0
for _, pending in ipairs(scheduled) do
    longestDelay = math.max(longestDelay, pending.delay or 0)
end
expect(longestDelay >= 250, "target readiness retries must cover at least 250ms")

table.sort(scheduled, function(left, right)
    return left.delay < right.delay
end)
generalTargetExists = true
scheduled[1].callback()
expect(TargetFrame.currentData ~= nil, "a late-created player target must appear on a scheduled retry")
expect(TargetFrame.currentData.name == "@WolfswoAccount", "late-created player name must be retained")

for index = 2, #scheduled do
    scheduled[index].callback()
end
expect(TargetFrame.currentData.title == nil and titleReadCount == 0,
    "removed player titles must neither be stored nor queried")
expect(root.hidden == false, "the target frame must be visible after target readiness catches up")

-- Players can exist exclusively through reticleoverplayer. This was the main
-- live failure: the overhead player name existed while the custom frame had no
-- reticleover model and stayed hidden.
generalTargetExists = false
playerTargetExists = true
TargetFrame:ApplyTargetData(nil, true)
TargetFrame:RefreshTarget(true)
expect(TargetFrame.currentData ~= nil, "a reticleoverplayer-only target must be acquired")
expect(TargetFrame.currentData.unitTag == "reticleoverplayer",
    "the dedicated player tag must become the resource source when reticleover is absent")
expect(TargetFrame.currentData.metadataUnitTag == "reticleoverplayer",
    "the dedicated player tag must provide player identity metadata")
expect(TargetFrame.currentData.classId == 2, "player-only acquisition must populate class metadata")
expect(TargetFrame.classIcon.hidden == false, "player-only acquisition must render its class icon")

-- When both aliases identify the same player, prefer the richer player alias
-- but fill any temporarily missing field from reticleover independently.
generalTargetExists = true
playerTargetExists = true
AreUnitsEqual = function(firstTag, secondTag)
    return firstTag == "reticleover" and secondTag == "reticleoverplayer"
end
GetUnitClassId = function(unitTag)
    return unitTag == "reticleoverplayer" and 0 or 2
end
TargetFrame:RefreshTarget(true)
expect(TargetFrame.currentData.metadataUnitTag == "reticleoverplayer",
    "matching player aliases must select reticleoverplayer for identity")
expect(TargetFrame.currentData.fallbackMetadataUnitTag == "reticleover",
    "matching player aliases must retain reticleover as a metadata fallback")
expect(TargetFrame.currentData.classId == 2,
    "a temporarily empty player-alias class must fall back to reticleover")

-- Before equality/name data is ready, a confirmed player on reticleover may
-- provisionally fill empty metadata from reticleoverplayer. Once both tags
-- have distinct stable names, that fallback must be rejected as stale.
AreUnitsEqual = function()
    return false
end
GetRawUnitName = nil
GetUnitName = nil
GetUnitDisplayName = nil
GetUnitClassId = function(unitTag)
    return unitTag == "reticleoverplayer" and 2 or 0
end
TargetFrame:RefreshTarget(true)
expect(TargetFrame.currentData.metadataUnitTag == "reticleover",
    "an unmatched primary player must remain the preferred identity source")
expect(TargetFrame.currentData.fallbackMetadataUnitTag == "reticleoverplayer",
    "an identity-not-ready player alias must remain available as provisional metadata fallback")
expect(TargetFrame.currentData.classId == 2,
    "provisional player metadata must fill class until tag identity becomes available")

GetRawUnitName = function(unitTag)
    return unitTag == "reticleover" and "Current Player^Mx" or "Stale Player^Fx"
end
GetUnitClassId = function(unitTag)
    return unitTag == "reticleoverplayer" and 3 or 2
end
TargetFrame:RefreshTarget(true)
expect(TargetFrame.currentData.fallbackMetadataUnitTag == nil,
    "stable mismatched identities must never mix stale player metadata")
expect(TargetFrame.currentData.classId == 2,
    "an explicit tag mismatch must keep the current general player's metadata")

-- Reconciliation must reacquire players after all finite event retries have
-- elapsed, and must tolerate the short tag gap produced while re-aiming.
GetUnitClassId = function()
    return 2
end
GetRawUnitName = nil
TargetFrame.initialized = true
TargetFrame:SetReconciliationEnabled(true)
local reconciliation = updateRegistrations["NirnsteelUI_TargetFrame_Reconcile"]
expect(reconciliation ~= nil and reconciliation.interval == 100,
    "enabled target frames must reconcile the two reticle tags every 100ms")

generalTargetExists = false
playerTargetExists = false
TargetFrame:ApplyTargetData(nil, true)
nowMS = 2000
playerTargetExists = true
reconciliation.handler()
expect(TargetFrame.currentData and TargetFrame.currentData.unitTag == "reticleoverplayer",
    "reconciliation must reacquire a player even after scheduled retries are exhausted")
expect(root.hidden == false, "reconciliation must make the reacquired player frame visible")

playerTargetExists = false
reconciliation.handler()
expect(TargetFrame.currentData ~= nil, "a transient player-tag gap must retain the current target")
nowMS = 2149
reconciliation.handler()
expect(TargetFrame.currentData ~= nil, "the target must remain during the full disappearance grace period")
nowMS = 2150
reconciliation.handler()
expect(TargetFrame.currentData == nil, "the target must clear once the disappearance grace period expires")

-- One transient runtime error must restore ESO's frame, keep reconciliation
-- alive, then recover automatically instead of permanently disabling players.
playerTargetExists = true
nowMS = 2200
reconciliation.handler()
expect(TargetFrame.currentData ~= nil, "the player target must be present before the recovery test")
local stockVisibilityCalls = {}
UNIT_FRAMES =
{
    GetFrame = function()
        return {}
    end,
    SetFrameHiddenForReason = function(_, _, _, hidden)
        stockVisibilityCalls[#stockVisibilityCalls + 1] = hidden == true
    end,
}
local originalReconcileTarget = TargetFrame.ReconcileTarget
TargetFrame.ReconcileTarget = function()
    error("transient player metadata failure")
end
nowMS = 2300
reconciliation.handler()
expect(TargetFrame.runtimeRecoveryActive == true, "a reconciliation error must enter recoverable fallback")
expect(TargetFrame.initialized == true, "a transient runtime error must not permanently uninitialize the module")
expect(updateRegistrations["NirnsteelUI_TargetFrame_Reconcile"] ~= nil,
    "a transient runtime error must not unregister reconciliation")
expect(stockVisibilityCalls[#stockVisibilityCalls] == false,
    "ESO's stock target frame must be restored while the custom frame recovers")
expect(root.hidden == true, "a faulted custom frame must remain hidden during recovery")
TargetFrame:SetStockFrameHidden(true)
expect(stockVisibilityCalls[#stockVisibilityCalls] == false,
    "visibility refreshes must not re-hide ESO's frame during recovery")

TargetFrame.ReconcileTarget = originalReconcileTarget
playerTargetExists = false
nowMS = 2799
reconciliation.handler()
expect(TargetFrame.runtimeRecoveryActive == true, "recovery must respect its short retry backoff")
nowMS = 2800
reconciliation.handler()
expect(TargetFrame.runtimeRecoveryActive == true,
    "an empty retry must keep ESO's fallback until the custom frame reacquires a target")
expect(stockVisibilityCalls[#stockVisibilityCalls] == false,
    "an empty recovery poll must not hide ESO's fallback frame")
playerTargetExists = true
nowMS = 2900
reconciliation.handler()
expect(TargetFrame.runtimeRecoveryActive == nil, "a real target snapshot must leave recovery automatically")
expect(TargetFrame.currentData ~= nil, "a successful recovery must reacquire the player target")
expect(stockVisibilityCalls[#stockVisibilityCalls] == true,
    "the stock frame may be hidden again only after custom-frame recovery succeeds")
UNIT_FRAMES = nil

print("target_frame_regression.lua: all checks passed")

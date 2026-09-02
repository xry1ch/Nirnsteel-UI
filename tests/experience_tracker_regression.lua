-- Focused Lua 5.1 regression checks for modules/experience_tracker.lua.
-- Run from the addon root with: lua51.exe tests/experience_tracker_regression.lua

local function expect(condition, message)
    if not condition then
        error(message, 2)
    end
end

local function near(actual, expected, epsilon)
    return math.abs(actual - expected) <= (epsilon or 0.001)
end

unpack = unpack or table.unpack
loadstring = loadstring or load

local function NewControl(parent)
    local control = {
        parent = parent,
        width = 0,
        height = 0,
        alpha = 1,
        scale = 1,
        hidden = false,
        text = "",
    }

    function control:SetDimensions(width, height) self.width, self.height = width, height end
    function control:GetWidth() return self.width end
    function control:GetHeight() return self.height end
    function control:SetAnchor(...) self.anchor = { ... } end
    function control:ClearAnchors() self.anchor = nil end
    function control:SetAnchorFill(target)
        self.anchorFill = target
        if target then self.width, self.height = target:GetWidth(), target:GetHeight() end
    end
    function control:SetAlpha(alpha) self.alpha = alpha end
    function control:GetAlpha() return self.alpha end
    function control:SetScale(scale) self.scale = scale end
    function control:SetHidden(hidden) self.hidden = hidden end
    function control:IsHidden() return self.hidden end
    function control:SetText(text) self.text = tostring(text or "") end
    function control:GetText() return self.text end
    function control:SetFont(font) self.font = font end
    function control:SetTexture(texture) self.texture = texture end
    function control:SetTextureCoords(...) self.textureCoords = { ... } end
    function control:SetColor(...) self.color = { ... } end
    function control:SetCenterColor(...) self.centerColor = { ... } end
    function control:SetEdgeColor(...) self.edgeColor = { ... } end
    function control:SetEdgeTexture(...) self.edgeTexture = { ... } end
    function control:SetGradientColors(...) self.gradient = { ... } end
    function control:SetMinMax(minimum, maximum) self.minimum, self.maximum = minimum, maximum end
    function control:SetValue(value) self.value = value end
    function control:SetHandler(name, handler) self.handlers = self.handlers or {}; self.handlers[name] = handler end
    function control:SetClampedToScreen(value) self.clamped = value end
    function control:SetMouseEnabled(value) self.mouseEnabled = value end
    function control:SetMovable(value) self.movable = value end
    function control:SetDrawTier(value) self.drawTier = value end
    function control:SetDrawLayer(value) self.drawLayer = value end
    function control:SetHorizontalAlignment(value) self.horizontalAlignment = value end
    function control:SetVerticalAlignment(value) self.verticalAlignment = value end
    function control:SetModifyTextType(value) self.modifyTextType = value end
    function control:EnableLeadingEdge(value) self.leadingEdgeEnabled = value end
    function control:SetLeadingEdge(...) self.leadingEdge = { ... } end
    function control:SetLeadingEdgeTextureCoords(...) self.leadingEdgeCoords = { ... } end
    function control:SetPixelRoundingEnabled(value) self.pixelRounding = value end
    function control:GetLeft() return 30 end
    function control:GetTop() return 30 end
    function control:StartMoving() end
    function control:StopMovingOrResizing() end

    return control
end

TOPLEFT, TOPRIGHT, TOP, BOTTOM, BOTTOMRIGHT = "TOPLEFT", "TOPRIGHT", "TOP", "BOTTOM", "BOTTOMRIGHT"
LEFT, RIGHT, CENTER = "LEFT", "RIGHT", "CENTER"
CT_BACKDROP, CT_LABEL, CT_TEXTURE, CT_STATUSBAR = 1, 2, 3, 4
DL_BACKGROUND, DL_CONTROLS, DL_OVERLAY = 1, 2, 3
DT_HIGH = 1
TEXT_ALIGN_LEFT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER = 1, 2, 3
MODIFY_TEXT_TYPE_UPPERCASE = 1
MOUSE_BUTTON_INDEX_LEFT = 1
CHAMPION_DISCIPLINE_TYPE_WORLD = 1
CHAMPION_DISCIPLINE_TYPE_COMBAT = 2
CHAMPION_DISCIPLINE_TYPE_CONDITIONING = 3
SI_EXPERIENCE_LEVEL_LABEL = 1
EVENT_ADD_ON_LOADED = 1
EVENT_EXPERIENCE_GAIN = 2
EVENT_DISCOVERY_EXPERIENCE = 3
EVENT_EXPERIENCE_UPDATE = 4
EVENT_CHAMPION_POINT_GAINED = 5
EVENT_PLAYER_ACTIVATED = 6
EVENT_SCREEN_RESIZED = 7
EVENT_GAMEPAD_PREFERRED_MODE_CHANGED = 8
REGISTER_FILTER_UNIT_TAG = 1

GuiRoot = NewControl(nil)
GuiRoot:SetDimensions(1920, 1080)
WINDOW_MANAGER = {}
function WINDOW_MANAGER:CreateTopLevelWindow() return NewControl(GuiRoot) end
function WINDOW_MANAGER:CreateControl(_, parent) return NewControl(parent) end

EVENT_MANAGER = {}
function EVENT_MANAGER:RegisterForEvent() end
function EVENT_MANAGER:UnregisterForEvent() end
function EVENT_MANAGER:AddFilterForEvent() end
function EVENT_MANAGER:RegisterForUpdate() end
function EVENT_MANAGER:UnregisterForUpdate() end

HUD_SCENE = { IsShowing = function() return true end, RegisterCallback = function() end }
HUD_UI_SCENE = nil
SLASH_COMMANDS = {}

local nowMS = 1000
local playedSounds = {}
function GetFrameTimeMilliseconds() return nowMS end
function PlaySound(sound) playedSounds[#playedSounds + 1] = sound end
function GetString() return "LEVEL" end
function GetNumChampionXPInChampionPoint() return 1000 end
function GetChampionPointPoolForRank() return CHAMPION_DISCIPLINE_TYPE_WORLD end
function GetPlayerChampionPointsEarned() return 2047 end
function GetPlayerChampionXP() return 420 end
function GetUnitLevel() return 10 end
function GetUnitXP() return 250 end
function GetUnitXPMax() return 1000 end
function GetNumExperiencePointsInLevel() return 1000 end
function CanUnitGainChampionPoints() return false end
function IsEnlightenedAvailableForCharacter() return false end
function zo_clamp(value, minimum, maximum) return math.min(math.max(value, minimum), maximum) end
function zo_lerp(startValue, stopValue, progress) return startValue + (stopValue - startValue) * progress end
zo_min = math.min
function zo_callLater() end
function ZO_CommaDelimitNumber(value) return tostring(value) end

SOUNDS = {
    PROMOTIONAL_EVENT_REWARD_TO_CLAIM_PROMPT = "chunk",
    BATTLEGROUND_ROUND_RECAP_SCREEN_FINAL_WIN = "level",
}

local trackerSettings = {
    enabled = true,
    unlocked = false,
    scale = 100,
    opacity = 100,
    width = 460,
    height = 56,
    durationMS = 3600,
    intensity = 100,
    visibilityMode = "fade",
    chunkSoundKey = "PROMOTIONAL_EVENT_REWARD_TO_CLAIM_PROMPT",
    levelUpSoundKey = "BATTLEGROUND_ROUND_RECAP_SCREEN_FINAL_WIN",
    showGainText = true,
    showProgressText = true,
    showChampionIcon = true,
    levelUpAnimationEnabled = true,
    levelUpIntensity = 100,
    hideBackground = false,
    hideStockProgressBar = true,
}

Nirnsteel_UI = {
    Settings = {
        GetExperienceTracker = function() return trackerSettings end,
        IsExperienceTrackerEnabled = function() return trackerSettings.enabled end,
        IsExperienceTrackerUnlocked = function() return trackerSettings.unlocked end,
        GetExperienceTrackerPosition = function() return { x = 30, y = 30 } end,
        SetExperienceTrackerPosition = function() end,
        ShouldExperienceTrackerHideStockProgressBar = function() return trackerSettings.hideStockProgressBar end,
        IsDebugModeEnabled = function() return false end,
    },
}

assert(loadfile("modules/experience_tracker.lua"))()
local ExperienceTracker = Nirnsteel_UI.ExperienceTracker

-- Compact two-row CP layout and setting semantics.
ExperienceTracker:SetVisualMode("cp", 2047)
local root = ExperienceTracker:GetRoot()
expect(root:GetWidth() == 460 and root:GetHeight() == 56, "the redesigned tracker must use the compact default size")
expect(root.topRail and root.bottomRail and root.divider, "the ornate native-asset frame must create rails and a divider")
expect(root.typeLabel.anchor[5] == root.gainLabel.anchor[5], "gain feedback must share the left header row")
expect(root.icon.hidden == false and root.rankHasIcon == true, "Champion mode must show its discipline icon by default")

trackerSettings.showChampionIcon = false
ExperienceTracker:SetVisualMode("cp", 2047)
expect(root.icon.hidden == true and root.rankHasIcon == false, "disabling the Champion icon must release its plaque space")
expect(root.levelLabel.anchor[1] == CENTER, "rank text must recenter when the Champion icon is hidden")
trackerSettings.showChampionIcon = true

trackerSettings.showProgressText = false
ExperienceTracker:SetBarValue(250, 1000)
expect(root.progressLabel.hidden == true, "disabling progress text must hide only the right header")
trackerSettings.showProgressText = true
ExperienceTracker:SetBarValue(250, 1000)
expect(root.progressLabel.text == "250 / 1000 - 25%", "progress text must retain current, maximum, and percentage")

trackerSettings.width = 360
ExperienceTracker:ApplyLayout()
ExperienceTracker:SetBarValue(250000, 1000000)
expect(root.progressLabel.text == "250K / 1M - 25%",
    "minimum-width layouts must compact large values without dropping the percentage")
trackerSettings.width = 460
ExperienceTracker:ApplyLayout()

trackerSettings.hideBackground = true
ExperienceTracker:ApplyLayout()
expect(root.panel.hidden and root.topRail.hidden and root.bottomRail.hidden and root.divider.hidden,
    "background-free mode must hide the plate and its ornaments")
expect(not root.badge.hidden and not root.track.hidden, "background-free mode must retain the plaque and progress track")
trackerSettings.hideBackground = false
ExperienceTracker:ApplyLayout()

-- Regular gains use the header swap, clipped earned interval, and existing chunk audio.
playedSounds = {}
nowMS = 2000
local regular = { mode = "xp", level = 10, startValue = 100, stopValue = 250, maxValue = 1000, wraps = false }
ExperienceTracker:QueueSegments({ regular }, 150, "xp")
local regularAnimation = ExperienceTracker.animation
expect(regularAnimation.type == "segment", "a regular gain must start a segment animation")
expect(near(root.bulk:GetWidth() / root.track:GetWidth(), 0.15, 0.001),
    "the translucent gain layer must cover only the newly earned interval")

nowMS = regularAnimation.startMS + math.floor(regularAnimation.durationMS * 0.5)
ExperienceTracker:OnUpdate()
expect(root.gainLabel.alpha > 0.9 and root.typeLabel.alpha < 0.1,
    "gain text must replace the mode label while XP is moving")
expect(root.bulk.value > 0 and root.bulk.value <= 150, "the gain overlay value must be relative to the earned interval")
expect(#playedSounds > 0 and playedSounds[1] == "chunk", "chunk boundaries must retain the configured sound")

nowMS = regularAnimation.startMS + regularAnimation.durationMS
ExperienceTracker:OnUpdate()
expect(ExperienceTracker.animation.type == "hold", "a completed gain must enter its hold state")
local holdAnimation = ExperienceTracker.animation
nowMS = holdAnimation.startMS + math.floor(holdAnimation.durationMS * 0.14)
ExperienceTracker:OnUpdate()
expect(root.typeLabel.alpha > 0 and root.gainLabel.alpha > 0,
    "the hold state must crossfade the gain header back to the mode label")

ExperienceTracker:HideRoot()
trackerSettings.showGainText = false
nowMS = 4000
ExperienceTracker:QueueSegments({ regular }, 150, "xp")
local noGainTextAnimation = ExperienceTracker.animation
nowMS = noGainTextAnimation.startMS + math.floor(noGainTextAnimation.durationMS * 0.5)
ExperienceTracker:OnUpdate()
expect(root.gainLabel.hidden and root.typeLabel.alpha == 1,
    "disabling gained-XP text must leave the normal mode label visible")
trackerSettings.showGainText = true

-- Wrapped gains reveal the next rank and then continue their queued segment.
ExperienceTracker:HideRoot()
trackerSettings.intensity = 100
trackerSettings.levelUpAnimationEnabled = true
playedSounds = {}
local wrapped = { mode = "xp", level = 10, startValue = 900, stopValue = 1000, maxValue = 1000, wraps = true }
local continuation = { mode = "xp", level = 11, startValue = 0, stopValue = 200, maxValue = 1000, wraps = false }
ExperienceTracker.segmentQueue = { continuation }
ExperienceTracker.totalGainAmount = 300
ExperienceTracker.totalGainMode = "xp"
ExperienceTracker:SetVisualMode("xp", 10)
ExperienceTracker:SetGainHeader("+300 XP")
nowMS = 5000
ExperienceTracker:BeginLevelUpBurst(wrapped)
local levelAnimation = ExperienceTracker.animation
expect(root.levelLabel.text == "10" and root.nextLevelLabel.text == "11" and not root.nextLevelLabel.hidden,
    "level-up preparation must create outgoing and incoming rank values")
expect(playedSounds[#playedSounds] == "level", "the redesigned level-up must retain its configured sound")

nowMS = levelAnimation.startMS + math.floor(levelAnimation.durationMS * 0.26)
ExperienceTracker:OnUpdate()
expect(root.nextLevelLabel.alpha > 0 and root.levelLabel.alpha < 1,
    "the new rank must rise in while the old rank fades out")

nowMS = levelAnimation.startMS + levelAnimation.durationMS
ExperienceTracker:OnUpdate()
expect(root.levelLabel.text == "11" and root.nextLevelLabel.hidden,
    "the revealed rank must become the plaque's settled value")
expect(ExperienceTracker.animation.type == "segment" and ExperienceTracker.animation.segment.level == 11,
    "a level-up burst must continue with the next queued XP segment")

-- Zero intensity removes decorative motion but still commits rank and sound.
ExperienceTracker:HideRoot()
trackerSettings.intensity = 0
playedSounds = {}
ExperienceTracker.segmentQueue = {}
ExperienceTracker:SetVisualMode("xp", 20)
ExperienceTracker:SetGainHeader("+100 XP")
nowMS = 8000
ExperienceTracker:BeginLevelUpBurst({
    mode = "xp", level = 20, startValue = 900, stopValue = 1000, maxValue = 1000, wraps = true,
})
local zeroAnimation = ExperienceTracker.animation
nowMS = zeroAnimation.startMS + math.floor(zeroAnimation.durationMS * 0.20)
ExperienceTracker:OnUpdate()
expect(root.levelLabel.text == "21" and root.nextLevelLabel.hidden,
    "zero intensity must still commit the new rank without decorative motion")
expect(root.impactFlash.alpha == 0 and root.levelBurst.alpha == 0,
    "zero intensity must suppress flash and burst layers")
expect(playedSounds[#playedSounds] == "level", "zero visual intensity must not suppress the level-up sound")

-- Disabling the special animation still advances directly into the next level.
ExperienceTracker:HideRoot()
trackerSettings.intensity = 100
trackerSettings.levelUpAnimationEnabled = false
playedSounds = {}
ExperienceTracker.segmentQueue = { wrapped, continuation }
ExperienceTracker.totalGainAmount = 300
ExperienceTracker.totalGainMode = "xp"
nowMS = 10000
ExperienceTracker:ShowRoot()
ExperienceTracker:StartNextSegment()
local disabledAnimation = ExperienceTracker.animation
nowMS = disabledAnimation.startMS + disabledAnimation.durationMS
ExperienceTracker:OnUpdate()
expect(ExperienceTracker.animation.type == "segment" and ExperienceTracker.animation.segment.level == 11,
    "disabling level-up animation must still advance to the next segment")
expect(root.levelLabel.text == "11" and root.nextLevelLabel.hidden,
    "the plaque must update when the special rank animation is disabled")
expect(playedSounds[#playedSounds] == "level", "disabling level-up animation must retain the sound")
trackerSettings.levelUpAnimationEnabled = true

-- Direct multi-point CP notifications reveal the actual ending rank and pluralize feedback.
ExperienceTracker:HideRoot()
playedSounds = {}
nowMS = 12000
ExperienceTracker:PreviewCPFlash(2050, 2)
expect(root.levelLabel.text == "2048" and root.nextLevelLabel.text == "2050",
    "multi-point CP notifications must reveal from the previous rank to the actual ending rank")
expect(root.gainLabel.text == "+2 Champion Points", "multi-point CP feedback must use a plural label")

-- A new gain cleanly replaces any in-flight ceremonial state.
local interruptingGain = { mode = "xp", level = 30, startValue = 200, stopValue = 300, maxValue = 1000, wraps = false }
ExperienceTracker:QueueSegments({ interruptingGain }, 100, "xp")
expect(ExperienceTracker.animation.type == "segment" and ExperienceTracker.animation.segment.level == 30,
    "rapid gains must replace the active animation with the latest progression segment")
expect(root.nextLevelLabel.hidden and root.levelBurst.hidden and root.badgeBurst.hidden,
    "rapid gains must clear stale rank and burst layers")
expect(root.badge.scale == 1 and ExperienceTracker.rankReveal == nil,
    "rapid gains must restore the plaque transform and rank state")

-- Execute the settings migration body directly so customized dimensions remain protected.
-- Fengari omits io.open; the add-on's Lua 5.1 regression runtime executes this block.
if io and io.open then
    local settingsFile = assert(io.open("modules/settings.lua", "r"))
    local settingsSource = settingsFile:read("*a"):gsub("\r\n", "\n")
    settingsFile:close()
    local migrationBody = assert(settingsSource:match(
        "local function UpgradeExperienceTrackerDefaults%(account%)(.-)\nend\n\nlocal function UpgradeResourceBarDefaults"))
    local migrationFactory = assert(loadstring("return function(account, ACCOUNT_DEFAULTS)" .. migrationBody .. "\nend"))
    local migrate = migrationFactory()
    local defaults = { modules = { experienceTracker = { width = 460, height = 56 } } }

    local untouched = { modules = { experienceTracker = { width = 460, height = 64 } } }
    migrate(untouched, defaults)
    expect(untouched.modules.experienceTracker.height == 56, "the untouched 460x64 default must migrate to 460x56")

    local customized = { modules = { experienceTracker = { width = 500, height = 64 } } }
    migrate(customized, defaults)
    expect(customized.modules.experienceTracker.width == 500 and customized.modules.experienceTracker.height == 64,
        "custom tracker dimensions must not be migrated")

    local legacy = { modules = { experienceTracker = { width = 420, height = 48 } } }
    migrate(legacy, defaults)
    expect(legacy.modules.experienceTracker.width == 460 and legacy.modules.experienceTracker.height == 56,
        "the older 420x48 default must migrate directly to the redesigned size")
end

print("experience_tracker_regression.lua: all checks passed")

-- Focused Lua 5.1 regression checks for modules/pvp.lua.
-- Run from the addon root with: lua51.exe tests/pvp_regression.lua

local function expect(condition, message)
    if not condition then
        error(message, 2)
    end
end

unpack = unpack or table.unpack

local function NewControl(parent)
    local control =
    {
        parent = parent,
        width = 0,
        height = 0,
        alpha = 1,
        scale = 1,
        hidden = false,
        handlers = {},
    }

    function control:SetDimensions(width, height) self.width, self.height = width, height end
    function control:GetWidth() return self.width end
    function control:GetHeight() return self.height end
    function control:SetAnchor(...) self.anchor = { ... } end
    function control:ClearAnchors() self.anchor = nil end
    function control:SetAnchorFill(target) self.anchorFill = target end
    function control:SetAlpha(value) self.alpha = value end
    function control:GetAlpha() return self.alpha end
    function control:SetScale(value) self.scale = value end
    function control:SetHidden(value) self.hidden = value end
    function control:IsHidden() return self.hidden end
    function control:SetMouseEnabled(value) self.mouseEnabled = value end
    function control:SetMovable(value) self.movable = value end
    function control:SetClampedToScreen(value) self.clamped = value end
    function control:SetDrawTier(value) self.drawTier = value end
    function control:SetDrawLayer(value) self.drawLayer = value end
    function control:SetDrawLevel(value) self.drawLevel = value end
    function control:SetTexture(value) self.texture = value end
    function control:SetTextureCoords(...) self.textureCoords = { ... } end
    function control:SetBlendMode(value) self.blendMode = value end
    function control:SetCenterColor(...) self.centerColor = { ... } end
    function control:SetBorderColor(...) self.borderColor = { ... } end
    function control:SetBorderThickness(...) self.borderThickness = { ... } end
    function control:SetBorderDirection(value) self.borderDirection = value end
    function control:SetPointLayout(value) self.pointLayout = value end
    function control:SetSmoothingEnabled(value) self.smoothing = value end
    function control:AddPoint(x, y)
        self.points = self.points or {}
        self.points[#self.points + 1] = {x, y}
    end
    function control:SetEdgeColor(...) self.edgeColor = { ... } end
    function control:SetEdgeTexture(...) self.edgeTexture = { ... } end
    function control:SetColor(...) self.color = { ... } end
    function control:SetText(value) self.text = tostring(value or "") end
    function control:GetText() return self.text end
    function control:SetFont(value) self.font = value end
    function control:SetHorizontalAlignment(value) self.horizontalAlignment = value end
    function control:SetVerticalAlignment(value) self.verticalAlignment = value end
    function control:SetTransformNormalizedOriginPoint(...) self.transformOrigin = { ... } end
    function control:SetTransformScale(value) self.transformScale = value end
    function control:SetTransformScaleX(value) self.transformScaleX = value end
    function control:SetTransformRotationZ(value) self.rotation = value end
    function control:SetTransformOffset(...) self.transformOffset = { ... } end
    function control:SetHandler(name, handler) self.handlers[name] = handler end
    function control:GetLeft() return self.left or 710 end
    function control:GetTop() return self.top or 634 end
    function control:StartMoving() self.startedMoving = true end
    function control:StopMovingOrResizing() self.stoppedMoving = true end

    return control
end

TOP, BOTTOM, LEFT, RIGHT, CENTER = "TOP", "BOTTOM", "LEFT", "RIGHT", "CENTER"
CT_CONTROL, CT_BACKDROP, CT_TEXTURE, CT_LABEL, CT_POLYGON = 1, 2, 3, 4, 5
POLYGON_POINT_LAYOUT_CLOCKWISE, POLYGON_BORDER_DIRECTION_IN = 1, 1
DT_HIGH = 1
DL_BACKGROUND, DL_CONTROLS, DL_OVERLAY = 1, 2, 3
TEX_BLEND_MODE_ADD = 1
TEXT_ALIGN_CENTER = 1
MOUSE_BUTTON_INDEX_LEFT = 1

EVENT_ADD_ON_LOADED = 1
EVENT_PVP_KILL_FEED_DEATH = 2
EVENT_PLAYER_DEAD = 3
EVENT_PLAYER_DEACTIVATED = 4
EVENT_PLAYER_ACTIVATED = 5
EVENT_ZONE_CHANGED = 6
EVENT_SCREEN_RESIZED = 7
EVENT_DUEL_STARTED = 8
EVENT_DUEL_FINISHED = 9
DUEL_RESULT_WON = 1
DUEL_RESULT_FORFEIT = 2

GuiRoot = NewControl(nil)
GuiRoot:SetDimensions(1920, 1080)

WINDOW_MANAGER = {}
function WINDOW_MANAGER:CreateTopLevelWindow()
    return NewControl(GuiRoot)
end
function WINDOW_MANAGER:CreateControl(_, parent)
    return NewControl(parent)
end

local registeredEvents = {}
EVENT_MANAGER = {}
function EVENT_MANAGER:RegisterForEvent(namespace, eventCode, callback)
    registeredEvents[namespace] = { eventCode = eventCode, callback = callback }
end
function EVENT_MANAGER:UnregisterForEvent(namespace)
    registeredEvents[namespace] = nil
end

HUD_SCENE =
{
    showing = true,
    callbacks = {},
    IsShowing = function(self) return self.showing end,
    RegisterCallback = function(self, _, callback) self.callbacks[#self.callbacks + 1] = callback end,
}
HUD_UI_SCENE = nil
SLASH_COMMANDS = {}

local nowMS = 1000
local delayedCalls = {}

function GetFrameTimeMilliseconds()
    return nowMS
end

function zo_callLater(callback, delayMS)
    delayedCalls[#delayedCalls + 1] = { callback = callback, dueMS = nowMS + delayMS }
end

local function RunVisualUpdate()
    local pvp = Nirnsteel_UI and Nirnsteel_UI.PvP
    local root = pvp and pvp.root
    if root and root.handlers.OnUpdate then
        root.handlers.OnUpdate()
    end
end

local function Advance(milliseconds)
    local targetMS = nowMS + milliseconds
    while true do
        local selectedIndex
        local selectedDueMS
        for index, delayed in ipairs(delayedCalls) do
            if delayed.dueMS <= targetMS and (not selectedDueMS or delayed.dueMS < selectedDueMS) then
                selectedIndex = index
                selectedDueMS = delayed.dueMS
            end
        end
        if not selectedIndex then
            break
        end

        nowMS = selectedDueMS
        local callback = table.remove(delayedCalls, selectedIndex).callback
        callback()
        RunVisualUpdate()
    end
    nowMS = targetMS
    RunVisualUpdate()
end

local playedSounds = {}
SOUNDS =
{
    CHAMPION_STAR_STAGE_UP = "x1",
    CODE_REDEMPTION_SUCCESS = "redemption-fallback",
    VENGEANCE_PERK_DROP = "x2-3",
    VENGEANCE_PERK_EQUIPPED = "x4-5",
    BATTLEGROUND_ROUND_RECAP_SCREEN_WIN = "x6-7",
    BATTLEGROUND_ROUND_RECAP_SCREEN_FINAL_WIN = "x8",
    BATTLEGROUND_LEAVE_MATCH = "fallback",
}
function PlaySound(sound)
    playedSounds[#playedSounds + 1] = sound
end

function GetDisplayName()
    return "@LocalPlayer"
end
function GetUnitDisplayName()
    return "@LocalPlayer"
end

local settings =
{
    enabled = true,
    unlocked = false,
    scale = 100,
    intensity = 100,
    soundEnabled = true,
    chainEnabled = true,
    includeDuels = true,
    -- Legacy saved values must no longer affect the fixed gameplay rules.
    chainWindowMS = 8000,
    maxChain = 4,
}
local position = { x = 0, y = 140 }

Nirnsteel_UI =
{
    Settings =
    {
        GetPvP = function() return settings end,
        GetPvPPosition = function() return position end,
        SetPvPPosition = function(_, x, y) position.x, position.y = x, y end,
        IsDebugModeEnabled = function() return true end,
    },
}

dofile("modules/pvp.lua")
local PvP = Nirnsteel_UI.PvP
PvP:RefreshSettings()

local root = PvP:GetRoot()
local mover = PvP:GetMover()
expect(root.width == 420 and root.height == 150, "the PvP root must use the planned 420x150 geometry")
expect(root.anchor[4] == 0 and root.anchor[5] == 140, "the badge must use the default centered server position")
expect(root.scale == 1 and mover.hidden, "the default scale must be 100% and the mover must start hidden")
expect(root.counterPlate == nil and #root.medal.rim.points == 64 and root.medal.rim.smoothing,
    "the live badge must be a smooth native circular polygon, without a rectangular plate")
expect(root.medal.skull.width == 38 and #root.cards == 8 and #root.ranks == 8,
    "the medallion must have a readable stamped skull and eight native kill cards")
expect(registeredEvents.NirnsteelUI_PvP_KillFeed ~= nil, "the enabled module must register the PvP kill-feed event")
expect(registeredEvents.NirnsteelUI_PvP_DuelFinished ~= nil, "duel wins must be registered by default")
expect(SLASH_COMMANDS["/nspvpkill"] and SLASH_COMMANDS["/nspvpchain"], "debug mode must expose both PvP preview commands")

-- Other players' kills are ignored. Two distinct local victims in the same
-- 120 ms batch become x2, while a duplicate pair is counted only once.
PvP:OnPvPKillFeedDeath("", "@SomeoneElse", "Other", 1, 1, "@Victim0")
PvP:OnPvPKillFeedDeath("", "@LocalPlayer", "Local", 1, 1, "@Victim1")
PvP:OnPvPKillFeedDeath("", "@LocalPlayer", "Local", 1, 1, "@Victim1")
PvP:OnPvPKillFeedDeath("", "@LocalPlayer", "Local", 1, 1, "@Victim2")
expect(PvP.pendingKillCount == 2 and root.hidden, "kills must batch before showing the celebration")
Advance(120)
expect(PvP.chainCount == 2 and root.counter.text == "×2", "distinct simultaneous victims must produce an x2 counter")
expect(not root.cards[1].hidden and not root.cards[2].hidden and root.cards[3].hidden,
    "each accepted kill must add one visible card, up to the chain cap")
expect(#playedSounds == 1 and playedSounds[1] == "x2-3", "the x2 batch must play one progressive sound")

-- The entrance grows the rails, the exit fades, and completion cleans the
-- OnUpdate handler so the HUD costs nothing while idle.
local animationStartMS = PvP.animation.startMS
nowMS = animationStartMS + 70
PvP:UpdateAnimation()
expect(root.rails[1].transformScaleX > 0 and root.rails[1].transformScaleX < 1,
    "the entrance must expand the tapered light rails")
expect(root.medal.transformScale < 1 and root.medal.strike.alpha > 0,
    "the badge must stamp inward, briefly recoil, and catch the impact light")
expect(root.cards[2].pose.alpha > 0 and root.cards[2].pose.alpha < 1,
    "new kill cards must enter progressively instead of appearing at full opacity")
nowMS = animationStartMS + 350
PvP:UpdateAnimation()
expect(root.medal.transformScale == 1 and root.medal.strike.alpha == 0 and root.counter.alpha == 1,
    "the impact must settle to a motionless, readable badge before fading")
expect(root.cards[1].pose.x < 0 and root.cards[2].pose.x > 0,
    "settled cards must form a balanced fan behind the medallion")
nowMS = animationStartMS + 760
PvP:UpdateAnimation()
expect(root.alpha > 0 and root.alpha < 1, "the final phase must fade the celebration")
nowMS = animationStartMS + 951
PvP:UpdateAnimation()
expect(root.hidden and root.handlers.OnUpdate == nil, "the completed animation must hide itself and remove OnUpdate")

-- A rapid extra kill preserves the existing cards' exact transforms at the
-- interruption, then spreads them to make room for the new card.
PvP:ShowCelebration(4, true)
Advance(95)
local oldPose = root.cards[2].pose
PvP:ShowCelebration(5, true)
expect(root.cards[2].pose.x == oldPose.x and root.cards[2].pose.y == oldPose.y
    and root.cards[2].pose.rotation == oldPose.rotation and root.cards[2].pose.alpha == oldPose.alpha,
    "a reimpact must not teleport or flash existing cards")
expect(root.cards[5].pose.alpha == 0, "only the newly added card must start transparent")
Advance(350)
expect(root.cards[5].pose.alpha == 1 and root.cards[5].pose.x > root.cards[4].pose.x,
    "a rapid new kill must settle into the enlarged fan")

-- A duplicate signature becomes valid again after the 1.5 second guard.
PvP:ResetState(true)
playedSounds = {}
nowMS = 3000
PvP:OnPvPKillFeedDeath("", "@LocalPlayer", "Local", 1, 1, "@Victim1")
Advance(120)
Advance(1501)
PvP:OnPvPKillFeedDeath("", "@LocalPlayer", "Local", 1, 1, "@Victim1")
Advance(120)
expect(PvP.chainCount == 2, "the same killer/victim pair must become eligible after 1.5 seconds")

-- A chain expires exactly 3.5 seconds after the last kill, regardless of
-- legacy saved settings. Batching must not extend the expiry timestamp.
PvP:ResetState(true)
playedSounds = {}
nowMS = 5000
PvP:QueueAcceptedKill()
Advance(120)
expect(PvP.chainCount == 1, "the first accepted kill must begin at x1")
expect(playedSounds[1] == "x1" and PvP.lastSoundKey == "CHAMPION_STAR_STAGE_UP",
    "a regular kill must use Champion Star Stage Up")
Advance(1000)
PvP:QueueAcceptedKill()
Advance(120)
expect(PvP.chainCount == 2, "a kill inside the 3.5-second window must extend the chain")
Advance(3379)
expect(PvP.chainCount == 2, "the chain must remain alive 3499 ms after the last kill")
Advance(1)
expect(PvP.chainCount == 0 and PvP.lastKillMS == nil, "the chain must expire exactly 3500 ms after the last accepted kill")
PvP:QueueAcceptedKill()
Advance(120)
expect(PvP.chainCount == 1, "the next kill after expiry must start a new chain")

-- Twenty simultaneous kills clamp directly to x8 and emit only the x8 sound.
PvP:ResetState(true)
playedSounds = {}
nowMS = 12000
for index = 1, 20 do
    PvP:OnPvPKillFeedDeath("", "@LocalPlayer", "Local", 1, 1, "@BomberVictim" .. index)
end
Advance(120)
expect(PvP.chainCount == 8 and root.counter.text == "×8", "a bomber batch must clamp directly to x8")
expect(#playedSounds == 1 and playedSounds[1] == "x8", "a bomber batch must emit one maximum-tier sound")
expect(not root.maxWave.hidden and root.maxWave.alpha > 0, "x8 must activate the maximum-chain shockwave")

-- Extra kills at the cap always restart the visual impact, but sounds cannot
-- overlap inside the 300 ms cooldown.
local firstCapStartMS = PvP.animation.startMS
PvP:QueueAcceptedKill()
Advance(120)
expect(PvP.chainCount == 8 and PvP.animation.startMS > firstCapStartMS, "an extra capped kill must reimpact at x8")
expect(#playedSounds == 1, "an x8 reimpact inside 300 ms must not overlap audio")
Advance(181)
PvP:QueueAcceptedKill()
Advance(120)
expect(#playedSounds == 2 and playedSounds[2] == "x8", "a later x8 reimpact must replay the maximum-tier sound")

-- The high-chain tier uses its own sound before the final x8 fanfare.
PvP:ResetState(true)
playedSounds = {}
nowMS = 14000
for _ = 1, 6 do
    PvP:QueueAcceptedKill()
end
Advance(120)
expect(#playedSounds == 1 and playedSounds[1] == "x6-7", "x6 and x7 must use the high-chain victory sound")

-- Legacy caps are ignored by both live kills and the settings preview.
PvP:ResetState(true)
settings.maxChain = 4
for _ = 1, 8 do PvP:QueueAcceptedKill() end
Advance(120)
expect(PvP.chainCount == 8 and root.counter.text == "×8", "live kills must use the fixed x8 cap despite legacy settings")
PvP:ShowCelebration(8, true)
expect(root.counter.text == "×8" and not root.cards[8].hidden,
    "preview must demonstrate x8 despite legacy saved caps")
Advance(760)
expect(root.cards[1].alpha > root.cards[8].alpha, "the card fan must fade out in a staggered sequence")
settings.maxChain = 8

-- Intensity zero keeps the badge and counter while removing impact light,
-- shake, particles, and both waves. Changing intensity must not leak state.
settings.intensity = 0
PvP:ShowCelebration(8, true)
Advance(80)
expect(root.flash.alpha == 0 and root.medal.strike.alpha == 0 and root.halo.alpha == 0
    and root.wave.hidden and root.maxWave.hidden and root.visual.transformOffset[1] == 0,
    "zero intensity must remove flashes, glow, waves, and shake")
for _, spark in ipairs(root.sparks) do expect(spark.hidden, "zero intensity must hide all sparks") end
Advance(300)
expect(not root.hidden and root.counter.alpha == 1 and root.medal.transformScale == 1,
    "the essential badge must remain readable at zero intensity")
settings.intensity = 100

-- Disabling chains collapses any batch to x1; disabling sound leaves the
-- complete visual behavior intact.
PvP:ResetState(true)
settings.chainEnabled = false
playedSounds = {}
nowMS = nowMS + 301
PvP:QueueAcceptedKill()
PvP:QueueAcceptedKill()
PvP:QueueAcceptedKill()
Advance(120)
expect(PvP.chainCount == 1 and root.counter.text == "×1", "chain-disabled batches must remain x1")
settings.soundEnabled = false
PvP:QueueAcceptedKill()
Advance(120)
expect(#playedSounds == 1, "sound-disabled kills must not add audio")
settings.chainEnabled = true
settings.soundEnabled = true

-- Only a local DUEL_RESULT_WON is a kill. Opponent wins and forfeits never
-- count, and the same duel result is deduplicated.
PvP:ResetState(true)
playedSounds = {}
nowMS = 20000
PvP:OnDuelFinished(DUEL_RESULT_WON, false, "Opponent", "@Opponent")
PvP:OnDuelFinished(DUEL_RESULT_FORFEIT, true, "Opponent", "@Opponent")
expect(PvP.pendingKillCount == 0, "opponent wins and local forfeits must not count")
PvP:OnDuelFinished(DUEL_RESULT_WON, true, "Opponent", "@Opponent")
PvP:OnDuelFinished(DUEL_RESULT_WON, true, "Opponent", "@Opponent")
PvP:OnPvPKillFeedDeath("", "@LocalPlayer", "Local", 1, 1, "@Opponent")
Advance(120)
expect(PvP.chainCount == 1, "duplicate duel and kill-feed reports for one opponent must count exactly once")

-- A local death or self-kill immediately clears all active chain state.
PvP:QueueAcceptedKill()
PvP:OnPvPKillFeedDeath("", "@Enemy", "Enemy", 1, 1, "@LocalPlayer")
expect(PvP.chainCount == 0 and PvP.pendingKillCount == 0 and root.hidden,
    "a local PvP death must reset the chain and hide the celebration")
PvP:QueueAcceptedKill()
PvP:OnPvPKillFeedDeath("", "@LocalPlayer", "Local", 1, 1, "@LocalPlayer")
expect(PvP.chainCount == 0 and PvP.pendingKillCount == 0, "a PvP self-kill must reset rather than celebrate")

PvP:QueueAcceptedKill()
Advance(120)
registeredEvents.NirnsteelUI_PvP_ZoneChanged.callback(EVENT_ZONE_CHANGED)
expect(PvP.chainCount == 0 and root.hidden, "changing zone must clear the active chain")
PvP:QueueAcceptedKill()
Advance(120)
registeredEvents.NirnsteelUI_PvP_Deactivated.callback(EVENT_PLAYER_DEACTIVATED)
expect(PvP.chainCount == 0 and root.hidden, "player deactivation must clear the active chain")

-- Duel registration follows the setting without disturbing the core PvP
-- feed registration.
settings.includeDuels = false
PvP:RefreshSettings()
expect(registeredEvents.NirnsteelUI_PvP_KillFeed ~= nil, "the kill feed must remain registered when duels are disabled")
expect(registeredEvents.NirnsteelUI_PvP_DuelFinished == nil, "duel events must unregister when the option is disabled")
expect(registeredEvents.NirnsteelUI_PvP_DuelStarted ~= nil, "duel starts must still reset an existing PvP chain")
PvP:QueueAcceptedKill()
Advance(120)
registeredEvents.NirnsteelUI_PvP_DuelStarted.callback(EVENT_DUEL_STARTED)
expect(PvP.chainCount == 0 and root.hidden, "starting a duel must reset the chain even when duel wins are excluded")
settings.includeDuels = true
PvP:RefreshSettings()

-- Unlocking exposes the scaled mover and suppresses the live badge; the preview
-- temporarily replaces the mover and demonstrates x1, x4, and x8.
settings.unlocked = true
settings.scale = 125
PvP:RefreshSettings()
expect(not mover.hidden and mover.scale == 1.25 and root.hidden, "unlock must show the scaled drag handle")
mover.left = 900
mover.top = 594
mover.handlers.OnMoveStop(mover)
expect(position.x == 150 and position.y == 100, "moving the handle must persist its centered server offset")
playedSounds = {}
PvP:PreviewChain()
Advance(0)
expect(root.counter.text == "×1" and not root.hidden and mover.hidden, "preview must begin with the x1 badge")
Advance(650)
expect(root.counter.text == "×4", "preview must advance to x4")
Advance(650)
expect(root.counter.text == "×8", "preview must finish with x8")
expect(playedSounds[1] == "x1" and playedSounds[2] == "x4-5" and playedSounds[3] == "x8",
    "preview must demonstrate the progressive x1, x4, and x8 sounds")
Advance(1050)
expect(root.hidden and not mover.hidden, "preview completion must restore the unlocked mover")

-- A real kill cancels the remaining preview callbacks and resumes normal
-- chain bookkeeping without inheriting the preview's demo count.
settings.unlocked = false
PvP:RefreshSettings()
PvP:PreviewChain()
Advance(0)
PvP:QueueAcceptedKill()
Advance(120)
expect(PvP.chainCount == 1 and not PvP.previewing, "a live kill must cancel preview state and start at x1")
Advance(530)
expect(root.counter.text == "×1", "canceled preview callbacks must not overwrite a live celebration")
settings.unlocked = true
PvP:RefreshSettings()

-- Debug uses eight distinct impacts spaced beyond the audio cooldown, and
-- repeated settings refreshes never accumulate scene callbacks.
settings.unlocked = false
PvP:RefreshSettings()
PvP.lastSoundMS = nil
playedSounds = {}
SLASH_COMMANDS["/nspvpchain"]()
Advance(3060)
expect(PvP.chainCount == 8 and #playedSounds == 8,
    "the debug chain must demonstrate all eight impacts with their sounds")
expect(#HUD_SCENE.callbacks == 1, "settings refreshes must not accumulate scene callbacks")
Advance(960)
expect(root.hidden and not root.handlers.OnUpdate, "debug completion must remove the animation handler")

-- Disabling the module removes every runtime event and visual.
PvP:PreviewChain()
Advance(0)
PvP:QueueAcceptedKill()
settings.enabled = false
PvP:RefreshSettings()
Advance(2500)
expect(root.hidden and mover.hidden and root.handlers.OnUpdate == nil,
    "disabling PvP must hide the badge and mover, including after stale callbacks fire")
expect(registeredEvents.NirnsteelUI_PvP_KillFeed == nil and registeredEvents.NirnsteelUI_PvP_DuelFinished == nil,
    "disabling PvP must unregister kill-feed and duel events")
for namespace in pairs(registeredEvents) do
    expect(namespace == "NirnsteelUI_PvP_Loaded", "disabling PvP must remove every runtime event")
end

print("pvp_regression.lua: all checks passed")

-- Run from the addon root with Lua 5.1+ or the Fengari CLI.

local function expect(condition, message)
    if not condition then
        error(message, 2)
    end
end

local function near(actual, expected)
    return math.abs(actual - expected) < 0.001
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
    function control:SetTransformSkewX(value) self.skew = value end
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


TOP, BOTTOM, LEFT, RIGHT, CENTER, TOPLEFT = 'TOP', 'BOTTOM', 'LEFT', 'RIGHT', 'CENTER', 'TOPLEFT'
CT_CONTROL, CT_BACKDROP, CT_TEXTURE, CT_LABEL = 1, 2, 3, 4
DT_HIGH, DL_BACKGROUND, DL_CONTROLS, DL_OVERLAY = 1, 1, 2, 3
TEX_BLEND_MODE_ADD, TEXT_ALIGN_CENTER, MOUSE_BUTTON_INDEX_LEFT = 1, 1, 1
EVENT_ADD_ON_LOADED, EVENT_PLAYER_DEACTIVATED, EVENT_COMBAT_EVENT = 1, 2, 3
ACTION_RESULT_DAMAGE, ACTION_RESULT_CRITICAL_DAMAGE, ACTION_RESULT_DOT_TICK = 1, 2, 3
COMBAT_UNIT_TYPE_PLAYER, COMBAT_UNIT_TYPE_PLAYER_PET, COMBAT_UNIT_TYPE_PLAYER_COMPANION = 1, 2, 3
GuiRoot = NewControl(nil)
GuiRoot:SetDimensions(1920, 1080)
WINDOW_MANAGER = {}
function WINDOW_MANAGER:CreateTopLevelWindow() return NewControl(GuiRoot) end
function WINDOW_MANAGER:CreateControl(_, parent) return NewControl(parent) end
local events, delayed, sounds = {}, {}, {}
EVENT_MANAGER = {}
function EVENT_MANAGER:RegisterForEvent(name, _, callback) events[name] = callback end
function EVENT_MANAGER:UnregisterForEvent(name) events[name] = nil end
function EVENT_MANAGER:AddFilterForEvent() end
HUD_SCENE = { showing = true, IsShowing = function(self) return self.showing end }
SLASH_COMMANDS = {}
SOUNDS = { OUTFIT_WEAPON_TYPE_RUNE = 'normal', VENGEANCE_PERK_EQUIPPED = 'crit', VENGEANCE_PERK_DROP = 'milestone' }
function PlaySound(sound) sounds[#sounds + 1] = sound end
local nowMS = 10000
function GetFrameTimeMilliseconds() return nowMS end
function zo_callLater(callback, delay) delayed[#delayed + 1] = {callback = callback, due = nowMS + delay} end
local settings = { enabled = true, unlocked = false, scale = 100, soundEnabled = true,
    displayMode = 'damageDone', graceMS = 1250, animationIntensity = 80,
    showTimer = true, showModeLabel = true, showHitCount = true, showPeakLabel = true }
local damageSettings = { damageDoneMinigame = settings, savedSctSettings = {} }
Nirnsteel_UI = { Settings = {} }
local Settings = Nirnsteel_UI.Settings
function Settings:GetDamageNumbers() return damageSettings end
function Settings:IsDamageDoneMinigameEnabled() return settings.enabled end
function Settings:IsDamageDoneMinigameUnlocked() return settings.unlocked end
function Settings:IsDamageNumbersEnabled() return false end
function Settings:IsDamageNumbersUnlocked() return false end
function Settings:GetDamageNumbersPosition() return { x = 0, y = 0 } end
function Settings:GetDamageDoneMinigamePosition() return { x = 470, y = 250 } end
function Settings:IsDebugModeEnabled() return true end
dofile('modules/damage_numbers.lua')
local Damage = Nirnsteel_UI.DamageNumbers
Damage:RefreshSettings()
local root = Damage:GetMinigameRoot()
local function Advance(ms)
    nowMS = nowMS + ms
    for i = #delayed, 1, -1 do
        if delayed[i].due <= nowMS then
            local call = table.remove(delayed, i)
            call.callback()
        end
    end
    if root.handlers.OnUpdate then root.handlers.OnUpdate() end
end
local function Reset(mode)
    Damage:ResetDamageDoneMinigame(true)
    nowMS = nowMS + 10000
    settings.displayMode = mode or 'damageDone'
    settings.enabled, settings.unlocked, settings.animationIntensity = true, false, 80
    HUD_SCENE.showing = true
    sounds = {}
end

-- Fast bursts retain all damage, share a delta, and do not erase a crit's impact.
Reset()
Damage:AddDamageDone(1000, false)
Advance(20)
Damage:AddDamageDone(2000, true)
local critStart = Damage.minigameImpact.startMS
for i = 1, 20 do Damage:AddDamageDone(100, false) end
expect(Damage.minigameScore == 5000 and Damage.minigameHitCount == 22, 'burst damage and hit counts must be exact')
expect(Damage.minigameLastDelta.minigameData.value == 5000, 'a burst must coalesce into one delta')
expect(Damage.minigameImpact.startMS == critStart and Damage.minigameImpact.isCrit, 'small ticks must not interrupt a crit')
expect(sounds[1] == 'normal' and sounds[2] == 'crit' and #sounds == 2, 'crit audio must take priority without an AoE sound storm')
Advance(250)
expect(near(Damage.minigameDisplayScore, 5000), 'the displayed score must settle to the exact total')
local pooled = #root.deltas
for i = 1, 100 do Advance(101); Damage:AddDamageDone(1, false) end
expect(#root.deltas == pooled, 'sustained damage must reuse a bounded control pool')

-- One-second attacks stay in grace. A rescue uses timestamp-exact remaining score.
Reset()
Damage:AddDamageDone(10000, false)
Advance(1000)
expect(Damage.minigameScore == 10000, 'the default grace must allow a one-second attack rhythm')
Damage:AddDamageDone(10000, false)
Advance(1750)
expect(near(Damage.minigameScore, 20000 * 2 / 3), 'drain starts at the deadline, not the first rendered frame')
Damage:AddDamageDone(1000, false)
expect(near(Damage.minigameScore, 20000 * 2 / 3 + 1000), 'a draining streak can be rescued')
expect(Damage.minigameHitCount == 3, 'rescue keeps the chain hit count')

-- The result shows the peak briefly, then completely removes its update handler.
Reset()
Damage:AddDamageDone(100000, true)
Advance(2750)
expect(Damage.minigameScore == 0 and root.mainLabel.text == '100,000', 'the result must show peak damage instead of a zero flash')
expect(root.caption.text == 'PEAK DAMAGE DONE  /  1 HIT' and root.timer.width == 310, 'result must clearly identify the peak and settle its underline')
Advance(900)
expect(root.hidden and root.handlers.OnUpdate == nil, 'finished streaks must release their update handler')

-- Expiry is also resolved before a new hit when no render update ran at all.
Reset()
Damage:AddDamageDone(100000, true)
nowMS = nowMS + 4000
Damage:AddDamageDone(1000, false)
expect(Damage.minigameScore == 1000 and Damage.minigameHitCount == 1, 'a stalled frame must not resurrect an expired chain')
expect(Damage.minigameHighestTier == 0 and Damage.minigamePeak == 1000, 'new streaks must reset milestones and peak')

-- DPS spans a rescued chain instead of resetting its denominator during drain.
Reset('dps')
Damage:AddDamageDone(10000, false)
Advance(1000)
Damage:AddDamageDone(10000, false)
Advance(1750)
Damage:AddDamageDone(7500, false)
expect(near(Damage.minigameScore, 10000), 'DPS must include all 27500 damage over the full 2.75-second chain')
expect(Damage.minigameHitCount == 3, 'DPS rescue must retain the chain')

-- Sparse and frequent updates must produce the same score in both modes.
for _, mode in ipairs({'damageDone', 'dps'}) do
    Reset(mode)
    Damage:AddDamageDone(60000, false)
    Advance(2000)
    local sparse = Damage.minigameScore
    Reset(mode)
    Damage:AddDamageDone(60000, false)
    for i = 1, 200 do Advance(10) end
    expect(near(Damage.minigameScore, sparse), 'score must be independent of frame cadence in ' .. mode)
end

-- Timer must deplete continuously and facing must preserve text orientation.
Reset()
Damage:AddDamageDone(1000, false)
Advance(1249)
local beforeDrain = root.timer.width
Advance(2)
expect(root.timer.width < beforeDrain and beforeDrain - root.timer.width < 1, 'timer must not refill when grace ends')
settings.faceRight = true
Damage:ApplyMinigameLayout()
expect(root.visual.rotation > 0 and root.visual.skew > 0, 'right-facing layout must mirror tilt and skew')
settings.faceRight = false
Damage:ApplyMinigameLayout()
expect(root.visual.rotation < 0 and root.visual.skew < 0, 'left-facing layout must restore tilt and skew')

-- A normal hit replacing an old crit must clear all chromatic echoes.
Reset()
Damage:AddDamageDone(2000, true)
Advance(240)
Damage:AddDamageDone(100, false)
Advance(10)
expect(root.echoRed.alpha == 0 and root.echoGold.alpha == 0, 'normal hits must not leave stale critical echoes')
settings.animationIntensity = 0
Damage:AddDamageDone(100000, true)
Advance(16)
expect(root.visual.transformScale == 1 and root.visual.transformOffset[1] == 0, 'zero motion must disable punch and recoil')
expect(root.echoRed.alpha == 0 and root.impactFlash.alpha == 0 and root.shockwave.alpha == 0, 'zero motion must disable impact overlays')
for _, spark in ipairs(root.sparks) do expect(spark.hidden, 'zero motion must hide sparks') end
settings.showModeLabel, settings.showHitCount = false, false
Advance(16)
expect(root.caption.hidden and root.timer.width < 310, 'hiding the caption must preserve the live timer')
settings.showHitCount = true
Advance(16)
expect(root.caption.text == '3 HITS', 'hit count alone must have no mode label or separator')
settings.showModeLabel, settings.showHitCount = true, false
Advance(16)
expect(root.caption.text == 'DAMAGE DONE', 'mode label must work without hit count')
settings.showTimer = false
Advance(16)
expect(not root.caption.hidden and root.timer.width == 310, 'timer toggle must not hide the caption')
settings.showModeLabel = false
Advance(2750)
expect(root.caption.text == 'PEAK' and not root.caption.hidden, 'peak label must work with mode and hit count hidden')
settings.showPeakLabel = false
Advance(16)
expect(root.caption.hidden and root.mainLabel.text == '102,100', 'hiding the peak label must keep the final score')
settings.showTimer, settings.showModeLabel, settings.showHitCount, settings.showPeakLabel = true, true, true, true

-- Preview works over settings; real damage discards all simulated points and callbacks.
Reset()
HUD_SCENE.showing = false
Damage:PreviewDamageDoneMinigame()
Advance(0)
expect(Damage.minigameScore == 11800 and root.alpha > 0, 'preview must be visible over settings')
Damage:AddDamageDone(1000, false)
Advance(40)
expect(Damage.minigameScore == 1000 and Damage.minigameHitCount == 1, 'preview points and delayed hits must not enter a real chain')
expect(root.alpha == 0, 'real combat overlays must be hidden outside the HUD')
HUD_SCENE.showing = true
Advance(10)
expect(root.alpha > 0, 'returning to the HUD must reveal an active chain')

-- Combat routing: outgoing player/pet hits count, incoming and companion hits do not.
Reset()
local function Combat(source, target, value)
    Damage:OnCombatEvent(ACTION_RESULT_DAMAGE, false, '', nil, nil, '', source, '', target, value)
end
Combat(COMBAT_UNIT_TYPE_PLAYER, 99, 1000)
Combat(COMBAT_UNIT_TYPE_PLAYER_PET, 99, 2000)
Combat(COMBAT_UNIT_TYPE_PLAYER_COMPANION, 99, 3000)
Combat(99, COMBAT_UNIT_TYPE_PLAYER, 4000)
expect(Damage.minigameScore == 3000 and Damage.minigameHitCount == 2, 'only eligible outgoing damage belongs to the minigame')

-- Settings changes, disabling, and world changes clean up active and queued state.
Damage.appliedMinigameDisplayMode = 'damageDone'
settings.displayMode = 'dps'
Damage:RefreshSettings()
expect(root.hidden and not Damage.minigameScore, 'mode changes must reset incompatible score state')
Damage:PreviewDamageDoneMinigame()
Advance(0)
settings.enabled = false
Damage:RefreshSettings()
Advance(3000)
expect(root.hidden and not root.handlers.OnUpdate and not Damage.minigameScore, 'disable must cancel the preview and all active visuals')
Reset()
Damage:PreviewDamageDoneMinigame()
Advance(0)
events.NirnsteelUI_DamageNumbers_Deactivated()
Advance(3000)
expect(root.hidden and not Damage.minigameScore, 'world changes must cancel preview callbacks')
print('damage_minigame_regression.lua: all checks passed')

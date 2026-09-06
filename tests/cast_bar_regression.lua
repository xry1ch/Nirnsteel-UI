-- Run from the addon root with Lua 5.1+ or the Fengari CLI.
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
        handlers = {},
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

    function control:SetDrawLevel(value) self.drawLevel = value end
    function control:SetBarAlignment(value) self.barAlignment = value end
    function control:SetMaxLineCount(value) self.maxLines = value end
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

BOTTOMLEFT = "BOTTOMLEFT"
CT_CONTROL, MODIFY_TEXT_TYPE_NONE, BAR_ALIGNMENT_NORMAL = 5, 0, 1
EVENT_ADD_ON_LOADED, EVENT_ACTION_SLOT_ABILITY_USED, EVENT_PLAYER_ACTIVATED = 1, 2, 3
EVENT_SCREEN_RESIZED, EVENT_GAMEPAD_PREFERRED_MODE_CHANGED = 4, 5
ACTION_TYPE_ABILITY, ACTION_TYPE_CRAFTED_ABILITY = 1, 2
local nowMS, hudShowing = 1000, true
local events = {}
function GetFrameTimeMilliseconds() return nowMS end
function zo_clamp(value, minimum, maximum) return math.min(math.max(value, minimum), maximum) end
GuiRoot = NewControl(nil)
GuiRoot:SetDimensions(1920, 1080)
WINDOW_MANAGER = {}
function WINDOW_MANAGER:CreateTopLevelWindow() return NewControl(GuiRoot) end
function WINDOW_MANAGER:CreateControl(_, parent) return NewControl(parent) end
EVENT_MANAGER = {}
function EVENT_MANAGER:RegisterForEvent(name, event, handler) events[name] = handler end
function EVENT_MANAGER:UnregisterForEvent(name) events[name] = nil end
HUD_SCENE = { IsShowing = function() return hudShowing end, RegisterCallback = function() end }
SLASH_COMMANDS = {}
local settings = {
    enabled = true, unlocked = false, scale = 100, width = 400, height = 20,
    opacity = 75, textMode = "nameAndTime", showIcon = true, showTicks = true, animationIntensity = 85,
}
local position = { x = 0, y = -180 }
Nirnsteel_UI = { Settings = {} }
function Nirnsteel_UI.Settings:GetCastBar() return settings end
function Nirnsteel_UI.Settings:GetCastBarPosition() return position end
function Nirnsteel_UI.Settings:IsCastBarEnabled() return settings.enabled end
function Nirnsteel_UI.Settings:IsCastBarUnlocked() return settings.unlocked end
function Nirnsteel_UI.Settings:IsDebugModeEnabled() return false end
function Nirnsteel_UI.Settings:SetCastBarPosition(x, y) position = {x = x, y = y} end
local slotType, abilityId, abilityName, duration = ACTION_TYPE_ABILITY, 123, "Crystal Fragments", 1200
function GetSlotType() return slotType end
function GetSlotBoundId() return abilityId end
function GetSlotName() return abilityName end
function GetSlotTexture() return "ability.dds" end
function GetAbilityCastInfo() return false, duration end
dofile("modules/cast_bar.lua")
local CastBar = Nirnsteel_UI.CastBar
CastBar:RefreshSettings()
local root = CastBar:GetRoot()
local frame = root.frame
local function Advance(ms)
    nowMS = nowMS + ms
    if root.handlers.OnUpdate then root.handlers.OnUpdate() end
end
-- PREVIEW HARNESS BOUNDARY

expect(root.hidden and not root.handlers.OnUpdate, "idle bar must not update")
CastBar:OnActionSlotAbilityUsed(3)
expect(CastBar.active and frame.icon.texture == "ability.dds", "eligible ability must start a cast")
expect(root.height == 20 and frame.track.height == 20 and frame.iconFrame.height == 20,
    "icon and bar must share their full height without an extra label row")
expect(frame.leftLabel.anchor[2] == frame.track and frame.leftLabel.anchor[5] == 2
    and frame.rightLabel.anchor[2] == frame.track and frame.rightLabel.anchor[5] == 2,
    "name and timer must share the optical centering offset inside the track")
expect(not frame.castGlow.hidden and frame.castGlow.alpha > 0.5, "cast start must provide immediate feedback")
expect(frame.leftLabel.maxLines == 1 and frame.leftLabel.modifyTextType == MODIFY_TEXT_TYPE_NONE,
    "ability names must retain casing and stay on one line")
Advance(300)
expect(near(frame.bar.value, 0.25) and near(root.alpha, 0.75), "fill must track actual time and respect opacity")
expect(frame.leftLabel.text == "Crystal Fragments" and frame.rightLabel.text == "0.3 / 1.2", "labels must reflect cast state")
expect(frame.wake.anchor[4] >= 0 and frame.wake.anchor[4] + frame.wake.width <= CastBar.trackWidth * frame.bar.value + 0.001,
    "wake must stay within filled progress")
expect(frame.ticks[1].alpha > frame.ticks[2].alpha, "progress marks must change only after being passed")
expect(frame.ticks[1].width > 1 and frame.ticks[2].width == 1, "only recently passed marks should flash")
expect(not frame.chargeSweep.hidden and frame.chargeSweep.alpha > 0, "casting must animate a traveling highlight")
expect(frame.chargeSweep.anchor[4] >= 0
    and frame.chargeSweep.anchor[4] + frame.chargeSweep.width <= CastBar.trackWidth * frame.bar.value + 0.001,
    "traveling highlight must stay within filled progress")
expect(frame.leftLabel.drawLevel > frame.feedbackFlash.drawLevel
    and frame.leftLabel.drawLevel > frame.textShade.drawLevel, "feedback must render below the text")
Advance(900)
expect(CastBar.phase == "complete" and frame.bar.value == 1 and not CastBar.active, "deadline must enter completion")
expect(not frame.feedbackFlash.hidden and frame.feedbackFlash.alpha > 0.5, "completion must flash immediately")
local initialGlowExpansion = math.abs(frame.finishGlow.anchor[4])
Advance(180)
expect(not frame.finishGlow.hidden and frame.finishGlow.alpha > 0, "completion feedback must stay alive through its hold")
expect(math.abs(frame.finishGlow.anchor[4]) > initialGlowExpansion, "completion glow must expand away from the frame")
local staleId = CastBar.castId
CastBar:StartCast(124, "Next Ability", "next.dds", 2000)
expect(frame.finishGlow.hidden and frame.finishSweep.hidden and frame.bar.value == 0
    and frame.feedbackFlash.color[1] < 1, "a new cast must clear previous completion effects and restore blue feedback")
CastBar:Complete(staleId)
expect(CastBar.active, "a stale completion must not finish a replacement cast")
Advance(2580)
expect(root.hidden and not root.handlers.OnUpdate and not CastBar.phase, "a delayed frame must finish all expired phases")

settings.animationIntensity = 0
CastBar:Preview()
Advance(800)
expect(frame.wake.hidden and near(root.alpha, 0.75), "zero intensity must disable decorative motion")
expect(frame.castGlow.hidden and frame.iconGlow.hidden and frame.chargeSweep.hidden and frame.feedbackFlash.hidden,
    "zero intensity must disable all additional casting effects")
for _, tick in ipairs(frame.ticks) do expect(tick.width == 1, "zero intensity must suppress mark flashes") end
Advance(2400)
Advance(180)
expect(frame.finishGlow.hidden and frame.finishSweep.hidden, "zero intensity must suppress completion effects")
expect(frame.feedbackFlash.hidden and frame.iconGlow.hidden, "zero intensity must suppress completion impact")
Advance(200)
local fadeAlpha = root.alpha
expect(CastBar.phase == "exit" and fadeAlpha < 0.75, "completion must fade out")
CastBar:ApplyLayout()
expect(near(root.alpha, fadeAlpha), "layout changes must not restart the fade")
Advance(200)
expect(root.hidden and root.handlers.OnUpdate == nil, "fade must detach the updater")

settings.animationIntensity = 160
for _, width in ipairs({220, 400, 620}) do
    for _, height in ipairs({18, 20, 48}) do
        for _, textMode in ipairs({"nameAndTime", "nameOnly", "timerOnly", "off"}) do
            for _, showIcon in ipairs({true, false}) do
                settings.width, settings.height, settings.textMode, settings.showIcon = width, height, textMode, showIcon
                CastBar:StartCast(1, "An unusually long ability name that must remain on one line", "", 120)
                Advance(60)
                expect(frame.leftLabel.width > 0 and CastBar.trackWidth > 0, "all supported layouts need positive content widths")
                expect(frame.rightLabel.width >= 86, "timer must retain readable space at the smallest width")
                expect(frame.iconFrame.hidden == not showIcon, "icon toggle must apply")
                expect(root.height == height and frame.track.height == height and frame.iconFrame.height == height,
                    "icon and rail alignment must survive all sizes and text modes")
                expect(frame.iconFrame.anchor[5] == frame.track.anchor[5], "icon and rail must retain the same center")
                expect(frame.leftLabel.height <= height and frame.rightLabel.height <= height,
                    "labels must fit vertically inside the configured bar")
                expect(frame.leftLabel.width + frame.rightLabel.width + 24 <= frame.track.width or textMode ~= "nameAndTime",
                    "name and timer must reserve non-overlapping horizontal space")
                expect(frame.leftLabel.hidden == (textMode == "off" or textMode == "timerOnly"), "name visibility must follow text mode")
                expect(frame.rightLabel.hidden == (textMode == "off" or textMode == "nameOnly"), "timer visibility must follow text mode")
                expect(frame.leadingEdge.anchor[4] + frame.leadingEdge.width <= CastBar.trackWidth + 0.001, "leading edge must stay within the rail")
                expect(root.alpha <= settings.opacity / 100, "high intensity must never exceed configured opacity")
                for _, effect in ipairs({frame.wake, frame.castGlow, frame.iconGlow, frame.chargeSweep, frame.feedbackFlash}) do
                    expect(effect.alpha >= 0 and effect.alpha <= 1, "effect alpha must remain bounded at maximum intensity")
                end
            end
        end
    end
end

settings.showTicks = false
CastBar:RefreshSettings()
for _, tick in ipairs(frame.ticks) do expect(tick.hidden, "progress mark toggle must apply mid-cast") end
hudShowing = false
CastBar:UpdateVisibility()
expect(root.hidden and not root.handlers.OnUpdate, "leaving the HUD must clear the bar and effects immediately")
hudShowing = true
CastBar:Preview()
settings.enabled = false
CastBar:RefreshSettings()
expect(root.hidden and CastBar:GetMover().hidden, "disabling must hide the bar and mover")
CastBar:Preview()
expect(root.hidden and not CastBar.active, "disabled module must reject previews")
settings.enabled = true
settings.unlocked = true
CastBar:RefreshSettings()
expect(not CastBar:GetMover().hidden, "unlocked mover must remain available while idle")
CastBar:SetSettingsPreviewActive(true)
expect(CastBar.active, "settings preview must use the casting animation")
CastBar:SetSettingsPreviewActive(false)
expect(root.hidden and not CastBar.previewActive, "closing preview must stop all animation")

for _, name in ipairs({"Heavy Attack", "Light Attack", "Weapon Attack"}) do
    abilityName = name
    CastBar:OnActionSlotAbilityUsed(3)
    expect(root.hidden, "weapon attacks must remain excluded")
end
abilityName = "Crystal Fragments"
duration = 0
CastBar:OnActionSlotAbilityUsed(3)
expect(root.hidden, "instant abilities must remain excluded")
duration = 2000
slotType = 99
CastBar:OnActionSlotAbilityUsed(3)
expect(root.hidden, "non-ability slots must remain excluded")
slotType = ACTION_TYPE_CRAFTED_ABILITY
CastBar:OnActionSlotAbilityUsed(3)
expect(CastBar.active, "crafted abilities must still trigger")
Advance(250)
CastBar:Hide(false)
Advance(220)
expect(root.hidden and not root.handlers.OnUpdate, "explicit hide must finish cleanly")
print("Cast bar regression checks passed")

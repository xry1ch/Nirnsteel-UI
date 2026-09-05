-- Run from the addon root with Lua 5.1+ (or the Fengari CLI).
local function expect(value, message)
    if not value then error(message, 2) end
end

local nowMS, gamepad = 0, false
local events, updates, callbacks = {}, {}, {}
local sounds = {}
local available, synergyName, icon, prompt = false, "", "", ""
local nativeCalls = 0
EVENT_ADD_ON_LOADED, EVENT_PLAYER_ACTIVATED, EVENT_SCREEN_RESIZED = 1, 2, 3
CT_CONTROL, CT_BACKDROP, CT_TEXTURE, CT_LABEL = 1, 2, 3, 4
CT_POLYGON, CENTER, TOP = 5, 6, 7
POLYGON_POINT_LAYOUT_CLOCKWISE, POLYGON_BORDER_DIRECTION_IN, TEX_BLEND_MODE_ADD = 1, 1, 1
unpack = unpack or table.unpack
TOPLEFT, BOTTOMRIGHT, LEFT, RIGHT, BOTTOM = 1, 2, 3, 4, 5
DT_HIGH, DL_CONTROLS, TEXT_ALIGN_CENTER, MOUSE_BUTTON_INDEX_LEFT = 1, 1, 1, 1
DL_BACKGROUND, DL_ARTWORK = 0, 2
TEXT_ALIGN_LEFT = 0
ZO_COMMON_INFO_DEFAULT_KEYBOARD_BOTTOM_OFFSET_Y = -210
ZO_COMMON_INFO_DEFAULT_GAMEPAD_BOTTOM_OFFSET_Y = -245
SI_USE_SYNERGY = "Use %s"
SOUNDS = { ABILITY_SYNERGY_READY = "original-ready" }

function GetFrameTimeMilliseconds() return nowMS end
function IsInGamepadPreferredMode() return gamepad end
function GetWorldName() return "EU Megaserver" end
function GetDisplayName() return "@Test" end
function GetCurrentCharacterId() return "123" end
function GetString(value) return tostring(value) end
function zo_round(value) return math.floor(value + 0.5) end
function zo_strformat(format, value) return format == "<<1>>" and (value or "") or string.format(format, value or "") end
function PlaySound(sound) sounds[#sounds + 1] = sound end
function ActivateSynergy() error("the visual replacement must not activate a synergy") end
function GetCurrentSynergyInfo() return available, synergyName, icon, prompt end

EVENT_MANAGER = {}
function EVENT_MANAGER:RegisterForEvent(name, event, handler) events[name] = { event = event, handler = handler } end
function EVENT_MANAGER:UnregisterForEvent(name) events[name] = nil end
function EVENT_MANAGER:RegisterForUpdate(name, interval, handler) updates[name] = { interval = interval, handler = handler } end
function EVENT_MANAGER:UnregisterForUpdate(name) updates[name] = nil end
CALLBACK_MANAGER = {}
function CALLBACK_MANAGER:RegisterCallback(name, handler)
    callbacks[name] = callbacks[name] or {}
    table.insert(callbacks[name], handler)
end
local function FireCallback(name, panel)
    for _, handler in ipairs(callbacks[name] or {}) do handler(panel) end
end

local function NewControl(parent)
    local control = { parent = parent, children = {}, handlers = {}, hidden = false, width = 0, height = 0, text = "" }
    if parent then table.insert(parent.children, control) end
    function control:IsHidden() return self.hidden end
    function control:IsControlHidden() return self.hidden or (self.parent and self.parent:IsControlHidden()) or false end
    function control:SetHidden(hidden)
        local before = {}
        local function Capture(c)
            before[c] = c:IsControlHidden()
            for _, child in ipairs(c.children) do Capture(child) end
        end
        local function Notify(c)
            local effective = c:IsControlHidden()
            if before[c] ~= effective then
                local handler = c.handlers[effective and "OnEffectivelyHidden" or "OnEffectivelyShown"]
                if handler then handler(c) end
            end
            for _, child in ipairs(c.children) do Notify(child) end
        end
        Capture(self)
        self.hidden = hidden
        Notify(self)
    end
    function control:SetHandler(name, handler) self.handlers[name] = handler end
    function control:GetHandler(name) return self.handlers[name] end
    function control:SetDimensions(w, h) self.width, self.height = w, h end
    function control:SetWidth(w) self.width = w end
    function control:SetHeight(h) self.height = h end
    function control:GetWidth() return self.width end
    function control:GetHeight() return self.height end
    function control:SetAnchor(...) self.anchor = { ... } end
    function control:ClearAnchors() self.anchor = nil end
    function control:SetAnchorFill(target) self.anchorFill = target end
    function control:SetAlpha(value) self.alpha = value end
    function control:SetScale(value) self.scale = value end
    function control:SetTexture(value) self.texture = value end
    function control:SetColor(...) self.color = { ... } end
    function control:SetCenterColor(...) self.centerColor = { ... } end
    function control:SetEdgeColor(...) self.edgeColor = { ... } end
    function control:SetEdgeTexture(...) self.edgeTexture = { ... } end
    function control:SetFont(value) self.font = value end
    function control:SetText(value) self.text = value end
    function control:GetTextHeight() return math.max(1, math.ceil(#self.text * 11 / math.max(1, self.width))) * 24 end
    function control:GetTextWidth() return #self.text * 11 end
    function control:SetVerticalAlignment(value) self.verticalAlignment = value end
    function control:SetHorizontalAlignment(value) self.horizontalAlignment = value end
    function control:SetBlendMode(value) self.blendMode = value end
    function control:SetDrawLevel(value) self.drawLevel = value end
    function control:SetTransformRotationZ(value) self.rotation = value end
    function control:SetPointLayout(value) self.pointLayout = value end
    function control:SetSmoothingEnabled(value) self.smoothing = value end
    function control:SetBorderThickness(...) self.borderThickness = { ... } end
    function control:SetBorderColor(...) self.borderColor = { ... } end
    function control:SetBorderDirection(value) self.borderDirection = value end
    function control:AddPoint(x, y)
        self.points = self.points or {}
        self.points[#self.points + 1] = { x, y }
    end
    function control:SetTransformScale(value)
        self.transformScale = value
        self.transformScaleWrites = (self.transformScaleWrites or 0) + 1
    end
    function control:SetTransformNormalizedOriginPoint(...) self.origin = { ... } end
    function control:SetDrawTier(value) self.tier = value end
    function control:SetDrawLayer(value) self.layer = value end
    function control:SetMouseEnabled(value) self.mouseEnabled = value end
    function control:SetClampedToScreen(value) self.clamped = value end
    function control:SetMovable(value) self.movable = value end
    function control:StartMoving() self.startedMoving = true end
    function control:StopMovingOrResizing()
        if self.startedMoving then
            self.startedMoving = false
            self.handlers.OnMoveStop(self)
        end
    end
    function control:GetCenter() return self.centerX or 960, 540 end
    function control:GetBottom() return self.bottom or 1080 end
    return control
end

GuiRoot = NewControl()
GuiRoot:SetDimensions(1920, 1080)
WINDOW_MANAGER = {}
function WINDOW_MANAGER:CreateControl(_, parent, kind)
    local control = NewControl(parent)
    control.kind = kind
    return control
end
function WINDOW_MANAGER:CreateTopLevelWindow() return NewControl(GuiRoot) end
function WINDOW_MANAGER:CreateControlFromVirtual(_, parent, template)
    expect(template == "ZO_KeybindButton", "use ESO's native binding widget")
    local key = NewControl(parent)
    function key:SetKeybind(binding) self.binding = binding end
    key:SetDimensions(44, 35)
    return key
end
function ApplyTemplateToControl(control, template)
    control.template = template
    control.width = gamepad and 94 or 44
    -- Templates may change geometry synchronously: layout must not recurse.
    if control.handlers.OnRectChanged then control.handlers.OnRectChanged(control) end
end
function ZO_PostHook(object, method, callback)
    local original = object[method]
    object[method] = function(...)
        local result = original(...)
        callback(...)
        return result
    end
end
function ZO_PostHookHandler(control, name, callback)
    local original = control.handlers[name]
    control.handlers[name] = function(...)
        if original then original(...) end
        callback(...)
    end
end

-- Exercise actual settings initialization, including adding defaults to old profiles.
local saved = {}
ZO_SavedVars = {}
function ZO_SavedVars:NewAccountWide(name, version, _, defaults, server)
    expect(version == 1, "adding synergy settings must not reset saved-variable versions")
    local key = name .. server
    saved[key] = saved[key] or {}
    return saved[key]
end
ZO_SavedVars.NewCharacterIdSettings = ZO_SavedVars.NewAccountWide
local menuOptions
LibAddonMenu2 = {}
function LibAddonMenu2:RegisterAddonPanel() end
function LibAddonMenu2:RegisterOptionControls(_, options) menuOptions = options end
dofile("modules/settings.lua")
local settings = Nirnsteel_UI.Settings
settings:Initialize()
local config = settings:GetSynergyAlert()
expect(config.enabled and not config.unlocked and config.scale == 100 and config.opacity == 100
    and config.animationIntensity == 85, "old profiles must receive the new defaults")
expect(not settings:GetSynergyAlertPosition().custom, "new positions must follow native layout")

local misc, previousName
for _, option in ipairs(menuOptions) do
    if option.type == "submenu" then
        local name = string.lower(option.name)
        expect(not previousName or previousName < name, "module categories must remain sorted")
        previousName = name
        if option.name == "Misc" then misc = option end
    end
end
expect(misc and misc.icon and misc.controls[1].name == "Synergy Alert", "Misc must contain Synergy Alert")
expect(#misc.controls == 8, "expose the essential controls and two buttons")

local nativeRoot = NewControl(GuiRoot)
nativeRoot:SetHidden(true)
SYNERGY = { control = nativeRoot, container = NewControl(nativeRoot) }
function SYNERGY:ApplyTextStyle() end
-- Contract of the unmodified ESO handler: only a changed name plays the ready sound.
function SYNERGY:OnSynergyAbilityChanged()
    nativeCalls = nativeCalls + 1
    if available then
        if self.lastSynergyName ~= synergyName then
            PlaySound(SOUNDS.ABILITY_SYNERGY_READY)
            self.lastSynergyName = synergyName
        end
    else
        self.lastSynergyName = nil
    end
    self.control:SetHidden(not available)
    return "native-result"
end

dofile("modules/synergy_alert.lua")
local alert = Nirnsteel_UI.SynergyAlert
events.NirnsteelUI_SynergyAlert_Loaded.handler(nil, "NirnsteelUI")
expect(alert.initialized and SYNERGY.container.hidden, "enabled replacement must hide only native contents")
expect(alert.live.parent == nativeRoot and alert.live:IsControlHidden(), "native parent must own live visibility")
expect(#sounds == 0 and nativeCalls == 0, "initializing must not call the native sound handler")
expect(alert.live.key.binding == "USE_SYNERGY" and alert.preview.key.binding == "USE_SYNERGY", "retain original action")
expect(alert.live.anchor[5] == -210, "keyboard placement must use the native offset")

available, synergyName, icon, prompt = true, "Combustion", "combustion.dds", ""
nowMS = 100
expect(SYNERGY:OnSynergyAbilityChanged() == "native-result", "post-hook must preserve native execution")
expect(#sounds == 1 and sounds[1] == "original-ready", "native handler must play the original sound once")
expect(not alert.live:IsControlHidden() and alert.live.label.text == "Combustion", "default caption must use the synergy name")
expect(alert.live.icon:GetWidth() == 112 and alert.live.icon.parent == alert.live.hero
    and alert.live.details.anchor[1] == TOP and alert.live.details.anchor[5] == 148,
    "the large centered icon must lead, with a separate caption below")
expect(alert.live.key.parent == alert.live.details and alert.live.label.parent == alert.live.details
    and alert.live.label.anchor[2] == alert.live.key and alert.live.label.anchor[4] == 8,
    "the key and caption must form a single compact row centered beneath the icon")
local function CheckArtworkSafety(control)
    expect(control.kind ~= CT_POLYGON, "no filled decorative polygons may obscure the ability artwork")
    expect(control.kind ~= CT_BACKDROP, "neither the icon nor binding should gain a filled background box")
    for _, child in ipairs(control.children) do CheckArtworkSafety(child) end
end
CheckArtworkSafety(alert.live)
expect(alert.live.glow.layer == DL_BACKGROUND and alert.live.icon.layer == DL_ARTWORK
    and alert.live.icon.color[1] == 1 and alert.live.icon.color[4] == 1,
    "the unmodified ability artwork must render above the additive glow")
for _, strip in ipairs(alert.live.border) do
    expect(math.abs(strip.anchor[4]) - strip.width * 0.5 >= 56
        or math.abs(strip.anchor[5]) - strip.height * 0.5 >= 56,
        "border strips must stay outside the entire icon")
end
expect(alert.live.details.anchor[5] > 72 + 56,
    "the action row must remain below the icon")
expect(alert.live.details.width == alert.live.key.width + 8 + alert.live.label.width,
    "the row must fit its content exactly so its visual center aligns with the icon")
local entrance = alert.live.entranceStartMS
local liveAnchor = alert.live.anchor
local iconScaleWrites = alert.live.hero.transformScaleWrites
local glowScaleWrites = alert.live.glow.transformScaleWrites
nowMS = 180
SYNERGY:OnSynergyAbilityChanged()
expect(alert.live.entranceStartMS == entrance and #sounds == 1, "repeated events must not restart sound or entrance")
expect(alert.live.anchor == liveAnchor, "repeated synergy events must not rebuild an unchanged layout")
nowMS = 316
alert.live.handlers.OnUpdate()
expect(alert.live.hero.transformScale == 1 and alert.live.hero.alpha > 0 and alert.live.hero.alpha < 1,
    "arrival must fade smoothly without scaling the icon")
nowMS = 460
alert.live.handlers.OnUpdate()
expect(alert.live.hero.alpha == 1 and alert.live.frame.alpha == 1, "icon fade must finish after 300ms")
local labelAnchor = alert.live.label.anchor
nowMS = 980
alert.live.handlers.OnUpdate()
expect(alert.live.glow.alpha > 0.36 and alert.live.hero.transformScale == 1
    and alert.live.label.anchor == labelAnchor, "idle glow must leave text stationary")
-- Irregular frame times and position notifications must never move or resize artwork.
local previousAlpha = 0
for _, elapsed in ipairs({ 0, 7, 16, 33, 80, 120, 216, 300, 501, 1600, 2700, 5000 }) do
    nowMS = entrance + elapsed
    alert.live.handlers.OnUpdate()
    alert.live.key.handlers.OnRectChanged()
    expect(alert.live.hero.alpha >= previousAlpha and alert.live.hero.alpha <= 1,
        "fade must be monotonic with no overshoot at irregular frame rates")
    previousAlpha = alert.live.hero.alpha
    expect(alert.live.anchor == liveAnchor and alert.live.label.anchor == labelAnchor
        and alert.live.hero.transformScaleWrites == iconScaleWrites
        and alert.live.glow.transformScaleWrites == glowScaleWrites,
        "animation and position-only binding updates must not touch layout or transforms")
end

nativeRoot:SetHidden(true)
expect(alert.live.handlers.OnUpdate == nil, "native suppression must stop animation updates")
nativeRoot:SetHidden(false)
expect(alert.live.handlers.OnUpdate ~= nil and #sounds == 1, "unsuppression must resume silently")
prompt = "A different localized instruction"
SYNERGY:OnSynergyAbilityChanged()
expect(alert.live.label.text == prompt and alert.live.entranceStartMS == entrance, "prompt-only changes refresh without entrance")
nowMS = 1100
synergyName, icon = "Healing Combustion", "healing.dds"
SYNERGY:OnSynergyAbilityChanged()
expect(alert.live.icon.texture == icon and alert.live.entranceStartMS == nowMS and #sounds == 2,
    "a new synergy must replace content, animate, and retain native sound")
available = false
SYNERGY:OnSynergyAbilityChanged()
expect(alert.live:IsControlHidden() and alert.live.handlers.OnUpdate == nil and alert.live.identity == nil,
    "unavailable synergy must hide and clear animation identity")
available = true
nowMS = 1300
SYNERGY:OnSynergyAbilityChanged()
expect(#sounds == 3 and alert.live.entranceStartMS == nowMS, "reacquiring a synergy follows native repeat behavior")

settings:SetSynergyAlertValue("animationIntensity", 0)
expect(alert.live.handlers.OnUpdate == nil and alert.live.frame.alpha == 1 and alert.live.frame.transformScale == 1,
    "zero intensity must produce a static visible prompt")
expect(alert.live.hero.transformScale == 1 and alert.live.glow.transformScale == 1,
    "zero intensity must reset the icon and glow scales")
settings:SetSynergyAlertValue("enabled", false)
expect(not SYNERGY.container.hidden and alert.live.hidden, "disabling must restore native content immediately")
local callsBeforeRefresh, soundsBeforeRefresh = nativeCalls, #sounds
settings:SetSynergyAlertValue("enabled", true)
expect(SYNERGY.container.hidden and not alert.live.hidden, "re-enabling must restore the custom prompt")
expect(nativeCalls == callsBeforeRefresh and #sounds == soundsBeforeRefresh, "settings must not replay native sound")

-- Geometry changes, controller style, reset, and persisted offsets.
gamepad = true
SYNERGY:ApplyTextStyle()
expect(alert.live.anchor[5] == -245 and alert.live.key.template == "ZO_KeybindButton_Gamepad_Template",
    "controller mode must follow native layout and glyph template")
settings:SetSynergyAlertPosition(50, -320)
alert:ApplyLayout()
expect(alert.live.anchor[4] == 50 and alert.live.anchor[5] == -320, "custom offsets must apply")
gamepad = false
SYNERGY:ApplyTextStyle()
expect(alert.live.anchor[5] == -320, "input mode changes must preserve custom offsets")
prompt = string.rep("Long localized synergy instruction ", 8)
SYNERGY:OnSynergyAbilityChanged()
expect(alert.live:GetHeight() > 74, "long text must expand the panel vertically")
alert.live.key.width = 200
alert.live.key.handlers.OnRectChanged()
expect(alert.live.details.width == 200 + 8 + alert.live.label.width
    and alert.live.width >= alert.live.details.width,
    "wide controller bindings must expand the centered row without overlapping the caption")
settings:ResetSynergyAlertPosition()
expect(not settings:GetSynergyAlertPosition().custom and alert.live.anchor[5] == -210, "reset must restore native placement")

-- Preview uses separate state, a finite timer, and no sounds or activation.
local liveIdentity, liveText = alert.live.identity, alert.live.label.text
soundsBeforeRefresh = #sounds
alert:Preview()
expect(alert.previewActive and not alert.preview.hidden and alert.live.hidden, "preview must display only one custom panel")
expect(alert.live.identity == liveIdentity and alert.live.label.text == liveText and #sounds == soundsBeforeRefresh,
    "preview must not alter live state or play a sound")
expect(updates.NirnsteelUI_SynergyAlert_Preview.interval == 4000, "locked preview must expire after four seconds")
settings:SetSynergyAlertValue("opacity", 80)
settings:SetSynergyAlertValue("animationIntensity", 85)
expect(alert.previewActive and alert.preview.alpha == 0.8 and alert.preview.handlers.OnUpdate
    and updates.NirnsteelUI_SynergyAlert_Preview, "editing settings must keep an active preview visible and animated")
synergyName, prompt = "New live synergy", "Use the new synergy"
SYNERGY:OnSynergyAbilityChanged()
expect(alert.preview.label.text ~= prompt and alert.live.label.text == prompt, "real changes must update behind the preview")
updates.NirnsteelUI_SynergyAlert_Preview.handler()
expect(not alert.previewActive and not alert.live.hidden and alert.preview.hidden
    and not updates.NirnsteelUI_SynergyAlert_Preview, "preview expiry must restore the latest live state and remove timer")

local panel = { GetName = function() return "Nirnsteel_UI_Settings" end }
FireCallback("LAM-PanelOpened", panel)
settings:SetSynergyAlertValue("unlocked", true)
expect(alert.previewActive and alert.preview.mouseEnabled and not updates.NirnsteelUI_SynergyAlert_Preview,
    "unlocked settings preview must remain draggable without a timer")
alert.preview.handlers.OnMouseDown(alert.preview, MOUSE_BUTTON_INDEX_LEFT)
alert.preview.centerX, alert.preview.bottom = 1015, 770
alert.preview.handlers.OnMouseUp(alert.preview, MOUSE_BUTTON_INDEX_LEFT)
expect(settings:GetSynergyAlertPosition().x == 55 and settings:GetSynergyAlertPosition().y == -310,
    "dragging must save bottom-center offsets")
FireCallback("LAM-PanelClosed", panel)
expect(not alert.previewActive and alert.preview.handlers.OnUpdate == nil, "closing settings must clean up preview")
alert:Preview()
settings:SetSynergyAlertValue("enabled", false)
expect(alert.preview.hidden and alert.live.hidden and not SYNERGY.container.hidden
    and not updates.NirnsteelUI_SynergyAlert_Preview, "disabling during preview must restore native UI and cancel its timer")
settings:SetSynergyAlertValue("enabled", true)

settings:SetSynergyAlertValue("scale", 125)
settings:SetSynergyAlertValue("opacity", 65)
expect(alert.live.scale == 1.25 and alert.live.alpha == 0.65, "appearance changes must apply live")
settings:Initialize()
expect(settings:GetSynergyAlert().scale == 125 and settings:GetSynergyAlertPosition().x == 55,
    "initializing again must preserve appearance and position")
settings:SetSynergyAlertValue("scale", 999)
expect(settings:GetSynergyAlert().scale == 160, "numeric settings must clamp to supported ranges")
settings:SetSynergyAlertValue("enabled", false)
SYNERGY.container:SetHidden(true)
settings:SetSynergyAlertValue("enabled", true)
settings:SetSynergyAlertValue("enabled", false)
expect(SYNERGY.container.hidden, "restore pre-existing native container state rather than force-showing it")

print("synergy_alert_regression.lua: all checks passed")

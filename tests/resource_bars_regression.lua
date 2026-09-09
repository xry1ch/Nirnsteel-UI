-- Focused Lua 5.1 regression checks for player resource fill colors.
-- Run from the addon root with: lua51.exe tests/resource_bars_regression.lua

local function expect(condition, message)
    if not condition then
        error(message, 2)
    end
end

COMBAT_MECHANIC_FLAGS_HEALTH = 1
COMBAT_MECHANIC_FLAGS_MAGICKA = 2
COMBAT_MECHANIC_FLAGS_STAMINA = 3
RESOURCE_NUMBERS_SETTING_NUMBER_ONLY = 1
RESOURCE_NUMBERS_SETTING_PERCENT_ONLY = 2
RESOURCE_NUMBERS_SETTING_NUMBER_AND_PERCENT = 3
BAR_ALIGNMENT_NORMAL = 1
BAR_ALIGNMENT_CENTER = 2
BAR_ALIGNMENT_REVERSE = 3
EVENT_ADD_ON_LOADED = 1

EVENT_MANAGER =
{
    RegisterForEvent = function()
    end,
}

local function NewLabel()
    return
    {
        SetDrawLevel = function()
        end,
    }
end

local function NewStatusBar()
    local statusBar = {}
    function statusBar:SetGradientColors(...)
        self.gradient = { ... }
    end
    return statusBar
end

local BarVisuals =
{
    Fonts = { gameSmall = "mock-font" },
    Create = function()
        return
        {
            bar = NewStatusBar(),
            centerLabel = NewLabel(),
            leftLabel = NewLabel(),
            rightLabel = NewLabel(),
        }
    end,
    SetAlignment = function(_, frame, alignment)
        frame.appliedAlignment = alignment
    end,
}

Nirnsteel_UI = { BarVisuals = BarVisuals }
assert(loadfile("modules/resource_bars.lua"))()
local ResourceBars = Nirnsteel_UI.ResourceBars

local function GetUpvalue(callback, wantedName)
    local index = 1
    while true do
        local name, value = debug.getupvalue(callback, index)
        if not name then
            return nil
        end
        if name == wantedName then
            return value
        end
        index = index + 1
    end
end

local resourceData = GetUpvalue(ResourceBars.RefreshPowerValues, "RESOURCE_DATA")
expect(resourceData ~= nil, "resource data must remain available to refresh player powers")

ResourceBars.root = {}
ResourceBars.bars = {}
for _, key in ipairs({ "health", "magicka", "stamina" }) do
    ResourceBars:CreateResourceBar(key, resourceData[key])
end

local healthGradient = ResourceBars.bars.health.bar.gradient
expect(healthGradient[1] == 0.98 and healthGradient[2] == 0.18
    and healthGradient[3] == 0.20 and healthGradient[4] == 0.98,
    "player health must use the established bright red color")
expect(healthGradient[1] == healthGradient[5]
    and healthGradient[2] == healthGradient[6]
    and healthGradient[3] == healthGradient[7]
    and healthGradient[4] == healthGradient[8],
    "player health must use identical gradient endpoints for a uniform fill")

for _, key in ipairs({ "magicka", "stamina" }) do
    local gradient = ResourceBars.bars[key].bar.gradient
    local endpointsDiffer = gradient[1] ~= gradient[5]
        or gradient[2] ~= gradient[6]
        or gradient[3] ~= gradient[7]
        or gradient[4] ~= gradient[8]
    expect(endpointsDiffer, key .. " must retain its existing gradient")
end

expect(ResourceBars.bars.health.alignment == BAR_ALIGNMENT_CENTER,
    "health must retain its centered fill direction")
expect(ResourceBars.bars.magicka.alignment == BAR_ALIGNMENT_REVERSE,
    "magicka must retain its reverse fill direction")
expect(ResourceBars.bars.stamina.alignment == BAR_ALIGNMENT_NORMAL,
    "stamina must retain its normal fill direction")

-- Exercise actual anchors and mover bounds with unequal bar widths.
TOP = 1
local settings = { rowHealthWidth = 300, rowMagickaWidth = 250, rowStaminaWidth = 270 }
local hideHealth = false
Nirnsteel_UI.Settings = {
    GetResourceBars = function() return settings end,
    ShouldHardcoreHideHealthResourceBar = function() return hideHealth end,
}
local function NewControl()
    return {
        SetDimensions = function(self, width, height) self.width, self.height = width, height end,
        SetHidden = function(self, hidden) self.hidden = hidden end,
        ClearAnchors = function() end,
        SetAnchor = function(self, _, _, _, x, y) self.x, self.y = x, y end,
    }
end
ResourceBars.root = NewControl()
ResourceBars.mover = NewControl()
ResourceBars.bars = { health = NewControl(), magicka = NewControl(), stamina = NewControl() }
ResourceBars.UpdateLabelLayout = function() end

local cases = {
    { nil, false, 528, 55, 0, 0, -139, 30, 129, 30 },
    { "invalid", false, 528, 55, 0, 0, -139, 30, 129, 30 },
    { "pyramid", true, 528, 25, 0, 0, -139, 0, 129, 0 },
    { "linear", false, 836, 25, -10, 0, -293, 0, 283, 0 },
    { "linear", true, 528, 25, -10, 0, -139, 0, 129, 0 },
    { "stacked", false, 300, 85, 0, 0, 0, 30, 0, 60 },
    { "stacked", true, 270, 55, 0, 0, 0, 0, 0, 30 },
}
for _, case in ipairs(cases) do
    settings.layout, hideHealth = case[1], case[2]
    ResourceBars:ApplyLayoutGeometry()
    local description = tostring(case[1]) .. " hideHealth=" .. tostring(hideHealth)
    for _, control in ipairs({ ResourceBars.root, ResourceBars.mover }) do
        expect(control.width == case[3] and control.height == case[4], description .. " bounds")
    end
    for index, key in ipairs({ "health", "magicka", "stamina" }) do
        local bar = ResourceBars.bars[key]
        expect(bar.x == case[3 + index * 2] and bar.y == case[4 + index * 2], description .. " " .. key .. " anchor")
        expect(bar.hidden == (key == "health" and hideHealth), description .. " " .. key .. " visibility")
    end
end

TOPLEFT, BOTTOMLEFT = 2, 3
local stockStamina = {}
local mount = { anchors = { { TOPLEFT, stockStamina, BOTTOMLEFT, 0, -1 } } }
function mount:GetNumAnchors() return #self.anchors end
function mount:GetAnchor(index) return true, unpack(self.anchors[index + 1]) end
function mount:ClearAnchors() self.anchors = {} end
function mount:SetAnchor(...) table.insert(self.anchors, { ... }) end
ZO_PlayerAttribute = { GetNamedChild = function(_, name)
    if name == "MountStamina" then return mount end
end }
local enabled = true
Nirnsteel_UI.Settings.IsResourceBarsEnabled = function() return enabled end
for _, layout in ipairs({ "pyramid", "linear", "stacked" }) do
    settings.layout = layout
    ResourceBars:ApplyLayoutGeometry()
    ResourceBars:ApplyMountStaminaAnchor()
    expect(mount.anchors[1][2] == ResourceBars.bars.stamina
        and mount.anchors[1][1] == TOPLEFT and mount.anchors[1][3] == BOTTOMLEFT,
        layout .. " must attach mount stamina below character stamina")
    expect(mount.anchors[1][5] == 5, "mount attachment must use vertical spacing")
end
settings.attachMountStamina = false
ResourceBars:ApplyMountStaminaAnchor()
expect(mount.anchors[1][2] == stockStamina and mount.anchors[1][5] == -1,
    "turning attachment off must restore the original anchor")
settings.attachMountStamina = true
ResourceBars:ApplyMountStaminaAnchor()
enabled = false
ResourceBars:ApplyMountStaminaAnchor()
expect(mount.anchors[1][2] == stockStamina and mount.anchors[1][5] == -1,
    "disabling resource bars must restore the original mount anchor")

print("resource_bars_regression.lua: all checks passed")

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

print("resource_bars_regression.lua: all checks passed")

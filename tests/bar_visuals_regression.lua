-- Focused Lua 5.1 regression checks for modules/bar_visuals.lua transition behavior.
-- Run from the addon root with: lua51.exe tests/bar_visuals_regression.lua

local function expect(condition, message)
    if not condition then
        error(message, 2)
    end
end

Nirnsteel_UI = {}
assert(loadfile("modules/bar_visuals.lua"))()
local BarVisuals = Nirnsteel_UI.BarVisuals

local function NewStatusBar()
    local control = {}
    function control:SetMinMax(minimum, maximum)
        self.minimum = minimum
        self.maximum = maximum
    end
    function control:SetValue(value)
        self.directValue = value
    end
    function control:SetHidden(hidden)
        self.hidden = hidden
    end
    return control
end

local frame =
{
    bar = NewStatusBar(),
    patternBar = NewStatusBar(),
    nirnsteelStyle = {},
}

local transitionCalls = {}
ZO_StatusBar_SmoothTransition = function(bar, current, maximum, forceValue)
    transitionCalls[#transitionCalls + 1] =
    {
        bar = bar,
        current = current,
        maximum = maximum,
        forceValue = forceValue,
    }
end

BarVisuals:SetValue(frame, 30, 100, true, false)
expect(#transitionCalls == 1 and transitionCalls[1].forceValue == false,
    "smooth updates must use ESO's normal transition path")

BarVisuals:SetValue(frame, 80, 100, false, false)
expect(#transitionCalls == 2 and transitionCalls[2].forceValue == true,
    "snap updates must force the value and cancel an in-flight transition")
expect(transitionCalls[2].current == 80 and transitionCalls[2].maximum == 100,
    "forced updates must snap to the new unit's exact resource values")

ZO_StatusBar_SmoothTransition = nil
BarVisuals:SetValue(frame, 55, 100, false, false)
expect(frame.bar.directValue == 55,
    "snap updates must retain a direct SetValue fallback when ESO's helper is unavailable")

print("bar_visuals_regression.lua: all checks passed")

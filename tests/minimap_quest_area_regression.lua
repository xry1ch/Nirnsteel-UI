local H = dofile("tests/minimap_harness.lua")
local M, S = H.module, H.settings
local function expect(v, message) if not v then error(message, 2) end end
local function color(r, g, b)
    return {UnpackRGBA = function() return r, g, b, 1 end}
end
ZO_MAP_PIN_ASSISTED_COLOR = color(0.2, 0.7, 0.9)
ZO_MAP_PIN_NORMAL_COLOR = color(0.7, 0.7, 0.7)
ZO_MapPin.ASSISTED_PIN_TYPES = {[2] = true}
local tracking = 2
function GetTrackingLevel() return tracking end
function GetQuestPinTypeForTrackingLevel(_, level) return level end
local function condition(radius)
    return {xLoc = 0.51, yLoc = 0.51, insideCurrentMapWorld = true, pinType = 1, areaRadius = radius}
end
local function questPin()
    local found
    for i = 1, M.activePinCount do
        if M.pinPool[i].data.kind == "quest" then
            expect(not found, "duplicate point and search conditions produce one pin")
            found = M.pinPool[i]
        end
    end
    return found
end
for _, radii in ipairs({{0, 0.04}, {0.04, 0}}) do
    H.questSteps = {[1] = {[1] = {condition(radii[1]), condition(radii[2])}}}
    CALLBACK_MANAGER:FireCallbacks("QuestAvailable"); H:Tick()
    local pin = questPin()
    expect(pin and pin.data.radius == 0.04 and not pin.area.hidden, "search radius survives either duplicate order")
    expect(pin.area.shaderEffectType == SHADER_EFFECT_TYPE_HALO, "search region uses native world-map halo")
    expect(pin.area.color[3] == 0.9, "tracked area uses native assisted blue")
    expect(math.abs(pin.area:GetWidth() - 0.08 * M.span) < 1e-6, "area preserves map-space radius")
    expect(pin.area.level < pin.icon.level, "region renders beneath markers")
end
tracking = 1
CALLBACK_MANAGER:FireCallbacks("QuestTrackerAssistStateChanged"); H:Tick()
expect(questPin().area.color[3] == 0.7, "changing tracked quest updates area color")
S:SetMinimapValue("shape", "rectangle")
S:SetMinimapValue("orientation", "rotating")
H.heading = 0.7; H:Tick()
local pin = questPin()
local x, y = M:Project(pin.data.x, pin.data.y)
local cx, cy = M.viewport:GetCenter()
local ax, ay = pin.area:GetCenter()
expect(math.abs(ax - cx - x) < 1e-6 and math.abs(ay - cy - y) < 1e-6, "area follows rotated map")
expect(pin.area.rectClip and not pin.area.circleClip, "search region clips to current shape")
S:SetMinimapValue("showQuests", false); H:Tick()
expect(not questPin() and pin.area.hidden, "quest filter removes the region")
S:SetMinimapValue("showQuests", true); H:Tick()
H.questSteps = {}; CALLBACK_MANAGER:FireCallbacks("QuestRemoved"); H:Tick()
expect(not questPin(), "completed quest removes search region")
print("minimap_quest_area_regression.lua: all checks passed")

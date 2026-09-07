local H = dofile("tests/minimap_harness.lua")
local M, S = H.module, H.settings
local function expect(value, message) if not value then error(message, 2) end end
local function near(a, b) return math.abs(a - b) < 0.00001 end

H.playerMap = H.map + 1
H:Tick(33)
expect(H.map == H.playerMap and M.mapReady, "zone crossings refresh before the one-second map check")

-- Every visible point must sample the map, including at minimum zoom and
-- rotated rectangular corners. Clicks and the player use the same origin.
for _, shape in ipairs({"circle", "rectangle"}) do
    S:SetMinimapValue("shape", shape)
    S:SetMinimapValue("orientation", "rotating")
    S:SetMinimapValue("width", 460)
    S:SetMinimapValue("height", 240)
    for _, zoom in ipairs({1, 2.5, 8}) do
        S:SetMinimapValue("zoom", zoom)
        for _, point in ipairs({{0.01, 0.01}, {0.99, 0.01}, {0.01, 0.99}, {0.99, 0.99}, {0.5, 0.5}}) do
            for _, angle in ipairs({0, 0.7, math.pi / 2, 4.2}) do
                M.angle = nil
                M:UpdateTransform(point[1], point[2], angle, 1)
                for i = 0, 64 do
                    local a = i * math.pi / 32
                    local x, y
                    if shape == "circle" then
                        x, y = math.cos(a) * M.width / 2, math.sin(a) * M.height / 2
                    else
                        x, y = M:EdgePoint(math.cos(a), math.sin(a), 0)
                    end
                    local mx, my = M:Unproject(x, y)
                    expect(mx >= -1e-8 and mx <= 1 + 1e-8 and my >= -1e-8 and my <= 1 + 1e-8,
                        "map covers viewport at all borders, rotations and zooms")
                end
                local px, py = M:Project(point[1], point[2])
                local mx, my = M:Unproject(px, py)
                expect(near(mx, point[1]) and near(my, point[2]), "border projection remains invertible")
            end
        end
    end
end

MAP_FILTER_TYPE_BATTLEGROUND, MAP_PIN_TYPE_INVALID = "battleground", "invalid"
local active, filter, objectives = true, MAP_FILTER_TYPE_BATTLEGROUND, {}
function IsActiveWorldBattleground() return active end
function GetMapFilterType() return filter end
function GetNumObjectives() return #objectives end
function GetObjectiveIdsForIndex(i) return 0, i, objectives[i].context or "local" end
function IsLocalBattlegroundContext(context) return context == "local" end
function IsBattlegroundObjective(_, id) return not objectives[id].ava end
function IsObjectiveEnabled(_, id) return not objectives[id].disabled end
function IsObjectiveObjectVisible(_, id) return not objectives[id].invisible end
function GetObjectiveInfo(_, id) return objectives[id].name end
local function info(id, key)
    return unpack(objectives[id][key] or {MAP_PIN_TYPE_INVALID, 0, 0})
end
function GetObjectivePinInfo(_, id) return info(id, "current") end
function GetObjectiveSpawnPinInfo(_, id) return info(id, "spawn") end
function GetObjectiveReturnPinInfo(_, id) return info(id, "returnPin") end
function GetObjectiveAuraPinInfo(_, id) return info(id, "aura") end
ZO_MapPin.PIN_DATA = {}
for _, name in ipairs({"flag", "ball", "relic", "capture", "spawn", "return", "aura", "enemy"}) do
    ZO_MapPin.PIN_DATA[name] = {texture = name .. ".dds"}
end
for _, name in ipairs({"flag", "ball", "relic", "capture"}) do
    objectives[#objectives + 1] = {name = name, current = {name, 0.51, 0.51}}
end
objectives[1].spawn = {"spawn", 0.49, 0.49}
objectives[1].returnPin = {"return", 0.52, 0.52}
objectives[1].aura = {"aura", 0.2, 0.6, 0.9}
objectives[5] = {name = "disabled", disabled = true, current = {"flag", 0.5, 0.5}}
objectives[6] = {name = "other campaign", context = "remote", current = {"flag", 0.5, 0.5}}
objectives[7] = {name = "hidden", invisible = true, current = {"flag", 0.5, 0.5}}
objectives[8] = {name = "outside", current = {"flag", 1.5, 0.5}}
objectives[9] = {name = "invalid", current = {MAP_PIN_TYPE_INVALID, 0.5, 0.5}}
objectives[10] = {name = "Cyrodiil", ava = true, current = {"flag", 0.5, 0.5}}
local function pins()
    local found = {}
    for i = 1, M.activePinCount do
        local pin = M.pinPool[i]
        if pin.data.kind == "objective" then found[#found + 1] = pin end
    end
    return found
end
S:SetMinimapValue("orientation", "north")
S:SetMinimapValue("zoom", 2.5)
S:SetMinimapValue("showLocations", false)
S:SetMinimapValue("showQuests", false)
S:SetMinimapValue("showGroup", false)
H:Tick()
expect(#pins() == 7, "flags, balls, relics, capture points, spawn, return and aura render independently of PvE filters")
expect(pins()[3].icon.color[2] == 0.6, "aura uses live team tint")
expect(pins()[4].icon.level > pins()[3].icon.level, "objective stays above its aura")
objectives[1].current = {"enemy", 0.55, 0.48}
H:Tick()
expect(pins()[4].data.icon == "enemy.dds" and pins()[4].data.x == 0.55, "carried objective position and ownership update each frame")
objectives[1].invisible = true
H:Tick()
expect(#pins() == 5, "hidden carrier removes current marker and aura while keeping bases")
active = false; H:Tick()
expect(#pins() == 0, "leaving battleground clears objective pins")
active, filter = true, "zone"; H:Tick()
expect(#pins() == 0, "battleground pins cannot leak onto a different map")
filter = MAP_FILTER_TYPE_BATTLEGROUND
M:Preview(); H:Tick()
expect(#pins() == 0, "preview excludes live match objectives")
M:StopPreview()
objectives = {}; H:Tick()
expect(#pins() == 0, "empty or ended match clears pooled pins")
print("minimap_objectives_regression.lua: all checks passed")

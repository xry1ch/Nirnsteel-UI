local H = dofile("tests/minimap_harness.lua")
local M, S = H.module, H.settings
local function expect(v, message) if not v then error(message, 2) end end
local active, shown, tracked = true, true, true
local border = {0.4, 0.42, 0.58, 0.4, 0.61, 0.55, 0.49, 0.6, 0.39, 0.52}
function GetNumInProgressAntiquities() return active and 2 or 0 end
function GetNumDigSitesForInProgressAntiquity() return 1 end
function GetInProgressAntiquityDigSiteId() return 123 end
function GetDigSiteNormalizedCenterPosition() return 0.5, 0.5, shown end
function GetDigSiteNormalizedBorderPoints() return unpack(border) end
function IsDigSiteAssociatedWithTrackedAntiquity() return tracked end
ZO_MAP_PIN_TRACKED_DIG_SITE_COLOR = {UnpackRGBA = function() return 1, 1, 1, 1 end}
ZO_MAP_PIN_DIG_SITE_COLOR = {UnpackRGBA = function() return 0.5, 0.5, 0.5, 1 end}
H:Tick(1100)
expect(#M.digSites == 1, "shared dig site deduplicates")
local polygon = M.digSitePool[1]
expect(not polygon.hidden and #polygon.points == 5, "irregular region appears without opening world map")
expect(polygon.fillColor[1] == 1 and polygon.fillColor[4] == 0.14, "opaque native fill stays translucent on minimap")
expect(polygon.border == 1.25 and polygon.borderColor[4] == 0.85, "thin readable outline remains independent of fill opacity")
for _, shape in ipairs({"circle", "rectangle"}) do
    S:SetMinimapValue("shape", shape)
    S:SetMinimapValue("orientation", "rotating")
    H.heading = 1.2; H:Tick()
    for i, p in ipairs(polygon.points) do
        local x, y = M:Project(border[i * 2 - 1], border[i * 2])
        local cx, cy = M.viewport:GetCenter()
        expect(math.abs(polygon:GetLeft() + p[1] * polygon:GetWidth() - cx - x) < 1e-6, "border x aligns with terrain")
        expect(math.abs(polygon:GetTop() + p[2] * polygon:GetHeight() - cy - y) < 1e-6, "border y aligns with terrain")
    end
    expect(shape == "circle" and polygon.circleClip or shape == "rectangle" and polygon.rectClip, "region clips to shape")
end
tracked = false; H:Tick(1100)
expect(polygon.fillColor[1] == 0.5 and polygon.fillColor[4] == 0.09, "untracked fill is more subtle")
shown = false; H:Tick(1100)
expect(polygon.hidden, "other map sites disappear")
shown = true; border = {0.4, 0.4, 0.6, 0.4, 0.5, 0.6}; H:Tick(1100)
expect(not polygon.hidden and #polygon.points == 3, "pool resets changed vertex counts")
border = {0.4, 0.4, 0.6}; H:Tick(1100)
expect(polygon.hidden, "invalid border rejected")
active = false; H:Tick(1100)
expect(#M.digSites == 0 and polygon.hidden, "completed sites removed")
print("minimap_dig_site_regression.lua: all checks passed")

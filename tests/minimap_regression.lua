-- Run from the addon root with Lua 5.1+ or Fengari.
local H = dofile("tests/minimap_harness.lua")
local M, S = H.module, H.settings
local function expect(v, message) if not v then error(message, 2) end end
local function near(a, b, epsilon) return math.abs(a - b) <= (epsilon or 0.00001) end
local function config(key, value) S:SetMinimapValue(key, value); H:Tick() end
local function count(kind)
    local n = 0
    for i = 1, M.activePinCount or 0 do if M.pinPool[i].data.kind == kind then n = n + 1 end end
    return n
end
local function quest(x, y, extra)
    local d = extra or {}; d.xLoc, d.yLoc, d.insideCurrentMapWorld, d.pinType = x, y, true, 1
    return { [1] = { [1] = d } }
end

expect(S:GetMinimap().enabled and S:GetMinimap().diameter == 280 and S:GetMinimap().orientation == "north", "new profiles get selected defaults")
expect(S:GetMinimapPosition().x == -32 and S:GetMinimapPosition().y == -48, "default bottom-right offsets")
expect(M.mapReady and M.available and not M.root.hidden, "activation draws a live map")
expect(near(M.root:GetRight(), 1888) and near(M.root:GetBottom(), 1032), "whole widget uses selected screen margins")
expect(H.mapChanges == 0 and H.mapNotifications == 0, "matching map requires no selection or notifications")
expect(count("wayshrine") == 1 and count("location") == 1, "known, current-map wayshrines only; deduplicate location providers")
-- A translucent backing/shadow above the textures made the live client almost
-- black, despite a bright diagnostic preview that used to sort by level alone.
local layerOrder = { [DL_BACKGROUND] = 0, [DL_CONTROLS] = 1, [DL_OVERLAY] = 2, [DL_TEXT] = 3 }
local function drawsBefore(a, b)
    expect(a.tier == DT_MEDIUM and b.tier == DT_MEDIUM, "mixed drawable kinds must have explicit matching tiers")
    return layerOrder[a.layer] < layerOrder[b.layer] or (a.layer == b.layer and a.level < b.level)
end
for _, shape in ipairs({ "circle", "rectangle" }) do
    config("shape", shape)
    local f, tile = M.frames[shape], M.tilePool[1]
    expect(drawsBefore(f.backing, tile) and drawsBefore(f.shadow, tile), "dark surfaces render behind terrain in " .. shape)
    expect(drawsBefore(f.backing, M.player) and drawsBefore(f.backing, M.pinPool[1].icon), "dark surfaces cannot cover navigation markers")
    expect(f.shadow.fillColor[4] == 0, "shadow has no fill across the map center")
    expect(tile.color[1] == 1 and tile.color[2] == 1 and tile.color[3] == 1 and tile.color[4] == 1, "map tiles retain their original brightness")
    expect(drawsBefore(tile, f.bevel) and f.bevel.fillColor[4] == 0, "metal edging overlays terrain without a filled center")
    local opacity = M.terrain.alpha
    config("shadow", false); config("frameOpacity", 35)
    expect(M.terrain.alpha == opacity and M.player.color[1] > 0.9, "frame settings leave terrain opacity and marker brightness intact")
    config("shadow", true); config("frameOpacity", 100)
end
config("shape", "circle")
-- Rectangular frame geometry must match the straight native terrain clip.
-- Native polygon smoothing bends sparse contours; our SVG preview used to
-- ignore that flag and therefore missed the expanded frame seen in ESO.
for _, dimensions in ipairs({ {220, 500}, {340, 240}, {600, 160} }) do
    config("width", dimensions[1]); config("height", dimensions[2]); config("shape", "rectangle")
    for _, orientation in ipairs({ "north", "rotating" }) do
        config("orientation", orientation); H.heading = 1.1; H:Tick()
        local cx, cy = M.viewport:GetCenter()
        for _, entry in ipairs({ {"backing", 0, 0}, {"outer", 10, 0}, {"bevel", 5, 0}, {"inner", 1, 0}, {"shadow", 19, 3} }) do
            local frame = M.frames.rectangle[entry[1]]
            expect(not frame.hidden and frame.smoothing == false, "rectangular " .. entry[1] .. " must retain straight edges in ESO")
            local fx, fy = frame:GetCenter()
            expect(near(fx, cx) and near(fy, cy + entry[3]), "rectangular frame stays centered on terrain")
            expect(near(frame:GetWidth(), M.width + entry[2]) and near(frame:GetHeight(), M.height + entry[2]), "frame retains constant edging at every aspect ratio")
            expect(#frame.points == 4, "rectangular frame has four corners")
            for i, p in ipairs(frame.points) do
                local nextPoint = frame.points[i % 4 + 1]
                expect((p[1] == 0 or p[1] == 1) and (p[2] == 0 or p[2] == 1), "corners remain at control bounds")
                expect((p[1] == nextPoint[1]) ~= (p[2] == nextPoint[2]), "frame sides remain horizontal or vertical")
            end
        end
        for _, frame in pairs(M.frames.circle) do expect(frame.hidden, "rectangle hides the entire circular frame") end
    end
    config("shape", "circle")
    for _, frame in pairs(M.frames.rectangle) do expect(frame.hidden, "circle hides the entire rectangular frame") end
end
config("width", 340); config("height", 240); config("orientation", "north"); H.heading = 0
local submenu, previous
for _, option in ipairs(H.menu) do
    if option.type == "submenu" then
        expect(not previous or previous < option.name:lower(), "module menu remains alphabetized")
        previous = option.name:lower()
        if option.name == "Minimap" then submenu = option end
    end
end
expect(submenu and submenu.icon and #submenu.controls >= 35, "complete settings panel registered with icon")
local selected = S:GetMinimap()
config("zoom", 3.5); S.account.modules.lootHistory.enabled = false
S:Initialize()
expect(S:GetMinimap().zoom == 3.5 and not S.account.modules.lootHistory.enabled, "initialization preserves old settings")
expect(S:GetMinimap() == selected, "settings initialization retains module table")

-- All four combinations share exact forward/inverse math and preserve aspect.
for _, shape in ipairs({ "circle", "rectangle" }) do
    for _, orientation in ipairs({ "north", "rotating" }) do
        config("shape", shape); config("orientation", orientation)
        M.angle = nil
        M:UpdateTransform(0.42, 0.63, 1.2, 1)
        local x, y = M:Project(0.51, 0.58)
        local mx, my = M:Unproject(x, y)
        expect(near(mx, 0.51) and near(my, 0.58), "projection inverse for " .. shape .. "/" .. orientation)
        local ax, ay = M:Project(0.52, 0.63)
        local bx, by = M:Project(0.42, 0.73)
        expect(near(ax * ax + ay * ay, bx * bx + by * by), "rectangular view cannot stretch terrain")
        if shape == "circle" then
            expect(not M:Contains(130, 130) and M:Contains(140, 0), "true circle hit testing")
            expect(M.tilePool[1].circleClip and not M.tilePool[1].rectClip, "switch clears rectangular tile clip")
        else
            expect(M:Contains(160, 110), "rectangular corner remains usable")
            expect(M.tilePool[1].rectClip and not M.tilePool[1].circleClip, "switch clears circular tile clip")
        end
    end
end
M.angle = math.pi * 2 - 0.02
M:UpdateTransform(0.5, 0.5, 0.02, 1 / 30)
expect(M.angle > 6.25 or M.angle < 0.02, "rotation takes shortest path across north")
config("orientation", "north"); config("shape", "circle"); config("zoom", 2.5)
config("width", 420); config("diameter", 320)
config("shape", "rectangle"); expect(M.width == 420, "rectangle width retained")
config("shape", "circle"); expect(M.width == 320, "circle diameter retained")
local clipX = M.tilePool[1].circleClip[1]
S:GetMinimapPosition().x = -200; M:Layout()
expect(M.tilePool[1].circleClip[1] ~= clipX, "moving refreshes drawable clipping")
expect(near(M.tilePool[1].circleClip[3], 160), "resize updates actual circular radius")
M:ResetPosition(); config("diameter", 280)

-- The unbound-by-default action uses the cursor and displayed transform,
-- without requiring Ctrl or an accompanying mouse click.
config("orientation", "rotating"); H.heading = 1.4; H:Tick()
H:Mouse(30, -20); H.ctrl = true
M:HandleClick(MOUSE_BUTTON_INDEX_LEFT)
H.ctrl = false; M:HandleClick(MOUSE_BUTTON_INDEX_LEFT)
expect(#H.pings == 0, "neither Ctrl-click nor plain left click places a waypoint")
H.cursor = false; M:PlaceWaypointAtCursor()
expect(#H.pings == 0, "keybind rejects a hidden cursor even before the next update")
H.cursor = true
expect(SI_BINDING_NAME_NIRNSTEEL_MINIMAP_WAYPOINT == "Minimap: Place Waypoint at Cursor", "keybind has a controls-menu label")
local mx, my = M:Unproject(30, -20)
M:PlaceWaypointAtCursor()
expect(#H.pings == 1 and near(H.pings[1][3], mx) and near(H.pings[1][4], my), "rotated waypoint projection")
H:Mouse(130, 130); M:PlaceWaypointAtCursor()
expect(#H.pings == 1, "circle corner cannot place waypoint")
H:Tick(); local wx, wy = M:Project(H.waypointX, H.waypointY)
H:Mouse(wx, wy); H.ctrl = false; M:HandleClick(MOUSE_BUTTON_INDEX_RIGHT)
expect(H.removedWaypoints == 1, "right click removes only the hit personal waypoint")
H:Mouse(80, 60); M:HandleClick(MOUSE_BUTTON_INDEX_RIGHT)
expect(H.removedWaypoints == 1, "empty terrain cannot clear waypoint")
config("orientation", "north"); H.x, H.y = 0.02, 0.02; H:Tick(); H:Mouse(-80, -80); H.ctrl = true
M:PlaceWaypointAtCursor(); expect(#H.pings == 1, "reject projected coordinates outside map bounds")
H.x, H.y, H.ctrl = 0.5, 0.5, false; H:Tick()
H.waypointX, H.waypointY = 0.98, 0.5; H:Tick()
expect(not M.waypointArrow.hidden and M:Contains(select(1, M.waypointArrow:GetCenter()) - select(1, M.viewport:GetCenter()), 0), "waypoint clamps inside circle")
config("waypointEdge", false); expect(M.waypointArrow.hidden, "edge indicator toggle")
config("showWaypoint", false); expect(count("waypoint") == 0, "waypoint filter")
config("showWayshrines", false); expect(count("wayshrine") == 0 and count("location") == 1, "location provider cannot bypass wayshrine filter")
config("showLocations", false); expect(count("location") == 0, "location filter")

H.questSteps = { [1] = quest(0.51, 0.51, { areaRadius = 0.04, isBreadcrumb = true }), [2] = quest(0.52, 0.53) }
CALLBACK_MANAGER:FireCallbacks("QuestAvailable"); H:Tick()
expect(count("quest") == 1, "tracked quest filter and delayed breadcrumb delivery")
local p = M.pinPool[1]; expect(p.data.icon == "door.dds" and not p.area.hidden, "native breadcrumb icon and search area")
config("questMode", "all"); expect(count("quest") == 2, "all journal quest filter")
config("showQuests", false); expect(count("quest") == 0, "quest filter hides areas and pins")
H.groups = {
    group1 = { x = 0.51, y = 0.49, shown = true, leader = true },
    group2 = { x = 0.52, y = 0.49, shown = true, sameInstance = false },
    group3 = { x = 0.53, y = 0.49, shown = true, sameLayer = false },
    group4 = { x = 0.54, y = 0.49, shown = false },
    group5 = { x = 0.55, y = 0.49, shown = true, online = false },
}
H.groupTags = { "group1", "group2", "group3", "group4", "group5" }; H.dungeon = true; H:Tick()
expect(count("group") == 1, "exclude offline, wrong map/instance/layer group members")
H.groups.group3.breadcrumb = true; H:Tick(); expect(count("group") == 2, "native group floor breadcrumbs remain available")
config("showGroup", false); expect(count("group") == 0, "group filter")

-- No static scans or control allocation per movement frame after pools warm up.
local reads, allocations = H.staticReads, #H.controls
for i = 1, 12 do H.x = 0.5 + i * 0.0001; H:Tick() end
expect(H.staticReads == reads and #H.controls == allocations, "movement reuses controls and static data")
H.playerShown = false; H:Tick(); expect(not M.available and M.pins.hidden and not M.status.hidden, "invalid player position clears navigation")
H.playerShown, H.x = true, 0 / 0; H:Tick(); expect(not M.available, "NaN player coordinates rejected")
H.x = 0.5; H:Tick(); expect(M.available, "valid player coordinates recover")

-- Opening either full-map scene relinquishes selection through every transition.
for _, name in ipairs({ "worldMap", "gamepad_worldMap", "inventory" }) do
    H:SetScene("hud", SCENE_HIDING); expect(M.root.hidden, "hide at start of HUD transition")
    H:SetScene(name); H.map = 999; local changes = H.mapChanges
    H:Tick(2000); M:RefreshMap(); H.ctrl = true; H:Mouse(0, 0); M:PlaceWaypointAtCursor()
    expect(H.mapChanges == changes and H.map == 999 and not H.updates.NirnsteelUI_Minimap, "browsing owns map and suspends updates")
    H:SetScene("hud"); H:Tick()
    expect(H.map == H.playerMap and M.available and H.mapChanges == changes + 1, "closing menu resumes player map once")
end
H.ctrl = false
local notifications = H.mapNotifications
H:Tick(1100); expect(H.mapNotifications == notifications, "unchanged map never notifies listeners")
H.playerMap = 11; H:Tick(1100)
expect(M.mapKey == "11:1" and #M.staticPins == 0, "zone switch invalidates previous quest data")
H.floor = 2; H:Tick(); expect(M.mapKey == "11:2", "floor changes refresh immediately")
H.noTexture = true; H.floor = 3; H:Tick(); expect(not M.available, "missing tiles produce unavailable state")
H.noTexture = false; H:Tick(1100); expect(M.available, "tile retry recovers")
H.failSelection = true; H.map = 999; H:Tick(1100); expect(not M.available, "failed selection cannot show stale map")
H.failSelection = false; H:Tick(1100); expect(M.available, "selection retry recovers")
H:Event(EVENT_START_FAST_TRAVEL_INTERACTION); H:Tick(); expect(M.root.hidden, "travel suspends minimap before scene change")
H:Event(EVENT_END_FAST_TRAVEL_INTERACTION); H:Tick(); expect(M.available and not M.root.hidden, "travel end resumes")
H:Event(EVENT_PLAYER_COMBAT_STATE, true); expect(not M.root.hidden, "combat default remains visible")
config("combatBehavior", "dim"); expect(near(M.root.alpha, 0.4), "combat dim opacity")
config("combatBehavior", "hide"); expect(M.root.hidden and not H.updates.NirnsteelUI_Minimap, "combat hide suspends updates")
H:Event(EVENT_PLAYER_COMBAT_STATE, false); H:Tick(); expect(not M.root.hidden, "combat end resumes")

config("clickThrough", true); H:Mouse(0, 0); H:Tick()
expect(not M.input.mouseEnabled and M.toolbar.hidden, "click-through disables interaction")
config("unlocked", true); expect(M.mover.mouseEnabled and not M.mover.hidden and M.root.mouseEnabled and not M.input.mouseEnabled, "unlock overrides click-through only for dragging")
config("unlocked", false); config("clickThrough", false); H.cursor = false; H:Tick()
expect(not M.input.mouseEnabled and not M.root.mouseEnabled, "game camera input stays untouched")
H.cursor = true; H:Tick(); local zoom = S:GetMinimap().zoom
M.input.handlers.OnMouseWheel(nil, 1); expect(near(S:GetMinimap().zoom, zoom + 0.25), "wheel zoom increment")
config("wheelZoom", false); zoom = S:GetMinimap().zoom; M.input.handlers.OnMouseWheel(nil, 1)
expect(S:GetMinimap().zoom == zoom, "wheel zoom can be disabled")
config("zoom", 1000); expect(S:GetMinimap().zoom == 8, "out-of-range settings clamped")
config("zoom", 0 / 0); expect(S:GetMinimap().zoom == 2.5, "non-finite settings use default")

H:SetScene("gameMenu"); M:SetSettingsPanelVisible(true)
local changes, pings = H.mapChanges, #H.pings
M:Preview(); H:Mouse(0, 0); H.ctrl = true; M:PlaceWaypointAtCursor()
expect(M.preview and not M.root.hidden and H.mapChanges == changes and #H.pings == pings, "preview works in settings without selecting maps or creating waypoints")
config("shape", "rectangle"); expect(M.preview and M.width == 420, "preview reflects settings live")
M:SetSettingsPanelVisible(false); expect(not M.preview and M.root.hidden, "closing settings clears sample data")
H:SetScene("hud"); H:Tick()
M:Preview(); H:Tick(12001); H:Tick(); expect(not M.preview and M.available, "preview expires and resumes live data")
config("enabled", false)
expect(M.root.hidden and not H.updates.NirnsteelUI_Minimap and not H.updates.NirnsteelUI_Minimap_Visibility, "disable stops all update timers")
expect(not H.events.NirnsteelUI_Minimap_EVENT_POI_UPDATED, "disable unregisters runtime data events")
local countControls = #H.controls
config("enabled", true); H:Tick(); expect(M.available and #H.controls == countControls, "re-enable reuses controls without leaked views")
H:Event(EVENT_PLAYER_DEACTIVATED); expect(M.root.hidden and not H.updates.NirnsteelUI_Minimap, "loading screen cleanup")
H:Event(EVENT_PLAYER_ACTIVATED); H:Tick(); expect(M.available, "activation restores minimap")
-- Unlock in settings provides a persistent mover even with click-through set.
H:SetScene("gameMenu"); M:SetSettingsPanelVisible(true)
config("clickThrough", true); config("unlocked", true)
H:Tick(13000)
expect(M.preview and not M.root.hidden and M.mover.mouseEnabled, "unlocked settings preview persists beyond sample duration")
M:SetSettingsPanelVisible(false); H:SetScene("hud"); H:Tick()
expect(not M.preview, "closing settings stops persistent preview")
-- Hidden/owned maps and cursor behavior must also recover after gamepad changes.
H.gamepad = true; H:Event(EVENT_GAMEPAD_PREFERRED_MODE_CHANGED); H:Tick()
expect(M.available, "gamepad preferred mode keeps HUD rendering")
H.interacting = true; H:Tick(); expect(M.root.hidden, "other interactions suspend map selection")
H.interacting = false; H:Event(EVENT_INTERACTION_ENDED); H:Tick()
expect(M.available and not M.root.hidden, "interaction end resumes HUD")
S:ResetMinimapSettings(); H:Tick()
expect(S:GetMinimap().shape == "circle" and S:GetMinimap().zoom == 2.5 and not S:GetMinimap().unlocked, "reset restores module defaults")
expect(not S.account.modules.lootHistory.enabled, "module reset leaves other modules intact")
expect(S:GetMinimapPosition().x == -32 and S:GetMinimapPosition().y == -48, "reset restores position")

-- Exercise the drawables, not just Project/Unproject: the original rotation
-- moved native clip space even though forward/inverse algebra still passed.
expect(M.playerHalo == nil, "player arrow has no background ring")
local function texturePoint(c, u, v)
    local ox, oy = c.textureOrigin[1], c.textureOrigin[2]
    local px, py = c:GetLeft() + ox * c:GetWidth(), c:GetTop() + oy * c:GetHeight()
    local dx, dy = (u - ox) * c:GetWidth(), (v - oy) * c:GetHeight()
    local a = -(c.textureRotation or 0) -- Native texture rotations are counterclockwise.
    return px + dx * math.cos(a) - dy * math.sin(a), py + dx * math.sin(a) + dy * math.cos(a)
end
local function terrainPoint(x, y)
    local column, row = math.floor(x * M.columns), math.floor(y * M.rows)
    local tile = M.tilePool[row * M.columns + column + 1]
    return texturePoint(tile, x * M.columns - column, y * M.rows - row)
end
local function vertex(c, i)
    return c:GetLeft() + c.points[i][1] * c:GetWidth(), c:GetTop() + c.points[i][2] * c:GetHeight()
end
local function fixedClip(c)
    local cx, cy = M.viewport:GetCenter()
    if S:GetMinimap().shape == "circle" then
        expect(c.circleClip and not c.rectClip and near(c.circleClip[1], cx)
            and near(c.circleClip[2], cy) and near(c.circleClip[3], M.width / 2), "circle clip stays at the viewport")
    else
        expect(c.rectClip and not c.circleClip and near(c.rectClip[1], M.viewport:GetLeft())
            and near(c.rectClip[2], M.viewport:GetTop()) and near(c.rectClip[3], M.viewport:GetRight())
            and near(c.rectClip[4], M.viewport:GetBottom()), "rectangle clip stays at the viewport")
    end
end
H.groups, H.groupTags = {}, {}
for i, point in ipairs({ {0.49, 0.49}, {0.51, 0.49}, {0.49, 0.51}, {0.51, 0.51} }) do
    local tag = "group" .. i
    H.groupTags[i] = tag
    H.groups[tag] = { x = point[1], y = point[2], shown = true }
end
H.x, H.y, H.ctrl = 0.47, 0.52, true
H.waypointX, H.waypointY = 0.99, 0.99
for _, shape in ipairs({ "circle", "rectangle" }) do
    config("shape", shape); config("orientation", "rotating")
    config(shape == "circle" and "diameter" or "width", shape == "circle" and 360 or 460)
    S:GetMinimapPosition().x, S:GetMinimapPosition().y = -330, -160; M:Layout()
    for _, zoom in ipairs({1, 2.5, 8}) do
        config("zoom", zoom)
        for _, heading in ipairs({0, math.pi / 2, math.pi, math.pi * 1.5, 1.2}) do
            H.heading, M.angle = heading, nil
            M:Render(1)
            local cx, cy = M.viewport:GetCenter()
            local px, py = terrainPoint(H.x, H.y)
            expect(near(px, cx, 0.36) and near(py, cy, 0.36), "terrain beneath player stays centered at every heading and zoom")
            local arrowX, arrowY = M.player:GetCenter()
            expect(near(arrowX, cx) and near(arrowY, cy) and near(M.player.textureRotation, 0), "player stays centered and faces up after camera rotation settles")
            for i = 1, M.tileCount do fixedClip(M.tilePool[i]) end
            fixedClip(M.waypointArrow)
            for i = 1, M.activePinCount do
                local pin = M.pinPool[i]
                if pin.data.kind == "group" then
                    local tx, ty = terrainPoint(pin.data.x, pin.data.y)
                    local ix, iy = pin.icon:GetCenter()
                    expect(pin.visible and near(tx, ix, 0.36) and near(ty, iy, 0.36), "markers on all four tiles follow the rotated terrain")
                    expect((pin.icon.textureRotation or 0) == 0, "group markers stay upright")
                    fixedClip(pin.icon)
                    H.mouseX, H.mouseY = tx, ty
                    local pingCount = #H.pings
                    M:PlaceWaypointAtCursor()
                    local ping = H.pings[#H.pings]
                    expect(#H.pings == pingCount + 1 and near(ping[3], pin.data.x, 0.002)
                        and near(ping[4], pin.data.y, 0.002), "clicking rendered terrain places the waypoint at its map coordinate")
                end
            end
            -- Native polygon vertices must stay small and point toward north
            -- or the off-screen destination without moving their control space.
            local nx, ny = vertex(M.north, 1)
            local ncx, ncy = M.north:GetCenter()
            expect(near(nx - ncx, 4 * math.sin(M.angle)) and near(ny - ncy, -4 * math.cos(M.angle)), "north triangle points along rotated north")
            H.waypointX, H.waypointY = 0.99, 0.99; M:DrawPins()
            local dx, dy = M:Project(H.waypointX, H.waypointY)
            if not M:Contains(dx, dy) then
                expect(not M.waypointArrow.hidden, "distant waypoint shows an edge arrow")
                local ax, ay = M.waypointArrow:GetCenter()
                local tipX, tipY = vertex(M.waypointArrow, 1)
                expect(near((tipX - ax) * dy - (tipY - ay) * dx, 0)
                    and (tipX - ax) * dx + (tipY - ay) * dy > 0, "edge arrow points toward its rotated waypoint")
                for j = 1, 3 do
                    local vx, vy = vertex(M.waypointArrow, j)
                    expect(M:Contains(vx - cx, vy - cy), "entire edge arrow remains inside the frame")
                end
            else
                expect(M.waypointArrow.hidden, "on-screen waypoint uses its marker")
            end
        end
    end
end
-- A quarter turn has a known screen direction independent of the inverse math.
H.x, H.y, H.heading, M.angle = 0.5, 0.5, math.pi / 2, nil; M:Render(1)
local cx, cy = M.viewport:GetCenter()
local eastX, eastY = terrainPoint(0.55, 0.5)
expect(near(eastX, cx, 0.36) and eastY > cy, "positive camera heading turns eastern terrain down")
local northX, northY = terrainPoint(0.5, 0.45)
expect(northX > cx and near(northY, cy, 0.36), "positive camera heading turns northern terrain right")
-- Interior maps can have non-square tiles; approaching their boundary must
-- still rotate around the player and leave uncovered terrain clipped.
H.tileColumns, H.tileRows = 2, 3; expect(M:LoadTiles(H.map), "non-square tile grid loads")
H.x, H.y = 0.02, 0.98
for _, heading in ipairs({0, 0.7, math.pi, math.pi * 1.7}) do
    H.heading, M.angle = heading, nil; M:Render(1)
    local px, py = terrainPoint(H.x, H.y)
    expect(near(px, cx, 0.36) and near(py, cy, 0.36), "non-square tiles stay centered near map edges")
    for i = 1, M.tileCount do fixedClip(M.tilePool[i]) end
end
config("orientation", "north")
expect(M.angle == 0 and M.tilePool[1].textureRotation == 0 and near(M.player.textureRotation, H.heading), "north-up restores unrotated terrain and rotating player arrow")
local pingCount = #H.pings
H:Mouse(0, 0)
for _, setting in ipairs({ "unlocked", "clickThrough" }) do
    config(setting, true); M:PlaceWaypointAtCursor()
    expect(#H.pings == pingCount, "keybind respects " .. setting)
    config(setting, false)
end
config("enabled", false); M:PlaceWaypointAtCursor()
expect(#H.pings == pingCount, "disabled module ignores its keybind")
print("minimap_regression.lua: all checks passed")

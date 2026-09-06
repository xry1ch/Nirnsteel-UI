-- Run from the addon root with Lua 5.1+ or Fengari.
local H = dofile("tests/minimap_harness.lua")
local M, S = H.module, H.settings
local function expect(value, message) if not value then error(message, 2) end end
local function near(a, b) return math.abs(a - b) < 0.00001 end
local function config(key, value) S:SetMinimapValue(key, value); H:Tick() end

-- Route real mouse positions to the foremost enabled control, then simulate
-- native window movement. Invoking the root handler directly misses covered
-- or disabled drag surfaces, which caused the in-client failure.
config("unlocked", true); config("clickThrough", true)
for _, shape in ipairs({ "circle", "rectangle" }) do
    config("shape", shape)
    for _, grab in ipairs({ "terrain", "header" }) do
        M:ResetPosition()
        if grab == "terrain" then H:Mouse(0, 0)
        else H.mouseX, H.mouseY = M.title:GetCenter() end
        local right, top, pings = M.root:GetRight(), M.root:GetTop(), #H.pings
        expect(H:MouseDown(MOUSE_BUTTON_INDEX_LEFT) == M.mover and M.dragging, "unlocked " .. shape .. " " .. grab .. " captures drag above artwork")
        local movableWrites = M.root.movableWrites
        H:MoveMouse(-160, -190); H:Tick(); H:Tick()
        expect(near(M.root:GetRight(), right - 160) and near(M.root:GetTop(), top - 190), "drag moves the entire widget")
        expect(M.dragging and M.root.movableWrites == movableWrites, "movement updates must not reset native drag state")
        local cx, cy = M.viewport:GetCenter()
        local tile = M.tilePool[1]
        if shape == "circle" then
            expect(near(tile.circleClip[1], cx) and near(tile.circleClip[2], cy), "circular terrain clipping follows during drag")
        else
            expect(near(tile.rectClip[1], M.viewport:GetLeft()) and near(tile.rectClip[2], M.viewport:GetTop()), "rectangular terrain clipping follows during drag")
        end
        H:MouseUp(MOUSE_BUTTON_INDEX_LEFT)
        expect(not M.dragging and not M.root.movable and not H.moving, "release finishes native movement")
        local savedX, savedY = S:GetMinimapPosition().x, S:GetMinimapPosition().y
        expect(near(savedX, right - 160 - GuiRoot:GetRight()) and near(savedY, M.root:GetBottom() - GuiRoot:GetBottom()), "release saves server-relative position")
        S:Initialize(); M:RefreshSettings(); H:Tick()
        expect(near(M.root:GetRight(), GuiRoot:GetRight() + savedX) and near(M.root:GetBottom(), GuiRoot:GetBottom() + savedY), "position persists through settings refresh")
        expect(#H.pings == pings, "drag never creates waypoints")
    end
end
H:Mouse(0, 0); H:MouseDown(MOUSE_BUTTON_INDEX_RIGHT)
expect(not M.dragging, "right-click does not drag")
H:MouseUp(MOUSE_BUTTON_INDEX_RIGHT)
H:Mouse(0, 0); H:MouseDown(MOUSE_BUTTON_INDEX_LEFT); H:MoveMouse(5000, -5000)
H:MouseUp(MOUSE_BUTTON_INDEX_LEFT)
expect(near(M.root:GetRight(), GuiRoot:GetRight()) and near(M.root:GetTop(), 0), "whole widget clamps at top-right screen edge")
expect(near(S:GetMinimapPosition().x, 0) and near(S:GetMinimapPosition().y, M.root:GetHeight() - GuiRoot:GetHeight()), "clamped drag saves the clamped position")
for _, stop in ipairs({ "cursor", "lock", "disable", "scene" }) do
    config("enabled", true); config("unlocked", true); H.cursor = true; H:SetScene("hud"); H:Tick()
    H:Mouse(0, 0); H:MouseDown(MOUSE_BUTTON_INDEX_LEFT); H:MoveMouse(-15, 15)
    if stop == "cursor" then H.cursor = false; H:Tick()
    elseif stop == "lock" then config("unlocked", false)
    elseif stop == "disable" then config("enabled", false)
    else H:SetScene("inventory") end
    expect(not M.dragging and not H.moving and not M.mover.mouseEnabled and M.mover.hidden, stop .. " ends drag and clears its hit surface")
    H:MouseUp(MOUSE_BUTTON_INDEX_LEFT)
end
H:SetScene("hud"); H.cursor = true; config("enabled", true); config("unlocked", false)
config("clickThrough", false)
H:Mouse(0, 0); expect(H:MouseDown(MOUSE_BUTTON_INDEX_LEFT) == M.input and not M.dragging, "locked map restores navigation hit surface")
H:MouseUp(MOUSE_BUTTON_INDEX_LEFT)
H:SetScene("gameMenu"); M:SetSettingsPanelVisible(true); config("unlocked", true)
H.mouseX, H.mouseY = M.title:GetCenter()
expect(M.preview and H:MouseDown(MOUSE_BUTTON_INDEX_LEFT) == M.mover and M.dragging, "settings preview can be dragged by its header")
H:MoveMouse(-20, 20); M:SetSettingsPanelVisible(false)
expect(not M.dragging and not H.moving and M.mover.hidden, "closing settings releases an active preview drag")
H:SetScene("hud"); S:ResetMinimapSettings(); H:Tick()

local panel, relative = ZO_FocusedQuestTrackerPanel, H.trackerRelative
local originalTop, originalRight = panel:GetTop(), panel:GetRight()
expect(S:GetMinimap().questTrackerOffset == 0, "new offset defaults to zero")
local slider
for _, option in ipairs(S:BuildMinimapControls()) do
    if option.name == "Quest Tracker Vertical Offset" then slider = option end
end
expect(slider and slider.type == "slider" and slider.min == 0 and slider.max == 600 and slider.default == 0, "offset slider is exposed in Minimap settings")
slider.setFunc(300)
expect(near(panel:GetTop(), originalTop + 300) and near(panel:GetRight(), originalRight), "slider immediately lowers quest tracker without moving it horizontally")
for i = 1, 4 do M:RefreshSettings(); H:Event(EVENT_GAMEPAD_PREFERRED_MODE_CHANGED) end
expect(near(panel:GetTop(), originalTop + 300), "settings and platform changes never accumulate the offset")
relative:SetDimensions(300, 120)
expect(near(panel:GetTop(), originalTop + 340), "native dynamic-event sizing continues to move the quest tracker")
config("questTrackerOffset", 150)
expect(near(panel:GetTop(), originalTop + 190), "changing the slider replaces its previous offset")
S:Initialize(); M:RefreshSettings()
expect(S:GetMinimap().questTrackerOffset == 150 and near(panel:GetTop(), originalTop + 190), "quest offset survives saved-setting initialization")
config("enabled", false)
expect(near(panel:GetTop(), originalTop + 40) and slider.disabled(), "disable restores native placement")
config("enabled", true)
expect(near(panel:GetTop(), originalTop + 190), "re-enable restores the saved offset once")
config("questTrackerOffset", 0)
expect(near(panel:GetTop(), originalTop + 40), "zero restores native placement")

-- A later native/other-addon anchor replacement becomes the new baseline.
config("questTrackerOffset", 200)
panel:ClearAnchors(); panel:SetAnchor(TOPRIGHT, relative, BOTTOMRIGHT, -8, 17, 1)
panel:SetAnchor(TOPLEFT, relative, BOTTOMLEFT, 10, 17, 1)
H:Event(EVENT_PLAYER_ACTIVATED)
local _, point, anchorTo, relativePoint, x, y, constraints = panel:GetAnchor(0)
expect(panel:GetNumAnchors() == 2 and point == TOPRIGHT and anchorTo == relative and relativePoint == BOTTOMRIGHT
    and x == -8 and y == 217 and constraints == 1, "reanchoring preserves native anchor targets, offsets, constraints and count")
S:ResetMinimapSettings(); H:Tick()
expect(select(6, panel:GetAnchor(0)) == 17 and select(6, panel:GetAnchor(1)) == 17, "reset restores both original anchor offsets")
config("questTrackerOffset", 1000); expect(S:GetMinimap().questTrackerOffset == 600, "offset upper bound")
config("questTrackerOffset", -50); expect(S:GetMinimap().questTrackerOffset == 0, "offset lower bound")
config("questTrackerOffset", 0 / 0); expect(S:GetMinimap().questTrackerOffset == 0, "invalid offset falls back to zero")
S:GetMinimap().questTrackerOffset = nil; config("zoom", 3.25); S:Initialize()
expect(S:GetMinimap().questTrackerOffset == 0 and S:GetMinimap().zoom == 3.25, "backfill adds the new setting without resetting preferences")
ZO_FocusedQuestTrackerPanel = nil; config("questTrackerOffset", 120)
ZO_FocusedQuestTrackerPanel = panel; H:Event(EVENT_PLAYER_ACTIVATED)
expect(select(6, panel:GetAnchor(0)) == 137, "delayed native quest tracker availability recovers on activation")
print("minimap_layout_regression.lua: all checks passed")

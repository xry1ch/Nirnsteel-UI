-- Minimal, strict ESO surface shared by the minimap regression and visual capture.
local H = {
    now = 1000, controls = {}, events = {}, updates = {}, callbacks = {},
    scene = "hud", sceneState = "shown", map = 10, playerMap = 10, floor = 1,
    x = 0.5, y = 0.5, heading = 0, playerShown = true, cursor = true,
    mapChanges = 0, mapNotifications = 0, staticReads = 0, textureReads = 0,
    worldMapOpens = 0, pings = {}, removedWaypoints = 0, groups = {}, questSteps = {},
    waypointX = 0, waypointY = 0, allowMapChange = true, tileColumns = 2, tileRows = 2,
}
unpack = unpack or table.unpack
math.atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
for _, name in ipairs({ "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT", "TOP", "BOTTOM", "LEFT", "RIGHT", "CENTER",
    "CT_CONTROL", "CT_POLYGON", "CT_TEXTURE", "CT_LABEL", "CT_BACKDROP", "DL_BACKGROUND", "DL_CONTROLS", "DL_OVERLAY", "DL_TEXT", "DT_LOW", "DT_MEDIUM", "DT_HIGH",
    "TEXT_ALIGN_CENTER", "POLYGON_POINT_LAYOUT_CLOCKWISE", "POLYGON_BORDER_DIRECTION_IN",
    "MAP_PIN_TYPE_PLAYER_WAYPOINT", "MAP_TYPE_LOCATION_CENTERED", "SET_MAP_RESULT_MAP_CHANGED", "SET_MAP_RESULT_CURRENT_MAP_UNCHANGED",
    "POI_TYPE_WAYSHRINE", "POI_TYPE_OBJECTIVE", "MAP_CONTENT_DUNGEON", "MAP_CONTENT_NONE", "TRACK_TYPE_QUEST",
    "QUEST_PIN_STATE_HAS_ADDITIONAL_SYMBOLIC_POSITION", "QUEST_PIN_STATE_IS_SYMBOLIC_POSITION" }) do _G[name] = name end
SCENE_SHOWN, SCENE_HIDING, SCENE_HIDDEN = "shown", "hiding", "hidden"
MOUSE_BUTTON_INDEX_LEFT, MOUSE_BUTTON_INDEX_RIGHT, MAX_JOURNAL_QUESTS = 1, 2, 25
for _, name in ipairs({ "EVENT_ADD_ON_LOADED", "EVENT_PLAYER_ACTIVATED", "EVENT_PLAYER_DEACTIVATED", "EVENT_SCREEN_RESIZED",
    "EVENT_GAMEPAD_PREFERRED_MODE_CHANGED", "EVENT_PLAYER_COMBAT_STATE", "EVENT_ZONE_CHANGED", "EVENT_POIS_INITIALIZED",
    "EVENT_POI_DISCOVERED", "EVENT_POI_UPDATED", "EVENT_FAST_TRAVEL_NETWORK_UPDATED", "EVENT_QUEST_ADDED", "EVENT_QUEST_REMOVED",
    "EVENT_QUEST_LIST_UPDATED", "EVENT_QUEST_ADVANCED", "EVENT_QUEST_CONDITION_COUNTER_CHANGED", "EVENT_QUEST_POSITION_REQUEST_COMPLETE",
    "EVENT_START_FAST_TRAVEL_INTERACTION", "EVENT_START_FAST_TRAVEL_KEEP_INTERACTION", "EVENT_END_FAST_TRAVEL_INTERACTION",
    "EVENT_END_FAST_TRAVEL_KEEP_INTERACTION", "EVENT_INTERACTION_ENDED", "EVENT_CLIENT_INTERACT_RESULT", "EVENT_AUTO_MAP_NAVIGATION_TARGET_SET" }) do _G[name] = name end

local offsets = { TOPLEFT = {0, 0}, TOPRIGHT = {1, 0}, BOTTOMLEFT = {0, 1}, BOTTOMRIGHT = {1, 1},
    TOP = {0.5, 0}, BOTTOM = {0.5, 1}, LEFT = {0, 0.5}, RIGHT = {1, 0.5}, CENTER = {0.5, 0.5} }
local function NewControl(parent, kind)
    local c = { parent = parent, kind = kind, children = {}, handlers = {}, hidden = false, alpha = 1, rotation = 0, points = {} }
    H.controls[#H.controls + 1] = c; c.id = #H.controls
    if parent then parent.children[#parent.children + 1] = c end
    function c:SetDimensions(w, h) self.width, self.height = w, h end
    function c:GetDimensions() return self:GetWidth(), self:GetHeight() end
    function c:GetWidth() return self.fill and self.fill:GetWidth() or self.width or 0 end
    function c:GetHeight() return self.fill and self.fill:GetHeight() or self.height or 0 end
    function c:SetAnchor(point, relative, relativePoint, x, y, constraints)
        self.anchors = self.anchors or {}
        local index = #self.anchors + 1
        for i, anchor in ipairs(self.anchors) do if anchor[1] == point then index = i; break end end
        self.anchors[index] = {point, relative or self.parent, relativePoint, x or 0, y or 0, constraints}
        self.anchor = self.anchors[1]
    end
    function c:ClearAnchors() self.anchor, self.fill, self.anchors = nil, nil, {} end
    function c:GetNumAnchors() return self.anchors and #self.anchors or 0 end
    function c:GetAnchor(index)
        local anchor = self.anchors and self.anchors[index + 1]
        if anchor then return true, unpack(anchor, 1, 6) end
        return false
    end
    function c:SetAnchorFill(target) self.fill = target end
    function c:GetLeft()
        if self.fill then return self.fill:GetLeft() end
        if not self.anchor then return self.parent and self.parent:GetLeft() or 0 end
        local a = self.anchor
        return a[2]:GetLeft() + offsets[a[3]][1] * a[2]:GetWidth() + a[4] - offsets[a[1]][1] * self:GetWidth()
    end
    function c:GetTop()
        if self.fill then return self.fill:GetTop() end
        if not self.anchor then return self.parent and self.parent:GetTop() or 0 end
        local a = self.anchor
        return a[2]:GetTop() + offsets[a[3]][2] * a[2]:GetHeight() + a[5] - offsets[a[1]][2] * self:GetHeight()
    end
    function c:GetRight() return self:GetLeft() + self:GetWidth() end
    function c:GetBottom() return self:GetTop() + self:GetHeight() end
    function c:GetCenter() return self:GetLeft() + self:GetWidth() / 2, self:GetTop() + self:GetHeight() / 2 end
    function c:SetHidden(v) self.hidden = not not v end
    function c:IsHidden() return self.hidden end
    function c:IsControlHidden() return self.hidden or (self.parent and self.parent:IsControlHidden()) or false end
    function c:SetHandler(name, callback) self.handlers[name] = callback end
    function c:SetAlpha(v) self.alpha = v end
    function c:SetMouseEnabled(v) self.mouseEnabled = not not v end
    function c:SetMovable(v) self.movable = not not v; self.movableWrites = (self.movableWrites or 0) + 1 end
    function c:SetClampedToScreen(v) self.clamped = v end
    function c:SetDrawTier(v) self.tier = v end
    function c:SetDrawLayer(v) self.layer = v end
    function c:SetDrawLevel(v) self.level = v end
    -- Native control transforms also affect screen-space clipping, unlike
    -- texture rotation. Reject them instead of modeling them as harmless art.
    function c:SetTransformNormalizedOriginPoint() error("minimap must keep control space untransformed") end
    function c:SetTransformRotationZ() error("minimap must rotate drawables without transforming clips") end
    function c:SetTextureRotation(v, x, y) self.textureRotation, self.textureOrigin = v, {x or 0.5, y or 0.5} end
    function c:SetPixelRoundingEnabled(v) self.pixelRounding = v end
    function c:SetPointLayout(v) self.pointLayout = v end
    function c:SetSmoothingEnabled(v) self.smoothing = v end
    function c:AddPoint(x, y) self.points[#self.points + 1] = {x, y} end
    function c:SetPoint(i, x, y)
        assert(self.points[i], "SetPoint requires an existing polygon vertex")
        self.points[i][1], self.points[i][2] = x, y
    end
    function c:SetBorderDirection(v) self.borderDirection = v end
    function c:SetBorderThickness(v) self.border = v end
    function c:SetBorderColor(...) self.borderColor = {...} end
    function c:SetCenterColor(...) self.fillColor = {...} end
    function c:SetTexture(v) self.texture = v end
    function c:SetColor(...) self.color = {...} end
    function c:SetFont(v) self.font = v end
    function c:SetText(v) self.text = v end
    function c:SetHorizontalAlignment(v) self.hAlign = v end
    function c:SetVerticalAlignment(v) self.vAlign = v end
    function c:ClearCircularClip() self.circleClip = nil end
    function c:ClearRectangularClip() self.rectClip = nil end
    function c:SetCircularClip(...) self.circleClip = {...} end
    function c:SetRectangularClip(...) self.rectClip = {...} end
    function c:StartMoving()
        if not self.movable or not self.mouseEnabled or self:IsControlHidden() then return false end
        self.moving, H.moving = true, self
        self.dragStart = { H.mouseX, H.mouseY, self:GetLeft(), self:GetTop() }
        return true
    end
    function c:StopMovingOrResizing()
        if self.moving then
            self.moving, H.moving = false, nil
            if self.handlers.OnMoveStop then self.handlers.OnMoveStop() end
        end
    end
    return c
end
GuiRoot = NewControl(nil, CT_CONTROL)
GuiRoot:SetDimensions(1920, 1080)
WINDOW_MANAGER = {}
function WINDOW_MANAGER:CreateControl(_, parent, kind) return NewControl(parent, kind) end
function WINDOW_MANAGER:CreateTopLevelWindow() return NewControl(GuiRoot, CT_CONTROL) end
H.trackerRelative = NewControl(GuiRoot, CT_CONTROL)
H.trackerRelative:SetDimensions(300, 80)
H.trackerRelative:SetAnchor(TOPRIGHT, GuiRoot, TOPRIGHT, -40, 60)
ZO_FocusedQuestTrackerPanel = NewControl(GuiRoot, CT_CONTROL)
ZO_FocusedQuestTrackerPanel:SetDimensions(275, 200)
ZO_FocusedQuestTrackerPanel:SetAnchor(TOPRIGHT, H.trackerRelative, BOTTOMRIGHT, 0, 0)
EVENT_MANAGER = {}
function EVENT_MANAGER:RegisterForEvent(ns, event, callback) H.events[ns] = {event, callback} end
function EVENT_MANAGER:UnregisterForEvent(ns) H.events[ns] = nil end
function EVENT_MANAGER:RegisterForUpdate(ns, interval, callback) H.updates[ns] = {interval, callback} end
function EVENT_MANAGER:UnregisterForUpdate(ns) H.updates[ns] = nil end
function H:Event(event, ...)
    local calls = {}
    for _, spec in pairs(self.events) do if spec[1] == event then calls[#calls + 1] = spec[2] end end
    for _, callback in ipairs(calls) do callback(event, ...) end
end
CALLBACK_MANAGER = {}
function CALLBACK_MANAGER:RegisterCallback(name, callback)
    H.callbacks[name] = H.callbacks[name] or {}; table.insert(H.callbacks[name], callback)
end
function CALLBACK_MANAGER:FireCallbacks(name, ...)
    if name == "OnWorldMapChanged" then H.mapNotifications = H.mapNotifications + 1; H.questSteps = {} end
    for _, callback in ipairs(H.callbacks[name] or {}) do callback(...) end
end
local scene = {}
function scene:GetName() return H.scene end
function scene:GetState() return H.sceneState end
SCENE_MANAGER = {}
function SCENE_MANAGER:GetCurrentScene() return scene end
function SCENE_MANAGER:RegisterCallback(name, callback) CALLBACK_MANAGER:RegisterCallback(name, callback) end
function H:SetScene(name, state)
    self.scene, self.sceneState = name, state or SCENE_SHOWN
    CALLBACK_MANAGER:FireCallbacks("SceneStateChanged", scene)
end
function H:FlushVisibility()
    local update = self.updates.NirnsteelUI_Minimap_Visibility
    if update then update[2]() end
end
function H:Tick(ms)
    self.now = self.now + (ms or 33)
    self:FlushVisibility()
    local update = self.updates.NirnsteelUI_Minimap
    if update then update[2]() end
end
function GetFrameTimeMilliseconds() return H.now end
function IsGameCameraUIModeActive() return H.cursor end
function IsInGamepadPreferredMode() return H.gamepad or false end
function IsUnitInCombat() return H.combat or false end
function IsInteracting() return H.interacting or false end
function HasAutoMapNavigationTarget() return H.autoNavigation or false end
function GetUIMousePosition() return H.mouseX or 0, H.mouseY or 0 end
function IsControlKeyDown() return H.ctrl or false end
function MouseIsOver(control)
    local x, y = GetUIMousePosition()
    return x >= control:GetLeft() and x <= control:GetRight() and y >= control:GetTop() and y <= control:GetBottom()
end
function H:Mouse(x, y) local cx, cy = self.module.viewport:GetCenter(); self.mouseX, self.mouseY = cx + x, cy + y end
function H:MouseDown(button)
    local tiers = { [DT_LOW] = 0, [DT_MEDIUM] = 1, [DT_HIGH] = 2 }
    local layers = { [DL_BACKGROUND] = 0, [DL_CONTROLS] = 1, [DL_OVERLAY] = 2, [DL_TEXT] = 3 }
    local best, bestOrder = nil, -1
    for _, c in ipairs(self.controls) do
        if c.mouseEnabled and not c:IsControlHidden() and MouseIsOver(c) then
            local order = (tiers[c.tier] or 0) * 1000000 + (layers[c.layer] or 0) * 10000 + (c.level or 0) * 100 + c.id
            if order > bestOrder then best, bestOrder = c, order end
        end
    end
    self.mouseDownControl = best
    if best and best.handlers.OnMouseDown then best.handlers.OnMouseDown(best, button) end
    return best
end
function H:MoveMouse(dx, dy)
    self.mouseX, self.mouseY = self.mouseX + dx, self.mouseY + dy
    local c = self.moving
    if c then
        local start = c.dragStart
        local left, top = start[3] + self.mouseX - start[1], start[4] + self.mouseY - start[2]
        if c.clamped then
            left = math.max(0, math.min(GuiRoot:GetWidth() - c:GetWidth(), left))
            top = math.max(0, math.min(GuiRoot:GetHeight() - c:GetHeight(), top))
        end
        c:ClearAnchors(); c:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, left, top)
        if c.handlers.OnRectChanged then c.handlers.OnRectChanged() end
    end
end
function H:MouseUp(button)
    local c = self.mouseDownControl; self.mouseDownControl = nil
    if c and c.handlers.OnMouseUp then c.handlers.OnMouseUp(c, button, MouseIsOver(c)) end
end
function ZO_WorldMap_IsWorldMapShowing() return H.scene == "worldMap" or H.scene == "gamepad_worldMap" end
function ZO_WorldMap_ShowWorldMap() H.worldMapOpens = H.worldMapOpens + 1; H:SetScene("worldMap") end
WORLD_MAP_MANAGER = {}
function WORLD_MAP_MANAGER:IsMapChangingAllowed() return H.allowMapChange end
function DoesCurrentMapMatchMapForPlayerLocation() return H.map == H.playerMap end
function GetCurrentMapId() return H.map end
function GetMapFloorInfo() return H.floor, 3 end
function SetMapToPlayerLocation()
    H.mapChanges = H.mapChanges + 1
    if H.map ~= H.playerMap and not H.failSelection then H.map = H.playerMap; return SET_MAP_RESULT_MAP_CHANGED end
    return SET_MAP_RESULT_CURRENT_MAP_UNCHANGED
end
function GetMapName() return "Stonefalls" end
function GetMapNumTilesForMapId() return H.tileColumns, H.tileRows end
function GetMapTileTextureForMapId(map, i)
    H.textureReads = H.textureReads + 1
    return H.noTexture and "" or "map-" .. map .. "-" .. i .. ".dds"
end
function GetMapPlayerPosition(tag)
    if tag == "player" then return H.x, H.y, 0, H.playerShown, H.symbolic end
    local g = H.groups[tag]; if g then return g.x, g.y, 0, g.shown, g.symbolic end
    return 0, 0, 0, false
end
function GetPlayerCameraHeading() return H.heading end
function GetNumFastTravelNodes() H.staticReads = H.staticReads + 1; return 3 end
function GetFastTravelNodeInfo(i)
    return i ~= 2, "Wayshrine " .. i, 0.35 + i * 0.03, 0.4, "wayshrine.dds", nil, POI_TYPE_WAYSHRINE, i ~= 3, false
end
function GetFastTravelNodePOIIndicies(i) return 1, i end
function GetCurrentMapZoneIndex() return 1 end
function GetNumPOIs() return 5 end
function GetPOIInfo(_, i) return i == 4 and "Fort" or "Wayshrine " .. i end
function GetPOIType(_, i) return i < 4 and POI_TYPE_WAYSHRINE or POI_TYPE_OBJECTIVE end
function GetPOIMapInfo(_, i) return 0.55, 0.56, 1, "fort.dds", true, false, i ~= 5, false end
function GetNumMapLocations() return 1 end
function IsMapLocationVisible() return true end
function GetMapLocationIcon() return "fort.dds", 0.55, 0.56 end
function GetMapLocationTooltipHeader() return "Fort" end
WORLD_MAP_QUEST_BREADCRUMBS = {}
function WORLD_MAP_QUEST_BREADCRUMBS:RegisterCallback(name, callback) CALLBACK_MANAGER:RegisterCallback(name, callback) end
function WORLD_MAP_QUEST_BREADCRUMBS:GetSteps(quest) return H.questSteps[quest] end
function IsValidQuestIndex(i) return i <= 2 end
function GetJournalQuestName(i) return "Quest " .. i end
FOCUSED_QUEST_TRACKER = {}
function FOCUSED_QUEST_TRACKER:IsOnTracker(_, quest) return quest == 1 end
function FOCUSED_QUEST_TRACKER:RegisterCallback(name, callback) CALLBACK_MANAGER:RegisterCallback(name, callback) end
ZO_MapPin = {}
function ZO_MapPin.GetQuestIcon(pin) return pin.m_PinTag.isBreadcrumb and "door.dds" or "quest.dds" end
function GetGroupSize() return #H.groupTags end
H.groupTags = {}
function GetGroupUnitTagByIndex(i) return H.groupTags[i] end
function DoesUnitExist(tag) return H.groups[tag] ~= nil end
function AreUnitsEqual(a, b) return a == b end
function IsUnitOnline(tag) return H.groups[tag].online ~= false end
function IsUnitGroupLeader(tag) return H.groups[tag].leader end
function IsGroupMemberInSameWorldAsPlayer(tag) return H.groups[tag].sameWorld ~= false end
function IsGroupMemberInSameInstanceAsPlayer(tag) return H.groups[tag].sameInstance ~= false end
function IsGroupMemberInSameLayerAsPlayer(tag) return H.groups[tag].sameLayer ~= false end
function IsUnitWorldMapPositionBreadcrumbed(tag) return H.groups[tag].breadcrumb end
function GetMapContentType() return H.dungeon and MAP_CONTENT_DUNGEON or MAP_CONTENT_NONE end
function GetCurrentZoneHouseId() return H.house and 1 or 0 end
function GetUnitName(tag) return tag end
function GetMapPlayerWaypoint() return H.waypointX, H.waypointY end
function PingMap(kind, display, x, y) H.pings[#H.pings + 1] = {kind, display, x, y}; H.waypointX, H.waypointY = x, y end
function RemovePlayerWaypoint() H.removedWaypoints = H.removedWaypoints + 1; H.waypointX, H.waypointY = 0, 0 end
InformationTooltip = {}
function InitializeTooltip() H.tooltip = true end
function InformationTooltip:AddLine(line) H.tooltipText = line end
function ClearTooltip() H.tooltip = false end
function GetWorldName() return "EU Megaserver" end
function GetDisplayName() return "@Test" end
function GetCurrentCharacterId() return "123" end
function GetString(v) return tostring(v) end
function ZO_CreateStringId(name, value) _G[name] = value end
function zo_round(v) return math.floor(v + 0.5) end
function zo_strformat(_, v) return v or "" end
local saved = {}
ZO_SavedVars = {}
function ZO_SavedVars:NewAccountWide(name, version, _, defaults, server)
    assert(version == 1, "saved-variable version must not reset existing profiles")
    local key = name .. server; saved[key] = saved[key] or {}; return saved[key]
end
ZO_SavedVars.NewCharacterIdSettings = ZO_SavedVars.NewAccountWide
LibAddonMenu2 = {}
function LibAddonMenu2:RegisterAddonPanel() end
function LibAddonMenu2:RegisterOptionControls(_, options) H.menu = options end
dofile("modules/settings.lua")
H.settings = Nirnsteel_UI.Settings
H.settings:Initialize()
dofile("modules/minimap.lua")
H.module = Nirnsteel_UI.Minimap
H:Event(EVENT_ADD_ON_LOADED, "NirnsteelUI")
H:Event(EVENT_PLAYER_ACTIVATED)
H:Tick()
return H

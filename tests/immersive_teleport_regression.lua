-- Run from the addon root with Lua 5.1+ or the Fengari CLI.
local now, enabled, moving, blocking, dead, combat = 0, false, false, false, false, false
local hidden, framed, scene, menuFramed = false, false, "hud", false
local target, distance, reframes = {}, nil, 0
local events, updates = {}, {}
local names = { "EVENT_ADD_ON_LOADED", "EVENT_COMBAT_EVENT", "EVENT_PLAYER_DEACTIVATED",
    "EVENT_PLAYER_ACTIVATED", "EVENT_PLAYER_TELEPORTED_LOCALLY", "EVENT_JUMP_FAILED",
    "EVENT_PLAYER_DEAD", "EVENT_SOCIAL_ERROR", "ACTION_RESULT_BEGIN", "ACTION_RESULT_INTERRUPT",
    "ACTION_RESULT_FAILED", "ACTION_RESULT_EFFECT_FADED", "COMBAT_UNIT_TYPE_PLAYER",
    "REGISTER_FILTER_ABILITY_ID", "REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE", "FRAMING_SCREEN_DEFAULT" }
for index, name in ipairs(names) do _G[name] = index end
EVENT_MANAGER = {}
function EVENT_MANAGER:RegisterForEvent(ns, event, callback) events[event] = callback end
function EVENT_MANAGER:UnregisterForEvent(ns, event) events[event] = nil end
function EVENT_MANAGER:AddFilterForEvent(...) end
function EVENT_MANAGER:RegisterForUpdate(ns, interval, callback) updates[ns] = callback end
function EVENT_MANAGER:UnregisterForUpdate(ns) updates[ns] = nil end
function GetFrameTimeMilliseconds() return now end
function GetAbilityCastInfo() return false, 8000 end
function GetGuiHidden() return hidden end
function SetGuiHidden(name, value) assert(name == "ingame"); hidden = value end
function SetFrameLocalPlayerInGameCamera(value) framed = value end
function SetFrameLocalPlayerTarget(x, y) target = { x, y } end
function SetFrameLocalPlayerLookAtDistanceFactor(value) distance = value end
function SetFramingScreenType(value) assert(value == FRAMING_SCREEN_DEFAULT) end
function RequestReframeLocalPlayerInGameCamera() reframes = reframes + 1 end
function IsPlayerMoving() return moving end
function IsBlockActive() return blocking end
function IsUnitDead() return dead end
function IsUnitInCombat() return combat end
SCENE_MANAGER = {}
function SCENE_MANAGER:ShowBaseScene() scene = "hud" end
function SCENE_MANAGER:IsShowing(name) return scene == name end
FRAME_PLAYER_FRAGMENT = { IsShowing = function() return menuFramed end }
Nirnsteel_UI = { Settings = { IsImmersiveTeleportEnabled = function() return enabled end } }
local travelCalls, failTravel = 0, false
local travelNames = { "FastTravelToNode", "TravelToKeep", "JumpToGroupLeader", "JumpToGroupMember",
    "JumpToGuildMember", "JumpToFriend", "JumpToHouse", "JumpToSpecificHouse",
    "RequestJumpToHouse", "RequestJumpToHousePreviewWithTemplate" }
for _, name in ipairs(travelNames) do
    _G[name] = function(argument)
        travelCalls = travelCalls + 1
        if failTravel then events[EVENT_JUMP_FAILED]() end
        return argument
    end
end
function CancelCast() return true end
function ZO_PreHook(name, callback)
    local original = _G[name]
    _G[name] = function(...)
        if callback(...) then return end
        return original(...)
    end
end
assert(loadfile("modules/immersive_teleport.lua"))()
events[EVENT_ADD_ON_LOADED](nil, "NirnsteelUI")
local teleport = Nirnsteel_UI.ImmersiveTeleport
local function tick()
    now = now + 50
    for _, callback in pairs(updates) do callback() end
end
local function begin(abilityId, sourceType)
    events[EVENT_COMBAT_EVENT](nil, ACTION_RESULT_BEGIN, false, nil, nil, nil, nil,
        sourceType or COMBAT_UNIT_TYPE_PLAYER, nil, nil, 8000, nil, nil, nil, nil, nil, abilityId or 6811)
end
assert(not events[EVENT_COMBAT_EVENT], "disabled by default")
teleport:Start(); assert(not teleport.state)
enabled = true; teleport:RefreshSettings()
begin(123); begin(6811, -1); assert(not teleport.state, "ignore unrelated casts and other players")
begin(); tick()
assert(hidden and framed and target[1] == 0.35 and target[2] == 0.55 and distance == 0.85)
begin(); tick(); assert(reframes == 1, "duplicate start must not replace the saved UI state")
events[EVENT_PLAYER_TELEPORTED_LOCALLY]()
assert(not hidden and not framed and target[1] == 0.50 and distance == nil)
for _, event in ipairs({ EVENT_PLAYER_DEACTIVATED, EVENT_PLAYER_ACTIVATED, EVENT_JUMP_FAILED, EVENT_PLAYER_DEAD }) do
    begin(); tick(); events[event](); assert(not hidden and not framed and not teleport.state)
end
for _, result in ipairs({ ACTION_RESULT_INTERRUPT, ACTION_RESULT_FAILED, ACTION_RESULT_EFFECT_FADED }) do
    begin(); tick(); teleport:OnRecallResult(result, false); assert(not hidden and not framed)
end
for _, cancel in ipairs({ "move", "block", "death", "combat" }) do
    begin(); tick()
    moving, blocking, dead, combat = cancel == "move", cancel == "block", cancel == "death", cancel == "combat"
    tick(); assert(not hidden and not framed and not teleport.state)
    moving, blocking, dead, combat = false, false, false, false
end
hidden = true; begin(); tick(); teleport:Restore(); assert(hidden, "preserve already hidden UI")
hidden = false; begin(); teleport:Restore(); tick(); assert(not hidden and not framed, "canceled before camera setup")
begin(); tick(); now = now + 11000; tick(); assert(not teleport.state and not hidden, "timeout cleanup")
begin(); tick(); scene, menuFramed = "stats", true; tick()
assert(not hidden and framed, "new menu keeps its character camera and remains visible")
menuFramed, framed = false, false
begin(); tick(); enabled = false; teleport:RefreshSettings()
assert(not hidden and not framed and not events[EVENT_COMBAT_EVENT] and next(updates) == nil)
assert(FastTravelToNode(42) == 42 and not teleport.state, "disabled hook preserves travel")
enabled = true; teleport:RefreshSettings()
for _, name in ipairs(travelNames) do
    local before = travelCalls
    assert(_G[name](42) == 42 and travelCalls == before + 1, "original travel runs once")
    tick()
    assert(hidden and framed, "travel without any combat event must activate framing: " .. name)
    assert(CancelCast() == true)
    assert(not hidden and not framed and not teleport.state, "explicit cancel restores immediately")
end
failTravel = true; FastTravelToNode(42); tick()
assert(not teleport.state and not hidden and not framed, "synchronous rejection cannot hide UI afterward")
failTravel = false; JumpToFriend("friend"); tick(); events[EVENT_SOCIAL_ERROR]()
assert(not teleport.state and not hidden, "social travel failure restores")
assert(loadfile("modules/settings.lua"), "settings syntax")
print("Immersive Teleport regression checks passed")

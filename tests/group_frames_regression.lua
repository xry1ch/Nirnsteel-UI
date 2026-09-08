-- Run from the addon root with Lua 5.1+ or Fengari.
local settings = { enabled = true }
Nirnsteel_UI = {
    LevelVisuals = { SHIMMER_CADENCE_MS = 2000 },
    Settings = { GetGroupFrames = function() return settings end },
}
GROUP_VOTE_CHOICE_ABSTAIN = 1
GROUP_VOTE_CHOICE_FOR = 2
GROUP_VOTE_CHOICE_AGAINST = 3
GROUP_VOTE_CHOICE_INVALID = 4
EVENT_MANAGER = { RegisterForEvent = function() end }
local hookCount = 0
function ZO_PostHook(object, method, callback)
    hookCount = hookCount + 1
    local original = object[method]
    object[method] = function(self, ...)
        local result = original(self, ...)
        callback(self, ...)
        return result
    end
end
local function NewFrame()
    return {
        reasons = {},
        SetHiddenForReason = function(self, reason, hidden)
            self.reasons[reason] = hidden or nil
        end,
        IsHidden = function(self) return next(self.reasons) ~= nil end,
    }
end
local reason = "NirnsteelUI_GroupFrames"
UNIT_FRAMES = {
    groupFrames = { group1 = NewFrame() },
    raidFrames = { group1 = NewFrame() },
    companionRaidFrames = { group1companion = NewFrame() },
    staticFrames = { player = NewFrame(), reticleover = NewFrame(), companion = NewFrame() },
    SetGroupAndRaidFramesHiddenForReason = function(self, _, hidden) self.fragmentHidden = hidden end,
    CreateFrame = function(self, tag, kind)
        local frame = NewFrame()
        self[kind][tag] = frame
        return frame
    end,
}
dofile("modules/group_frames.lua")
local group = Nirnsteel_UI.GroupFrames
group:SetStockFramesHidden(true)
-- Simulate the shared container becoming visible during a native refresh.
UNIT_FRAMES.fragmentHidden = false
for _, kind in ipairs({ "groupFrames", "raidFrames", "companionRaidFrames" }) do
    for _, frame in pairs(UNIT_FRAMES[kind]) do
        assert(frame:IsHidden(), kind .. " leaked through the visible container")
    end
    local frame = UNIT_FRAMES:CreateFrame("lateMember", kind)
    assert(frame:IsHidden(), "late " .. kind .. " frame was not suppressed")
end
for _, frame in pairs(UNIT_FRAMES.staticFrames) do
    assert(not frame:IsHidden(), "unrelated stock frame was hidden")
end
local existing = UNIT_FRAMES.groupFrames.group1
existing:SetHiddenForReason("anotherAddon", true)
group:SetStockFramesHidden(true)
assert(hookCount == 1, "duplicate creation hooks")
settings.enabled = false
group:SetStockFramesHidden(false)
assert(existing:IsHidden(), "another addon's hide reason was removed")
for _, kind in ipairs({ "groupFrames", "raidFrames", "companionRaidFrames" }) do
    for _, frame in pairs(UNIT_FRAMES[kind]) do
        assert(not frame.reasons[reason], "Nirnsteel hide reason remained after disabling")
    end
    assert(not UNIT_FRAMES:CreateFrame("disabledMember", kind):IsHidden())
end
settings.enabled = true
group:SetStockFramesHidden(true)
assert(UNIT_FRAMES.groupFrames.disabledMember:IsHidden(), "reenabling missed cached frames")
assert(hookCount == 1)
print("group_frames_regression: passed")

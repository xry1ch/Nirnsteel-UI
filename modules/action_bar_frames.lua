local ADDON_NAME = "Nirnsteel-UI"
local EVENT_NAMESPACE = ADDON_NAME .. "_ActionBarFrames"

Nirnsteel_UI = Nirnsteel_UI or {}
local ActionBarFrames = {}
Nirnsteel_UI.ActionBarFrames = ActionBarFrames

local NORMAL_FRAME = "EsoUI/Art/ActionBar/actionslot_normal.dds"
local PRESSED_FRAME = "EsoUI/Art/ActionBar/actionslot_pressed.dds"
local TOGGLED_FRAME = "EsoUI/Art/ActionBar/actionslot_toggledon.dds"
local STOCK_NORMAL_FRAME = "EsoUI/Art/ActionBar/abilityFrame64_up.dds"
local STOCK_PRESSED_FRAME = "EsoUI/Art/ActionBar/abilityFrame64_down.dds"
local NO_TEXTURE = ""

local function IsModuleEnabled()
    return not Nirnsteel_UI.Settings or Nirnsteel_UI.Settings:IsActionBarFramesEnabled()
end

local function IsUltimateReady(button)
    if not button or not ZO_ActionBar_IsUltimateSlot(button:GetSlot(), button:GetHotbarCategory()) then
        return false
    end

    local cost = GetSlotAbilityCost(button:GetSlot(), COMBAT_MECHANIC_FLAGS_ULTIMATE, button:GetHotbarCategory())
    return cost and cost > 0 and button:GetUltimateCount() >= cost
end

local function IsQuickslotConsumableOnCooldown(button)
    if not button or button:GetHotbarCategory() ~= HOTBAR_CATEGORY_QUICKSLOT_WHEEL then
        return false
    end

    local slotNum = button:GetSlot()
    local hotbarCategory = button:GetHotbarCategory()
    local slotType = GetSlotType(slotNum, hotbarCategory)
    if slotType ~= ACTION_TYPE_ITEM and slotType ~= ACTION_TYPE_COLLECTIBLE and slotType ~= ACTION_TYPE_QUEST_ITEM then
        return false
    end

    local remain, duration = GetSlotCooldownInfo(slotNum, hotbarCategory)
    return duration and duration > 0 and remain and remain > 0
end

local function GetOverlayTexture(button)
    if IsQuickslotConsumableOnCooldown(button) then
        return TOGGLED_FRAME
    end

    if IsUltimateReady(button) then
        return PRESSED_FRAME
    end
end

local function GetStockNormalFrameTexture()
    return IsInGamepadPreferredMode() and NO_TEXTURE or STOCK_NORMAL_FRAME
end

local function GetStockPressedFrameTexture()
    return IsInGamepadPreferredMode() and NO_TEXTURE or STOCK_PRESSED_FRAME
end

local function IsStockActionFrame(texture)
    return texture == STOCK_NORMAL_FRAME
        or texture == STOCK_PRESSED_FRAME
        or texture == NO_TEXTURE
end

local function GetSetupNormalFrame(normalFrame)
    if IsModuleEnabled() and IsStockActionFrame(normalFrame) then
        return NORMAL_FRAME
    end

    return normalFrame
end

local function GetSetupPressedFrame(pressedFrame)
    if IsModuleEnabled() then
        if pressedFrame == STOCK_PRESSED_FRAME then
            return PRESSED_FRAME
        elseif pressedFrame == STOCK_NORMAL_FRAME then
            return NORMAL_FRAME
        elseif pressedFrame == NO_TEXTURE then
            return PRESSED_FRAME
        end
    end

    return pressedFrame
end

function ActionBarFrames:ApplyToButton(button)
    if not button or not button.button then
        return
    end

    local moduleEnabled = IsModuleEnabled()
    button.button:SetNormalTexture(moduleEnabled and NORMAL_FRAME or GetStockNormalFrameTexture())
    button.button:SetPressedTexture(moduleEnabled and PRESSED_FRAME or GetStockPressedFrameTexture())

    if button.status then
        local overlayTexture = moduleEnabled and GetOverlayTexture(button)
        if overlayTexture then
            button.status:SetTexture(overlayTexture)
            button.status:SetHidden(false)
        elseif moduleEnabled then
            button.status:SetHidden(true)
        else
            local slotNum = button:GetSlot()
            local hotbarCategory = button:GetHotbarCategory()
            local slotIsEmpty = GetSlotType(slotNum, hotbarCategory) == ACTION_TYPE_NOTHING
            button.status:SetTexture(TOGGLED_FRAME)
            button.status:SetHidden(slotIsEmpty or IsSlotToggled(slotNum, hotbarCategory) == false)
        end
    end
end

function ActionBarFrames:ApplyQuickslot()
    if ZO_ActionBar_GetButton then
        self:ApplyToButton(ZO_ActionBar_GetButton(nil, HOTBAR_CATEGORY_QUICKSLOT_WHEEL))
    end
end

function ActionBarFrames:ApplyActiveUltimate()
    if ZO_ActionBar_GetButton then
        self:ApplyToButton(ZO_ActionBar_GetButton(ACTION_BAR_ULTIMATE_SLOT_INDEX + 1))
    end
end

function ActionBarFrames:ApplyCompanionUltimate()
    if ZO_ActionBar_GetButton then
        self:ApplyToButton(ZO_ActionBar_GetButton(ACTION_BAR_ULTIMATE_SLOT_INDEX + 1, HOTBAR_CATEGORY_COMPANION))
    end
end

function ActionBarFrames:ApplyAll()
    if not ZO_ActionBar_GetButton then
        return
    end

    for i = ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 1, ACTION_BAR_ULTIMATE_SLOT_INDEX + 1 do
        self:ApplyToButton(ZO_ActionBar_GetButton(i))
    end

    self:ApplyQuickslot()
    self:ApplyCompanionUltimate()
end

function ActionBarFrames:RefreshAssignableActionBars()
    if SKILLS_WINDOW and SKILLS_WINDOW.assignableActionBar then
        SKILLS_WINDOW.assignableActionBar:RefreshAllButtons()
    end

    if GAMEPAD_SKILLS and GAMEPAD_SKILLS.assignableActionBar then
        GAMEPAD_SKILLS.assignableActionBar:RefreshAllButtons()
    end
end

local function WrapActionButtonMethod(methodName)
    if not ActionButton or ActionButton["NirnsteelOriginal" .. methodName] then
        return
    end

    local original = ActionButton[methodName]
    if not original then
        return
    end

    ActionButton["NirnsteelOriginal" .. methodName] = original
    ActionButton[methodName] = function(button, ...)
        local result = original(button, ...)
        ActionBarFrames:ApplyToButton(button)
        return result
    end
end

function ActionBarFrames:InstallActionSlotHooks()
    if self.actionSlotHooksInstalled or not ZO_ActionSlot_SetupSlot or not ZO_ActionSlot_ClearSlot then
        return
    end

    self.originalSetupSlot = ZO_ActionSlot_SetupSlot
    self.originalClearSlot = ZO_ActionSlot_ClearSlot

    ZO_ActionSlot_SetupSlot = function(iconControl, buttonControl, icon, normalFrame, downFrame, cooldownIconControl, mouseOverTexture)
        return ActionBarFrames.originalSetupSlot(
            iconControl,
            buttonControl,
            icon,
            GetSetupNormalFrame(normalFrame),
            GetSetupPressedFrame(downFrame),
            cooldownIconControl,
            mouseOverTexture
        )
    end

    ZO_ActionSlot_ClearSlot = function(iconControl, buttonControl, normalFrame, downFrame, cooldownIconControl, mouseOverTexture)
        return ActionBarFrames.originalClearSlot(
            iconControl,
            buttonControl,
            GetSetupNormalFrame(normalFrame),
            GetSetupPressedFrame(downFrame),
            cooldownIconControl,
            mouseOverTexture
        )
    end

    self.actionSlotHooksInstalled = true
end

function ActionBarFrames:InstallHooks()
    if self.hooksInstalled then
        return
    end

    self:InstallActionSlotHooks()
    WrapActionButtonMethod("HandleSlotChanged")
    WrapActionButtonMethod("UpdateState")
    WrapActionButtonMethod("UpdateCooldown")
    WrapActionButtonMethod("RefreshCooldown")
    WrapActionButtonMethod("SetUltimateMeter")
    WrapActionButtonMethod("Clear")
    WrapActionButtonMethod("ApplyStyle")

    self.hooksInstalled = true
end

function ActionBarFrames:RegisterEvents()
    if self.eventsRegistered then
        return
    end

    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_ACTION_UPDATE_COOLDOWNS, function()
        self:ApplyQuickslot()
    end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_HOTBAR_SLOT_UPDATED, function()
        self:ApplyAll()
    end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_HOTBAR_SLOT_STATE_UPDATED, function()
        self:ApplyAll()
    end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_ACTION_SLOTS_ACTIVE_HOTBAR_UPDATED, function()
        zo_callLater(function() self:ApplyAll() end, 250)
        zo_callLater(function() self:ApplyAll() end, 550)
    end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_ACTION_SLOTS_ALL_HOTBARS_UPDATED, function()
        zo_callLater(function() self:ApplyAll() end, 100)
    end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_ACTIVE_QUICKSLOT_CHANGED, function()
        self:ApplyQuickslot()
    end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_PLAYER_ACTIVATED, function()
        zo_callLater(function() self:ApplyAll() end, 1000)
    end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_POWER_UPDATE, function()
        self:ApplyActiveUltimate()
    end)
    EVENT_MANAGER:AddFilterForEvent(EVENT_NAMESPACE, EVENT_POWER_UPDATE, REGISTER_FILTER_POWER_TYPE, COMBAT_MECHANIC_FLAGS_ULTIMATE, REGISTER_FILTER_UNIT_TAG, "player")

    self.eventsRegistered = true
end

function ActionBarFrames:RefreshSettings()
    self:RegisterEvents()
    self:ApplyAll()
    self:RefreshAssignableActionBars()
end

local function OnAddOnLoaded(_, addonName)
    if addonName ~= ADDON_NAME then
        return
    end

    EVENT_MANAGER:UnregisterForEvent(EVENT_NAMESPACE .. "_Loaded", EVENT_ADD_ON_LOADED)
    ActionBarFrames:InstallHooks()
    ActionBarFrames:RefreshSettings()
    zo_callLater(function() ActionBarFrames:ApplyAll() end, 1000)
end

EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE .. "_Loaded", EVENT_ADD_ON_LOADED, OnAddOnLoaded)

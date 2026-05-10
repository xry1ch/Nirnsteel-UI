local ADDON_NAME = "Nirnsteel-UI"
local ADDON_DISPLAY_NAME = "Nirnsteel UI"
local SAVED_VARS_VERSION = 1

Nirnsteel_UI = Nirnsteel_UI or {}

local Settings = {}
Nirnsteel_UI.Settings = Settings

local ACCOUNT_DEFAULTS =
{
    modules =
    {
        lootHistory =
        {
            enabled = true,
            unlocked = false,
            soundsEnabled = true,
            filterExperience = false,
        },
    },
}

local SERVER_DEFAULTS =
{
    servers =
    {
        ["*"] =
        {
            modules =
            {
                lootHistory =
                {
                    x = 180,
                    y = -230,
                },
            },
        },
    },
}

local function GetServerKey()
    local worldName = GetWorldName()
    if worldName and worldName ~= "" then
        return worldName
    end

    local lastRealm = GetCVar("LastRealm")
    if lastRealm and lastRealm ~= "" then
        return lastRealm
    end

    return "Default"
end

local function CopyDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then
                target[key] = {}
            end
            CopyDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

function Settings:Initialize()
    self.account = ZO_SavedVars:NewAccountWide("NirnsteelUI_Account", SAVED_VARS_VERSION, nil, ACCOUNT_DEFAULTS)
    self.servers = ZO_SavedVars:NewAccountWide("NirnsteelUI_Servers", SAVED_VARS_VERSION, nil, SERVER_DEFAULTS)
    self.serverKey = GetServerKey()
    self.servers.servers[self.serverKey] = self.servers.servers[self.serverKey] or {}
    self.server = self.servers.servers[self.serverKey]
    CopyDefaults(self.server, SERVER_DEFAULTS.servers["*"])

    self:RegisterAddonMenu()
end

function Settings:GetLootHistory()
    return self.account.modules.lootHistory
end

function Settings:GetLootHistoryPosition()
    return self.server.modules.lootHistory
end

function Settings:IsLootHistoryEnabled()
    return self:GetLootHistory().enabled
end

function Settings:IsLootHistoryUnlocked()
    return self:GetLootHistory().unlocked
end

function Settings:AreLootHistorySoundsEnabled()
    return self:GetLootHistory().soundsEnabled
end

function Settings:ShouldFilterLootHistoryExperience()
    return self:GetLootHistory().filterExperience
end

function Settings:SetLootHistoryEnabled(value)
    self:GetLootHistory().enabled = value
    if Nirnsteel_UI.LootHistory then
        Nirnsteel_UI.LootHistory:RefreshSettings()
    end
end

function Settings:SetLootHistoryUnlocked(value)
    self:GetLootHistory().unlocked = value
    if Nirnsteel_UI.LootHistory then
        Nirnsteel_UI.LootHistory:RefreshSettings()
    end
end

function Settings:SetLootHistorySoundsEnabled(value)
    self:GetLootHistory().soundsEnabled = value
end

function Settings:SetLootHistoryFilterExperience(value)
    self:GetLootHistory().filterExperience = value
end

function Settings:SetLootHistoryPosition(x, y)
    local position = self:GetLootHistoryPosition()
    position.x = x
    position.y = y
end

function Settings:RegisterAddonMenu()
    local LAM = LibAddonMenu2
    if not LAM and LibStub then
        local foundLib, lib = pcall(LibStub, "LibAddonMenu-2.0")
        if foundLib then
            LAM = lib
        end
    end

    if not LAM then
        d("Nirnsteel UI: LibAddonMenu-2.0 not found.")
        return
    end

    local panelName = "Nirnsteel_UI_Settings"
    local panelData =
    {
        type = "panel",
        name = ADDON_DISPLAY_NAME,
        displayName = ADDON_DISPLAY_NAME,
        author = "Nirnsteel",
        version = "0.1.0",
        registerForRefresh = true,
        registerForDefaults = true,
    }

    local options =
    {
        {
            type = "description",
            text = "Account-wide module settings are kept separate from per-server HUD positions.",
        },
        {
            type = "header",
            name = "Loot History",
        },
        {
            type = "checkbox",
            name = "Enable Loot History Module",
            tooltip = "Completely enables or disables the Nirnsteel loot history replacement.",
            getFunc = function() return self:IsLootHistoryEnabled() end,
            setFunc = function(value) self:SetLootHistoryEnabled(value) end,
            default = ACCOUNT_DEFAULTS.modules.lootHistory.enabled,
        },
        {
            type = "checkbox",
            name = "Unlock Loot Frame",
            tooltip = "Shows a draggable HUD handle for positioning the loot history frame. Position is saved per server.",
            getFunc = function() return self:IsLootHistoryUnlocked() end,
            setFunc = function(value) self:SetLootHistoryUnlocked(value) end,
            disabled = function() return not self:IsLootHistoryEnabled() end,
            default = ACCOUNT_DEFAULTS.modules.lootHistory.unlocked,
        },
        {
            type = "checkbox",
            name = "Enable Sounds",
            tooltip = "Plays loot feedback sounds, including the special legendary fanfare.",
            getFunc = function() return self:AreLootHistorySoundsEnabled() end,
            setFunc = function(value) self:SetLootHistorySoundsEnabled(value) end,
            disabled = function() return not self:IsLootHistoryEnabled() end,
            default = ACCOUNT_DEFAULTS.modules.lootHistory.soundsEnabled,
        },
        {
            type = "checkbox",
            name = "Filter Out Experience",
            tooltip = "Prevents experience gains from appearing in the Nirnsteel loot history stream.",
            getFunc = function() return self:ShouldFilterLootHistoryExperience() end,
            setFunc = function(value) self:SetLootHistoryFilterExperience(value) end,
            disabled = function() return not self:IsLootHistoryEnabled() end,
            default = ACCOUNT_DEFAULTS.modules.lootHistory.filterExperience,
        },
    }

    LAM:RegisterAddonPanel(panelName, panelData)
    LAM:RegisterOptionControls(panelName, options)
end

local function OnAddOnLoaded(_, addonName)
    if addonName ~= ADDON_NAME then
        return
    end

    EVENT_MANAGER:UnregisterForEvent(ADDON_NAME .. "_Settings", EVENT_ADD_ON_LOADED)
    Settings:Initialize()
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME .. "_Settings", EVENT_ADD_ON_LOADED, OnAddOnLoaded)

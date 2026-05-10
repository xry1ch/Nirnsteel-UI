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
        damageNumbers =
        {
            enabled = true,
            unlocked = false,
            hideDefaultDamage = true,
            critSoundEnabled = true,
            fontKey = "trajan",
            critSoundKey = "RETURNING_PLAYER_OPEN_KEYBOARD",
            normalFontSize = 32,
            critFontSize = 65,
            durationMS = 850,
            spread = 170,
            drift = 15,
            bigHitThreshold = 40000,
            maxActive = 30,
            soundThrottleMS = 40,
            savedSctSettings = {},
        },
        actionBarFrames =
        {
            enabled = true,
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
                damageNumbers =
                {
                    x = 0,
                    y = -45,
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

local function UpgradeDamageNumberDefaults(account)
    local damageNumbers = account
        and account.modules
        and account.modules.damageNumbers

    if not damageNumbers then
        return
    end

    if damageNumbers.normalFontSize == 42 then
        damageNumbers.normalFontSize = ACCOUNT_DEFAULTS.modules.damageNumbers.normalFontSize
    end

    if damageNumbers.critFontSize == 58 then
        damageNumbers.critFontSize = ACCOUNT_DEFAULTS.modules.damageNumbers.critFontSize
    end

    if damageNumbers.durationMS == 950 then
        damageNumbers.durationMS = ACCOUNT_DEFAULTS.modules.damageNumbers.durationMS
    end

    if damageNumbers.spread == 150 then
        damageNumbers.spread = ACCOUNT_DEFAULTS.modules.damageNumbers.spread
    end

    if damageNumbers.drift == 120 then
        damageNumbers.drift = ACCOUNT_DEFAULTS.modules.damageNumbers.drift
    end
end

function Settings:Initialize()
    self.account = ZO_SavedVars:NewAccountWide("NirnsteelUI_Account", SAVED_VARS_VERSION, nil, ACCOUNT_DEFAULTS)
    CopyDefaults(self.account, ACCOUNT_DEFAULTS)
    UpgradeDamageNumberDefaults(self.account)
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

function Settings:GetDamageNumbers()
    return self.account.modules.damageNumbers
end

function Settings:GetDamageNumbersPosition()
    return self.server.modules.damageNumbers
end

function Settings:GetActionBarFrames()
    return self.account.modules.actionBarFrames
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

function Settings:IsDamageNumbersEnabled()
    return self:GetDamageNumbers().enabled
end

function Settings:IsDamageNumbersUnlocked()
    return self:GetDamageNumbers().unlocked
end

function Settings:ShouldHideDefaultDamageNumbers()
    return self:GetDamageNumbers().hideDefaultDamage
end

function Settings:AreDamageNumberCritSoundsEnabled()
    return self:GetDamageNumbers().critSoundEnabled
end

function Settings:SetDamageNumbersEnabled(value)
    self:GetDamageNumbers().enabled = value
    if Nirnsteel_UI.DamageNumbers then
        Nirnsteel_UI.DamageNumbers:RefreshSettings()
    end
end

function Settings:SetDamageNumbersUnlocked(value)
    self:GetDamageNumbers().unlocked = value
    if Nirnsteel_UI.DamageNumbers then
        Nirnsteel_UI.DamageNumbers:RefreshSettings()
    end
end

function Settings:SetDamageNumbersHideDefault(value)
    self:GetDamageNumbers().hideDefaultDamage = value
    if Nirnsteel_UI.DamageNumbers then
        Nirnsteel_UI.DamageNumbers:RefreshSettings()
    end
end

function Settings:SetDamageNumberCritSoundsEnabled(value)
    self:GetDamageNumbers().critSoundEnabled = value
end

function Settings:SetDamageNumberValue(key, value)
    self:GetDamageNumbers()[key] = value
    if Nirnsteel_UI.DamageNumbers then
        Nirnsteel_UI.DamageNumbers:RefreshSettings()
    end
end

function Settings:SetDamageNumbersPosition(x, y)
    local position = self:GetDamageNumbersPosition()
    position.x = x
    position.y = y
end

function Settings:IsActionBarFramesEnabled()
    return self:GetActionBarFrames().enabled
end

function Settings:SetActionBarFramesEnabled(value)
    self:GetActionBarFrames().enabled = value
    if Nirnsteel_UI.ActionBarFrames then
        Nirnsteel_UI.ActionBarFrames:RefreshSettings()
    end
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
            type = "submenu",
            name = "Loot History",
            tooltip = "Settings for the Nirnsteel loot history replacement.",
            controls =
            {
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
            },
        },
        {
            type = "submenu",
            name = "Damage Numbers",
            tooltip = "Settings for custom Nirnsteel combat damage numbers.",
            controls =
            {
                {
                    type = "checkbox",
                    name = "Enable Damage Numbers Module",
                    tooltip = "Shows custom Nirnsteel combat damage numbers near the center of combat.",
                    getFunc = function() return self:IsDamageNumbersEnabled() end,
                    setFunc = function(value) self:SetDamageNumbersEnabled(value) end,
                    default = ACCOUNT_DEFAULTS.modules.damageNumbers.enabled,
                },
                {
                    type = "checkbox",
                    name = "Unlock Damage Number Origin",
                    tooltip = "Shows a draggable anchor for the center point where damage numbers spawn. Position is saved per server.",
                    getFunc = function() return self:IsDamageNumbersUnlocked() end,
                    setFunc = function(value) self:SetDamageNumbersUnlocked(value) end,
                    disabled = function() return not self:IsDamageNumbersEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.damageNumbers.unlocked,
                },
                {
                    type = "checkbox",
                    name = "Hide Default Damage Numbers",
                    tooltip = "Disables ESO damage and DoT scrolling combat text categories while the Nirnsteel module is enabled.",
                    getFunc = function() return self:ShouldHideDefaultDamageNumbers() end,
                    setFunc = function(value) self:SetDamageNumbersHideDefault(value) end,
                    disabled = function() return not self:IsDamageNumbersEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.damageNumbers.hideDefaultDamage,
                },
                {
                    type = "checkbox",
                    name = "Critical Hit Sound",
                    tooltip = "Plays a throttled impact sound for critical damage events.",
                    getFunc = function() return self:AreDamageNumberCritSoundsEnabled() end,
                    setFunc = function(value) self:SetDamageNumberCritSoundsEnabled(value) end,
                    disabled = function() return not self:IsDamageNumbersEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.damageNumbers.critSoundEnabled,
                },
                {
                    type = "dropdown",
                    name = "Damage Number Font",
                    tooltip = "Chooses the font family used by custom damage numbers.",
                    choices =
                    {
                        "Antique",
                        "Handwritten",
                        "Stone Tablet",
                        "Prose Antique",
                        "Trajan",
                        "Univers 57",
                        "Univers 67",
                        "Univers Cyrillic",
                        "Univers Cyrillic Bold",
                        "Futura Light",
                        "Futura Medium",
                        "Futura Bold",
                        "ESO Japanese",
                        "ESO Japanese Medium",
                        "Chinese Medium",
                        "Gamepad Bold",
                        "Gamepad Medium",
                        "Gamepad Light",
                        "Gamepad Number",
                        "Keyboard Bold",
                        "Keyboard Medium",
                        "Chat",
                    },
                    choicesValues =
                    {
                        "antique",
                        "handwritten",
                        "stoneTablet",
                        "proseAntique",
                        "trajan",
                        "univers57",
                        "univers67",
                        "universCyrillic",
                        "universCyrillicBold",
                        "futuraLight",
                        "futuraMedium",
                        "futuraBold",
                        "esoJapanese",
                        "esoJapaneseMedium",
                        "chineseMedium",
                        "gamepadBold",
                        "gamepadMedium",
                        "gamepadLight",
                        "gamepadNumber",
                        "keyboardBold",
                        "keyboardMedium",
                        "chat",
                    },
                    getFunc = function() return self:GetDamageNumbers().fontKey end,
                    setFunc = function(value) self:SetDamageNumberValue("fontKey", value) end,
                    disabled = function() return not self:IsDamageNumbersEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.damageNumbers.fontKey,
                },
                {
                    type = "dropdown",
                    name = "Critical Sound",
                    tooltip = "Chooses the sound played for critical damage numbers.",
                    choices =
                    {
                        "CONSOLE_GAME_ENTER",
                        "RETURNING_PLAYER_OPEN_KEYBOARD",
                        "VENGEANCE_PERK_EQUIPPED",
                        "KEYBIND_BUTTON_DISABLED",
                        "PROMOTIONAL_EVENT_REWARD_TO_CLAIM_PROMPT"
                    },
                    choicesValues =
                    {
                        "CONSOLE_GAME_ENTER",
                        "RETURNING_PLAYER_OPEN_KEYBOARD",
                        "VENGEANCE_PERK_EQUIPPED",
                        "KEYBIND_BUTTON_DISABLED",
                        "PROMOTIONAL_EVENT_REWARD_TO_CLAIM_PROMPT"

                    },
                    getFunc = function() return self:GetDamageNumbers().critSoundKey end,
                    setFunc = function(value) self:SetDamageNumberValue("critSoundKey", value) end,
                    disabled = function() return not self:IsDamageNumbersEnabled() or not self:AreDamageNumberCritSoundsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.damageNumbers.critSoundKey,
                },
                {
                    type = "slider",
                    name = "Normal Font Size",
                    tooltip = "Controls the font size for regular damage numbers.",
                    min = 32,
                    max = 96,
                    step = 1,
                    getFunc = function() return self:GetDamageNumbers().normalFontSize end,
                    setFunc = function(value) self:SetDamageNumberValue("normalFontSize", value) end,
                    disabled = function() return not self:IsDamageNumbersEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.damageNumbers.normalFontSize,
                },
                {
                    type = "slider",
                    name = "Critical Font Size",
                    tooltip = "Controls the font size for critical damage numbers.",
                    min = 48,
                    max = 128,
                    step = 1,
                    getFunc = function() return self:GetDamageNumbers().critFontSize end,
                    setFunc = function(value) self:SetDamageNumberValue("critFontSize", value) end,
                    disabled = function() return not self:IsDamageNumbersEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.damageNumbers.critFontSize,
                },
                {
                    type = "slider",
                    name = "Duration",
                    tooltip = "Controls how long damage numbers remain visible.",
                    min = 450,
                    max = 1800,
                    step = 25,
                    getFunc = function() return self:GetDamageNumbers().durationMS end,
                    setFunc = function(value) self:SetDamageNumberValue("durationMS", value) end,
                    disabled = function() return not self:IsDamageNumbersEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.damageNumbers.durationMS,
                },
                {
                    type = "slider",
                    name = "Spread",
                    tooltip = "Controls how far new damage numbers scatter around the combat center.",
                    min = 40,
                    max = 280,
                    step = 5,
                    getFunc = function() return self:GetDamageNumbers().spread end,
                    setFunc = function(value) self:SetDamageNumberValue("spread", value) end,
                    disabled = function() return not self:IsDamageNumbersEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.damageNumbers.spread,
                },
                {
                    type = "slider",
                    name = "Drift",
                    tooltip = "Controls how far damage numbers travel after the pop.",
                    min = 0,
                    max = 160,
                    step = 5,
                    getFunc = function() return self:GetDamageNumbers().drift end,
                    setFunc = function(value) self:SetDamageNumberValue("drift", value) end,
                    disabled = function() return not self:IsDamageNumbersEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.damageNumbers.drift,
                },
                {
                    type = "slider",
                    name = "Big Hit Threshold",
                    tooltip = "Hits at or above this value drift less so they feel heavier.",
                    min = 1000,
                    max = 200000,
                    step = 1000,
                    getFunc = function() return self:GetDamageNumbers().bigHitThreshold end,
                    setFunc = function(value) self:SetDamageNumberValue("bigHitThreshold", value) end,
                    disabled = function() return not self:IsDamageNumbersEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.damageNumbers.bigHitThreshold,
                },
                {
                    type = "slider",
                    name = "Maximum Active Numbers",
                    tooltip = "Caps the number of visible damage labels. The oldest label is reused when the cap is reached.",
                    min = 8,
                    max = 80,
                    step = 1,
                    getFunc = function() return self:GetDamageNumbers().maxActive end,
                    setFunc = function(value) self:SetDamageNumberValue("maxActive", value) end,
                    disabled = function() return not self:IsDamageNumbersEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.damageNumbers.maxActive,
                },
                {
                    type = "slider",
                    name = "Critical Sound Throttle",
                    tooltip = "Minimum milliseconds between critical-hit sounds.",
                    min = 0,
                    max = 800,
                    step = 10,
                    getFunc = function() return self:GetDamageNumbers().soundThrottleMS end,
                    setFunc = function(value) self:SetDamageNumberValue("soundThrottleMS", value) end,
                    disabled = function() return not self:IsDamageNumbersEnabled() or not self:AreDamageNumberCritSoundsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.damageNumbers.soundThrottleMS,
                },
            },
        },
        {
            type = "submenu",
            name = "Action Bar Frames",
            tooltip = "Settings for Nirnsteel action bar slot frame textures.",
            controls =
            {
                {
                    type = "checkbox",
                    name = "Enable Action Bar Frames Module",
                    tooltip = "Replaces action bar button frames and highlights ready ultimate and quickslot cooldown states.",
                    getFunc = function() return self:IsActionBarFramesEnabled() end,
                    setFunc = function(value) self:SetActionBarFramesEnabled(value) end,
                    default = ACCOUNT_DEFAULTS.modules.actionBarFrames.enabled,
                },
            },
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

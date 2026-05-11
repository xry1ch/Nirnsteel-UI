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
            regularSoundKey = "TRIBUTE_AGENT_HEALED",
            filterExperience = false,
        },
        damageNumbers =
        {
            enabled = true,
            unlocked = false,
            hideDefaultDamage = true,
            critSoundEnabled = true,
            fontKey = "trajan",
            textEffect = "none",
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
        killSound =
        {
            enabled = true,
            soundKey = "BATTLEGROUND_KILL_KILLING_BLOW",
        },
        actionBarFrames =
        {
            enabled = true,
            skillUseShrinkEnabled = true,
            globalCooldownEnabled = true,
        },
        compass =
        {
            enabled = true,
        },
        experienceTracker =
        {
            enabled = true,
            unlocked = false,
            scale = 100,
            opacity = 100,
            width = 460,
            height = 64,
            durationMS = 3600,
            intensity = 100,
            visibilityMode = "fade",
            chunkSoundKey = "PROMOTIONAL_EVENT_REWARD_TO_CLAIM_PROMPT",
            showGainText = true,
            hideStockProgressBar = true,
        },
        resourceBars =
        {
            enabled = true,
            unlocked = false,
            scale = 109,
            barHeight = 25,
            rowSpacing = 5,
            columnSpacing = 8,
            rowHealthWidth = 300,
            rowMagickaWidth = 270,
            rowStaminaWidth = 270,
            opacity = 100,
            glossEnabled = true,
            healthTextFormat = "numberAndPercent",
            magickaTextFormat = "numberAndPercent",
            staminaTextFormat = "numberAndPercent",
            healthTextPosition = "sides",
            magickaTextPosition = "sides",
            staminaTextPosition = "sides",
            shieldOverlayEnabled = true,
            shieldTextMode = "healthAndShield",
            shieldFillOpacity = 70,
            shieldFillColor = { r = 0.95, g = 0.60, b = 0.33 },
            shieldGlowEnabled = true,
            shieldGlowOpacity = 65,
            shieldGlowColor = { r = 0.95, g = 0.66, b = 0.56 },
            barPatternEnabled = true,
            barPatternKey = "Molten",
            barPatternOpacity = 6,
            barPatternScale = 228,
            feedbackEnabled = true,
            feedbackIntensity = 100,
            gainPulseEnabled = true,
            spendPulseEnabled = true,
            fullResourcePulseEnabled = true,
            shieldPulseEnabled = true,
            lowResourceGlowEnabled = true,
            borderWidth = 0,
            cornerSize = 2,
            innerShadowAlpha = 60,
            outerShadowAlpha = 100,
            textFontKey = "gameSmall",
            textSize = 18,
            textOutline = "thick-outline",
            textOpacity = 100,
            textInset = 6,
            textVerticalOffset = 3,
            textColor = { r = 0.96, g = 0.92, b = 0.82 },
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
                experienceTracker =
                {
                    x = 30,
                    y = 30,
                },
                resourceBars =
                {
                    x = 0,
                    y = -120,
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

local function UpgradeExperienceTrackerDefaults(account)
    local experienceTracker = account
        and account.modules
        and account.modules.experienceTracker

    if not experienceTracker then
        return
    end

    if experienceTracker.width == 420 and experienceTracker.height == 48 then
        experienceTracker.width = ACCOUNT_DEFAULTS.modules.experienceTracker.width
        experienceTracker.height = ACCOUNT_DEFAULTS.modules.experienceTracker.height
    end
end

local function UpgradeResourceBarDefaults(account)
    local resourceBars = account
        and account.modules
        and account.modules.resourceBars

    if not resourceBars then
        return
    end

    if resourceBars.rowHealthWidth == 220 then
        resourceBars.rowHealthWidth = ACCOUNT_DEFAULTS.modules.resourceBars.rowHealthWidth
    end
    if resourceBars.rowMagickaWidth == 220 then
        resourceBars.rowMagickaWidth = ACCOUNT_DEFAULTS.modules.resourceBars.rowMagickaWidth
    end
    if resourceBars.rowStaminaWidth == 220 then
        resourceBars.rowStaminaWidth = ACCOUNT_DEFAULTS.modules.resourceBars.rowStaminaWidth
    end
    if resourceBars.columnSpacing == 0 then
        resourceBars.columnSpacing = ACCOUNT_DEFAULTS.modules.resourceBars.columnSpacing
    end
    resourceBars.layoutMode = nil
    resourceBars.healthPositionMode = nil
    resourceBars.stackedWidth = nil
    resourceBars.width = nil
    resourceBars.healthChaseSpeed = nil

    local textFormatAliases =
    {
        Number = "number",
        Percent = "percent",
        ["Number + Percent"] = "numberAndPercent",
        ["Number and Percent"] = "numberAndPercent",
    }
    local textPositionAliases =
    {
        Center = "center",
        Sides = "sides",
    }
    local shieldTextAliases =
    {
        Off = "off",
        ["Shield Only"] = "shieldOnly",
        ["Health + Shield"] = "healthAndShield",
    }
    local fontAliases =
    {
        ["Game Small"] = "gameSmall",
        ["Game Medium"] = "gameMedium",
        Antique = "antique",
        Trajan = "trajan",
        Univers = "univers",
        Chat = "chat",
    }
    local outlineAliases =
    {
        None = "none",
        ["Soft Thin"] = "soft-shadow-thin",
        ["Soft Thick"] = "soft-shadow-thick",
        ["Thick Outline"] = "thick-outline",
    }
    local patternAliases =
    {
        Smoke = "smoke",
        Stillwater = "stillwater",
    }

    for _, key in ipairs({ "healthTextFormat", "magickaTextFormat", "staminaTextFormat" }) do
        resourceBars[key] = textFormatAliases[resourceBars[key]] or resourceBars[key] or ACCOUNT_DEFAULTS.modules.resourceBars[key]
    end
    for _, key in ipairs({ "healthTextPosition", "magickaTextPosition", "staminaTextPosition" }) do
        resourceBars[key] = textPositionAliases[resourceBars[key]] or resourceBars[key] or ACCOUNT_DEFAULTS.modules.resourceBars[key]
    end
    resourceBars.shieldTextMode = shieldTextAliases[resourceBars.shieldTextMode] or resourceBars.shieldTextMode or ACCOUNT_DEFAULTS.modules.resourceBars.shieldTextMode
    resourceBars.textFontKey = fontAliases[resourceBars.textFontKey] or resourceBars.textFontKey or ACCOUNT_DEFAULTS.modules.resourceBars.textFontKey
    resourceBars.textOutline = outlineAliases[resourceBars.textOutline] or resourceBars.textOutline or ACCOUNT_DEFAULTS.modules.resourceBars.textOutline
    resourceBars.barPatternKey = patternAliases[resourceBars.barPatternKey] or resourceBars.barPatternKey or ACCOUNT_DEFAULTS.modules.resourceBars.barPatternKey
end

function Settings:Initialize()
    self.account = ZO_SavedVars:NewAccountWide("NirnsteelUI_Account", SAVED_VARS_VERSION, nil, ACCOUNT_DEFAULTS)
    CopyDefaults(self.account, ACCOUNT_DEFAULTS)
    UpgradeDamageNumberDefaults(self.account)
    UpgradeExperienceTrackerDefaults(self.account)
    UpgradeResourceBarDefaults(self.account)
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

function Settings:GetKillSound()
    return self.account.modules.killSound
end

function Settings:GetActionBarFrames()
    return self.account.modules.actionBarFrames
end

function Settings:GetCompass()
    return self.account.modules.compass
end

function Settings:GetExperienceTracker()
    return self.account.modules.experienceTracker
end

function Settings:GetExperienceTrackerPosition()
    return self.server.modules.experienceTracker
end

function Settings:GetResourceBars()
    return self.account.modules.resourceBars
end

function Settings:GetResourceBarsPosition()
    return self.server.modules.resourceBars
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

function Settings:SetLootHistoryValue(key, value)
    self:GetLootHistory()[key] = value
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

function Settings:IsKillSoundEnabled()
    return self:GetKillSound().enabled
end

function Settings:SetKillSoundEnabled(value)
    self:GetKillSound().enabled = value
    if Nirnsteel_UI.KillSound then
        Nirnsteel_UI.KillSound:RefreshSettings()
    end
end

function Settings:SetKillSoundValue(key, value)
    self:GetKillSound()[key] = value
    if Nirnsteel_UI.KillSound then
        Nirnsteel_UI.KillSound:RefreshSettings()
    end
end

function Settings:PreviewDamageNumberCritSound()
    if Nirnsteel_UI.DamageNumbers and Nirnsteel_UI.DamageNumbers.PreviewCriticalSound then
        Nirnsteel_UI.DamageNumbers:PreviewCriticalSound()
    end
end

function Settings:PreviewKillSound()
    if Nirnsteel_UI.KillSound and Nirnsteel_UI.KillSound.PreviewSound then
        Nirnsteel_UI.KillSound:PreviewSound()
    end
end

function Settings:PreviewLootHistoryRegularSound()
    if Nirnsteel_UI.LootHistory and Nirnsteel_UI.LootHistory.PreviewRegularSound then
        Nirnsteel_UI.LootHistory:PreviewRegularSound()
    end
end

function Settings:IsActionBarFramesEnabled()
    return self:GetActionBarFrames().enabled
end

function Settings:IsActionBarSkillUseShrinkEnabled()
    return self:GetActionBarFrames().skillUseShrinkEnabled
end

function Settings:IsActionBarGlobalCooldownEnabled()
    return self:GetActionBarFrames().globalCooldownEnabled
end

function Settings:SetActionBarFramesEnabled(value)
    self:GetActionBarFrames().enabled = value
    if Nirnsteel_UI.ActionBarFrames then
        Nirnsteel_UI.ActionBarFrames:RefreshSettings()
    end
end

function Settings:SetActionBarSkillUseShrinkEnabled(value)
    self:GetActionBarFrames().skillUseShrinkEnabled = value
end

function Settings:SetActionBarGlobalCooldownEnabled(value)
    self:GetActionBarFrames().globalCooldownEnabled = value
    if Nirnsteel_UI.ActionBarFrames then
        Nirnsteel_UI.ActionBarFrames:RefreshSettings()
    end
end

function Settings:IsCompassEnabled()
    return self:GetCompass().enabled
end

function Settings:SetCompassEnabled(value)
    self:GetCompass().enabled = value
    if Nirnsteel_UI.Compass then
        Nirnsteel_UI.Compass:RefreshSettings()
    end
end

function Settings:IsExperienceTrackerEnabled()
    return self:GetExperienceTracker().enabled
end

function Settings:IsExperienceTrackerUnlocked()
    return self:GetExperienceTracker().unlocked
end

function Settings:ShouldExperienceTrackerHideStockProgressBar()
    return self:GetExperienceTracker().hideStockProgressBar
end

function Settings:SetExperienceTrackerEnabled(value)
    self:GetExperienceTracker().enabled = value
    if Nirnsteel_UI.ExperienceTracker then
        Nirnsteel_UI.ExperienceTracker:RefreshSettings()
    end
end

function Settings:SetExperienceTrackerUnlocked(value)
    self:GetExperienceTracker().unlocked = value
    if Nirnsteel_UI.ExperienceTracker then
        Nirnsteel_UI.ExperienceTracker:RefreshSettings()
    end
end

function Settings:SetExperienceTrackerValue(key, value)
    self:GetExperienceTracker()[key] = value
    if Nirnsteel_UI.ExperienceTracker then
        Nirnsteel_UI.ExperienceTracker:RefreshSettings()
    end
end

function Settings:SetExperienceTrackerPosition(x, y)
    local position = self:GetExperienceTrackerPosition()
    position.x = x
    position.y = y
end

function Settings:PreviewExperienceTracker()
    if Nirnsteel_UI.ExperienceTracker and Nirnsteel_UI.ExperienceTracker.PreviewGain then
        Nirnsteel_UI.ExperienceTracker:PreviewGain()
    end
end

function Settings:IsResourceBarsEnabled()
    return self:GetResourceBars().enabled
end

function Settings:IsResourceBarsUnlocked()
    return self:GetResourceBars().unlocked
end

function Settings:SetResourceBarsEnabled(value)
    self:GetResourceBars().enabled = value
    if Nirnsteel_UI.ResourceBars then
        Nirnsteel_UI.ResourceBars:RefreshSettings()
    end
end

function Settings:SetResourceBarsUnlocked(value)
    self:GetResourceBars().unlocked = value
    if Nirnsteel_UI.ResourceBars then
        Nirnsteel_UI.ResourceBars:RefreshSettings()
    end
end

function Settings:SetResourceBarsValue(key, value)
    local textFormatAliases =
    {
        Number = "number",
        Percent = "percent",
        ["Number + Percent"] = "numberAndPercent",
        ["Number and Percent"] = "numberAndPercent",
    }
    local textPositionAliases =
    {
        Center = "center",
        Sides = "sides",
    }
    local shieldTextAliases =
    {
        Off = "off",
        ["Shield Only"] = "shieldOnly",
        ["Health + Shield"] = "healthAndShield",
    }
    local fontAliases =
    {
        ["Game Small"] = "gameSmall",
        ["Game Medium"] = "gameMedium",
        Antique = "antique",
        Trajan = "trajan",
        Univers = "univers",
        Chat = "chat",
    }
    local outlineAliases =
    {
        None = "none",
        ["Soft Thin"] = "soft-shadow-thin",
        ["Soft Thick"] = "soft-shadow-thick",
        ["Thick Outline"] = "thick-outline",
    }
    local patternAliases =
    {
        Smoke = "smoke",
        Stillwater = "stillwater",
    }

    if key == "healthTextFormat" or key == "magickaTextFormat" or key == "staminaTextFormat" then
        value = textFormatAliases[value] or value
    elseif key == "healthTextPosition" or key == "magickaTextPosition" or key == "staminaTextPosition" then
        value = textPositionAliases[value] or value
    elseif key == "shieldTextMode" then
        value = shieldTextAliases[value] or value
    elseif key == "textFontKey" then
        value = fontAliases[value] or value
    elseif key == "textOutline" then
        value = outlineAliases[value] or value
    elseif key == "barPatternKey" then
        value = patternAliases[value] or value
    end

    self:GetResourceBars()[key] = value
    if Nirnsteel_UI.ResourceBars then
        Nirnsteel_UI.ResourceBars:RefreshSettings()
    end
end

function Settings:SetResourceBarsPosition(x, y)
    local position = self:GetResourceBarsPosition()
    position.x = x
    position.y = y
end

function Settings:SetResourceBarsSettingsPreviewActive(active)
    if Nirnsteel_UI.ResourceBars and Nirnsteel_UI.ResourceBars.SetSettingsPreviewActive then
        Nirnsteel_UI.ResourceBars:SetSettingsPreviewActive(active)
    end
end

function Settings:HookResourceBarsSubmenuPreview(panelName)
    if self.resourceBarsPreviewHooked then
        return
    end

    self.resourceBarsPreviewHooked = true
    CALLBACK_MANAGER:RegisterCallback("LAM-PanelControlsCreated", function(panel)
        if not panel or panel:GetName() ~= panelName then
            return
        end

        local submenu = Nirnsteel_UI_ResourceBarsSubmenu
        if not submenu or submenu.nirnsteelPreviewHooked then
            return
        end

        local function UpdatePreview()
            zo_callLater(function()
                self:SetResourceBarsSettingsPreviewActive(submenu.open == true)
            end, 50)
        end

        if ZO_PostHookHandler then
            ZO_PostHookHandler(submenu.label, "OnMouseUp", UpdatePreview)
            ZO_PostHookHandler(submenu.btmToggle, "OnMouseUp", UpdatePreview)
        end

        submenu.nirnsteelPreviewHooked = true
        UpdatePreview()
    end)

    CALLBACK_MANAGER:RegisterCallback("LAM-PanelClosed", function(panel)
        if panel and panel:GetName() == panelName then
            self:SetResourceBarsSettingsPreviewActive(false)
        end
    end)
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
                    type = "dropdown",
                    name = "Regular Loot Sound",
                    tooltip = "Chooses the sound played for non-legendary loot.",
                    choices =
                    {
                        "TRIBUTE_AGENT_HEALED",
                        "STATS_RESPEC_CLEAR_ALL",
                        "TRIBUTE_CARD_UNTARGETED",
                        "VENGEANCE_PERK_DROP",
                    },
                    choicesValues =
                    {
                        "TRIBUTE_AGENT_HEALED",
                        "STATS_RESPEC_CLEAR_ALL",
                        "TRIBUTE_CARD_UNTARGETED",
                        "VENGEANCE_PERK_DROP",
                    },
                    getFunc = function() return self:GetLootHistory().regularSoundKey end,
                    setFunc = function(value)
                        self:SetLootHistoryValue("regularSoundKey", value)
                        self:PreviewLootHistoryRegularSound()
                    end,
                    disabled = function() return not self:IsLootHistoryEnabled() or not self:AreLootHistorySoundsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.lootHistory.regularSoundKey,
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
                    name = "Text Effect",
                    tooltip = "Applies an optional text effect to damage numbers.",
                    choices =
                    {
                        "None",
                        "Shadow",
                        "Outline",
                    },
                    choicesValues =
                    {
                        "none",
                        "shadow",
                        "outline",
                    },
                    getFunc = function() return self:GetDamageNumbers().textEffect end,
                    setFunc = function(value) self:SetDamageNumberValue("textEffect", value) end,
                    disabled = function() return not self:IsDamageNumbersEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.damageNumbers.textEffect,
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
                    setFunc = function(value)
                        self:SetDamageNumberValue("critSoundKey", value)
                        self:PreviewDamageNumberCritSound()
                    end,
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
            name = "Kill Sound",
            tooltip = "Settings for the sound played when your character lands the killing blow.",
            controls =
            {
                {
                    type = "description",
                    text = "Kill sound volume follows ESO audio settings (SFX/UI volume). ESO API PlaySound has no per-sound volume parameter.",
                },
                {
                    type = "checkbox",
                    name = "Enable Kill Sound Module",
                    tooltip = "Plays a configurable sound when your character lands the killing blow.",
                    getFunc = function() return self:IsKillSoundEnabled() end,
                    setFunc = function(value) self:SetKillSoundEnabled(value) end,
                    default = ACCOUNT_DEFAULTS.modules.killSound.enabled,
                },
                {
                    type = "dropdown",
                    name = "Killing Blow Sound",
                    tooltip = "Chooses the sound played for your killing blows.",
                    choices =
                    {
                        "BATTLEGROUND_KILL_KILLING_BLOW",
                        "CODE_REDEMPTION_SUCCESS",
                        "BATTLEGROUND_LEAVE_MATCH",
                        "BATTLEGROUND_ROUND_RECAP_SCREEN_END",
                        "SKILLS_SUBCLASSING_TRAIN"
                    },
                    choicesValues =
                    {
                        "BATTLEGROUND_KILL_KILLING_BLOW",
                        "CODE_REDEMPTION_SUCCESS",
                        "BATTLEGROUND_LEAVE_MATCH",
                        "BATTLEGROUND_ROUND_RECAP_SCREEN_END",
                        "SKILLS_SUBCLASSING_TRAIN"
                    },
                    getFunc = function() return self:GetKillSound().soundKey end,
                    setFunc = function(value)
                        self:SetKillSoundValue("soundKey", value)
                        self:PreviewKillSound()
                    end,
                    disabled = function() return not self:IsKillSoundEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.killSound.soundKey,
                },
            },
        },
        {
            type = "submenu",
            name = "Action Bar",
            tooltip = "Settings for Nirnsteel action bar visuals and feedback.",
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
                {
                    type = "checkbox",
                    name = "Shrink Used Skills",
                    tooltip = "Briefly shrinks the action bar button when you use a slotted skill.",
                    getFunc = function() return self:IsActionBarSkillUseShrinkEnabled() end,
                    setFunc = function(value) self:SetActionBarSkillUseShrinkEnabled(value) end,
                    disabled = function() return not self:IsActionBarFramesEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.actionBarFrames.skillUseShrinkEnabled,
                },
                {
                    type = "checkbox",
                    name = "Show Global Cooldown",
                    tooltip = "Shows ESO's global cooldown overlay on skill buttons after using a slotted skill.",
                    getFunc = function() return self:IsActionBarGlobalCooldownEnabled() end,
                    setFunc = function(value) self:SetActionBarGlobalCooldownEnabled(value) end,
                    disabled = function() return not self:IsActionBarFramesEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.actionBarFrames.globalCooldownEnabled,
                },
            },
        },
        {
            type = "submenu",
            name = "Compass",
            tooltip = "Settings for the Nirnsteel compass frame style.",
            controls =
            {
                {
                    type = "checkbox",
                    name = "Enable Compass Module",
                    tooltip = "Restyles the stock compass frame with a darker Nirnsteel frame using ESO art.",
                    getFunc = function() return self:IsCompassEnabled() end,
                    setFunc = function(value) self:SetCompassEnabled(value) end,
                    default = ACCOUNT_DEFAULTS.modules.compass.enabled,
                },
            },
        },
        {
            type = "submenu",
            name = "Experience Tracker",
            tooltip = "Settings for the custom HUD XP and Champion Point gain tracker.",
            controls =
            {
                {
                    type = "checkbox",
                    name = "Enable Experience Tracker",
                    tooltip = "Shows a custom Nirnsteel XP or Champion Point gain animation on the HUD.",
                    getFunc = function() return self:IsExperienceTrackerEnabled() end,
                    setFunc = function(value) self:SetExperienceTrackerEnabled(value) end,
                    default = ACCOUNT_DEFAULTS.modules.experienceTracker.enabled,
                },
                {
                    type = "checkbox",
                    name = "Unlock Experience Tracker",
                    tooltip = "Shows a draggable handle for positioning the tracker. Position is saved per server.",
                    getFunc = function() return self:IsExperienceTrackerUnlocked() end,
                    setFunc = function(value) self:SetExperienceTrackerUnlocked(value) end,
                    disabled = function() return not self:IsExperienceTrackerEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.experienceTracker.unlocked,
                },
                {
                    type = "checkbox",
                    name = "Hide Stock Progress Bar",
                    tooltip = "Suppresses ESO's default HUD XP progress bar while the custom tracker is enabled.",
                    getFunc = function() return self:ShouldExperienceTrackerHideStockProgressBar() end,
                    setFunc = function(value) self:SetExperienceTrackerValue("hideStockProgressBar", value) end,
                    disabled = function() return not self:IsExperienceTrackerEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.experienceTracker.hideStockProgressBar,
                },
                {
                    type = "checkbox",
                    name = "Show Gained XP Text",
                    tooltip = "Shows the gained XP amount during the tracker animation.",
                    getFunc = function() return self:GetExperienceTracker().showGainText end,
                    setFunc = function(value) self:SetExperienceTrackerValue("showGainText", value) end,
                    disabled = function() return not self:IsExperienceTrackerEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.experienceTracker.showGainText,
                },
                {
                    type = "dropdown",
                    name = "Visibility",
                    tooltip = "Chooses whether the tracker fades after XP gains or stays visible on the HUD.",
                    choices = { "Fade After Gains", "Always Visible" },
                    choicesValues = { "fade", "always" },
                    getFunc = function() return self:GetExperienceTracker().visibilityMode end,
                    setFunc = function(value) self:SetExperienceTrackerValue("visibilityMode", value) end,
                    disabled = function() return not self:IsExperienceTrackerEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.experienceTracker.visibilityMode,
                },
                {
                    type = "dropdown",
                    name = "Chunk Sound",
                    tooltip = "Chooses the sound played for each XP fill chunk.",
                    choices =
                    {
                        "None",
                        "Outfit Weapon Type Rune",
                        "Promotional Event Reward To Claim",
                        "Endless Dungeon Counter Down",
                    },
                    choicesValues =
                    {
                        "none",
                        "OUTFIT_WEAPON_TYPE_RUNE",
                        "PROMOTIONAL_EVENT_REWARD_TO_CLAIM_PROMPT",
                        "ENDLESS_DUNGEON_COUNTER_DOWN",
                    },
                    getFunc = function() return self:GetExperienceTracker().chunkSoundKey end,
                    setFunc = function(value) self:SetExperienceTrackerValue("chunkSoundKey", value) end,
                    disabled = function() return not self:IsExperienceTrackerEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.experienceTracker.chunkSoundKey,
                },
                {
                    type = "slider",
                    name = "Scale",
                    tooltip = "Controls the overall size of the experience tracker.",
                    min = 70,
                    max = 160,
                    step = 1,
                    getFunc = function() return self:GetExperienceTracker().scale end,
                    setFunc = function(value) self:SetExperienceTrackerValue("scale", value) end,
                    disabled = function() return not self:IsExperienceTrackerEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.experienceTracker.scale,
                },
                {
                    type = "slider",
                    name = "Opacity",
                    tooltip = "Controls the opacity of the tracker while visible.",
                    min = 20,
                    max = 100,
                    step = 1,
                    getFunc = function() return self:GetExperienceTracker().opacity end,
                    setFunc = function(value) self:SetExperienceTrackerValue("opacity", value) end,
                    disabled = function() return not self:IsExperienceTrackerEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.experienceTracker.opacity,
                },
                {
                    type = "slider",
                    name = "Width",
                    tooltip = "Controls the tracker bar width.",
                    min = 360,
                    max = 680,
                    step = 10,
                    getFunc = function() return self:GetExperienceTracker().width end,
                    setFunc = function(value) self:SetExperienceTrackerValue("width", value) end,
                    disabled = function() return not self:IsExperienceTrackerEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.experienceTracker.width,
                },
                {
                    type = "slider",
                    name = "Height",
                    tooltip = "Controls the tracker height.",
                    min = 54,
                    max = 76,
                    step = 1,
                    getFunc = function() return self:GetExperienceTracker().height end,
                    setFunc = function(value) self:SetExperienceTrackerValue("height", value) end,
                    disabled = function() return not self:IsExperienceTrackerEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.experienceTracker.height,
                },
                {
                    type = "slider",
                    name = "Visible Duration",
                    tooltip = "Milliseconds the tracker remains visible after a gain animation starts.",
                    min = 1800,
                    max = 7000,
                    step = 100,
                    getFunc = function() return self:GetExperienceTracker().durationMS end,
                    setFunc = function(value) self:SetExperienceTrackerValue("durationMS", value) end,
                    disabled = function() return not self:IsExperienceTrackerEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.experienceTracker.durationMS,
                },
                {
                    type = "slider",
                    name = "Feedback Intensity",
                    tooltip = "Controls glow, flash, and bulk-fill strength.",
                    min = 0,
                    max = 140,
                    step = 5,
                    getFunc = function() return self:GetExperienceTracker().intensity end,
                    setFunc = function(value) self:SetExperienceTrackerValue("intensity", value) end,
                    disabled = function() return not self:IsExperienceTrackerEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.experienceTracker.intensity,
                },
                {
                    type = "button",
                    name = "Preview",
                    tooltip = "Plays a sample experience gain animation.",
                    func = function() self:PreviewExperienceTracker() end,
                    disabled = function() return not self:IsExperienceTrackerEnabled() end,
                },
            },
        },
        {
            type = "submenu",
            name = "Resource Bars",
            tooltip = "Settings for the centered Nirnsteel player resource bars.",
            reference = "Nirnsteel_UI_ResourceBarsSubmenu",
            controls =
            {
                {
                    type = "checkbox",
                    name = "Enable Resource Bars Module",
                    tooltip = "Replaces the stock player health, magicka, and stamina bars with centered Nirnsteel bars.",
                    getFunc = function() return self:IsResourceBarsEnabled() end,
                    setFunc = function(value) self:SetResourceBarsEnabled(value) end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.enabled,
                },
                {
                    type = "checkbox",
                    name = "Unlock Resource Bars",
                    tooltip = "Shows a draggable handle for positioning resource bars. Position is saved per server.",
                    getFunc = function() return self:IsResourceBarsUnlocked() end,
                    setFunc = function(value) self:SetResourceBarsUnlocked(value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.unlocked,
                },
                {
                    type = "slider",
                    name = "Scale",
                    tooltip = "Controls the overall size of the Nirnsteel resource bars.",
                    min = 70,
                    max = 160,
                    step = 1,
                    getFunc = function() return self:GetResourceBars().scale end,
                    setFunc = function(value) self:SetResourceBarsValue("scale", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.scale,
                },
                {
                    type = "slider",
                    name = "Health Width",
                    tooltip = "Health bar width.",
                    min = 96,
                    max = 620,
                    step = 8,
                    getFunc = function() return self:GetResourceBars().rowHealthWidth end,
                    setFunc = function(value) self:SetResourceBarsValue("rowHealthWidth", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.rowHealthWidth,
                },
                {
                    type = "slider",
                    name = "Magicka Width",
                    tooltip = "Magicka bar width.",
                    min = 96,
                    max = 620,
                    step = 8,
                    getFunc = function() return self:GetResourceBars().rowMagickaWidth end,
                    setFunc = function(value) self:SetResourceBarsValue("rowMagickaWidth", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.rowMagickaWidth,
                },
                {
                    type = "slider",
                    name = "Stamina Width",
                    tooltip = "Stamina bar width.",
                    min = 96,
                    max = 620,
                    step = 8,
                    getFunc = function() return self:GetResourceBars().rowStaminaWidth end,
                    setFunc = function(value) self:SetResourceBarsValue("rowStaminaWidth", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.rowStaminaWidth,
                },
                {
                    type = "slider",
                    name = "Bar Height",
                    tooltip = "Shared height for all bars.",
                    min = 10,
                    max = 48,
                    step = 1,
                    getFunc = function() return self:GetResourceBars().barHeight end,
                    setFunc = function(value) self:SetResourceBarsValue("barHeight", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.barHeight,
                },
                {
                    type = "slider",
                    name = "Vertical Spacing",
                    tooltip = "Spacing between health and the lower resource bars.",
                    min = 0,
                    max = 32,
                    step = 1,
                    getFunc = function() return self:GetResourceBars().rowSpacing end,
                    setFunc = function(value) self:SetResourceBarsValue("rowSpacing", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.rowSpacing,
                },
                {
                    type = "slider",
                    name = "Horizontal Spacing",
                    tooltip = "Spacing between magicka and stamina.",
                    min = 0,
                    max = 32,
                    step = 1,
                    getFunc = function() return self:GetResourceBars().columnSpacing end,
                    setFunc = function(value) self:SetResourceBarsValue("columnSpacing", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.columnSpacing,
                },
                {
                    type = "slider",
                    name = "Bar Opacity",
                    tooltip = "Controls fill opacity for all resource bars.",
                    min = 10,
                    max = 100,
                    step = 1,
                    getFunc = function() return self:GetResourceBars().opacity end,
                    setFunc = function(value) self:SetResourceBarsValue("opacity", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.opacity,
                },
                {
                    type = "checkbox",
                    name = "Gloss Overlay",
                    tooltip = "Toggles the top gloss effect.",
                    getFunc = function() return self:GetResourceBars().glossEnabled end,
                    setFunc = function(value) self:SetResourceBarsValue("glossEnabled", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.glossEnabled,
                },
                {
                    type = "checkbox",
                    name = "Fill Pattern Overlay",
                    tooltip = "Adds a low-opacity texture over the colored fill. The resource color is preserved.",
                    getFunc = function() return self:GetResourceBars().barPatternEnabled end,
                    setFunc = function(value) self:SetResourceBarsValue("barPatternEnabled", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.barPatternEnabled,
                },
                {
                    type = "dropdown",
                    name = "Fill Pattern",
                    tooltip = "Pattern texture layered over the bar color.",
                    choices = { "Smoke", "Stillwater", "ZigZag", "Stone", "Dirt", "Lava", "RockLava", "LavaWave", "Molten" },
                    choicesValues = { "smoke", "stillwater" },
                    getFunc = function() return self:GetResourceBars().barPatternKey end,
                    setFunc = function(value) self:SetResourceBarsValue("barPatternKey", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() or not self:GetResourceBars().barPatternEnabled end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.barPatternKey,
                },
                {
                    type = "slider",
                    name = "Fill Pattern Opacity",
                    tooltip = "How strongly the pattern shows over the bar color.",
                    min = 0,
                    max = 60,
                    step = 1,
                    getFunc = function() return self:GetResourceBars().barPatternOpacity end,
                    setFunc = function(value) self:SetResourceBarsValue("barPatternOpacity", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() or not self:GetResourceBars().barPatternEnabled end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.barPatternOpacity,
                },
                {
                    type = "slider",
                    name = "Fill Pattern Scale",
                    tooltip = "Lower values repeat the pattern more often; higher values make it larger.",
                    min = 128,
                    max = 512,
                    step = 4,
                    getFunc = function() return self:GetResourceBars().barPatternScale end,
                    setFunc = function(value) self:SetResourceBarsValue("barPatternScale", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() or not self:GetResourceBars().barPatternEnabled end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.barPatternScale,
                },
                {
                    type = "header",
                    name = "Resource Feedback",
                },
                {
                    type = "checkbox",
                    name = "Resource Feedback",
                    tooltip = "Adds short gain, spend, full-resource, shield, and low-resource feedback effects.",
                    getFunc = function() return self:GetResourceBars().feedbackEnabled end,
                    setFunc = function(value) self:SetResourceBarsValue("feedbackEnabled", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.feedbackEnabled,
                },
                {
                    type = "slider",
                    name = "Feedback Intensity",
                    tooltip = "Controls the strength of resource feedback effects.",
                    min = 0,
                    max = 100,
                    step = 1,
                    getFunc = function() return self:GetResourceBars().feedbackIntensity end,
                    setFunc = function(value) self:SetResourceBarsValue("feedbackIntensity", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() or not self:GetResourceBars().feedbackEnabled end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.feedbackIntensity,
                },
                {
                    type = "checkbox",
                    name = "Gain Pulse",
                    tooltip = "Briefly brightens a bar after a meaningful resource gain.",
                    getFunc = function() return self:GetResourceBars().gainPulseEnabled end,
                    setFunc = function(value) self:SetResourceBarsValue("gainPulseEnabled", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() or not self:GetResourceBars().feedbackEnabled end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.gainPulseEnabled,
                },
                {
                    type = "checkbox",
                    name = "Spend Pulse",
                    tooltip = "Briefly brightens a bar after a meaningful resource spend or loss.",
                    getFunc = function() return self:GetResourceBars().spendPulseEnabled end,
                    setFunc = function(value) self:SetResourceBarsValue("spendPulseEnabled", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() or not self:GetResourceBars().feedbackEnabled end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.spendPulseEnabled,
                },
                {
                    type = "checkbox",
                    name = "Full Resource Pulse",
                    tooltip = "Briefly highlights a bar when it refills to full.",
                    getFunc = function() return self:GetResourceBars().fullResourcePulseEnabled end,
                    setFunc = function(value) self:SetResourceBarsValue("fullResourcePulseEnabled", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() or not self:GetResourceBars().feedbackEnabled end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.fullResourcePulseEnabled,
                },
                {
                    type = "checkbox",
                    name = "Shield Pulse",
                    tooltip = "Briefly highlights health when a damage shield increases.",
                    getFunc = function() return self:GetResourceBars().shieldPulseEnabled end,
                    setFunc = function(value) self:SetResourceBarsValue("shieldPulseEnabled", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() or not self:GetResourceBars().feedbackEnabled end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.shieldPulseEnabled,
                },
                {
                    type = "checkbox",
                    name = "Low Resource Glow",
                    tooltip = "Adds a static edge glow while a resource is low.",
                    getFunc = function() return self:GetResourceBars().lowResourceGlowEnabled end,
                    setFunc = function(value) self:SetResourceBarsValue("lowResourceGlowEnabled", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() or not self:GetResourceBars().feedbackEnabled end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.lowResourceGlowEnabled,
                },
                {
                    type = "header",
                    name = "Frame Styling",
                },
                {
                    type = "slider",
                    name = "Black Border Width",
                    tooltip = "Width of the black border around each resource bar.",
                    min = 0,
                    max = 8,
                    step = 1,
                    getFunc = function() return self:GetResourceBars().borderWidth end,
                    setFunc = function(value) self:SetResourceBarsValue("borderWidth", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.borderWidth,
                },
                {
                    type = "slider",
                    name = "Corner Rounding",
                    tooltip = "Corner size for the ESO backdrop border. Fill clipping is limited by ESO UI controls.",
                    min = 0,
                    max = 12,
                    step = 1,
                    getFunc = function() return self:GetResourceBars().cornerSize end,
                    setFunc = function(value) self:SetResourceBarsValue("cornerSize", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.cornerSize,
                },
                {
                    type = "slider",
                    name = "Inner Shadow",
                    tooltip = "Darkens the inside edge of each bar.",
                    min = 0,
                    max = 100,
                    step = 1,
                    getFunc = function() return self:GetResourceBars().innerShadowAlpha end,
                    setFunc = function(value) self:SetResourceBarsValue("innerShadowAlpha", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.innerShadowAlpha,
                },
                {
                    type = "slider",
                    name = "Outer Shadow",
                    tooltip = "Adds a dark shadow outside each bar.",
                    min = 0,
                    max = 100,
                    step = 1,
                    getFunc = function() return self:GetResourceBars().outerShadowAlpha end,
                    setFunc = function(value) self:SetResourceBarsValue("outerShadowAlpha", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.outerShadowAlpha,
                },
                {
                    type = "header",
                    name = "Text Personalization",
                },
                {
                    type = "dropdown",
                    name = "Text Font",
                    choices = { "Game Small", "Game Medium", "Antique", "Trajan", "Univers", "Chat" },
                    choicesValues = { "gameSmall", "gameMedium", "antique", "trajan", "univers", "chat" },
                    getFunc = function() return self:GetResourceBars().textFontKey end,
                    setFunc = function(value) self:SetResourceBarsValue("textFontKey", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.textFontKey,
                },
                {
                    type = "slider",
                    name = "Text Size",
                    min = 8,
                    max = 32,
                    step = 1,
                    getFunc = function() return self:GetResourceBars().textSize end,
                    setFunc = function(value) self:SetResourceBarsValue("textSize", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.textSize,
                },
                {
                    type = "dropdown",
                    name = "Text Outline",
                    choices = { "None", "Soft Thin", "Soft Thick", "Thick Outline" },
                    choicesValues = { "none", "soft-shadow-thin", "soft-shadow-thick", "thick-outline" },
                    getFunc = function() return self:GetResourceBars().textOutline end,
                    setFunc = function(value) self:SetResourceBarsValue("textOutline", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.textOutline,
                },
                {
                    type = "slider",
                    name = "Text Opacity",
                    min = 10,
                    max = 100,
                    step = 1,
                    getFunc = function() return self:GetResourceBars().textOpacity end,
                    setFunc = function(value) self:SetResourceBarsValue("textOpacity", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.textOpacity,
                },
                {
                    type = "colorpicker",
                    name = "Text Color",
                    getFunc = function()
                        local color = self:GetResourceBars().textColor
                        return color.r, color.g, color.b, 1
                    end,
                    setFunc = function(r, g, b)
                        local color = self:GetResourceBars().textColor
                        color.r = r
                        color.g = g
                        color.b = b
                        if Nirnsteel_UI.ResourceBars then
                            Nirnsteel_UI.ResourceBars:RefreshSettings()
                        end
                    end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = function()
                        local color = ACCOUNT_DEFAULTS.modules.resourceBars.textColor
                        return color.r, color.g, color.b, 1
                    end,
                },
                {
                    type = "slider",
                    name = "Text Side Inset",
                    tooltip = "Padding used by side-positioned text.",
                    min = 0,
                    max = 24,
                    step = 1,
                    getFunc = function() return self:GetResourceBars().textInset end,
                    setFunc = function(value) self:SetResourceBarsValue("textInset", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.textInset,
                },
                {
                    type = "slider",
                    name = "Text Vertical Offset",
                    tooltip = "Moves bar text up or down to compensate for font baseline differences.",
                    min = -8,
                    max = 8,
                    step = 1,
                    getFunc = function() return self:GetResourceBars().textVerticalOffset end,
                    setFunc = function(value) self:SetResourceBarsValue("textVerticalOffset", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.textVerticalOffset,
                },
                {
                    type = "dropdown",
                    name = "Health Text Format",
                    choices = { "Number", "Percent", "Number + Percent" },
                    choicesValues = { "number", "percent", "numberAndPercent" },
                    getFunc = function() return self:GetResourceBars().healthTextFormat end,
                    setFunc = function(value) self:SetResourceBarsValue("healthTextFormat", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.healthTextFormat,
                },
                {
                    type = "dropdown",
                    name = "Magicka Text Format",
                    choices = { "Number", "Percent", "Number + Percent" },
                    choicesValues = { "number", "percent", "numberAndPercent" },
                    getFunc = function() return self:GetResourceBars().magickaTextFormat end,
                    setFunc = function(value) self:SetResourceBarsValue("magickaTextFormat", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.magickaTextFormat,
                },
                {
                    type = "dropdown",
                    name = "Stamina Text Format",
                    choices = { "Number", "Percent", "Number + Percent" },
                    choicesValues = { "number", "percent", "numberAndPercent" },
                    getFunc = function() return self:GetResourceBars().staminaTextFormat end,
                    setFunc = function(value) self:SetResourceBarsValue("staminaTextFormat", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.staminaTextFormat,
                },
                {
                    type = "dropdown",
                    name = "Health Text Position",
                    choices = { "Center", "Sides" },
                    choicesValues = { "center", "sides" },
                    getFunc = function() return self:GetResourceBars().healthTextPosition end,
                    setFunc = function(value) self:SetResourceBarsValue("healthTextPosition", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.healthTextPosition,
                },
                {
                    type = "dropdown",
                    name = "Magicka Text Position",
                    choices = { "Center", "Sides" },
                    choicesValues = { "center", "sides" },
                    getFunc = function() return self:GetResourceBars().magickaTextPosition end,
                    setFunc = function(value) self:SetResourceBarsValue("magickaTextPosition", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.magickaTextPosition,
                },
                {
                    type = "dropdown",
                    name = "Stamina Text Position",
                    choices = { "Center", "Sides" },
                    choicesValues = { "center", "sides" },
                    getFunc = function() return self:GetResourceBars().staminaTextPosition end,
                    setFunc = function(value) self:SetResourceBarsValue("staminaTextPosition", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.staminaTextPosition,
                },
                {
                    type = "header",
                    name = "Shield",
                },
                {
                    type = "checkbox",
                    name = "Shield Overlay",
                    tooltip = "Shows shield amount as a blue overlay on health bar.",
                    getFunc = function() return self:GetResourceBars().shieldOverlayEnabled end,
                    setFunc = function(value) self:SetResourceBarsValue("shieldOverlayEnabled", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.shieldOverlayEnabled,
                },
                {
                    type = "slider",
                    name = "Shield Fill Opacity",
                    tooltip = "Opacity of the shield fill overlay.",
                    min = 0,
                    max = 100,
                    step = 1,
                    getFunc = function() return self:GetResourceBars().shieldFillOpacity end,
                    setFunc = function(value) self:SetResourceBarsValue("shieldFillOpacity", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() or not self:GetResourceBars().shieldOverlayEnabled end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.shieldFillOpacity,
                },
                {
                    type = "colorpicker",
                    name = "Shield Fill Color",
                    tooltip = "Color tint of the shield fill.",
                    getFunc = function()
                        local color = self:GetResourceBars().shieldFillColor
                        return color.r, color.g, color.b, 1
                    end,
                    setFunc = function(r, g, b)
                        local color = self:GetResourceBars().shieldFillColor
                        color.r = r
                        color.g = g
                        color.b = b
                        if Nirnsteel_UI.ResourceBars then
                            Nirnsteel_UI.ResourceBars:RefreshSettings()
                        end
                    end,
                    disabled = function() return not self:IsResourceBarsEnabled() or not self:GetResourceBars().shieldOverlayEnabled end,
                    default = function()
                        local color = ACCOUNT_DEFAULTS.modules.resourceBars.shieldFillColor
                        return color.r, color.g, color.b, 1
                    end,
                },
                {
                    type = "checkbox",
                    name = "Shield Glow",
                    tooltip = "Shows a gloss/glow layer over the shield fill.",
                    getFunc = function() return self:GetResourceBars().shieldGlowEnabled end,
                    setFunc = function(value) self:SetResourceBarsValue("shieldGlowEnabled", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() or not self:GetResourceBars().shieldOverlayEnabled end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.shieldGlowEnabled,
                },
                {
                    type = "slider",
                    name = "Shield Glow Opacity",
                    tooltip = "Opacity of the shield glow layer.",
                    min = 0,
                    max = 100,
                    step = 1,
                    getFunc = function() return self:GetResourceBars().shieldGlowOpacity end,
                    setFunc = function(value) self:SetResourceBarsValue("shieldGlowOpacity", value) end,
                    disabled = function()
                        return not self:IsResourceBarsEnabled()
                            or not self:GetResourceBars().shieldOverlayEnabled
                            or not self:GetResourceBars().shieldGlowEnabled
                    end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.shieldGlowOpacity,
                },
                {
                    type = "colorpicker",
                    name = "Shield Glow Color",
                    tooltip = "Color tint of the shield glow.",
                    getFunc = function()
                        local color = self:GetResourceBars().shieldGlowColor
                        return color.r, color.g, color.b, 1
                    end,
                    setFunc = function(r, g, b)
                        local color = self:GetResourceBars().shieldGlowColor
                        color.r = r
                        color.g = g
                        color.b = b
                        if Nirnsteel_UI.ResourceBars then
                            Nirnsteel_UI.ResourceBars:RefreshSettings()
                        end
                    end,
                    disabled = function()
                        return not self:IsResourceBarsEnabled()
                            or not self:GetResourceBars().shieldOverlayEnabled
                            or not self:GetResourceBars().shieldGlowEnabled
                    end,
                    default = function()
                        local color = ACCOUNT_DEFAULTS.modules.resourceBars.shieldGlowColor
                        return color.r, color.g, color.b, 1
                    end,
                },
                {
                    type = "dropdown",
                    name = "Shield Text Mode",
                    choices = { "Off", "Shield Only", "Health + Shield" },
                    choicesValues = { "off", "shieldOnly", "healthAndShield" },
                    getFunc = function() return self:GetResourceBars().shieldTextMode end,
                    setFunc = function(value) self:SetResourceBarsValue("shieldTextMode", value) end,
                    disabled = function() return not self:IsResourceBarsEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.shieldTextMode,
                },
            },
        },
    }

    LAM:RegisterAddonPanel(panelName, panelData)
    LAM:RegisterOptionControls(panelName, options)
    self:HookResourceBarsSubmenuPreview(panelName)
end

local function OnAddOnLoaded(_, addonName)
    if addonName ~= ADDON_NAME then
        return
    end

    EVENT_MANAGER:UnregisterForEvent(ADDON_NAME .. "_Settings", EVENT_ADD_ON_LOADED)
    Settings:Initialize()
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME .. "_Settings", EVENT_ADD_ON_LOADED, OnAddOnLoaded)

local ADDON_NAME = "Nirnsteel-UI"
local ADDON_DISPLAY_NAME = "NirnSteel UI"
local SAVED_VARS_VERSION = 1

Nirnsteel_UI = Nirnsteel_UI or {}

local Settings = {}
Nirnsteel_UI.Settings = Settings

local LAM_SLIDER_HANDLER_NAMESPACE = "LAM2_Slider"

local function ClearLamSliderMouseWheel(control)
    if not control then
        return
    end

    if control.slider then
        control.slider:SetHandler("OnMouseWheel", nil, LAM_SLIDER_HANDLER_NAMESPACE)
    end

    if control.slidervalue then
        control.slidervalue:SetHandler("OnFocusGained", nil, LAM_SLIDER_HANDLER_NAMESPACE)
        control.slidervalue:SetHandler("OnFocusLost", nil, LAM_SLIDER_HANDLER_NAMESPACE)
        control.slidervalue:SetHandler("OnMouseWheel", nil, LAM_SLIDER_HANDLER_NAMESPACE)
    end
end

local function DisableLamSliderMouseWheelSupport()
    if not LAMCreateControl or not LAMCreateControl.slider or LAMCreateControl.nirnsteelNoMouseWheelSliders then
        return
    end

    local originalSliderFactory = LAMCreateControl.slider
    LAMCreateControl.nirnsteelNoMouseWheelSliders = true

    LAMCreateControl.slider = function(parent, sliderData, controlName)
        if not sliderData or not sliderData.nirnsteelDisableMouseWheel then
            return originalSliderFactory(parent, sliderData, controlName)
        end

        local ok, control = xpcall(function()
            return originalSliderFactory(parent, sliderData, controlName)
        end, function(errorMessage)
            return errorMessage
        end)

        if not ok then
            error(control)
        end

        ClearLamSliderMouseWheel(control)
        return control
    end
end

local function MarkSliderOptionsNoMouseWheel(options)
    if not options then
        return
    end

    for _, option in ipairs(options) do
        if option.type == "slider" then
            option.nirnsteelDisableMouseWheel = true
        end

        if option.controls then
            MarkSliderOptionsNoMouseWheel(option.controls)
        end
    end
end

local CAMERA_PROFILE_DEFAULTS =
{
    horizontalLookSpeed = 0.85,
    verticalLookSpeed = 0.85,
    fieldOfView = 50,
    horizontalPosition = 1,
    horizontalOffset = 0,
    verticalOffset = 0,
}

local ADVENTURE_CAMERA_DISPLAY_SETTINGS =
{
    horizontalLookSpeed = { rawMin = 0.1, rawMax = 1.6, displayMin = 0, displayMax = 100 },
    verticalLookSpeed = { rawMin = 0.1, rawMax = 1.6, displayMin = 0, displayMax = 100 },
    fieldOfView = { rawMin = 35, rawMax = 65, displayMin = 70, displayMax = 130 },
    horizontalPosition = { rawMin = -1, rawMax = 1, displayMin = -100, displayMax = 100 },
    horizontalOffset = { rawMin = -1, rawMax = 1, displayMin = -100, displayMax = 100 },
    verticalOffset = { rawMin = -0.3, rawMax = 0.5, displayMin = -60, displayMax = 100 },
}

local ADVENTURE_CAMERA_SETTING_IDS =
{
    horizontalLookSpeed = CAMERA_SETTING_SENSITIVITY_THIRD_PERSON_X,
    verticalLookSpeed = CAMERA_SETTING_SENSITIVITY_THIRD_PERSON_Y,
    fieldOfView = CAMERA_SETTING_THIRD_PERSON_FIELD_OF_VIEW,
    horizontalPosition = CAMERA_SETTING_THIRD_PERSON_HORIZONTAL_POSITION_MULTIPLIER,
    horizontalOffset = CAMERA_SETTING_THIRD_PERSON_HORIZONTAL_OFFSET,
    verticalOffset = CAMERA_SETTING_THIRD_PERSON_VERTICAL_OFFSET,
}

local function ClampNumber(value, minValue, maxValue)
    value = tonumber(value) or minValue
    return math.min(math.max(value, minValue), maxValue)
end

local function RawCameraValueToDisplay(key, rawValue)
    local display = ADVENTURE_CAMERA_DISPLAY_SETTINGS[key]
    if not display then
        return rawValue
    end

    rawValue = ClampNumber(rawValue, display.rawMin, display.rawMax)
    local percent = (rawValue - display.rawMin) / (display.rawMax - display.rawMin)
    return zo_round(display.displayMin + ((display.displayMax - display.displayMin) * percent))
end

local function DisplayCameraValueToRaw(key, displayValue)
    local display = ADVENTURE_CAMERA_DISPLAY_SETTINGS[key]
    if not display then
        return displayValue
    end

    displayValue = ClampNumber(displayValue, display.displayMin, display.displayMax)
    local percent = (displayValue - display.displayMin) / (display.displayMax - display.displayMin)
    return display.rawMin + ((display.rawMax - display.rawMin) * percent)
end

local function CopyCameraProfile(profile)
    local copy = {}
    profile = profile or CAMERA_PROFILE_DEFAULTS

    for key, defaultValue in pairs(CAMERA_PROFILE_DEFAULTS) do
        copy[key] = tonumber(profile[key]) or defaultValue
    end

    return copy
end

local function ReadCurrentCameraProfile()
    local profile = {}

    for key, settingId in pairs(ADVENTURE_CAMERA_SETTING_IDS) do
        profile[key] = tonumber(GetSetting(SETTING_TYPE_CAMERA, settingId)) or CAMERA_PROFILE_DEFAULTS[key]
    end

    return profile
end

local SOUND_CHOICE_LABELS =
{
    TRIBUTE_AGENT_HEALED = "Soft Chime",
    STATS_RESPEC_CLEAR_ALL = "Clean Click",
    TRIBUTE_CARD_UNTARGETED = "Card Tap",
    VENGEANCE_PERK_DROP = "Reward Drop",
    CONSOLE_GAME_ENTER = "Deep Hit",
    RETURNING_PLAYER_OPEN_KEYBOARD = "Sharp Hit",
    VENGEANCE_PERK_EQUIPPED = "Heavy Clang",
    KEYBIND_BUTTON_DISABLED = "Muted Tick",
    PROMOTIONAL_EVENT_REWARD_TO_CLAIM_PROMPT = "Reward Ping",
    BATTLEGROUND_KILL_KILLING_BLOW = "Killing Blow",
    CODE_REDEMPTION_SUCCESS = "Victory Chime",
    BATTLEGROUND_LEAVE_MATCH = "Match Exit",
    BATTLEGROUND_ROUND_RECAP_SCREEN_END = "Round End",
    SKILLS_SUBCLASSING_TRAIN = "Skill Trained",
    none = "None",
    OUTFIT_WEAPON_TYPE_RUNE = "Rune Tick",
    ENDLESS_DUNGEON_COUNTER_DOWN = "Counter Tick",
    BATTLEGROUND_ROUND_RECAP_SCREEN_FINAL_WIN = "Major Victory",
    BATTLEGROUND_ROUND_RECAP_SCREEN_WIN = "Victory",
}

local SOUND_KEYS_BY_LABEL = {}
for key, label in pairs(SOUND_CHOICE_LABELS) do
    SOUND_KEYS_BY_LABEL[label] = key
end
SOUND_KEYS_BY_LABEL["Outfit Weapon Type Rune"] = "OUTFIT_WEAPON_TYPE_RUNE"
SOUND_KEYS_BY_LABEL["Promotional Event Reward To Claim"] = "PROMOTIONAL_EVENT_REWARD_TO_CLAIM_PROMPT"
SOUND_KEYS_BY_LABEL["Endless Dungeon Counter Down"] = "ENDLESS_DUNGEON_COUNTER_DOWN"
SOUND_KEYS_BY_LABEL["Battleground Round Recap Final Win"] = "BATTLEGROUND_ROUND_RECAP_SCREEN_FINAL_WIN"
SOUND_KEYS_BY_LABEL["Battleground Round Recap Win"] = "BATTLEGROUND_ROUND_RECAP_SCREEN_WIN"

local function GetSoundChoiceLabel(value)
    return SOUND_CHOICE_LABELS[value] or value
end

local function NormalizeSoundChoice(value)
    return SOUND_KEYS_BY_LABEL[value] or value
end

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
            textEffect = "shadow",
            critSoundKey = "RETURNING_PLAYER_OPEN_KEYBOARD",
            normalFontSize = 20,
            critFontSize = 55,
            durationMS = 850,
            spread = 170,
            drift = 15,
            bigHitThreshold = 40000,
            maxActive = 20,
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
        adventureCamera =
        {
            enabled = false,
            initialized = false,
            transitionMS = 150,
            actionProfile = CAMERA_PROFILE_DEFAULTS,
            adventureProfile = CAMERA_PROFILE_DEFAULTS,
        },
        castBar =
        {
            enabled = true,
            unlocked = false,
            scale = 100,
            width = 400,
            height = 20,
            opacity = 100,
            textMode = "nameAndTime",
            showIcon = true,
            animationIntensity = 85,
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
            levelUpSoundKey = "BATTLEGROUND_ROUND_RECAP_SCREEN_FINAL_WIN",
            showGainText = true,
            showProgressText = true,
            showChampionIcon = true,
            levelUpAnimationEnabled = true,
            levelUpIntensity = 100,
            hideBackground = false,
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
                castBar =
                {
                    x = 0,
                    y = -180,
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
        ["Still Water"] = "stillwater",
        ZigZag = "ZigZag",
        Zigzag = "ZigZag",
        Stone = "Stone",
        Dirt = "Dirt",
        Lava = "Lava",
        RockLava = "RockLava",
        ["Rock Lava"] = "RockLava",
        LavaWave = "LavaWave",
        ["Lava Wave"] = "LavaWave",
        Molten = "Molten",
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

local function UpgradeSoundChoiceLabels(account)
    local modules = account and account.modules
    if not modules then
        return
    end

    if modules.lootHistory then
        modules.lootHistory.regularSoundKey = NormalizeSoundChoice(modules.lootHistory.regularSoundKey)
            or ACCOUNT_DEFAULTS.modules.lootHistory.regularSoundKey
    end

    if modules.damageNumbers then
        modules.damageNumbers.critSoundKey = NormalizeSoundChoice(modules.damageNumbers.critSoundKey)
            or ACCOUNT_DEFAULTS.modules.damageNumbers.critSoundKey
    end

    if modules.killSound then
        modules.killSound.soundKey = NormalizeSoundChoice(modules.killSound.soundKey)
            or ACCOUNT_DEFAULTS.modules.killSound.soundKey
    end

    if modules.experienceTracker then
        modules.experienceTracker.chunkSoundKey = NormalizeSoundChoice(modules.experienceTracker.chunkSoundKey)
            or ACCOUNT_DEFAULTS.modules.experienceTracker.chunkSoundKey
        modules.experienceTracker.levelUpSoundKey = NormalizeSoundChoice(modules.experienceTracker.levelUpSoundKey)
            or ACCOUNT_DEFAULTS.modules.experienceTracker.levelUpSoundKey
    end
end

local function UpgradeCastBarDefaults(account)
    local castBar = account
        and account.modules
        and account.modules.castBar

    if not castBar then
        return
    end

    local textModeAliases =
    {
        ["Name + Time"] = "nameAndTime",
        ["Name Only"] = "nameOnly",
        ["Timer Only"] = "timerOnly",
        Off = "off",
    }

    castBar.textMode = textModeAliases[castBar.textMode] or castBar.textMode or ACCOUNT_DEFAULTS.modules.castBar.textMode
    if castBar.width == 320 or castBar.width == 380 then
        castBar.width = ACCOUNT_DEFAULTS.modules.castBar.width
    end
    if castBar.height == 28 or castBar.height == 34 then
        castBar.height = ACCOUNT_DEFAULTS.modules.castBar.height
    end
    if castBar.animationIntensity == 100 then
        castBar.animationIntensity = ACCOUNT_DEFAULTS.modules.castBar.animationIntensity
    end
end

function Settings:Initialize()
    self.account = ZO_SavedVars:NewAccountWide("NirnsteelUI_Account", SAVED_VARS_VERSION, nil, ACCOUNT_DEFAULTS)
    CopyDefaults(self.account, ACCOUNT_DEFAULTS)
    UpgradeDamageNumberDefaults(self.account)
    UpgradeExperienceTrackerDefaults(self.account)
    UpgradeResourceBarDefaults(self.account)
    UpgradeSoundChoiceLabels(self.account)
    UpgradeCastBarDefaults(self.account)
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

function Settings:GetAdventureCamera()
    return self.account.modules.adventureCamera
end

function Settings:GetCastBar()
    return self.account.modules.castBar
end

function Settings:GetCastBarPosition()
    return self.server.modules.castBar
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
    if key == "regularSoundKey" then
        value = NormalizeSoundChoice(value)
    end

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
    if key == "critSoundKey" then
        value = NormalizeSoundChoice(value)
    end

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
    if key == "soundKey" then
        value = NormalizeSoundChoice(value)
    end

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

function Settings:IsAdventureCameraEnabled()
    return self:GetAdventureCamera().enabled
end

function Settings:InitializeAdventureCameraProfilesIfNeeded()
    local settings = self:GetAdventureCamera()
    if settings.initialized then
        return
    end

    local currentProfile = ReadCurrentCameraProfile()
    settings.actionProfile = CopyCameraProfile(currentProfile)
    settings.adventureProfile = CopyCameraProfile(currentProfile)
    settings.initialized = true
end

function Settings:SetAdventureCameraEnabled(value)
    if value then
        self:InitializeAdventureCameraProfilesIfNeeded()
    end

    self:GetAdventureCamera().enabled = value
    if Nirnsteel_UI.AdventureCamera then
        Nirnsteel_UI.AdventureCamera:RefreshSettings()
    end
end

function Settings:SetAdventureCameraValue(key, value)
    self:GetAdventureCamera()[key] = value
    if Nirnsteel_UI.AdventureCamera then
        Nirnsteel_UI.AdventureCamera:RefreshSettings()
    end
end

function Settings:GetAdventureCameraDisplayValue(key)
    local settings = self:GetAdventureCamera()
    local profile = settings.adventureProfile or CAMERA_PROFILE_DEFAULTS
    return RawCameraValueToDisplay(key, profile[key] or CAMERA_PROFILE_DEFAULTS[key])
end

function Settings:SetAdventureCameraDisplayValue(key, value)
    local settings = self:GetAdventureCamera()
    settings.adventureProfile = settings.adventureProfile or CopyCameraProfile(CAMERA_PROFILE_DEFAULTS)
    settings.adventureProfile[key] = DisplayCameraValueToRaw(key, value)

    if Nirnsteel_UI.AdventureCamera then
        Nirnsteel_UI.AdventureCamera:RefreshSettings()
    end
end

function Settings:CaptureAdventureCameraActionProfile()
    local settings = self:GetAdventureCamera()
    local currentProfile = ReadCurrentCameraProfile()
    settings.actionProfile = CopyCameraProfile(currentProfile)
    if not settings.initialized then
        settings.adventureProfile = CopyCameraProfile(currentProfile)
    end
    settings.initialized = true

    if Nirnsteel_UI.AdventureCamera then
        Nirnsteel_UI.AdventureCamera:RefreshSettings()
    end
end

function Settings:IsCastBarEnabled()
    return self:GetCastBar().enabled
end

function Settings:IsCastBarUnlocked()
    return self:GetCastBar().unlocked
end

function Settings:SetCastBarEnabled(value)
    self:GetCastBar().enabled = value
    if Nirnsteel_UI.CastBar then
        Nirnsteel_UI.CastBar:RefreshSettings()
    end
end

function Settings:SetCastBarUnlocked(value)
    self:GetCastBar().unlocked = value
    if Nirnsteel_UI.CastBar then
        Nirnsteel_UI.CastBar:RefreshSettings()
    end
end

function Settings:SetCastBarValue(key, value)
    local textModeAliases =
    {
        ["Name + Time"] = "nameAndTime",
        ["Name Only"] = "nameOnly",
        ["Timer Only"] = "timerOnly",
        Off = "off",
    }

    if key == "textMode" then
        value = textModeAliases[value] or value
    end

    self:GetCastBar()[key] = value
    if Nirnsteel_UI.CastBar then
        Nirnsteel_UI.CastBar:RefreshSettings()
    end
end

function Settings:SetCastBarPosition(x, y)
    local position = self:GetCastBarPosition()
    position.x = x
    position.y = y
end

function Settings:PreviewCastBar()
    if Nirnsteel_UI.CastBar and Nirnsteel_UI.CastBar.Preview then
        Nirnsteel_UI.CastBar:Preview()
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
    if key == "chunkSoundKey" or key == "levelUpSoundKey" then
        value = NormalizeSoundChoice(value)
    end

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
        ["Still Water"] = "stillwater",
        ZigZag = "ZigZag",
        Zigzag = "ZigZag",
        Stone = "Stone",
        Dirt = "Dirt",
        Lava = "Lava",
        RockLava = "RockLava",
        ["Rock Lava"] = "RockLava",
        LavaWave = "LavaWave",
        ["Lava Wave"] = "LavaWave",
        Molten = "Molten",
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

    DisableLamSliderMouseWheelSupport()

    local panelName = "Nirnsteel_UI_Settings"
    local panelData =
    {
        type = "panel",
        name = ADDON_DISPLAY_NAME,
        displayName = ADDON_DISPLAY_NAME,
        author = "Wrynch",
        version = "1.0.0",
        registerForRefresh = true,
        registerForDefaults = true,
    }

    local options =
    {
        {
            type = "description",
            text = "Most settings apply to your whole account. When you unlock and move a HUD element, its position is saved for the server you are on.",
        },
        {
            type = "submenu",
            name = "Loot History",
            tooltip = "Customize the loot messages and sounds shown on the HUD.",
            controls =
            {
                {
                    type = "checkbox",
                    name = "Enable Loot History",
                    tooltip = "Shows Nirnsteel's loot history frame instead of the default one.",
                    getFunc = function() return self:IsLootHistoryEnabled() end,
                    setFunc = function(value) self:SetLootHistoryEnabled(value) end,
                    default = ACCOUNT_DEFAULTS.modules.lootHistory.enabled,
                },
                {
                    type = "checkbox",
                    name = "Unlock Loot Frame",
                    tooltip = "Shows a handle so you can drag the loot history frame. The position is saved for this server.",
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
                        "Soft Chime",
                        "Clean Click",
                        "Card Tap",
                        "Reward Drop",
                    },
                    getFunc = function() return GetSoundChoiceLabel(self:GetLootHistory().regularSoundKey) end,
                    setFunc = function(value)
                        self:SetLootHistoryValue("regularSoundKey", value)
                        self:PreviewLootHistoryRegularSound()
                    end,
                    disabled = function() return not self:IsLootHistoryEnabled() or not self:AreLootHistorySoundsEnabled() end,
                    default = GetSoundChoiceLabel(ACCOUNT_DEFAULTS.modules.lootHistory.regularSoundKey),
                },
                {
                    type = "checkbox",
                    name = "Hide Experience Gains",
                    tooltip = "Keeps XP gains out of the loot history feed.",
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
            tooltip = "Customize the combat numbers shown near the center of the screen.",
            controls =
            {
                {
                    type = "checkbox",
                    name = "Enable Damage Numbers",
                    tooltip = "Shows Nirnsteel combat damage numbers near the center of the screen.",
                    getFunc = function() return self:IsDamageNumbersEnabled() end,
                    setFunc = function(value) self:SetDamageNumbersEnabled(value) end,
                    default = ACCOUNT_DEFAULTS.modules.damageNumbers.enabled,
                },
                {
                    type = "checkbox",
                    name = "Unlock Damage Number Origin",
                    tooltip = "Shows a handle for the point where damage numbers appear. The position is saved for this server.",
                    getFunc = function() return self:IsDamageNumbersUnlocked() end,
                    setFunc = function(value) self:SetDamageNumbersUnlocked(value) end,
                    disabled = function() return not self:IsDamageNumbersEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.damageNumbers.unlocked,
                },
                {
                    type = "checkbox",
                    name = "Hide Default Damage Numbers",
                    tooltip = "Hides ESO's built-in damage numbers while Nirnsteel damage numbers are enabled.",
                    getFunc = function() return self:ShouldHideDefaultDamageNumbers() end,
                    setFunc = function(value) self:SetDamageNumbersHideDefault(value) end,
                    disabled = function() return not self:IsDamageNumbersEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.damageNumbers.hideDefaultDamage,
                },
                {
                    type = "checkbox",
                    name = "Critical Hit Sound",
                    tooltip = "Plays a short impact sound when you critically hit.",
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
                        "Deep Hit",
                        "Sharp Hit",
                        "Heavy Clang",
                        "Muted Tick",
                        "Reward Ping"
                    },
                    getFunc = function() return GetSoundChoiceLabel(self:GetDamageNumbers().critSoundKey) end,
                    setFunc = function(value)
                        self:SetDamageNumberValue("critSoundKey", value)
                        self:PreviewDamageNumberCritSound()
                    end,
                    disabled = function() return not self:IsDamageNumbersEnabled() or not self:AreDamageNumberCritSoundsEnabled() end,
                    default = GetSoundChoiceLabel(ACCOUNT_DEFAULTS.modules.damageNumbers.critSoundKey),
                },
                {
                    type = "slider",
                    name = "Normal Font Size",
                    tooltip = "Controls the font size for regular damage numbers.",
                    min = 12,
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
            tooltip = "Choose the sound played when you land the killing blow.",
            controls =
            {
                {
                    type = "description",
                    text = "Kill sounds use your ESO SFX/UI volume. ESO does not let addons set a separate volume for one sound.",
                },
                {
                    type = "checkbox",
                    name = "Enable Kill Sound",
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
                        "Killing Blow",
                        "Victory Chime",
                        "Match Exit",
                        "Round End",
                        "Skill Trained"
                    },
                    getFunc = function() return GetSoundChoiceLabel(self:GetKillSound().soundKey) end,
                    setFunc = function(value)
                        self:SetKillSoundValue("soundKey", value)
                        self:PreviewKillSound()
                    end,
                    disabled = function() return not self:IsKillSoundEnabled() end,
                    default = GetSoundChoiceLabel(ACCOUNT_DEFAULTS.modules.killSound.soundKey),
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
                    name = "Enable Action Bar Frames",
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
            name = "Adventure Camera",
            tooltip = "Applies a separate third-person camera profile out of combat and restores your action camera in combat.",
            controls =
            {
                {
                    type = "description",
                    text = "Adventure Camera keeps one camera setup for combat and another for exploration. When you first enable it, your current camera is copied into both setups so nothing jumps. Adjust the sliders below for exploration, then use the capture button whenever you want your current ESO camera to become the combat setup.",
                },
                {
                    type = "checkbox",
                    name = "Enable Adventure Camera",
                    tooltip = "Uses the Adventure Camera profile out of combat and the captured Action Camera profile in combat.",
                    getFunc = function() return self:IsAdventureCameraEnabled() end,
                    setFunc = function(value) self:SetAdventureCameraEnabled(value) end,
                    default = ACCOUNT_DEFAULTS.modules.adventureCamera.enabled,
                },
                {
                    type = "slider",
                    name = "Transition Duration",
                    tooltip = "Milliseconds used to transition between Adventure Camera and Action Camera.",
                    min = 0,
                    max = 3000,
                    step = 50,
                    getFunc = function() return self:GetAdventureCamera().transitionMS end,
                    setFunc = function(value) self:SetAdventureCameraValue("transitionMS", value) end,
                    disabled = function() return not self:IsAdventureCameraEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.adventureCamera.transitionMS,
                },
                {
                    type = "button",
                    name = "Capture Current as Action Camera",
                    tooltip = "Uses your current ESO third-person camera settings as the combat camera.",
                    func = function() self:CaptureAdventureCameraActionProfile() end,
                },
                {
                    type = "header",
                    name = "Adventure Camera",
                },
                {
                    type = "slider",
                    name = "Horizontal Look Speed",
                    min = 0,
                    max = 100,
                    step = 1,
                    getFunc = function() return self:GetAdventureCameraDisplayValue("horizontalLookSpeed") end,
                    setFunc = function(value) self:SetAdventureCameraDisplayValue("horizontalLookSpeed", value) end,
                    disabled = function() return not self:IsAdventureCameraEnabled() end,
                    default = RawCameraValueToDisplay("horizontalLookSpeed", ACCOUNT_DEFAULTS.modules.adventureCamera.adventureProfile.horizontalLookSpeed),
                },
                {
                    type = "slider",
                    name = "Vertical Look Speed",
                    min = 0,
                    max = 100,
                    step = 1,
                    getFunc = function() return self:GetAdventureCameraDisplayValue("verticalLookSpeed") end,
                    setFunc = function(value) self:SetAdventureCameraDisplayValue("verticalLookSpeed", value) end,
                    disabled = function() return not self:IsAdventureCameraEnabled() end,
                    default = RawCameraValueToDisplay("verticalLookSpeed", ACCOUNT_DEFAULTS.modules.adventureCamera.adventureProfile.verticalLookSpeed),
                },
                {
                    type = "slider",
                    name = "Field of View",
                    min = 70,
                    max = 130,
                    step = 1,
                    getFunc = function() return self:GetAdventureCameraDisplayValue("fieldOfView") end,
                    setFunc = function(value) self:SetAdventureCameraDisplayValue("fieldOfView", value) end,
                    disabled = function() return not self:IsAdventureCameraEnabled() end,
                    default = RawCameraValueToDisplay("fieldOfView", ACCOUNT_DEFAULTS.modules.adventureCamera.adventureProfile.fieldOfView),
                },
                {
                    type = "slider",
                    name = "Horizontal Position",
                    min = -100,
                    max = 100,
                    step = 1,
                    getFunc = function() return self:GetAdventureCameraDisplayValue("horizontalPosition") end,
                    setFunc = function(value) self:SetAdventureCameraDisplayValue("horizontalPosition", value) end,
                    disabled = function() return not self:IsAdventureCameraEnabled() end,
                    default = RawCameraValueToDisplay("horizontalPosition", ACCOUNT_DEFAULTS.modules.adventureCamera.adventureProfile.horizontalPosition),
                },
                {
                    type = "slider",
                    name = "Horizontal Offset",
                    min = -100,
                    max = 100,
                    step = 1,
                    getFunc = function() return self:GetAdventureCameraDisplayValue("horizontalOffset") end,
                    setFunc = function(value) self:SetAdventureCameraDisplayValue("horizontalOffset", value) end,
                    disabled = function() return not self:IsAdventureCameraEnabled() end,
                    default = RawCameraValueToDisplay("horizontalOffset", ACCOUNT_DEFAULTS.modules.adventureCamera.adventureProfile.horizontalOffset),
                },
                {
                    type = "slider",
                    name = "Vertical Offset",
                    min = -60,
                    max = 100,
                    step = 1,
                    getFunc = function() return self:GetAdventureCameraDisplayValue("verticalOffset") end,
                    setFunc = function(value) self:SetAdventureCameraDisplayValue("verticalOffset", value) end,
                    disabled = function() return not self:IsAdventureCameraEnabled() end,
                    default = RawCameraValueToDisplay("verticalOffset", ACCOUNT_DEFAULTS.modules.adventureCamera.adventureProfile.verticalOffset),
                },
            },
        },
        {
            type = "submenu",
            name = "Cast Bar",
            tooltip = "Customize the cast and channel progress bar.",
            controls =
            {
                {
                    type = "checkbox",
                    name = "Enable Cast Bar",
                    tooltip = "Shows a custom progress bar for non-instant slotted abilities with cast or channel time.",
                    getFunc = function() return self:IsCastBarEnabled() end,
                    setFunc = function(value) self:SetCastBarEnabled(value) end,
                    default = ACCOUNT_DEFAULTS.modules.castBar.enabled,
                },
                {
                    type = "checkbox",
                    name = "Unlock Cast Bar",
                    tooltip = "Shows a handle so you can drag the cast bar. The position is saved for this server.",
                    getFunc = function() return self:IsCastBarUnlocked() end,
                    setFunc = function(value) self:SetCastBarUnlocked(value) end,
                    disabled = function() return not self:IsCastBarEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.castBar.unlocked,
                },
                {
                    type = "checkbox",
                    name = "Show Ability Icon",
                    tooltip = "Shows the ability icon at the left edge of the cast bar.",
                    getFunc = function() return self:GetCastBar().showIcon end,
                    setFunc = function(value) self:SetCastBarValue("showIcon", value) end,
                    disabled = function() return not self:IsCastBarEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.castBar.showIcon,
                },
                {
                    type = "dropdown",
                    name = "Text Mode",
                    tooltip = "Chooses the text shown while casting.",
                    choices = { "Name + Time", "Name Only", "Timer Only", "Off" },
                    choicesValues = { "nameAndTime", "nameOnly", "timerOnly", "off" },
                    getFunc = function() return self:GetCastBar().textMode end,
                    setFunc = function(value) self:SetCastBarValue("textMode", value) end,
                    disabled = function() return not self:IsCastBarEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.castBar.textMode,
                },
                {
                    type = "slider",
                    name = "Scale",
                    tooltip = "Controls the overall size of the cast bar.",
                    min = 70,
                    max = 160,
                    step = 1,
                    getFunc = function() return self:GetCastBar().scale end,
                    setFunc = function(value) self:SetCastBarValue("scale", value) end,
                    disabled = function() return not self:IsCastBarEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.castBar.scale,
                },
                {
                    type = "slider",
                    name = "Width",
                    tooltip = "Controls the cast bar width.",
                    min = 220,
                    max = 620,
                    step = 10,
                    getFunc = function() return self:GetCastBar().width end,
                    setFunc = function(value) self:SetCastBarValue("width", value) end,
                    disabled = function() return not self:IsCastBarEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.castBar.width,
                },
                {
                    type = "slider",
                    name = "Height",
                    tooltip = "Controls the cast bar height.",
                    min = 18,
                    max = 48,
                    step = 1,
                    getFunc = function() return self:GetCastBar().height end,
                    setFunc = function(value) self:SetCastBarValue("height", value) end,
                    disabled = function() return not self:IsCastBarEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.castBar.height,
                },
                {
                    type = "slider",
                    name = "Opacity",
                    tooltip = "Controls cast bar opacity while visible.",
                    min = 20,
                    max = 100,
                    step = 1,
                    getFunc = function() return self:GetCastBar().opacity end,
                    setFunc = function(value) self:SetCastBarValue("opacity", value) end,
                    disabled = function() return not self:IsCastBarEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.castBar.opacity,
                },
                {
                    type = "slider",
                    name = "Animation Intensity",
                    tooltip = "Controls glow, start pulse, and completion flash strength.",
                    min = 0,
                    max = 160,
                    step = 5,
                    getFunc = function() return self:GetCastBar().animationIntensity end,
                    setFunc = function(value) self:SetCastBarValue("animationIntensity", value) end,
                    disabled = function() return not self:IsCastBarEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.castBar.animationIntensity,
                },
                {
                    type = "button",
                    name = "Preview",
                    tooltip = "Plays a sample cast bar animation.",
                    func = function() self:PreviewCastBar() end,
                    disabled = function() return not self:IsCastBarEnabled() end,
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
                    name = "Enable Compass Frame",
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
            tooltip = "Customize the HUD XP and Champion Point gain tracker.",
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
                    tooltip = "Shows a handle so you can drag the tracker. The position is saved for this server.",
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
                    type = "checkbox",
                    name = "Show Progress Text",
                    tooltip = "Shows the current XP progress amount and percentage.",
                    getFunc = function() return self:GetExperienceTracker().showProgressText end,
                    setFunc = function(value) self:SetExperienceTrackerValue("showProgressText", value) end,
                    disabled = function() return not self:IsExperienceTrackerEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.experienceTracker.showProgressText,
                },
                {
                    type = "checkbox",
                    name = "Show Champion Icon",
                    tooltip = "Shows the Champion discipline icon inside the tracker badge.",
                    getFunc = function() return self:GetExperienceTracker().showChampionIcon end,
                    setFunc = function(value) self:SetExperienceTrackerValue("showChampionIcon", value) end,
                    disabled = function() return not self:IsExperienceTrackerEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.experienceTracker.showChampionIcon,
                },
                {
                    type = "checkbox",
                    name = "Hide Background",
                    tooltip = "Hides the tracker panel background while keeping the badge and progress bar visible.",
                    getFunc = function() return self:GetExperienceTracker().hideBackground end,
                    setFunc = function(value) self:SetExperienceTrackerValue("hideBackground", value) end,
                    disabled = function() return not self:IsExperienceTrackerEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.experienceTracker.hideBackground,
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
                        "Rune Tick",
                        "Reward Ping",
                        "Counter Tick",
                    },
                    getFunc = function() return GetSoundChoiceLabel(self:GetExperienceTracker().chunkSoundKey) end,
                    setFunc = function(value)
                        self:SetExperienceTrackerValue("chunkSoundKey", value)
                        if Nirnsteel_UI.ExperienceTracker and Nirnsteel_UI.ExperienceTracker.PreviewChunkSound then
                            Nirnsteel_UI.ExperienceTracker:PreviewChunkSound()
                        end
                    end,
                    disabled = function() return not self:IsExperienceTrackerEnabled() end,
                    default = GetSoundChoiceLabel(ACCOUNT_DEFAULTS.modules.experienceTracker.chunkSoundKey),
                },
                {
                    type = "dropdown",
                    name = "Level Up Sound",
                    tooltip = "Chooses the sound played when the tracker reaches a new level or Champion Point.",
                    choices =
                    {
                        "None",
                        "Major Victory",
                        "Victory",
                    },
                    getFunc = function() return GetSoundChoiceLabel(self:GetExperienceTracker().levelUpSoundKey) end,
                    setFunc = function(value)
                        self:SetExperienceTrackerValue("levelUpSoundKey", value)
                        if Nirnsteel_UI.ExperienceTracker and Nirnsteel_UI.ExperienceTracker.PreviewLevelUpSound then
                            Nirnsteel_UI.ExperienceTracker:PreviewLevelUpSound()
                        end
                    end,
                    disabled = function() return not self:IsExperienceTrackerEnabled() end,
                    default = GetSoundChoiceLabel(ACCOUNT_DEFAULTS.modules.experienceTracker.levelUpSoundKey),
                },
                {
                    type = "checkbox",
                    name = "Enable Level Up Animation",
                    tooltip = "Plays the special burst animation when reaching a new level or Champion Point.",
                    getFunc = function() return self:GetExperienceTracker().levelUpAnimationEnabled end,
                    setFunc = function(value) self:SetExperienceTrackerValue("levelUpAnimationEnabled", value) end,
                    disabled = function() return not self:IsExperienceTrackerEnabled() end,
                    default = ACCOUNT_DEFAULTS.modules.experienceTracker.levelUpAnimationEnabled,
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
                    type = "slider",
                    name = "Level Up Animation Strength",
                    tooltip = "Controls the strength of the special level-up burst animation.",
                    min = 0,
                    max = 160,
                    step = 5,
                    getFunc = function() return self:GetExperienceTracker().levelUpIntensity end,
                    setFunc = function(value) self:SetExperienceTrackerValue("levelUpIntensity", value) end,
                    disabled = function()
                        return not self:IsExperienceTrackerEnabled()
                            or not self:GetExperienceTracker().levelUpAnimationEnabled
                    end,
                    default = ACCOUNT_DEFAULTS.modules.experienceTracker.levelUpIntensity,
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
            tooltip = "Customize the centered health, magicka, and stamina bars.",
            reference = "Nirnsteel_UI_ResourceBarsSubmenu",
            controls =
            {
                {
                    type = "checkbox",
                    name = "Enable Resource Bars",
                    tooltip = "Replaces the stock player health, magicka, and stamina bars with centered Nirnsteel bars.",
                    getFunc = function() return self:IsResourceBarsEnabled() end,
                    setFunc = function(value) self:SetResourceBarsEnabled(value) end,
                    default = ACCOUNT_DEFAULTS.modules.resourceBars.enabled,
                },
                {
                    type = "checkbox",
                    name = "Unlock Resource Bars",
                    tooltip = "Shows a handle so you can drag the resource bars. The position is saved for this server.",
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
                    tooltip = "Adds a light gloss along the top of each bar.",
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
                    choices = { "Smoke", "Still Water", "Zigzag", "Stone", "Dirt", "Lava", "Rock Lava", "Lava Wave", "Molten" },
                    choicesValues = { "smoke", "stillwater", "ZigZag", "Stone", "Dirt", "Lava", "RockLava", "LavaWave", "Molten" },
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
                    tooltip = "Rounds the resource bar frame corners. ESO may still draw the fill with square edges.",
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
                    name = "Text",
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
                    tooltip = "Moves side text inward from the bar edges.",
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
                    tooltip = "Moves bar text up or down.",
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

    MarkSliderOptionsNoMouseWheel(options)

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

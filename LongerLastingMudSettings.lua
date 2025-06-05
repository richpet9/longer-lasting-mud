-- This software is the intellectual property of Richard Petrosino (owner of
-- this LUA code) and GIANTS Software GmbH (owner of the software this code
-- modifies) as of June 2025.
--
-- This work may be reproduced and/or redstributed for non-commercial purposes
-- with the written consent of the author, Richard Petrosino. This work may
-- be reproduced and/or redstributed by GIANTS Software GmbH. for any purpose.
-- The author can be contacted at: https://github.com/richpet9
LongerLastingMudSettings = {}
LongerLastingMudSettings.SETTINGS_FILE_NAME = "longer_lasting_mud"
LongerLastingMudSettings.I18N_PREFIX = "rp_llm_"
LongerLastingMudSettings.SECTION_TITLE_ID = LongerLastingMudSettings.I18N_PREFIX .. "settings_section_title"
LongerLastingMudSettings.STREET_MULTIPLER_KEY = "streetMultiplier"

LongerLastingMudSettings.VALUE_DEFAULT = 5.0
LongerLastingMudSettings.VALUE_MIN = 0.5
LongerLastingMudSettings.VALUE_MAX = 10.0

LongerLastingMudSettings.CONTROL = {
    name = LongerLastingMudSettings.STREET_MULTIPLER_KEY,
    min = LongerLastingMudSettings.VALUE_MIN,
    max = LongerLastingMudSettings.VALUE_MAX,
    step = 0.5,
    autoBind = true,
}

LongerLastingMudSettings.settingsloadAttempted = false
LongerLastingMudSettings.isUiAdded = false

local LongerLastingMudSettings_mt = Class(LongerLastingMudSettings)
function LongerLastingMudSettings.new()
    self = setmetatable({}, LongerLastingMudSettings_mt)

    self.controls = {} -- Required by UIHelper. Stores the control props.
    self.settings = {}
    self.settings[LongerLastingMudSettings.STREET_MULTIPLER_KEY] = LongerLastingMudSettings.VALUE_DEFAULT
    self.settingsFromXml = {}

    return self
end

function LongerLastingMudSettings:getStreetMultipler()
    return self.settings[LongerLastingMudSettings.STREET_MULTIPLER_KEY] or LongerLastingMudSettings.VALUE_DEFAULT
end

function LongerLastingMudSettings:addSettingsUiToGame()
    if LongerLastingMudSettings.isUiAdded then
        return
    end

    local settingsPage = g_gui.screenControllers[InGameMenu].pageSettings

    UIHelper.createControlsDynamically(settingsPage, LongerLastingMudSettings.SECTION_TITLE_ID, self, {
        LongerLastingMudSettings.CONTROL,
    }, LongerLastingMudSettings.I18N_PREFIX)
    UIHelper.setupAutoBindControls(self, self.settings)

    LongerLastingMudSettings.isUiAdded = true

    if LongerLastingMud.__DEBUG__ then
        print("LongerLastingMud: Added settings UI to the game.")
    end
end

function LongerLastingMudSettings:loadSettingsFromXml()
    if LongerLastingMudSettings.settingsloadAttempted then
        return -- Don't re-attempt.
    end

    local xmlFilePath = LongerLastingMudSettings.getXmlFilePath()

    if xmlFilePath == nil then
        LongerLastingMudSettings.settingsloadAttempted = true
        return -- This is a new savegame, so there's no savegame dir.
    end

    if not fileExists(xmlFilePath) then
        LongerLastingMudSettings.settingsloadAttempted = true
        return -- The settings file doesn't exist yet.
    end

    local xmlFileId = loadXMLFile("LongerLastingMud", xmlFilePath)
    if xmlFileId == 0 then
        LongerLastingMudSettings.settingsloadAttempted = true
        Logging.warning("LongerLastingMudSettings: Failed reading from XML file")
        return -- The XML failed to parse.
    end

    local streetMultiplier = getXMLFloat(xmlFileId, "LongerLastingMud.streetMultiplier") or
                                 self.settings[LongerLastingMudSettings.STREET_MULTIPLER_KEY]

    if LongerLastingMud.__DEBUG__ then
        print(("LongerLastingMud: Loaded streetMultiplier from XML: %s"):format(streetMultiplier))
    end

    self.settings[LongerLastingMudSettings.STREET_MULTIPLER_KEY] =
        math.min(math.max(streetMultiplier, LongerLastingMudSettings.VALUE_MIN), LongerLastingMudSettings.VALUE_MAX)

    self.settingsFromXml = self:getSettingsCopy()
    LongerLastingMudSettings.settingsloadAttempted = true
end

function LongerLastingMudSettings:maybeSaveSettingsToXml()
    if self.settings[LongerLastingMudSettings.STREET_MULTIPLER_KEY] ~=
        self.settingsFromXml[LongerLastingMudSettings.STREET_MULTIPLER_KEY] then
        self:saveSettingsToXml()
    end
end

function LongerLastingMudSettings:saveSettingsToXml(settings)
    local xmlFilePath = LongerLastingMudSettings.getXmlFilePath()
    if xmlFilePath == nil then
        return -- This is a new savegame, so there's no savegame dir.
    end

    -- Create an empty XML file in memory.
    local xmlFileId = createXMLFile("LongerLastingMud", xmlFilePath, "LongerLastingMud")

    -- Add XML data in memory
    setXMLFloat(xmlFileId, "LongerLastingMud.streetMultiplier",
                self.settings[LongerLastingMudSettings.STREET_MULTIPLER_KEY] or -1)

    -- Write the XML file to disk.
    saveXMLFile(xmlFileId)

    -- Important: this ensures we don't keep re-writing the settings when the Menu closes.
    self.settingsFromXml = self:getSettingsCopy()

    if LongerLastingMud.__DEBUG__ then
        print(("LongerLastingMud: Changed settings saved to XML: %s"):format(xmlFilePath))
    end
end

function LongerLastingMudSettings:getSettingsCopy()
    local settings = {}
    settings[LongerLastingMudSettings.STREET_MULTIPLER_KEY] =
        self.settings[LongerLastingMudSettings.STREET_MULTIPLER_KEY]
    return settings
end

function LongerLastingMudSettings.getXmlFilePath()
    if g_currentMission.missionInfo then
        local savegameDirectory = g_currentMission.missionInfo.savegameDirectory
        if savegameDirectory ~= nil then
            return ("%s/%s.xml"):format(savegameDirectory, LongerLastingMudSettings.SETTINGS_FILE_NAME)
        end
    end
    return nil
end

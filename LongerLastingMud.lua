-- This software is the intellectual property of Richard Petrosino (owner of
-- this LUA code) and GIANTS Software GmbH (owner of the software this code
-- modifies) as of June 2025.
--
-- This work may be reproduced and/or redstributed for non-commercial purposes
-- with the written consent of the author, Richard Petrosino. This work may
-- be reproduced and/or redstributed by GIANTS Software GmbH. for any purpose.
-- The author can be contacted at: https://github.com/richpet9
LongerLastingMud = {}
LongerLastingMud.settings = LongerLastingMudSettings.new()
LongerLastingMud.__DEBUG__ = false

-- Executed for each wheel in the savegame during savegame load.
WheelPhysics.finalize = Utils.appendedFunction(WheelPhysics.finalize, function(self, ...)
    if self.streetDirtMultiplier ~= nil and self.streetDirtMultiplierDefault == nil then
        self.streetDirtMultiplierDefault = self.streetDirtMultiplier
        self.streetDirtMultiplierDivisor = LongerLastingMudSettings.VALUE_DEFAULT
        self:setNewStreetDirtMultiplier()
    end
end)

-- Executed once per tick for each wheel the player is near.
WheelPhysics.serverUpdate = Utils.appendedFunction(WheelPhysics.serverUpdate, function(self, ...)
    if self.streetDirtMultiplier ~= nil and self.streetDirtMultiplierDefault ~= nil then
        local newDivisor = LongerLastingMud.settings:getStreetMultipler()
        if self.streetDirtMultiplierDivisor ~= newDivisor then
            self.streetDirtMultiplierDivisor = newDivisor
            self:setNewStreetDirtMultiplier()
        end
    end
end)

-- Executed during savegame load after the map has finished loading.
BaseMission.loadMapFinished = Utils.prependedFunction(BaseMission.loadMapFinished, function(...)
    LongerLastingMud.settings:addSettingsUiToGame()
    LongerLastingMud.settings:loadSettingsFromXml()
end)

InGameMenu.onClose = Utils.appendedFunction(InGameMenu.onClose, function(...)
    LongerLastingMud.settings:maybeSaveSettingsToXml()
end)

-- Executed when saving the game.
ItemSystem.save = Utils.appendedFunction(ItemSystem.save, function(...)
    LongerLastingMud.settings:saveSettingsToXml()
end)

-- Helper function which sets the dirt multiplier based on user setting.
function WheelPhysics:setNewStreetDirtMultiplier()
    if self.streetDirtMultiplierDefault ~= nil then
        self.streetDirtMultiplier = self.streetDirtMultiplierDefault / self.streetDirtMultiplierDivisor
        if LongerLastingMud.__DEBUG__ then
            print(("LongerLastingMud: Set streetDirtMultiplier to %s (divisor=%s)"):format(self.streetDirtMultiplier,
                                                                                           self.streetDirtMultiplierDivisor))
        end
    end
end

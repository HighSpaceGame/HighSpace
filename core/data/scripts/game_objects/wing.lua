local Class          = require("class")
local GrCommon       = require('gr_common')
local Inspect        = require('inspect')
local ShipGroup      = require("ship_group")
local Utils          = require('utils')

local Wing = Class(ShipGroup)

local icon_map = {
    ["Terran"] = {
        ["Fighter"] = GrCommon.loadTexture("iconT-fightW", true),
        ["Bomber"] = GrCommon.loadTexture("iconT-bomberW", true),
    },
    ["Vasudan"] = {
        ["Fighter"] = GrCommon.loadTexture("iconv-fightW", true),
        ["Bomber"] = GrCommon.loadTexture("iconv-bomberW", true),
    },
    ["Shivan"] = {
        ["Fighter"] = GrCommon.loadTexture("icons-fighterW", true),
        ["Bomber"] = GrCommon.loadTexture("icons-bomberW", true),
    },
}

function Wing:init(properties)
    ba.println("Wing:init: " .. Inspect(properties.Name))

    self.Type = "Wing"
    self.Class = "Wing"
    self.Name = properties.Name
end

function Wing:copy()
    local result = Wing(self)

    self:forEach(function(ship)
        result:add(ship:copy())
    end)

    return result
end

function Wing:add(ship)
    ship.Parent = self
    self.Ships:add(ship)
    if not self._top_ship then
        self._top_ship = ship
    end
end

function Wing:getMapDisplayName()
    return self.Name .. " Wing"
end

function Wing:getIcon()
    return self._top_ship and icon_map[self._top_ship.Species][self._top_ship.Type] or icon_map["Terran"]
end

return Wing
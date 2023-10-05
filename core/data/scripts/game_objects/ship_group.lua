local Class          = require("class")
local GameObject     = require("game_object")
local Inspect        = require('inspect')
local ShipList       = require("ship_list")
local Utils          = require('utils')

local ShipGroup = Class(GameObject)

function ShipGroup:init(properties)
    self.Ships = ShipList()

    local list = Utils.Game.getMandatoryProperty(properties, 'Ships')
    list = list._list or list

    for _, ship in pairs(list) do
        local ship_clone = ship:copy()
        if ship_clone.Class then
            self._top_ship = ship_clone.Name
        end

        ship_clone.ParentList = self.Ships
        self.Ships:add(ship_clone)
        ba.println("ShipGroup:init(): " .. Inspect(self.Ships:get(ship.Name)))
    end

    self.Team = Utils.Game.getMandatoryProperty(properties, 'Team')
    self.Category = 'Ship'
end

function ShipGroup:getIcon()
    return self._top_ship and self:getTopShip():getIcon() or nil
end

function ShipGroup:copy()
    return ShipGroup(self)
end

function ShipGroup:getTopShip()
    if self._top_ship then
       return self.Ships:get(self._top_ship)
    end

    return nil
end

function ShipGroup:forEach(callback)
    self.Ships:forEach(callback)
end

function ShipGroup:getMapDisplayName()
    if self._top_ship then
        return self.Ships:get(self._top_ship):getMapDisplayName() .. ' Battle Group'
    end

    return 'Battle Group'
end

return ShipGroup
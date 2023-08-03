local Class          = require("class")
local GameObject     = require("game_object")
local Inspect        = require('inspect')
local ShipList       = require("ship_list")
local Utils          = require('utils')

local ShipGroup = Class(GameObject)

function ShipGroup:init(properties)
    self.Ships = ShipList()

    local list = Utils.Game.getMandatoryProperty(properties, 'Ships')
    list = list.List or list

    for _, ship in pairs(list) do
        ba.println("ShipGroup:init(): " .. Inspect(ship.Name))
        self.Ships:add(ship:clone())
        if ship.Class then
            self._top_ship = ship.Name
        end
    end

    self.Team = Utils.Game.getMandatoryProperty(properties, 'Team')
end

function ShipGroup:clone()
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
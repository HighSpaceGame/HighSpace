local Class          = require("class")
local Inspect        = require('inspect')
local Ship           = require("ship")
local ShipList       = require("ship_list")
local Utils          = require('utils')

local ShipGroup = Class(Ship)

function ShipGroup:init(properties)
    ba.println("ShipGroup:init: " .. Inspect(properties.Name))
    self.Ships = ShipList()

    self.Type = "Group"
    self.Class = "Group"

    local list = properties.Ships or {}
    list = list._list or list

    for _, ship in pairs(list) do
        self:add(ship)
    end
end

function ShipGroup:getIcon()
    return self._top_ship and self:getTopShip():getIcon() or nil
end

function ShipGroup:copy()
    local result = ShipGroup(self)

    self:forEach(function(ship)
        result:add(ship:copy())
    end)

    return result
end

function ShipGroup:getTopShip()
    return self._top_ship
end

function ShipGroup:forEach(callback)
    self.Ships:forEach(callback)
end

--TODO: move to somewhere global
local type_hierarchy = {
    ["Wing"] = 1,
    ["Cruiser"] = 2,
    ["Corvette"] = 3,
}

function ShipGroup:add(ship)
    ship.Parent = self
    self.Ships:add(ship)
    if not self._top_ship or ((type_hierarchy[ship.Type] or 0) > (type_hierarchy[self._top_ship.Type] or 0)) then
        self._top_ship = ship
        self.Name = self:getMapDisplayName()
    end
end

function ShipGroup:split(ship_list)
    local split_ships
    if not ship_list or ship_list:count() == 0 then
        return nil
    elseif ship_list:count() > 1 then
        split_ships = ShipGroup()
        ship_list:forEach(function(ship)
            split_ships:add(ship)
            self:remove(ship.Name)
        end)
    else
        require("mobdebug").start()
        _, split_ships = next(ship_list._list)
        self:remove(split_ships)
    end

    self.Parent:add(split_ships)
    split_ships.System.Position = self.System.Position:copy()
    split_ships:recalculateOrbit()

    if self.Ships:count() == 1 then
        local leftover = next(self.Ships._list)

        self.Parent:add(leftover)
        leftover.System.Position = self.SelectedShip.System.Position:copy()
        leftover:recalculateOrbit()
        self:remove(leftover)
        self.Parent:remove(self)
    end

    return split_ships
end

function ShipGroup:join(ships)
    ship.Parent = self
    self.Ships:add(ship)
    if not self._top_ship or ((type_hierarchy[ship.Type] or 0) > (type_hierarchy[self._top_ship.Type] or 0)) then
        self._top_ship = ship
        self.Name = self:getMapDisplayName()
    end
end

function ShipGroup:remove(ship)
    self.Ships:remove(ship)
    if self._top_ship == ship then
        self._top_ship = next(self.Ships._list)
    end
end

function ShipGroup:getMapDisplayName()
    if self._top_ship then
        return self._top_ship:getMapDisplayName() .. ' Battle Group'
    end

    return 'Battle Group'
end

return ShipGroup
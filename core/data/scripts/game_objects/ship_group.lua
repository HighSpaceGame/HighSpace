local Class          = require("class")
local Inspect        = require('inspect')
local Ship           = require("ship")
local ShipList       = require("ship_list")
local Utils          = require('utils')

--- @class ShipGroup
local ShipGroup = Class(Ship)

local group_no = 1

function ShipGroup:init(properties)
    ba.println("ShipGroup:init: " .. Inspect(properties.Name))
    self.Ships = ShipList()

    self.Type = "Group"
    self.Class = "Group"
    self.Name =  "Group " .. group_no
    group_no = group_no + 1

    local list = properties.Type == "Group" and properties.Ships or {}
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

    result.Ships:clear()
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

function ShipGroup:add(ship)
    local scoreShip = ship
    if ship.Type == "Group" then
        scoreShip = ship._top_ship
        ship:forEach(function(sub_ship)
            sub_ship.Parent:remove(sub_ship)
            self:add(sub_ship)
        end)
    else
        ship.Parent = self
        self.Ships:add(ship)
    end

    if not self._top_ship or (Utils.Game.getShipScore(scoreShip) > Utils.Game.getShipScore(self._top_ship)) then
        self._top_ship = ship
    end
end

function ShipGroup:remove(ship)
    self.Ships:remove(ship)
    if self._top_ship == ship then
        _, self._top_ship = next(self.Ships._list)
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
        _, split_ships = next(ship_list._list)
        self:remove(split_ships)
    end

    GameState.System:add(split_ships, self.Parent)
    split_ships.System.Position = self.System.Position:copy()
    split_ships:recalculateOrbit()
    AIController:onShipGroupSplit(self, split_ships)

    if self.Ships:count() == 1 then
        local _, leftover = next(self.Ships._list)
        GameState.System:add(leftover, self.Parent)
        leftover.System.Position = self.System.Position:copy()
        leftover:recalculateOrbit()
        self:remove(leftover)
        AIController:onShipGroupSplit(self, leftover)
        GameState.System:remove(self)
    end

    return split_ships
end

function ShipGroup.join(ship1, ship2)
    local result
    local parent = ship1.Parent

    GameState.System:remove(ship1)
    GameState.System:remove(ship2)

    if ship1.Type == "Group" then
        result = ship1
        result:add(ship2)
    elseif ship2.Type == "Group" then
        result = ship2
        result:add(ship1)
    else
        result = ShipGroup(ship1)
        result:add(ship1)
        result:add(ship2)
    end

    global_debug = 1
    GameState.System:add(result, parent)
    result:recalculateOrbit()
    AIController:onShipGroupMerge(ship1, ship2, result)

    return result
end

function ShipGroup:getMapDisplayName()
    if self._top_ship then
        return self._top_ship:getMapDisplayName() .. ' Battle Group'
    end

    return 'Battle Group'
end

return ShipGroup
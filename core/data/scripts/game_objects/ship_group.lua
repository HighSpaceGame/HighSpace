local Class          = require("class")
local Inspect        = require('inspect')
local Satellite      = require('satellite')
local ShipList       = require("ship_list")
local Utils          = require('utils')

local ShipGroup = Class(Satellite)

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
    end

    self.Team = Utils.Game.getMandatoryProperty(properties, 'Team')
    self.Category = 'Ship'

    if properties.System then
        self.System = self.System or {}

        self.System.Destination = nil
        self.System.Speed = Utils.Game.getMandatoryProperty(properties.System, 'Speed')
        self.System.SubspaceSpeed = Utils.Game.getMandatoryProperty(properties.System, 'SubspaceSpeed')
        self.System.UpdateTime = 0
    end
end

function ShipGroup:getIcon()
    return self._top_ship and self:getTopShip():getIcon() or nil
end

function ShipGroup:copy()
    return ShipGroup(self)
end

function ShipGroup:update()
    if self.System.Destination then
        local movement = (self.System.Destination - self.System.Position):normalize()
        movement = movement * (GameState.CurrentTime - self.System.UpdateTime) * self.System.Speed
        if movement:getSqrMagnitude() > (self.System.Destination - self.System.Position):getSqrMagnitude() then
            movement = self.System.Destination - self.System.Position
            self.System.Destination = nil
        end

        self.System.Position = self.System.Position + movement
    else
        self._base.update(self)
    end

    local nearest = GameSystemMap.ObjectKDTree:findNearest(self.System.Position, self.SemiMajorAxis,
            function(objects) return objects[1] and objects[1].Category == 'Astral' end
    )
    self.Parent = nearest and nearest[1] or self.Parent
    self:recalculateOrbit()
    self:recalculateOrbitParent()
    self.System.UpdateTime = GameState.CurrentTime
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
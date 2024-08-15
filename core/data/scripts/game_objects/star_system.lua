local Class          = require("class")
local GameObject     = require("game_object")
local GO_CATS        = require("enums").GameObject.Categories
local Inspect        = require('inspect')
local Satellite      = require('satellite')
local ShipGroup       = require("ship_group")
local Utils          = require('utils')
local Vector         = require('vector')

local StarSystem = Class(GameObject)

function StarSystem:init(properties, parent)
    self.Stars = {}
    self._star_map = {[GO_CATS.ALL] = {}, [GO_CATS.GROUPED] = {}}
    self._counts = {[GO_CATS.ALL] = 0, [GO_CATS.GROUPED] = 0}

    if properties.Stars then
        for _, star in pairs(properties.Stars) do
            table.insert(self.Stars, Satellite(star, nil, self))
        end
    end
end

function StarSystem:get(name, category)
    category = category or GO_CATS.ALL

    local result = self._star_map[category][name]

    if not result then
        result = self._star_map[GO_CATS.GROUPED][name]
    end

    return result
end

function StarSystem:count(category)
    category = category or GO_CATS.ALL

    return self._counts[category] or 0
end

function StarSystem:_add_to_category(satellite, category)
    self._star_map[category] = self._star_map[category] or {}
    self._star_map[category][satellite.Name] = satellite
    self._counts[category] = (self._counts[category] or 0) + 1
end

function StarSystem:_add_to_grouped(satellite)
    if satellite:is_a(ShipGroup) then
        satellite:forEach(function(group_ship)
            self:_add_to_category(group_ship, GO_CATS.GROUPED)
            self:_add_to_grouped(group_ship)
        end)
    end
end

function StarSystem:_remove_from_category(satellite, category)
    local star_map_sat = self._star_map[category][satellite.Name]
    if star_map_sat then
        self._star_map[category][satellite.Name] = nil
        self._counts[category] = (self._counts[category] or 1) - 1
    end
end

function StarSystem:add(satellite, parent)
    self:_add_to_category(satellite, satellite.Category)
    self:_add_to_category(satellite, GO_CATS.ALL)

    if parent then
        parent:add(satellite)
    end

    self:_add_to_grouped(satellite)
end

function StarSystem:remove(satellite)
    satellite.StarSystem = nil

    if satellite.Parent then
        satellite.Parent:remove(satellite)
        if satellite.Parent and satellite.Parent:is_a(ShipGroup) and satellite.Parent.Ships:count() <= 0 then
            self:remove(satellite.Parent)
        end
    end

    self:_remove_from_category(satellite, satellite.Category)
    self:_remove_from_category(satellite, GO_CATS.ALL)
    self:_remove_from_category(satellite, GO_CATS.GROUPED)
end

function StarSystem:forEach(callback, category)
    category = category or GO_CATS.ALL

    for _, object in pairs(self._star_map[category]) do
        local ret = callback(object)

        if ret ~= nil and ret == false then
            break
        end
    end
end

function StarSystem:update()
    for _, star in pairs(self.Stars) do
        star:update()
    end
end

function StarSystem:copy()
    return StarSystem(self)
end

return StarSystem
local Class          = require("class")
local GameObject     = require("game_object")
local Inspect        = require('inspect')
local Satellite      = require('satellite')
local Utils          = require('utils')
local Vector         = require('vector')

local StarSystem = Class(GameObject)

function StarSystem:init(properties, parent)
    self.Stars = {}
    self._star_map = {["All"] = {}}
    self._counts = {["All"] = 0}

    if properties.Stars then
        for _, star in pairs(properties.Stars) do
            table.insert(self.Stars, Satellite(star, nil, self))
        end
    end
end

function StarSystem:get(name, category)
    category = category or 'All'

    return self._star_map[category][name]
end

function StarSystem:count(category)
    category = category or 'All'

    return self._counts[category] or 0
end

function StarSystem:add(satellite)
    self._star_map[satellite.Category] = self._star_map[satellite.Category] or {}
    self._star_map[satellite.Category][satellite.Name] = satellite
    self._star_map["All"][satellite.Name] = satellite

    self._counts[satellite.Category] = (self._counts[satellite.Category] or 0) + 1
    self._counts["All"] = self._counts["All"] + 1
end

function StarSystem:remove(satellite)
    satellite.StarSystem = nil
    self._star_map[satellite.Category][satellite.Name] = nil
    self._star_map["All"][satellite.Name] = nil

    self._counts[satellite.Category] = (self._counts[satellite.Category] or 1) - 1
    self._counts["All"] = self._counts["All"] - 1
end

function StarSystem:forEach(callback, category)
    category = category or "All"

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
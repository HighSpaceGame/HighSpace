local Class          = require("class")
local GameObject     = require("game_object")
local Inspect        = require('inspect')
local Satellite      = require('satellite')
local Utils          = require('utils')
local Vector         = require('vector')

local StarSystem = Class(GameObject)

function StarSystem:init(properties, parent)
    self.Stars = {}

    if properties.Stars then
        for _, star in pairs(properties.Stars) do
            table.insert(self.Stars, Satellite(star))
        end
    end
end

function StarSystem:update()
    for _, star in pairs(self.Stars) do
        star:update()
    end
end

function StarSystem:copy()
    return Satellite(self)
end

return StarSystem
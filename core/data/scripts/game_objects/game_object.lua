local Class     = require("class")
local Inspect   = require('inspect')
local Utils     = require('utils')

local GameObject = Class()

function GameObject:init(properties)
    ba.println("GameObject:init")

    self.Mission = {}
    self.System = {
        ['IsSelected'] = false,
        ['Position'] = ba.createVector(0,0,0),
    }

    if properties.System then
        self.System.IsSelected = properties.System.IsSelected or self.System.IsSelected
        self.System.Position = properties.System.Position or self.System.Position
    end
end

return GameObject
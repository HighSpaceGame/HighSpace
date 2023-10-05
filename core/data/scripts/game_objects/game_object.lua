local Class     = require("class")
local Inspect   = require('inspect')
local Utils     = require('utils')
local Vector     = require('vector')

local GameObject = Class()

local unknown_icon = gr.loadTexture('iconunknown', true)

function GameObject:init(properties)
    self.Name = Utils.Game.getMandatoryProperty(properties, 'Name')
    ba.println("GameObject:init: " .. self.Name)

    self.Category = 'GameObject'
    self.Mission = {}
    self.System = {
        ['IsSelected'] = false,
        ['Position'] = Vector(0,0,0),
    }

    if properties.System then
        self.System.IsSelected = properties.System.IsSelected or self.System.IsSelected
        self.System.Position = properties.System.Position:copy() or self.System.Position
    end
end

function GameObject:getIcon()
    return unknown_icon
end

function GameObject:copy()
    return GameObject(self)
end

function GameObject:getMapDisplayName()
    return self.Name
end

return GameObject
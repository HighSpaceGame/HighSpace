local Class          = require("class")
local GameObject     = require("game_object")
local Inspect        = require('inspect')
local Utils          = require('utils')
local Vector         = require('vector')

local Satellite = Class(GameObject)

function Satellite:init(properties, parent)
    self.SemiMajorAxis = Utils.Game.getMandatoryProperty(properties, 'SemiMajorAxis')
    self.MeanAnomalyEpoch = Utils.Game.getMandatoryProperty(properties, 'MeanAnomalyEpoch')
    self.Epoch = Utils.Game.getMandatoryProperty(properties, 'Epoch')
    self.Radius = Utils.Game.getMandatoryProperty(properties, 'Radius')
    self.Mass = Utils.Game.getMandatoryProperty(properties, 'Mass')
    self.Icon = Utils.Game.getMandatoryProperty(properties, 'Icon')
    self.Icon = gr.loadTexture(self.Icon, true)

    self.Parent = parent
    self.Satellites = {}

    if properties.Satellites then
        for _, satellite in pairs(properties.Satellites) do
            table.insert(self.Satellites, Satellite(satellite, self))
        end
    end
end

function Satellite:update()
    self.System.Position = Vector(1, 0)
    self.System.Position = self.System.Position * self.SemiMajorAxis * Utils.Math.AU
    self.System.Position:rotate(0, math.rad(self.MeanAnomalyEpoch), 0)

    if self.Parent then
        self.System.Position = self.System.Position + self.Parent.System.Position
    end

    for _, sat in pairs(self.Satellites) do
        sat:update()
    end
end

function Satellite:copy()
    return Satellite(self)
end

return Satellite
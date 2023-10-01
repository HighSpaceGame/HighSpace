local Class          = require("class")
local GameObject     = require("game_object")
local GrCommon       = require("gr_common")
local Inspect        = require('inspect')
local Utils          = require('utils')
local Vector         = require('vector')

local Satellite = Class(GameObject)

function Satellite:init(properties, parent)
    self.SemiMajorAxis = Utils.Game.getMandatoryProperty(properties, 'SemiMajorAxis')
    self.MeanAnomalyEpoch = math.rad(Utils.Game.getMandatoryProperty(properties, 'MeanAnomalyEpoch'))
    self.MeanAnomaly = 0
    self.OrbitalPeriod = Utils.Game.getMandatoryProperty(properties, 'OrbitalPeriod') * 86400
    self.Epoch = Utils.DateTime.parse(Utils.Game.getMandatoryProperty(properties, 'Epoch'))
    self.Radius = Utils.Game.getMandatoryProperty(properties, 'Radius')
    self.Mass = Utils.Game.getMandatoryProperty(properties, 'Mass')
    self.Icon = Utils.Game.getMandatoryProperty(properties, 'Icon')
    self.Icon = GrCommon.loadTexture(self.Icon, true)

    self.Parent = parent
    self.Satellites = {}

    if properties.Satellites then
        for _, satellite in pairs(properties.Satellites) do
            table.insert(self.Satellites, Satellite(satellite, self))
        end
    end
end

function Satellite:_updateMeanAnomaly()
    if self.OrbitalPeriod <= 0 then
        self.MeanAnomaly = 0
        return
    end

    self.MeanAnomaly = self.MeanAnomalyEpoch + Utils.Math.PITwo * ((GameSystemMap.CurrentTime - self.Epoch) % self.OrbitalPeriod) / self.OrbitalPeriod;
    if self.MeanAnomaly > Utils.Math.PITwo then
        self.MeanAnomaly = self.MeanAnomaly - Utils.Math.PITwo
    elseif self.MeanAnomaly < 0 then
        self.MeanAnomaly = self.MeanAnomaly + Utils.Math.PITwo
    end
end

function Satellite:getIcon()
    return self.Icon
end

function Satellite:update()
    self:_updateMeanAnomaly()
    self.System.Position = Vector(1, 0)
    self.System.Position = self.System.Position * self.SemiMajorAxis * Utils.Math.AU
    self.System.Position:rotate(0, self.MeanAnomaly, 0)

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
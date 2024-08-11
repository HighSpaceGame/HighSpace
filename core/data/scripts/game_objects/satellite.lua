local Class          = require("class")
local GameObject     = require("game_object")
local GrCommon       = require("gr_common")
local Inspect        = require('inspect')
local Utils          = require('utils')
local Vector         = require('vector')

local Satellite = Class(GameObject)

function Satellite:init(properties, parent, star_system)
    ba.println("Satellite:init: " .. properties.Name)
    self.SemiMajorAxis = Utils.Game.getMandatoryProperty(properties, 'SemiMajorAxis')
    self.MeanAnomalyEpoch = math.rad(Utils.Game.getMandatoryProperty(properties, 'MeanAnomalyEpoch'))
    self.MeanAnomaly = 0
    self.OrbitalPeriod = Utils.Game.getMandatoryProperty(properties, 'OrbitalPeriod')
    self.Radius = Utils.Game.getMandatoryProperty(properties, 'Radius')
    self.Mass = Utils.Game.getMandatoryProperty(properties, 'Mass')
    self.Category = 'Astral'

    self.Epoch = Utils.Game.getMandatoryProperty(properties, 'Epoch')
    -- If epoch is provided in string, we assume we're reading from a file, where units are in a more human-readable format
    if type(self.Epoch) == 'string' then
        self.Epoch = Utils.DateTime.parse(self.Epoch)
        self.OrbitalPeriod = self.OrbitalPeriod * 86400 -- Days to seconds
        self.SemiMajorAxis = self.SemiMajorAxis * Utils.Math.AU -- Astronomical Units to meters
    end

    if properties.Icon then
        self.Icon = GrCommon.loadTexture(properties.Icon, true)
    end

    self.Parent = parent
    self.Satellites = {}

    if star_system then
        self.StarSystem = star_system
        self.StarSystem:add(self)
    end

    if properties.Satellites then
        for _, satellite in pairs(properties.Satellites) do
            self.Satellites[satellite.Name] = Satellite(satellite, self, self.StarSystem)
        end
    end
end

function Satellite:_updateMeanAnomaly()
    if not self.OrbitalPeriod or self.OrbitalPeriod <= 0 then
        self.MeanAnomaly = 0
        return
    end

    self.MeanAnomaly = self.MeanAnomalyEpoch + Utils.Math.PITwo * ((GameState.CurrentTime - self.Epoch) % self.OrbitalPeriod) / self.OrbitalPeriod;
    if self.MeanAnomaly > Utils.Math.PITwo then
        self.MeanAnomaly = self.MeanAnomaly - Utils.Math.PITwo
    elseif self.MeanAnomaly < 0 then
        self.MeanAnomaly = self.MeanAnomaly + Utils.Math.PITwo
    end
end

function Satellite:recalculateOrbitParent()
    if self.Parent and self.Parent.Parent then
        if Utils.Math.hasEscapedFromOrbit(self.SemiMajorAxis, self.Parent.SemiMajorAxis, self.Parent.Mass, self.Parent.Parent.Mass) then
            local prevParent = self.Parent
            local newParent = self.Parent.Parent
            prevParent:remove(self)
            newParent:add(self)
            self:recalculateOrbit()
            self:recalculateOrbitParent()
        end
    end
end

function Satellite:recalculateOrbit()
    if not self.Parent or self.Parent.Mass <= 0.0 then
        return
    end

    local rel_position = self.System.Position - self.Parent.System.Position
    self.SemiMajorAxis = rel_position:getMagnitude()
    rel_position = rel_position / self.SemiMajorAxis
    self.MeanAnomalyEpoch = Vector.angle(rel_position)
    self.MeanAnomaly = self.MeanAnomalyEpoch
    self.Epoch = GameState.CurrentTime
    self.OrbitalPeriod = Utils.Math.orbitalPeriod(self.SemiMajorAxis, self.Parent.Mass)

    --ba.println("Satellite:_recalculateOrbit(): " .. Inspect({ self.Name, self.OrbitalPeriod, math.deg(self.MeanAnomaly), math.deg(math.atan2(0.89165917083566, 0.45270732605588)), rel_position.x, rel_position.y }))
end

function Satellite:add(satellite)
    if satellite.Parent then
        satellite.Parent:remove(satellite)
    end

    self.Satellites[satellite.Name] = satellite
    self.StarSystem:add(satellite)
    satellite.Parent = self
end

function Satellite:remove(satellite)
    self.Satellites[satellite.Name] = nil
    self.StarSystem:remove(satellite)
    satellite.Parent = nil
end

function Satellite:getIcon()
    return self.Icon
end

function Satellite:update()
    --ba.println("Satellite:update(): " .. Inspect({ self.Name }))
    self:updatePosition()

    for _, sat in pairs(self.Satellites) do
        sat:update()
    end
end

function Satellite:updatePosition()
    --ba.println("Satellite:update(): " .. Inspect({ self.Name }))
    self:_updateMeanAnomaly()
    self.System.Position = Vector(1, 0)
    self.System.Position = self.System.Position * self.SemiMajorAxis
    self.System.Position:rotate(0, self.MeanAnomaly, 0)

    if self.Parent then
        self.System.Position = self.System.Position + self.Parent.System.Position
    end
end

function Satellite:copy()
    return Satellite(self)
end

return Satellite
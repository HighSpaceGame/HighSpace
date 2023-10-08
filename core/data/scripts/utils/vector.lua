local Class     = require("class")
local Inspect   = require('inspect')
local Utils     = require('utils')

local Vector = Class()

function Vector:init(x, y, z)
    --ba.println("Vector:init")
    self.x = x or 0.0
    self.y = y or 0.0
    self.z = z or 0.0

    local mt = getmetatable(self)
    mt.__add = function(v1, v2)
        return Vector(v1.x + v2.x, v1.y + v2.y, v1.z + v2.z)
    end

    mt.__sub = function(v1, v2)
        return Vector(v1.x - v2.x, v1.y - v2.y, v1.z - v2.z)
    end

    mt.__mul = function(v1, num)
        return Vector(v1.x * num, v1.y * num, v1.z * num)
    end

    mt.__div = function(v1, num)
        return Vector(v1.x / num, v1.y / num, v1.z / num)
    end

    setmetatable(self, mt)
end

function Vector:copy()
    return Vector(self.x, self.y, self.z)
end

function Vector:toFS2Vector()
    return ba.createVector(self.x, self.y, self.z)
end

function Vector:fromFS2Vector(vector)
    self.x = vector.x
    self.y = vector.y
    self.z = vector.z
end

function Vector:getSqrMagnitude()
    return (self.x*self.x + self.y*self.y + self.z*self.z)
end

function Vector:getMagnitude()
    return math.sqrt(self:getSqrMagnitude())
end

function Vector:floor()
    self.x = math.floor(self.x)
    self.y = math.floor(self.y)
    self.z = math.floor(self.z)

    return self
end

function Vector:normalize()
    local length = self:getMagnitude()

    self.x = self.x / length
    self.y = self.y / length
    self.z = self.z / length

    return self
end

--- Rotates a vector around the specified angles
--- Note: right now this is only used for the System Map so we only rotate around the Z-Axis (bank angle)
--- One day we might want to do proper matrix rotation
--- @param p number the pitch angle of rotation
--- @param b number the bank angle of rotation
--- @param h number the heading angle of rotation
function Vector:rotate(p, b, h)
    --We want a clockwise rotation
    local sinb = math.sin(-b)
    local cosb = math.cos(-b)

    self.x, self.y = self.x*cosb - self.y*sinb, self.x*sinb + self.y*cosb

    --ba.println("Vector:rotate(p, b, h) - " .. Inspect({b, sinb, cosb, self.x, self.y}))

    return self
end

function Vector.dot(lhs, rhs)
    return lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z
end

function Vector.angle(to, from)
    if not from then
        from = Vector(1, 0)
    end

    return math.atan2(to.x - from.x, to.y - from.y) * 2
end

return Vector
local Class           = require("class")
local SystemAI        = require("system_ai")
local Utils           = require('utils')

--- Symple System Map AI that chases the ship that generated the most Aggro
--- @class SystemSimpleAggroAI
local SystemSimpleAggroAI = Class(SystemAI)

--- Initialize object
--- @param ship Ship
function SystemSimpleAggroAI:init(ship)
    self.Ship = ship
    self.Aggro = {
        { ["Ship"] = GameState.System:get("Taganrog").Parent, ["Aggro"] = 50 }
    }
end

function SystemSimpleAggroAI:aggroLevel()
    local aggroInfo = self.Aggro[1]
    local distance = (aggroInfo.Ship.System.Position - self.Ship.System.Position):getMagnitude() / Utils.Math.AU

    return aggroInfo.Aggro / distance
end

function SystemSimpleAggroAI:update()
    table.sort(self.Aggro, function(a,b) return a.Aggro > b.Aggro end)
    local aggroInfo = self.Aggro[1]
    if not aggroInfo then return end

    local level = self:aggroLevel()
    if level < 100 then return end

    self.Ship.System.Destination = { ["Position"] = aggroInfo.Ship.System.Position - aggroInfo.Ship.Parent.System.Position }
    self.Ship.System.Destination.Parent = aggroInfo.Ship.Parent
    self.Ship.System.IsInSubspace = true
end

return SystemSimpleAggroAI
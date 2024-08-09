local Class      = require("class")
local Inspect    = require('inspect')
local Utils      = require('utils')

GameMapGenerator = Class()

--math.randomseed(1) -- For debugging
function GameMapGenerator.addShipToRandomOrbit(ship, system)
    system = system or GameState.System
    local target
    local n, s = 0, math.random(0, system:count("Astral") - 1)

    system:forEach(function(sat)
        if n == s then
            target = sat
            return false
        end
        n = n + 1
    end, "Astral")

    ship.MeanAnomalyEpoch = math.random() * 360
    if target.SemiMajorAxis > 0 then
        ship.SemiMajorAxis = Utils.Math.AU * 5 * math.random() + target.Radius * 2
    else
        ship.SemiMajorAxis = Utils.Math.AU * 35 * math.random()
    end
    target:add(ship)
end

return GameMapGenerator
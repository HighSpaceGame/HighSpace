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

    ship.Epoch = GameState.CurrentTime
    ship.MeanAnomalyEpoch = math.random() * Utils.Math.PITwo
    if target.SemiMajorAxis > 0 then
        ship.SemiMajorAxis = Utils.Math.AU * 5 * math.random() + target.Radius * 2
    else
        ship.SemiMajorAxis = Utils.Math.AU * 35 * math.random()
    end
    target:add(ship)
    ship:updatePosition()
    ship:recalculateOrbitParent()
end

function GameMapGenerator.chaseRandomShip(ship, chased_ships)
    local target
    local n, s = 0, math.random(0, #chased_ships - 1)

    for _, chased_ship in pairs(chased_ships) do
        if n == s then
            target = chased_ship
            break
        end
        n = n + 1
    end

    ship.Epoch = GameState.CurrentTime
    ship.SemiMajorAxis = Utils.Math.deviateFromAbs(target.SemiMajorAxis, Utils.Math.AU * 0.002, Utils.Math.AU * 0.01)
    ship.MeanAnomalyEpoch = Utils.Math.angleRangeForDistance(
            Utils.Math.AU * 0.01, Utils.Math.AU * 0.05,
            ship.SemiMajorAxis, target.SemiMajorAxis, target.MeanAnomalyEpoch
    )
    target.Parent:add(ship)
    ship:updatePosition()
end

return GameMapGenerator
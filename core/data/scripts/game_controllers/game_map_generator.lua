local Class      = require("class")
local Inspect    = require('inspect')
local Utils      = require('utils')

GameMapGenerator = Class()

math.randomseed(os.time())
function GameMapGenerator.addShipToRandomOrbit(ship, parent)
    local n = 0;
    local c = GameState.System:count("Astral")
    local s = math.random(1, c)
    ba.println("addShipToRandomOrbit "  .. Inspect({c, s}))
    local target

    GameState.System:forEach(function(sat)
        if n == s then
            target = sat
            return false
        end
        n = n + 1
    end, "Astral")

    if target.SemiMajorAxis > 0 then
        ship.SemiMajorAxis = math.random() * target.SemiMajorAxis / 2
    else
        ship.SemiMajorAxis = Utils.Math.AU * 20
    end
    target:add(ship)
end

return GameMapGenerator
local Class                     = require("class")
local SystemAI                  = require("system_ai")
local SystemSimpleAggroAI       = require("system_simple_aggro_ai")

--- Symple System Map AI that chases the ship that generated the most Aggro
--- @class AIController
--- @field private _system_ais SystemAI[]
AIController = Class()

--- @class AIProfileList
AIController.SystemAIs = {
    ["SystemSimpleAggroAI"] = SystemSimpleAggroAI,
}
--- @private
AIController._system_ais = {}

--- Assign a SystemAI to a ship
--- @param ship Ship
--- @param ai SystemAI
function AIController:addSystemAIToShip(ship, ai)
    self._system_ais[ship.Name] = ai(ship)
end

--- Process current frame by all AIs
function AIController:update()
    for ship_name, ai in pairs(self._system_ais) do
        ai:update()
    end
end

return AIController
local Class           = require("class")

--- Base class for System AI
--- @class SystemAI
local SystemAI = Class()

function SystemAI:init(properties, parent)
    self.Ship = properties.Ship
end

function SystemAI:update()
end

return SystemAI
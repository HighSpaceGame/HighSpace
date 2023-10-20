local Class          = require("class")
local Inspect        = require('inspect')
local ShipGroup      = require("ship_group")
local Utils          = require('utils')

local Wing = Class(ShipGroup)

function Wing:init(properties)
    ba.println("Wing:init: " .. Inspect(properties.Name))
end

function Wing:copy()
    return Wing(self)
end

return Wing
local Class          = require("class")
local GameObject     = require("game_object")
local Inspect        = require('inspect')
local ShipList       = require("ship_list")
local Utils          = require('utils')

local ShipGroup = Class(GameObject)

function ShipGroup:init(properties)
    self.Ships = ShipList()
end

function ShipGroup:forEach(callback)
    self.Ships:forEach(callback)
end

return ShipGroup
local Class     = require("class")
local Inspect   = require('inspect')
local Utils     = require('utils')

local ShipList = Class()

function ShipList:init(properties)
    self.List = {}
end

function ShipList:add(ship)
    self.List[ship.Name] = ship
end

function ShipList:get(ship_name)
    return self.List[ship_name]
end

function ShipList:forEach(callback)
    for _, ship in pairs(self.List) do
        callback(ship)
    end
end

return ShipList
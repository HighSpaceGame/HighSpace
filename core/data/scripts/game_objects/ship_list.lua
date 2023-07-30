local Class     = require("class")
local Inspect   = require('inspect')
local Utils     = require('utils')

local ShipList = Class()

function ShipList:init(properties)
    self.List = {}
end

function ShipList:clear()
    self.List = {}
end

function ShipList:add(ship)
    self.List[ship.Name] = ship
end

function ShipList:remove(ship_name)
    self.List[ship_name] = nil
end

function ShipList:get(ship_name)
    return self.List[ship_name]
end

function ShipList:forEach(callback)
    for _, ship in pairs(self.List) do
        local ret = callback(ship)

        if ret ~= nil and ret == false then
            break
        end
    end
end

return ShipList